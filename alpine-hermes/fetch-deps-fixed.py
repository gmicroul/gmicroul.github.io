#!/usr/bin/env python3
"""Download correct Linux/Pure wheels for platform-specific packages."""
import subprocess, os, json

OUT = "/home/phablet/alpine-browser-iso/hermes-deps"
PROXY = "http://192.168.2.209:7897"
UA = "Mozilla/5.0"

# Pkgs that need Linux/Pure wheels (replace macosx entries)
REPLACE = [
    ("cffi", "2.0.0"),
    ("charset-normalizer", "3.4.4"),
    ("cryptography", "46.0.3"),
    ("jiter", "0.11.1"),
    ("MarkupSafe", "3.0.3"),
    ("psutil", "7.2.2"),
    ("pydantic-core", "2.33.2"),
    ("PyYAML", "6.0.3"),
]

for name, version in REPLACE:
    print(f"--- {name}=={version} ---")
    url = f"https://pypi.org/pypi/{name}/{version}/json"
    r = subprocess.run(["curl", "-s", "-x", PROXY, "-H", f"User-Agent: {UA}", url],
                       capture_output=True, text=True, timeout=30)
    if r.returncode != 0:
        print(f"  CURL FAIL")
        continue
    try:
        data = json.loads(r.stdout)
    except:
        print(f"  PARSE FAIL")
        continue
    # Prioritize: linux x86 Pure → any Pure → linux x86 → source
    urls = data.get("urls", [])
    chosen = None
    priority = 999
    for u in urls:
        fn = u["filename"].lower()
        pt = u["packagetype"]
        score = 999
        if pt == "bdist_wheel":
            if "none-any" in fn or "py3-none-any" in fn:
                score = 1  # best: pure python
            elif "manylinux" in fn and ("i686" in fn or "x86" in fn):
                score = 5  # Linux x86
            elif "musllinux" in fn and "x86" in fn:
                score = 6  # musl linux
            elif "linux" in fn and ("i686" in fn or "x86" in fn):
                score = 7
            elif pt == "sdist" and "tar.gz" in fn:
                score = 90  # source, need compilation
        if score < priority:
            priority = score
            chosen = u["url"]
    if chosen:
        fname = chosen.rsplit("/", 1)[-1].split("#")[0]
        outpath = os.path.join(OUT, fname)
        # Remove old macosx variant
        for old in os.listdir(OUT):
            if old.startswith(name.lower()) and "macosx" in old:
                os.remove(os.path.join(OUT, old))
        print(f"  Downloading: {fname}")
        subprocess.run(["curl", "-L", "-x", PROXY, "-o", outpath, chosen],
                       capture_output=True, text=True, timeout=60)
        sz = os.path.getsize(outpath) if os.path.exists(outpath) else 0
        print(f"  Got: {sz} bytes")
    else:
        print(f"  No suitable wheel")

print(f"\n=== Final ===")
for f in sorted(os.listdir(OUT)):
    sz = os.path.getsize(os.path.join(OUT, f))
    print(f"  {f}: {sz}")
total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
print(f"Total: {total/1024/1024:.1f} MB")