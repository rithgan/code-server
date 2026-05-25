FROM codercom/code-server:latest

USER root

# System dependencies
RUN apt-get update && apt-get install -y \
    git curl build-essential sudo \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 (required for Claude Code)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Stage extensions where the volume won't shadow them
RUN mkdir -p /opt/code-server-seed/extensions \
    && chown -R coder:coder /opt/code-server-seed

USER coder
RUN code-server \
        --extensions-dir /opt/code-server-seed/extensions \
        --install-extension esbenp.prettier-vscode \
    && code-server \
        --extensions-dir /opt/code-server-seed/extensions \
        --install-extension dbaeumer.vscode-eslint \
    && code-server \
        --extensions-dir /opt/code-server-seed/extensions \
        --install-extension anthropic.claude-code

# Entrypoint: seed volume as root, then drop to coder via su
USER root
RUN cat > /usr/local/bin/start.sh <<'EOF'
#!/bin/bash
set -e

# Make sure the home dir skeleton exists on the volume
mkdir -p /home/coder/project
mkdir -p /home/coder/.local/share/code-server
mkdir -p /home/coder/.config/code-server

# Seed extensions if the volume doesn't have them yet
if [ ! -d /home/coder/.local/share/code-server/extensions ] || \
   [ -z "$(ls -A /home/coder/.local/share/code-server/extensions 2>/dev/null)" ]; then
    echo "Seeding extensions into volume..."
    mkdir -p /home/coder/.local/share/code-server/extensions
    cp -rn /opt/code-server-seed/extensions/. /home/coder/.local/share/code-server/extensions/
fi

# Fix ownership — the volume may mount as root-owned
chown -R coder:coder /home/coder

# Drop to the coder user and launch code-server
exec su coder -c "code-server --bind-addr 0.0.0.0:8080 --auth password /home/coder/project"
EOF
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8080
ENV PORT=8080

ENTRYPOINT []
CMD ["/usr/local/bin/start.sh"]
