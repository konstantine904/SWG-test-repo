[CmdletBinding()]
param(
    [switch]$Rebuild,
    [switch]$Compile,
    [switch]$Run
)

$ErrorActionPreference = 'Stop'
$projectDir = $PSScriptRoot
Set-Location -LiteralPath $projectDir

docker volume inspect project-kamino-tre *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'TRE volume is missing. Run .\Initialize-AotcTreVolume.ps1 first.'
}

$upArgs = @('compose', 'up', '-d')
if ($Rebuild) { $upArgs += '--build' }
& docker @upArgs
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose failed to start the AOTC container.' }

Write-Host 'Waiting for AOTC first-boot provisioning...'
$ready = $false
for ($attempt = 1; $attempt -le 60; $attempt++) {
    docker compose exec -T aotc bash -lc 'test -f /home/swgemu/.env && test -f /home/swgemu/workspace/Core3/MMOCoreORB/bin/conf/config-local.lua' *> $null
    if ($LASTEXITCODE -eq 0) {
        $ready = $true
        break
    }
    Start-Sleep -Seconds 5
}
if (-not $ready) {
    docker compose logs --tail 100 aotc
    throw 'AOTC did not finish first-boot provisioning within five minutes.'
}

if ($Compile) {
    Write-Host 'Compiling Core3. This may take a while on the first build...'
    docker compose exec -T --user 44400:44400 aotc bash -lc `
        'git config --global --add safe.directory /home/swgemu/workspace/Core3 && cd /home/swgemu/workspace/Core3/MMOCoreORB/build/unix/ninja-debug && cmake -G Ninja -DRUN_GIT=ON -DCMAKE_BUILD_TYPE=Debug -DENABLE_BUILD_CLIENT=OFF -DCMAKE_CXX_FLAGS=-DNDEBUG=1\ -Wno-deprecated-literal-operator\ -Wno-nontrivial-memcall ../../.. && ninja'
    if ($LASTEXITCODE -ne 0) { throw 'Core3 compilation failed.' }
}

if ($Run) {
    Write-Host 'Starting Core3 in the background...'
    docker compose exec -d -e TERM=xterm aotc su - swgemu -c run
}

docker compose ps
Write-Host 'Use .\Status-Aotc.ps1 to view status and recent logs.'
