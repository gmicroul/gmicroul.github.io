#!/bin/bash
set -e


echo "=============================="
echo " Hermes Agent"
echo "=============================="


echo "MODEL:"
echo "$OPENAI_MODEL"


echo "BASE:"
echo "$OPENAI_BASE_URL"


echo "KEY LENGTH:"
echo "${#OPENAI_API_KEY}"


mkdir -p /root/.hermes


envsubst < /tmp/config.yaml > /root/.hermes/config.yaml


echo "Hermes config installed"


grep -A6 "custom_providers" /root/.hermes/config.yaml || true


cd /opt/hermes-agent


hermes \
    --cli \
    -z "$@"


echo "Fix output permission"


if [ -d /output ]; then
    chmod -R a+rX /output
fi
