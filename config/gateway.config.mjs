import { defineConfig } from "@graphql-hive/gateway";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const serviceRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");

export const gatewayConfig = defineConfig({
  supergraph: process.env.GRAPHQL_MESH_SUPERGRAPH_PATH ?? resolve(serviceRoot, "runtime", "supergraph.graphql"),
  host: process.env.GRAPHQL_MESH_HOST ?? "127.0.0.1",
  port: Number.parseInt(process.env.GRAPHQL_MESH_PORT ?? "4000", 10),
  graphqlEndpoint: process.env.GRAPHQL_MESH_ENDPOINT ?? "/graphql",
});
