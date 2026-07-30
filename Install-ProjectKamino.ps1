[CmdletBinding()]
param(
    [string]$BaseGamePath = 'C:\ProjectKamino\BaseGame',
    [string]$ClientPath = 'C:\ProjectKamino\Client',
    [switch]$SkipCompile,
    [switch]$SkipRun
)

$ErrorActionPreference = 'Stop'
$projectDir = $PSScriptRoot
Set-Location -LiteralPath $projectDir

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker Desktop is not installed or docker.exe is not available in PATH.'
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Desktop is not running or is not using Linux containers.'
}

if (-not (Test-Path -LiteralPath '.env')) {
    Copy-Item -LiteralPath '.env.example' -Destination '.env'
    Write-Host 'Created .env from .env.example.'
}

& "$projectDir\Initialize-AotcTreVolume.ps1" `
    -BaseGamePath $BaseGamePath `
    -ClientPath $ClientPath

& "$projectDir\Start-Aotc.ps1" -Rebuild

if (-not $SkipCompile) {
    & "$projectDir\Start-Aotc.ps1" -Compile
}

if (-not $SkipRun) {
    & "$projectDir\Start-Aotc.ps1" -Run
}

Write-Host 'Project Kamino installation is complete.'
