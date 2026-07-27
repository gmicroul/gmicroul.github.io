#!/bin/bash
set -e


export PYTHONUNBUFFERED=1


echo "=============================="
echo " Hermes Agent"
echo "=============================="


echo "MODEL:"
echo "$OPENAI_MODEL"


echo "BASE:"
echo "$OPENAI_BASE_URL"


echo "KEY:"
echo "${#OPENAI_API_KEY} chars"


mkdir -p /root/.hermes


envsubst < /tmp/config.yaml > /root/.hermes/config.yaml


echo "Hermes config installed"


echo "Checking provider:"


grep -A6 "custom_providers" /root/.hermes/config.yaml



mkdir -p /output


cd /opt/hermes-agent


exec uv run hermes \
    --cli \
    -z "$@"
