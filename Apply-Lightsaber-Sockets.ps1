[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

docker cp "$PSScriptRoot\Apply-Lightsaber-Sockets.sh" project-kamino-aotc:/tmp/apply-lightsaber-sockets.sh
if ($LASTEXITCODE -ne 0) { throw 'Could not copy the lightsaber socket update into the AOTC container.' }

docker compose exec -T aotc bash /tmp/apply-lightsaber-sockets.sh
if ($LASTEXITCODE -ne 0) { throw 'Could not apply the generation-based lightsaber crystal slots.' }

Write-Host 'Restarting Core3 to load the updated lightsaber templates...'
docker compose exec -T aotc pkill core3
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { throw 'Could not stop the running Core3 process.' }

docker compose exec -T aotc su - swgemu -c 'screen -S swgemu-server -X quit' *> $null
docker compose exec -d -e TERM=xterm aotc su - swgemu -c 'cd /home/swgemu/workspace/Core3/MMOCoreORB/bin && screen -dmS swgemu-server -L ./core3'
if ($LASTEXITCODE -ne 0) { throw 'Could not restart Core3.' }
if ($LASTEXITCODE -ne 0) { throw 'Could not start Core3 after applying the lightsaber socket update.' }

Write-Host 'Generation-based lightsaber crystal slots applied and Core3 restarted.'
