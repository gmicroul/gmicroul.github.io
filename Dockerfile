FROM python:3.12-slim


RUN apt update && apt install -y \
    git \
    curl \
    bash \
    nodejs \
    npm \
    ripgrep \
    gettext-base \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt


RUN git clone --depth=1 \
    https://github.com/NousResearch/hermes-agent.git


WORKDIR /opt/hermes-agent


RUN pip install --upgrade pip setuptools wheel


RUN pip install .


# 确认 hermes 安装位置
RUN which hermes || true
RUN python3 -m pip show hermes-agent || true


COPY config.yaml /tmp/config.yaml

COPY run.sh /usr/local/bin/run-hermes


RUN chmod +x /usr/local/bin/run-hermes


ENTRYPOINT ["run-hermes"]
