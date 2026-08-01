[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'ProjectKaminoLauncher.cs'
$output = Join-Path $PSScriptRoot 'ProjectKaminoLauncher.exe'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw "The .NET Framework C# compiler was not found at $compiler."
}

& $compiler `
    /nologo `
    /target:winexe `
    /optimize+ `
    /platform:anycpu `
    /win32icon:"$PSScriptRoot\ProjectKamino.ico" `
    /reference:System.dll `
    /reference:System.Drawing.dll `
    /reference:System.Windows.Forms.dll `
    /resource:"$PSScriptRoot\assets\ProjectKaminoBackground.png",ProjectKamino.Background.png `
    /out:"$output" `
    "$source"

if ($LASTEXITCODE -ne 0) {
    throw 'Project Kamino Launcher compilation failed.'
}

Write-Host "Created $output"
