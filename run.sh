#!/bin/bash
set -e


export PYTHONUNBUFFERED=1


echo "=============================="
echo " Hermes News Generator"
echo "=============================="


echo "MODEL:"
echo "$OPENAI_MODEL"


echo "BASE URL:"
echo "$OPENAI_BASE_URL"


echo "API KEY LENGTH:"
echo "${#OPENAI_API_KEY}"


if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY missing"
    exit 1
fi



mkdir -p /root/.hermes



cat > /root/.hermes/config.yaml <<EOF
model:
  default: ${OPENAI_MODEL}
  provider: custom
  api_key: ${OPENAI_API_KEY}
  base_url: ${OPENAI_BASE_URL}
  api_mode: chat_completions

providers: {}
EOF



echo "Hermes config:"
cat /root/.hermes/config.yaml | sed 's/api_key:.*/api_key: ******/'



mkdir -p /output



cd /opt/hermes-agent



echo "Starting Hermes CLI..."



timeout 20m uv run hermes \
    --cli \
    -z "$@"



echo "Hermes finished"


echo "Output files:"

ls -lah /output
