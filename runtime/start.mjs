import { access } from "node:fs/promises";
import { spawn } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const runtimeRoot = dirname(fileURLToPath(import.meta.url));
const serviceRoot = resolve(runtimeRoot, "..");
const configPath = process.env.GRAPHQL_MESH_GATEWAY_CONFIG ?? resolve(serviceRoot, "config", "gateway.config.mjs");
const supergraphPath = process.env.GRAPHQL_MESH_SUPERGRAPH_PATH ?? resolve(runtimeRoot, "supergraph.graphql");
const gatewayBin = resolve(runtimeRoot, "node_modules", "@graphql-hive", "gateway", "dist", "bin.js");

for (const requiredPath of [configPath, supergraphPath, gatewayBin]) {
  try {
    await access(requiredPath);
  } catch {
    console.error(`GraphQL Mesh cannot start: required file is missing: ${requiredPath}`);
    console.error("Run the compose helper after supplying a Mesh compose configuration, then retry.");
    process.exit(2);
  }
}

const child = spawn(process.execPath, [gatewayBin, "--config-path", configPath], {
  cwd: serviceRoot,
  env: { ...process.env, GRAPHQL_MESH_SUPERGRAPH_PATH: supergraphPath },
  stdio: "inherit",
});

child.on("exit", (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
child.on("error", (error) => {
  console.error(`GraphQL Mesh gateway failed to launch: ${error.message}`);
  process.exit(1);
});
