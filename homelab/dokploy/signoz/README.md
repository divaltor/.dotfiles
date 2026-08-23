# SigNoz on Dokploy

This is the SigNoz Foundry deployment adapted into one Dokploy Compose file.
Use **Docker Compose**, not Docker Stack.

## Install

1. Generate the JWT and OTLP secrets and save them in 1Password:

   ```sh
   openssl rand -hex 32 # SIGNOZ_TOKENIZER_JWT_SECRET
   openssl rand -hex 32 # SIGNOZ_OTLP_TOKEN
   ```

2. Create a Dokploy Compose service with these environment variables:

   ```dotenv
   SIGNOZ_TOKENIZER_JWT_SECRET=<generated JWT secret>
   SIGNOZ_OTLP_TOKEN=<generated OTLP token>
   ```

3. Use the Git source and Compose path:

   ```text
   ./homelab/dokploy/signoz/compose.yaml
   ```

4. Add a domain and deploy:

   ```text
   Service:        signoz-signoz-0
   Container port: 8080
   Path:           /
   ```

5. In Cloudflare tunnel `divaos`, publish the ingestion route:

   ```text
   Hostname: otlp.divaltor.dev
   Service:  http://localhost:4318
   ```

The one-shot user-script and migrator services must exit with code `0`. Send
telemetry with the OTLP bearer token:

```dotenv
OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.divaltor.dev
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer%20<SIGNOZ_OTLP_TOKEN>
```

Inside the homelab, `http://homelab.local:4318` can be used instead with the
same token.
