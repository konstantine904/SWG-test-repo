# Project Kamino 2.0

Project Kamino packages the AOTC V2 Core3 server for Docker Desktop and applies
the current server modifications automatically. The AOTC source is pinned to
commit `33f3439f03981f8f7c6fb7837a60d233993f263f`.

Retail SWG and AOTC client TRE archives are **not** included. Each server owner
must provide their own legally obtained game and AOTC client files.

## Included changes

- AOTC Force Sensitive, Jedi Initiate, Padawan, Knight, and FRS progression
- Blue Frog selection for every Light and Dark FRS rank
- Correct AOTC `prequel_*` Form and Mastery skill trees
- Four Force Sensitive branches awarded before Jedi training
- Permanent council faction and overt status for Jedi Knights
- No Blue Frog teleport to an enclave
- Jedi removed from server-side starting professions
- Council-specific taped FRS robes with defense and lightsaber modifiers

## Requirements

- Windows 10/11
- Docker Desktop using Linux containers
- At least 8 GB of memory assigned to Docker; 12–16 GB is recommended
- Approximately 25 GB of free disk space
- Retail SWG TRE files
- A compatible AOTC client installation

The installer defaults to:

```text
C:\ProjectKamino\BaseGame
C:\ProjectKamino\Client
```

Alternative locations can be passed to the installer.

## Install

Open PowerShell:

```powershell
git clone https://github.com/ayehuazkuh/ProjectKamino2.0.git
cd ProjectKamino2.0
Set-ExecutionPolicy -Scope Process Bypass
.\Install-ProjectKamino.ps1
```

Using custom game locations:

```powershell
.\Install-ProjectKamino.ps1 `
  -BaseGamePath 'D:\SWG\BaseGame' `
  -ClientPath 'D:\SWG\AOTC'
```

The installer:

1. Creates a private Docker volume for the TRE files.
2. Imports retail TREs followed by the AOTC TREs.
3. Builds the Project Kamino Docker image.
4. Provisions MariaDB and the pinned AOTC source.
5. Applies the Project Kamino source overrides.
6. Compiles and launches Core3.

The initial image build and compilation can take a while.

## Client connection

For a client on the Docker host, configure:

```text
127.0.0.1:44453
```

For LAN or Internet connections, use the Docker host address and allow/forward:

- TCP 44455 — status
- UDP 44453 — login
- UDP 44462 — ping
- UDP 44463 — zone

MariaDB is internal and should not be exposed.

The small `project_kamino_no_jedi_start.tre` client patch used by the original
installation is intentionally not published. Without that optional patch, the
server still rejects Jedi as a starting profession, but an unpatched client may
continue to display Jedi in its character-creation list.

## Operations

```powershell
.\Status-Aotc.ps1
.\Stop-Aotc.ps1
.\Start-Aotc.ps1 -Run
.\Backup-Aotc.ps1
```

To rebuild after changing an override:

```powershell
.\Start-Aotc.ps1 -Rebuild
.\Start-Aotc.ps1 -Compile
```

Persistent state is stored in:

- `project-kamino-home` — source and server state
- `project-kamino-mariadb` — MariaDB data
- `project-kamino-tre` — private game archives

## Security and asset policy

- `.env`, backups, logs, executables, ISOs, and TRE files are ignored.
- Generated database and administrator credentials remain in Docker volumes.
- Never publish the TRE volume or a Docker image containing retail/client
  archives.

## Upstream projects

- [SWGEmu Core3](https://github.com/swgemu/Core3)
- [AOTC V2](https://gitlab.com/alpha38/aotc-v2)
