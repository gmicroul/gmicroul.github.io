FROM python:3.12-slim


RUN apt update && apt install -y \
    git \
    curl \
    bash \
    nodejs \
    npm \
    ripgrep \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt


RUN git clone --depth=1 \
    https://github.com/NousResearch/hermes-agent.git


WORKDIR /opt/hermes-agent


RUN curl -LsSf https://astral.sh/uv/install.sh | sh


ENV PATH="/root/.local/bin:$PATH"


RUN uv sync


COPY config.yaml /tmp/config.yaml

COPY run.sh /usr/local/bin/run-hermes


RUN chmod +x /usr/local/bin/run-hermes


ENTRYPOINT ["run-hermes"]
