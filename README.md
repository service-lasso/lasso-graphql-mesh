# GraphQL Mesh for Service Lasso

This package pins GraphQL Mesh Compose and Hive Gateway into a Service Lasso
release artifact. Mesh v1 composes a supergraph; Hive Gateway serves it.

## Operator flow

1. Copy `config/mesh.config.mjs.example` outside source control and declare the
   approved subgraphs and credentials through environment variables.
2. Run `node runtime/compose.mjs` to generate `runtime/supergraph.graphql`.
3. Start through Service Lasso. The package refuses to start without the composed
   supergraph, avoiding a misleading healthy process.

## Validate

```powershell
pwsh -NoLogo -NoProfile -File ./scripts/test.ps1
pwsh -NoLogo -NoProfile -File ./scripts/package.ps1
```

No release is published by this development work. The manifest points at this
repository's future release assets; consumers must use a real tagged release and
checksum before treating acquisition as qualified.
