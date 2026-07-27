#!/bin/bash
set -e


echo "=============================="
echo " Hermes Automation Runner"
echo "=============================="


echo "MODEL:"
echo "$OPENAI_MODEL"

echo "BASE_URL:"
echo "$OPENAI_BASE_URL"


if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY missing"
    exit 1
fi


mkdir -p /output


cd /opt/hermes-agent


TASK="$@"


if [ -z "$TASK" ]; then
    TASK="Generate a report."
fi


echo ""
echo "Task:"
echo "$TASK"
echo ""


exec uv run hermes "$TASK"
