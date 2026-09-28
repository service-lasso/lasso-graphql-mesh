# Upstream runtime decision

The package uses GraphQL Mesh v1's two-part model:

- `@graphql-mesh/compose-cli` **1.8.2** composes a supergraph from explicitly
  configured subgraphs.
- `@graphql-hive/gateway` **2.15.0** serves that supergraph.
- `graphql` **16.14.2** is pinned because Gateway 2.15 declares GraphQL 15/16
  as its compatible peer range; forcing GraphQL 17 would leave an invalid tree.

This follows the current Mesh documentation: v1 composes and a Gateway serves
the resulting supergraph. The package does not use legacy Mesh v0's combined
`mesh start` runtime.

`config/mesh.config.mjs.example` deliberately contains no real service URL or
credential. An operator supplies approved subgraphs and secret delivery through
the Service Lasso configuration boundary, runs composition, and only then starts
the managed gateway. This prevents a package artifact from silently connecting
to an invented upstream or shipping credentials.
