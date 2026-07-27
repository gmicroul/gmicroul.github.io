FROM python:3.12-slim


RUN apt update && apt install -y \
    git \
    curl \
    nodejs \
    npm \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /opt


RUN git clone \
https://github.com/NousResearch/hermes-agent.git \
hermes-agent


WORKDIR /opt/hermes-agent


RUN pip install --no-cache-dir -r requirements.txt


COPY run.sh /usr/local/bin/run-hermes

RUN chmod +x /usr/local/bin/run-hermes


ENTRYPOINT ["run-hermes"]
