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

$clientAssetPackages = @(
    'client-assets\borries-better-lightsabers',
    'client-assets\project-kamino'
)
Write-Host "Installing Project Kamino's built-in client assets..."
foreach ($relativeAssetPath in $clientAssetPackages) {
    $clientAssetsPath = Join-Path $projectDir $relativeAssetPath
    if (Test-Path -LiteralPath $clientAssetsPath -PathType Container) {
        Get-ChildItem -LiteralPath $clientAssetsPath -Directory | ForEach-Object {
            $destination = Join-Path $ClientPath $_.Name
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Copy-Item -Path (Join-Path $_.FullName '*') -Destination $destination -Recurse -Force
        }
    }
}

$launcherSource = Join-Path $projectDir 'launcher\ProjectKaminoLauncher.exe'
if (Test-Path -LiteralPath $launcherSource -PathType Leaf) {
    $launcherDestination = Join-Path $ClientPath 'ProjectKaminoLauncher.exe'
    Copy-Item -LiteralPath $launcherSource -Destination $launcherDestination -Force

    $desktopPath = [Environment]::GetFolderPath('Desktop')
    if (-not [string]::IsNullOrWhiteSpace($desktopPath)) {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut((Join-Path $desktopPath 'Project Kamino.lnk'))
        $shortcut.TargetPath = $launcherDestination
        $shortcut.WorkingDirectory = $ClientPath
        $shortcut.IconLocation = "$launcherDestination,0"
        $shortcut.Description = 'Launch and configure Project Kamino'
        $shortcut.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
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
