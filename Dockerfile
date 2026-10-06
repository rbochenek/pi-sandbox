FROM node:24-bookworm-slim

# docker CLI + compose let the agent drive the HOST docker daemon (the
# wrapper bind-mounts the host socket in; see pi-sandbox). Debian's
# docker-compose is v2 — symlink it into the cli-plugins dir so the
# 'docker compose' form works as well as the standalone 'docker-compose'.
RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep kitty-terminfo python3 curl procps less file build-essential pkg-config docker.io docker-compose \
  && mkdir -p /usr/libexec/docker/cli-plugins \
  && ln -sf /usr/bin/docker-compose /usr/libexec/docker/cli-plugins/docker-compose \
  && rm -rf /var/lib/apt/lists/*

# Non-root user pi runs as. The wrapper passes --user "$(id -u):$(id -g)",
# which Docker accepts for ANY uid/gid (no passwd entry needed), so files
# created on bind mounts (sessions included) are owned by the invoking host
# user. The 'agent' user just provides the home dir skeleton; it is made
# world-writable (1777) so any uid can use it as HOME. Replaces the stock
# 'node' user to avoid a uid clash.
RUN groupdel node 2>/dev/null || true \
  && userdel -r node 2>/dev/null || true \
  && groupadd -g 1000 agent \
  && useradd -m -u 1000 -g agent -s /bin/bash agent \
  && mkdir -p /home/agent/.pi/agent \
  && chmod -R 1777 /home/agent

# Install Rust via rustup (system-wide, minimal profile)
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
  | sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable \
  && chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME"

# Headless browser for the agent: Debian's chromium (all runtime deps come
# with it and it works for any uid, unlike a per-HOME Chrome download) driven
# through agent-browser, a CLI built for AI agents (open/snapshot/click/...).
# --no-sandbox: Chrome's sandbox needs user namespaces, which Docker's default
# seccomp profile blocks. --disable-dev-shm-usage: /dev/shm is 64MB in Docker.
RUN apt-get update \
  && apt-get install -y --no-install-recommends chromium fonts-liberation \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g agent-browser
ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/bin/chromium \
    AGENT_BROWSER_ARGS=--no-sandbox,--disable-dev-shm-usage \
    AGENT_BROWSER_SOCKET_DIR=/tmp/agent-browser

# Install Pi
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
# Install openspec
RUN npm install -g @fission-ai/openspec@latest

ENTRYPOINT ["pi"]
