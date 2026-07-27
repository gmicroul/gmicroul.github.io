FROM python:3.12-slim


RUN apt update && apt install -y \
    git \
    curl \
    build-essential \
    python3-dev \
    nodejs \
    npm \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt


RUN git clone \
https://github.com/NousResearch/hermes-agent.git


WORKDIR /opt/hermes-agent


RUN pip install --upgrade pip setuptools wheel


RUN pip install .


COPY run.sh /usr/local/bin/run-hermes

RUN chmod +x /usr/local/bin/run-hermes


ENTRYPOINT ["run-hermes"]
