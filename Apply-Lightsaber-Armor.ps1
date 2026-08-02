[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

# Copy the update script into the running container to avoid Windows argument
# splitting when a multi-line Bash program is passed through docker.exe.
docker cp "$PSScriptRoot\Apply-Lightsaber-Armor.sh" project-kamino-aotc:/tmp/apply-lightsaber-armor.sh
if ($LASTEXITCODE -ne 0) { throw 'Could not copy the lightsaber update script into the AOTC container.' }

docker compose exec -T aotc bash /tmp/apply-lightsaber-armor.sh
if ($LASTEXITCODE -ne 0) { throw 'Could not update every lightsaber armor-penetration template.' }

Write-Host 'Restarting Core3 to load the updated weapon templates...'
docker compose exec -T aotc pkill core3
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { throw 'Could not stop the running Core3 process.' }

docker compose exec -T aotc su - swgemu -c 'screen -S swgemu-server -X quit' *> $null
docker compose exec -d -e TERM=xterm aotc su - swgemu -c 'cd /home/swgemu/workspace/Core3/MMOCoreORB/bin && screen -dmS swgemu-server -L ./core3'
if ($LASTEXITCODE -ne 0) { throw 'Could not restart Core3.' }
if ($LASTEXITCODE -ne 0) { throw 'Could not start Core3 after applying the lightsaber update.' }

Write-Host 'Lightsaber armor penetration updated to Heavy and Core3 restarted.'
