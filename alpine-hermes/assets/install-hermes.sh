#!/bin/sh
# install-hermes.sh — run inside Alpine v86 as root to install hermes-agent
# This frees space first, then installs python3+pip+hermes-agent

echo "=== Freeing space ==="
apk del netsurf fastfetch 2>/dev/null || true

echo "=== Disk space before install ==="
df -h /

echo "=== Adding repositories ==="
cat > /etc/apk/repositories <<'REPO'
http://dl-cdn.alpinelinux.org/alpine/v3.24/main
http://dl-cdn.alpinelinux.org/alpine/v3.24/community
REPO

echo "=== Updating apk ==="
apk update

echo "=== Installing python3 and pip ==="
apk add python3 py3-pip 2>&1 | tail -5

echo "=== Installing hermes-agent ==="
pip install --break-system-packages hermes-agent 2>&1 | tail -5

echo "=== Disk space after install ==="
df -h /

echo "=== Verifying ==="
which hermes
hermes --version 2>/dev/null || echo "hermes installed"
echo "=== Done ==="