FROM node:22-bookworm-slim
ARG SUPABASE_CLI_VERSION=2.115.0
ARG TARGETARCH=amd64
ENV NODE_ENV=production PORT=3000 DATA_DIR=/var/lib/vaultmanager BACKUP_DIR=/var/lib/vaultmanager/backups
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl postgresql-client tar awscli && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/supabase_${SUPABASE_CLI_VERSION}_linux_${TARGETARCH}.tar.gz" -o /tmp/supabase.tgz \
    && curl -fsSL "https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/checksums.txt" -o /tmp/supabase.checksums \
    && grep " supabase_${SUPABASE_CLI_VERSION}_linux_${TARGETARCH}.tar.gz$" /tmp/supabase.checksums | sha256sum -c - \
    && tar -xzf /tmp/supabase.tgz -C /usr/local/bin supabase \
    && rm /tmp/supabase.tgz /tmp/supabase.checksums \
    && useradd --system --uid 10001 --create-home vault
WORKDIR /app
COPY --chown=vault:vault package.json server.js public ./
COPY --chown=vault:vault scripts ./scripts
RUN mkdir -p /var/lib/vaultmanager/backups && chown -R vault:vault /var/lib/vaultmanager
USER vault
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD node -e "require('node:http').get('http://127.0.0.1:3000/',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"
CMD ["node","server.js"]
