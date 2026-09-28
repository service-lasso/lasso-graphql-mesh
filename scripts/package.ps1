$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
$runtime = Join-Path $root 'runtime'
$staging = Join-Path $dist 'graphql-mesh-win32'
$zipPath = Join-Path $dist 'graphql-mesh-win32.zip'

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Force -Path $staging | Out-Null

Copy-Item -Recurse -Force $runtime (Join-Path $staging 'runtime')
Copy-Item -Recurse -Force (Join-Path $root 'config') (Join-Path $staging 'config')
Copy-Item (Join-Path $root 'package.json') (Join-Path $staging 'runtime\package.json')
Copy-Item (Join-Path $root 'package-lock.json') (Join-Path $staging 'runtime\package-lock.json')
& npm ci --omit=dev --ignore-scripts --prefix (Join-Path $staging 'runtime')
if ($LASTEXITCODE -ne 0) { throw 'npm ci failed while staging GraphQL Mesh runtime dependencies.' }

if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath
Write-Host "Created $zipPath"
