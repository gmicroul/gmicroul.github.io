#!/bin/bash
set -e


echo "======================"
echo " Hermes Agent Start "
echo "======================"


echo "MODEL=$OPENAI_MODEL"
echo "BASE_URL=$OPENAI_BASE_URL"


if [ -z "$OPENAI_API_KEY" ]; then
    echo "Missing OPENAI_API_KEY"
    exit 1
fi


cd /opt/hermes-agent


exec uv run hermes "$@"
