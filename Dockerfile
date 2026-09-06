FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep kitty-terminfo python3 curl procps less file build-essential pkg-config \
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

# Install Pi
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
# Install openspec
RUN npm install -g @fission-ai/openspec@latest

ENTRYPOINT ["pi"]
