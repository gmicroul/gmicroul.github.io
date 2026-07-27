#!/bin/bash
set -e

echo "================================="
echo " Hermes Agent Starting"
echo "================================="


# 检查 API Key

if [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "ERROR:"
    echo "No AI API key found"
    echo "Please set OPENAI_API_KEY or ANTHROPIC_API_KEY"
    exit 1
fi


# 创建配置目录

mkdir -p /root/.hermes


echo "Environment:"
echo "Python:"
python3 --version

echo "Node:"
node --version || true


echo ""
echo "Starting Hermes..."
echo ""


# 启动 Hermes

cd /opt/hermes-agent


exec python3 -m hermes "$@"
