#!/bin/bash
set -e


echo "=============================="
echo " Hermes Automation Runner"
echo "=============================="


echo "MODEL=$OPENAI_MODEL"
echo "BASE_URL=$OPENAI_BASE_URL"


if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY missing"
    exit 1
fi


cd /opt/hermes-agent


TASK="$@"


if [ -z "$TASK" ]; then
    TASK="请生成一份日报。"
fi


echo "Task:"
echo "$TASK"


exec uv run hermes -z "$TASK"
