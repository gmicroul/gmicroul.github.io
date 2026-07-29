#!/bin/bash
set -e


echo "=============================="
echo " Hermes Agent"
echo "=============================="


export HOME=/root


mkdir -p /root/.hermes


if [ -f /tmp/config.yaml ]; then
    envsubst < /tmp/config.yaml > /root/.hermes/config.yaml
fi


echo "===== Config ====="

cat /root/.hermes/config.yaml || true

echo "=================="


cd /opt/hermes-agent


echo "Starting Hermes..."


exec uv run hermes -z "$@"
