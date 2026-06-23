#!/usr/bin/env python3
"""Validate config changes for issue #4 (MCP 권한 설정 전면 재검토).

Checks that each subtask's intended change is present and that the k8s
manifests remain syntactically valid YAML. Run with:

    python3 tests/validate_config.py
"""
import pathlib
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
FAILURES = []


def check(name, cond, detail=""):
    status = "PASS" if cond else "FAIL"
    print(f"[{status}] {name}" + (f" — {detail}" if detail and not cond else ""))
    if not cond:
        FAILURES.append(name)


def load_all(rel):
    return list(yaml.safe_load_all((ROOT / rel).read_text()))


def find(docs, kind):
    return next((d for d in docs if d and d.get("kind") == kind), None)


# --- st-1: agent-prompt.md grants full access to all MCP servers ---
prompt = (ROOT / "agent-prompt.md").read_text()
check("st-1 prompt declares full access", "풀 권한" in prompt and "Full Access" in prompt)
check("st-1 hard prohibition removed", "절대 사용하지 않는 MCP" not in prompt)
check("st-1 routing is recommendation-only", "폴백 가능" in prompt)

# --- st-2: ingress CORS + proxy ---
ing = find(load_all("k8s/ingress.yaml"), "Ingress")
ann = ing["metadata"]["annotations"]
check("st-2 cors-allow-origin is '*'", ann["nginx.ingress.kubernetes.io/cors-allow-origin"] == "*")
check("st-2 PATCH allowed in cors methods", "PATCH" in ann["nginx.ingress.kubernetes.io/cors-allow-methods"])
check(
    "st-2 credentials false with wildcard origin",
    ann["nginx.ingress.kubernetes.io/cors-allow-credentials"] == "false",
)
check("st-2 proxy-buffering disabled", ann.get("nginx.ingress.kubernetes.io/proxy-buffering") == "off")

# --- st-3: deployment resources + env vars ---
dep = find(load_all("k8s/deployment.yaml"), "Deployment")
container = dep["spec"]["template"]["spec"]["containers"][0]
env_names = {e["name"] for e in container["env"]}
check("st-3 GIT_DEFAULT_BRANCH env set", "GIT_DEFAULT_BRANCH" in env_names)
check("st-3 GIT_USER_NAME env set", "GIT_USER_NAME" in env_names)
check("st-3 GIT_USER_EMAIL env set", "GIT_USER_EMAIL" in env_names)
check("st-3 cpu limit raised to 4000m", container["resources"]["limits"]["cpu"] == "4000m")

# --- st-4: builder resources ---
builder = find(load_all("k8s/builder.yaml"), "Pod")
bres = builder["spec"]["containers"][0]["resources"]
check("st-4 builder mem limit 6Gi", bres["limits"]["memory"] == "6Gi")
check("st-4 builder cpu request 1000m", bres["requests"]["cpu"] == "1000m")

# --- st-5: secret uses placeholders, no real key committed ---
sec_text = (ROOT / "k8s/secret.yaml").read_text()
check("st-5 ANTHROPIC_API_KEY is placeholder", "<base64-encoded-key>" in sec_text)
check("st-5 no leaked secret value", "c2VjcmV0LWtleS1yZXZpc2Vk" not in sec_text)

if FAILURES:
    print(f"\n{len(FAILURES)} check(s) failed: {', '.join(FAILURES)}")
    sys.exit(1)
print("\nAll config checks passed.")
