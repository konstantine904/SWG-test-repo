[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'ProjectKaminoLauncher.cs'
$output = Join-Path $PSScriptRoot 'ProjectKaminoLauncher.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$assetBuildDirectory = Join-Path $PSScriptRoot 'build\client-assets'
$assetArchive = Join-Path $PSScriptRoot 'build\ProjectKaminoClientAssets.zip'

if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw "The .NET Framework C# compiler was not found at $compiler."
}

if (Test-Path -LiteralPath $assetBuildDirectory) {
    Remove-Item -LiteralPath $assetBuildDirectory -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $assetBuildDirectory | Out-Null

foreach ($package in @('borries-better-lightsabers', 'project-kamino')) {
    $packagePath = Join-Path $PSScriptRoot "..\client-assets\$package"
    Get-ChildItem -LiteralPath $packagePath -Directory | ForEach-Object {
        $destination = Join-Path $assetBuildDirectory $_.Name
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Copy-Item -Path (Join-Path $_.FullName '*') -Destination $destination -Recurse -Force
    }
}

if (Test-Path -LiteralPath $assetArchive) {
    Remove-Item -LiteralPath $assetArchive -Force
}
Compress-Archive -Path (Join-Path $assetBuildDirectory '*') -DestinationPath $assetArchive `
    -CompressionLevel Optimal

& $compiler `
    /nologo `
    /target:winexe `
    /optimize+ `
    /platform:anycpu `
    /win32icon:"$PSScriptRoot\ProjectKamino.ico" `
    /reference:System.dll `
    /reference:System.Drawing.dll `
    /reference:System.IO.Compression.dll `
    /reference:System.IO.Compression.FileSystem.dll `
    /reference:System.Windows.Forms.dll `
    /resource:"$PSScriptRoot\assets\ProjectKaminoBackground.png",ProjectKamino.Background.png `
    /resource:"$assetArchive",ProjectKamino.ClientAssets.zip `
    /out:"$output" `
    "$source"

if ($LASTEXITCODE -ne 0) {
    throw 'Project Kamino Launcher compilation failed.'
}

Write-Host "Created $output"
