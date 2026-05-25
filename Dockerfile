FROM codercom/code-server:latest

USER root

# System dependencies
RUN apt-get update && apt-get install -y \
    git curl build-essential sudo \
    && rm -rf /var/lib/apt/lists/*

# Optional runtimes — add or remove as you need
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Create the project directory that the volume will mount over
RUN mkdir -p /home/coder/project \
    && chown -R coder:coder /home/coder/project

USER coder
WORKDIR /home/coder/project

# Pre-install extensions (baked into the image, restored on every rebuild)
RUN code-server --install-extension esbenp.prettier-vscode \
    && code-server --install-extension dbaeumer.vscode-eslint

EXPOSE 8080

CMD ["sh", "-c", "exec code-server --bind-addr 0.0.0.0:${PORT:-8080} --auth password /home/coder/project"]
