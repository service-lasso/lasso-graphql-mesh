$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

$required = @(
  (Join-Path $root 'service.json'),
  (Join-Path $root 'verify\service-harness.json'),
  (Join-Path $root 'runtime\start.mjs'),
  (Join-Path $root 'runtime\compose.mjs'),
  (Join-Path $root 'config\gateway.config.mjs'),
  (Join-Path $root 'config\mesh.config.mjs.example'),
  (Join-Path $root 'package-lock.json')
)

foreach ($path in $required) {
  if (-not (Test-Path $path)) {
    throw "Missing required file: $path"
  }
}

$service = Get-Content (Join-Path $root 'service.json') -Raw | ConvertFrom-Json
if ($service.id -ne 'graphql-mesh') {
  throw 'service.json id mismatch'
}

$manifestPaths = @((Join-Path $root 'service.json'))
$servicesRoot = Join-Path $root 'services'
if (Test-Path $servicesRoot) {
  $manifestPaths += Get-ChildItem -Path $servicesRoot -Recurse -Filter 'service.json' | ForEach-Object { $_.FullName }
}

foreach ($manifestPath in $manifestPaths) {
  $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
  if ($manifest.PSObject.Properties.Name -contains 'healthcheck') {
    throw "Singular healthcheck is not allowed in $manifestPath; use healthchecks[]."
  }
  if ($manifest.execconfig -and $manifest.execconfig.PSObject.Properties.Name -contains 'healthcheck') {
    throw "execconfig.healthcheck is not allowed in $manifestPath; use top-level healthchecks[]."
  }
  if ($manifest.PSObject.Properties.Name -contains 'healthchecks') {
    if ($null -eq $manifest.healthchecks -or -not ($manifest.healthchecks -is [array])) {
      throw "healthchecks must be an array in $manifestPath."
    }
    foreach ($check in $manifest.healthchecks) {
      if (-not $check.id) {
        throw "Every healthchecks[] item needs a stable id in $manifestPath."
      }
    }
  }
}

$contract = Get-Content (Join-Path $root 'verify\service-harness.json') -Raw | ConvertFrom-Json
if ($contract.serviceId -ne 'graphql-mesh') {
  throw 'service-harness.json serviceId mismatch'
}

foreach ($script in @('runtime\start.mjs', 'runtime\compose.mjs')) {
  & node --check (Join-Path $root $script)
  if ($LASTEXITCODE -ne 0) { throw "Node syntax check failed: $script" }
}

$result = & node (Join-Path $root 'runtime\start.mjs') 2>&1
if ($LASTEXITCODE -ne 2 -or (($result | Out-String) -notmatch 'required file is missing')) { throw 'Gateway preflight did not fail safely without a composed supergraph.' }

Write-Host 'Template tests passed (Windows)'
