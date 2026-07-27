#!/bin/bash
set -e


echo "=============================="
echo " Hermes News Generator"
echo "=============================="


echo "OPENAI_BASE_URL:"
echo "$OPENAI_BASE_URL"


echo "OPENAI_MODEL:"
echo "$OPENAI_MODEL"


echo "OPENAI_API_KEY length:"
echo "${#OPENAI_API_KEY}"


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


mkdir -p /output


cd /opt/hermes-agent


TASK="$@"


if [ -z "$TASK" ]; then
    TASK="生成新闻页面"
fi


echo ""
echo "Task:"
echo "$TASK"
echo ""


exec uv run hermes \
    -z "$TASK" \
    -m "$OPENAI_MODEL" \
    --provider openai
