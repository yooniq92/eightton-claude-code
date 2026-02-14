#!/usr/bin/env node
/**
 * MCP Proxy - Strips outputSchema + adds request/response logging.
 *
 * Architecture: supergateway → proxy.mjs (stdio) → claude mcp serve (stdio)
 */
import { spawn } from "child_process";
import { createInterface } from "readline";

const LOG_PREFIX = "[mcp-proxy]";

function ts() {
  return new Date().toISOString();
}

function log(msg) {
  process.stderr.write(`${LOG_PREFIX} ${ts()} ${msg}\n`);
}

function summarizeToolCall(params) {
  const name = params?.name ?? "?";
  const args = params?.arguments ?? {};

  switch (name) {
    case "Bash":
      return `Bash: ${args.command?.slice(0, 120) ?? ""}`;
    case "Read":
      return `Read: ${args.file_path ?? ""}`;
    case "Write":
      return `Write: ${args.file_path ?? ""}`;
    case "Edit":
      return `Edit: ${args.file_path ?? ""} (${args.old_string?.slice(0, 40) ?? ""}...)`;
    case "Glob":
      return `Glob: ${args.pattern ?? ""} in ${args.path ?? "cwd"}`;
    case "Grep":
      return `Grep: "${args.pattern ?? ""}" in ${args.path ?? "cwd"}`;
    case "Task":
      return `Task: [${args.subagent_type}] ${args.description ?? ""}`;
    default:
      return `${name}: ${JSON.stringify(args).slice(0, 100)}`;
  }
}

function summarizeToolResult(result) {
  const content = result?.content;
  if (!Array.isArray(content)) return "no content";

  const text = content
    .filter((c) => c.type === "text")
    .map((c) => c.text)
    .join("");

  if (text.length <= 200) return text;
  return text.slice(0, 200) + `... (${text.length} chars)`;
}

const child = spawn("claude", ["mcp", "serve"], {
  stdio: ["pipe", "pipe", "pipe"],
});

// Forward child stderr to our stderr (claude code's own logs)
child.stderr.on("data", (data) => {
  process.stderr.write(data);
});

log("Proxy started, spawned 'claude mcp serve'");

// === Inbound: supergateway → child ===
const inRl = createInterface({ input: process.stdin, crlfDelay: Infinity });

inRl.on("line", (line) => {
  try {
    const msg = JSON.parse(line);

    if (msg.method === "tools/call") {
      log(`→ CALL [id=${msg.id}] ${summarizeToolCall(msg.params)}`);
    } else if (msg.method === "tools/list") {
      log(`→ LIST tools [id=${msg.id}]`);
    } else if (msg.method === "initialize") {
      log(`→ INIT [id=${msg.id}] client=${msg.params?.clientInfo?.name ?? "?"}`);
    } else if (msg.method) {
      log(`→ ${msg.method} [id=${msg.id ?? "notif"}]`);
    }
  } catch {
    // non-JSON, pass through
  }
  child.stdin.write(line + "\n");
});

// === Outbound: child → supergateway ===
const outRl = createInterface({ input: child.stdout, crlfDelay: Infinity });

outRl.on("line", (line) => {
  try {
    const msg = JSON.parse(line);

    // Strip outputSchema from tools/list responses
    if (msg.result && Array.isArray(msg.result.tools)) {
      const count = msg.result.tools.length;
      msg.result.tools = msg.result.tools.map((tool) => {
        const { outputSchema, ...rest } = tool;
        return rest;
      });
      log(`← LIST [id=${msg.id}] ${count} tools (outputSchema stripped)`);
    }
    // Log tool call results
    else if (msg.result?.content) {
      const summary = summarizeToolResult(msg.result);
      const isError = msg.result.isError;
      log(`← RESULT [id=${msg.id}]${isError ? " ERROR" : ""} ${summary}`);
    }
    // Log errors
    else if (msg.error) {
      log(`← ERROR [id=${msg.id}] ${msg.error.code}: ${msg.error.message}`);
    }

    process.stdout.write(JSON.stringify(msg) + "\n");
  } catch {
    process.stdout.write(line + "\n");
  }
});

child.on("exit", (code) => {
  log(`Child process exited with code ${code}`);
  process.exit(code ?? 1);
});
process.on("SIGTERM", () => {
  log("SIGTERM received, killing child");
  child.kill("SIGTERM");
});
process.on("SIGINT", () => {
  log("SIGINT received, killing child");
  child.kill("SIGINT");
});
