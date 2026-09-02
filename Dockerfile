FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep kitty-terminfo python3 curl procps less build-essential pkg-config \
  && rm -rf /var/lib/apt/lists/*

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
