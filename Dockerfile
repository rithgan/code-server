FROM codercom/code-server:latest

USER root

# System dependencies
RUN apt-get update && apt-get install -y \
    git curl build-essential sudo \
    && rm -rf /var/lib/apt/lists/*

# Optional runtimes
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Create the project directory that the volume will mount over
RUN mkdir -p /home/coder/project \
    && chown -R coder:coder /home/coder/project

USER coder
WORKDIR /home/coder/project

# Pre-install extensions
RUN code-server --install-extension esbenp.prettier-vscode \
    && code-server --install-extension dbaeumer.vscode-eslint

EXPOSE 8080
ENV PORT=8080

# Override the base image's entrypoint so it doesn't wrap our command
ENTRYPOINT []
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password", "/home/coder/project"]
