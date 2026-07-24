#!/usr/bin/env python3
"""Download all hermes-agent wheel dependencies from PyPI."""
import subprocess, os, re, json, sys

OUT = "/home/phablet/alpine-browser-iso/hermes-deps"
os.makedirs(OUT, exist_ok=True)

DEPS = [
    "openai==2.24.0", "python-dotenv==1.2.2", "fire==0.7.1",
    "httpx==0.28.1", "rich==14.3.3", "tenacity==9.1.4",
    "pyyaml==6.0.3", "ruamel.yaml==0.18.17", "requests==2.33.0",
    "jinja2==3.1.6", "pydantic==2.13.4", "prompt_toolkit==3.0.52",
    "croniter==6.0.0", "PyJWT==2.12.1", "psutil==7.2.2",
    "socksio==1.0.0", "httpcore==1.0.9", "anyio==4.11.0",
    "h11==0.16.0", "certifi==2025.11.12", "idna==3.10",
    "markdown-it-py==3.0.0", "mdurl==0.1.2", "pygments==2.19.2",
    "typing-extensions==4.15.0", "annotated-types==0.7.0",
    "pydantic-core==2.33.2", "MarkupSafe==3.0.3",
    "wcwidth==0.2.14", "python-dateutil==2.9.0.post0",
    "six==1.17.0", "charset-normalizer==3.4.4",
    "urllib3==2.5.0", "distro==1.9.0", "jiter==0.11.1",
    "sniffio==1.3.1", "tqdm==4.67.1", "colorama==0.4.6",
    "termcolor==3.1.0", "cryptography==46.0.3",
    "cffi==2.0.0", "pycparser==2.23",
]

PROXY = "http://192.168.2.209:7897"
UA = "Mozilla/5.0"

for dep in DEPS:
    name = dep.split("==")[0]
    version = dep.split("==")[1] if "==" in dep else None
    print(f"--- {dep} ---")
    # Get JSON from pypi.org
    url = f"https://pypi.org/pypi/{name}/{version}/json" if version else f"https://pypi.org/pypi/{name}/json"
    cmd = ["curl", "-s", "-x", PROXY, "-H", f"User-Agent: {UA}", url]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    if r.returncode != 0:
        print(f"  FAIL: {r.stderr[:100]}")
        continue
    try:
        data = json.loads(r.stdout)
    except:
        print(f"  PARSE FAIL: {r.stdout[:100]}")
        continue
    # Get any wheel URL for the version
    urls = data.get("urls", [])
    wheel_url = None
    for u in urls:
        if u["packagetype"] == "bdist_wheel" and (u["filename"].endswith("-py3-none-any.whl") or f"-{version}-" in u["filename"]):
            wheel_url = u["url"]
            break
    if not wheel_url:
        print(f"  No suitable wheel found")
        continue
    fname = wheel_url.rsplit("/", 1)[-1].split("#")[0]
    outpath = os.path.join(OUT, fname)
    if os.path.exists(outpath) and os.path.getsize(outpath) > 1000:
        print(f"  SKIP already: {fname}")
        continue
    print(f"  Downloading: {fname}")
    cmd2 = ["curl", "-L", "-x", PROXY, "-o", outpath, wheel_url]
    r2 = subprocess.run(cmd2, capture_output=True, text=True, timeout=60)
    sz = os.path.getsize(outpath) if os.path.exists(outpath) else 0
    print(f"  Got: {sz} bytes")

print(f"\n=== Total ===")
for f in sorted(os.listdir(OUT)):
    sz = os.path.getsize(os.path.join(OUT, f))
    print(f"  {f}: {sz}")
total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
print(f"Total: {total} bytes ({total/1024/1024:.1f} MB)")