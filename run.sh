#!/bin/bash
set -e


echo "=============================="
echo " Hermes Agent CI Runner"
echo "=============================="


if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY missing"
    exit 1
fi


if [ -z "$OPENAI_BASE_URL" ]; then
    echo "ERROR: OPENAI_BASE_URL missing"
    exit 1
fi


if [ -z "$OPENAI_MODEL" ]; then
    echo "ERROR: OPENAI_MODEL missing"
    exit 1
fi


echo "Model:"
echo "$OPENAI_MODEL"

echo "Base URL:"
echo "$OPENAI_BASE_URL"


mkdir -p /root/.hermes


cd /opt/hermes-agent


echo "Starting Hermes..."


exec hermes "$@"
