FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep kitty-terminfo \
  && rm -rf /var/lib/apt/lists/*

# Install Pi
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
# Install openspec
RUN npm install -g @fission-ai/openspec@latest

ENTRYPOINT ["pi"]
