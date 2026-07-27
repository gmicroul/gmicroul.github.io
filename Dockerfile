FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1


RUN apt update && apt install -y \
    git \
    curl \
    ca-certificates \
    build-essential \
    python3-dev \
    nodejs \
    npm \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt


RUN git clone --depth=1 \
    https://github.com/NousResearch/hermes-agent.git \
    hermes-agent


WORKDIR /opt/hermes-agent


RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:$PATH"


RUN uv sync


COPY run.sh /usr/local/bin/run-hermes

RUN chmod +x /usr/local/bin/run-hermes


ENTRYPOINT ["run-hermes"]
