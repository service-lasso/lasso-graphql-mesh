import { access, mkdir } from "node:fs/promises";
import { spawn } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const runtimeRoot = dirname(fileURLToPath(import.meta.url));
const serviceRoot = resolve(runtimeRoot, "..");
const configPath = process.env.GRAPHQL_MESH_COMPOSE_CONFIG ?? resolve(serviceRoot, "config", "mesh.config.mjs");
const outputPath = process.env.GRAPHQL_MESH_SUPERGRAPH_PATH ?? resolve(runtimeRoot, "supergraph.graphql");
const composeBin = resolve(runtimeRoot, "node_modules", "@graphql-mesh", "compose-cli", "esm", "bin.js");

for (const requiredPath of [configPath, composeBin]) {
  try {
    await access(requiredPath);
  } catch {
    console.error(`GraphQL Mesh cannot compose: required file is missing: ${requiredPath}`);
    console.error("Copy config/mesh.config.mjs.example to a protected operator configuration and declare real subgraphs.");
    process.exit(2);
  }
}

await mkdir(dirname(outputPath), { recursive: true });
const child = spawn(process.execPath, [composeBin, "--config-path", configPath, "--output", outputPath], {
  cwd: serviceRoot,
  env: process.env,
  stdio: "inherit",
});
child.on("exit", (code, signal) => process.exit(code ?? (signal ? 1 : 0)));
child.on("error", (error) => {
  console.error(`GraphQL Mesh composition failed to launch: ${error.message}`);
  process.exit(1);
});
