[CmdletBinding()]
param(
    [string]$BaseGamePath = 'C:\ProjectKamino\BaseGame',
    [string]$ClientPath = 'C:\ProjectKamino\Client',
    [string]$VolumeName = 'project-kamino-tre'
)

$ErrorActionPreference = 'Stop'

foreach ($path in @($BaseGamePath, $ClientPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "TRE source folder does not exist: $path"
    }
}

$baseTre = @(Get-ChildItem -LiteralPath $BaseGamePath -File -Filter '*.tre')
$clientTre = @(Get-ChildItem -LiteralPath $ClientPath -File -Filter '*.tre')
if ($baseTre.Count -eq 0 -or $clientTre.Count -eq 0) {
    throw "Expected TRE files in both folders. Found base=$($baseTre.Count), client=$($clientTre.Count)."
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Desktop is not running or is not accessible.'
}

docker volume create $VolumeName | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not create Docker volume $VolumeName." }

# Copy the retail archives first, then the AOTC client archives. AOTC versions
# intentionally win when filenames overlap (for example default_patch.tre).
docker run --rm `
    --mount "type=bind,source=$BaseGamePath,target=/source,readonly" `
    --mount "type=volume,source=$VolumeName,target=/tre" `
    alpine:3.22 sh -c 'rm -f /tre/*.tre && cp -v /source/*.tre /tre/'
if ($LASTEXITCODE -ne 0) { throw 'Failed while importing base-game TRE files.' }

docker run --rm `
    --mount "type=bind,source=$ClientPath,target=/source,readonly" `
    --mount "type=volume,source=$VolumeName,target=/tre" `
    alpine:3.22 sh -c 'cp -vf /source/*.tre /tre/ && chmod 0444 /tre/*.tre'
if ($LASTEXITCODE -ne 0) { throw 'Failed while importing AOTC client TRE files.' }

$expectedNames = @($baseTre.Name + $clientTre.Name | Sort-Object -Unique)
$actualNames = @(docker run --rm --mount "type=volume,source=$VolumeName,target=/tre,readonly" alpine:3.22 sh -c 'find /tre -maxdepth 1 -type f -name "*.tre" -printf "%f\n"' | Sort-Object)
if ($LASTEXITCODE -ne 0) { throw 'Could not verify the TRE volume.' }

$missing = @($expectedNames | Where-Object { $_ -notin $actualNames })
if ($missing.Count -gt 0) {
    throw "TRE volume verification failed. Missing: $($missing -join ', ')"
}

Write-Host "Imported and verified $($actualNames.Count) unique TRE files in volume '$VolumeName'."
