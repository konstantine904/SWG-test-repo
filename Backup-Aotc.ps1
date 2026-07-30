[CmdletBinding()]
param([string]$Destination = (Join-Path $PSScriptRoot 'backups'))

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$archive = Join-Path $Destination "project-kamino-$stamp.tar.gz"

docker run --rm `
    --mount 'type=volume,source=project-kamino-home,target=/data,readonly' `
    --mount "type=bind,source=$Destination,target=/backup" `
    alpine:3.22 tar -czf "/backup/project-kamino-$stamp.tar.gz" -C /data .
if ($LASTEXITCODE -ne 0) { throw 'Backup failed.' }
Write-Host "Backup created: $archive"
