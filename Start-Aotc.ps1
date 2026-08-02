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
    # Clang 20 treats the historic space in these C++ user-defined literal
    # declarations as an error under Core3's -Werror policy. Normalize the
    # declarations in the pinned source before configuring the build.
    docker compose exec -T --user 44400:44400 aotc sed -Ei 's/operator[[:space:]]*\x22\x22[[:space:]]*_([[:alnum:]_]+)/operator\x22\x22_\1/g' `
        /home/swgemu/workspace/Core3/MMOCoreORB/utils/engine3/MMOEngine/src/system/lang/String.h `
        /home/swgemu/workspace/Core3/MMOCoreORB/utils/engine3/MMOEngine/src/engine/util/json.hpp
    if ($LASTEXITCODE -ne 0) { throw 'Could not apply the Core3 compiler compatibility fix.' }

    docker compose exec -T --user 44400:44400 aotc sed -Ei 's/memset\(m_tiles,/memset\(\(void*\)m_tiles,/' `
        /home/swgemu/workspace/Core3/MMOCoreORB/src/pathfinding/recast/DetourNavMesh.cpp
    if ($LASTEXITCODE -ne 0) { throw 'Could not apply the Core3 pathfinding compatibility fix.' }

    # The bundled AOTC build command configures, compiles, and installs core3
    # into bin/, which is the location used by the server run script.
    docker compose exec -T --user 44400:44400 aotc bash -lc `
        'set -o pipefail; git config --global --add safe.directory /home/swgemu/workspace/Core3 && TERM=xterm /home/swgemu/bin/build 2>&1 | tee /home/swgemu/core3-build.log'
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Last 160 lines of the Core3 build log:'
        docker compose exec -T aotc bash -lc 'tail -n 160 /home/swgemu/core3-build.log || true'
        throw 'Core3 compilation failed.'
    }
}

if ($Run) {
    Write-Host 'Starting Core3 in the background...'
    # The upstream `run` helper launches Core3 under GDB and leaves it paused
    # after a debugger signal. Start the compiled server directly in screen so
    # it can continue servicing the UDP login and galaxy ports.
    docker compose exec -T aotc su - swgemu -c 'screen -S swgemu-server -X quit' *> $null
    docker compose exec -d -e TERM=xterm aotc su - swgemu -c 'cd /home/swgemu/workspace/Core3/MMOCoreORB/bin && screen -dmS swgemu-server -L ./core3'
    if ($LASTEXITCODE -ne 0) { throw 'Could not start Core3.' }
}

docker compose ps
Write-Host 'Use .\Status-Aotc.ps1 to view status and recent logs.'
