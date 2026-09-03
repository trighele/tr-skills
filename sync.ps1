#Requires -Version 5.1
<#
.SYNOPSIS
    Install / refresh the tr-* skills into the local Claude Code skills directory.

.DESCRIPTION
    Copies, never symlinks: nothing git-shaped is created under ~/.claude, and the
    copies survive being bind-mounted into a dev container.

    Only touches directories matching tr-* . Anything else in the destination
    (msk-*, hand-written skills, plugins) is left strictly alone.

.PARAMETER NoPull
    Install what is already checked out, without running git pull first.

.EXAMPLE
    .\sync.ps1
    .\sync.ps1 -NoPull
#>
[CmdletBinding()]
param([switch]$NoPull)

$ErrorActionPreference = 'Stop'

$Repo = $PSScriptRoot
$Src  = Join-Path $Repo 'skills'
$Dest = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR }
        else { Join-Path $env:USERPROFILE '.claude\skills' }

if (-not (Test-Path -LiteralPath $Src -PathType Container)) {
    throw "No skills/ directory in $Repo"
}

# Refuse to invent a Claude home. An empty ~/.claude almost always means the path
# is wrong, and silently creating it turns that into "my skills vanished" later.
$Parent = Split-Path -Parent $Dest
if (-not (Test-Path -LiteralPath $Parent -PathType Container)) {
    throw "$Parent does not exist. Claude Code has not run on this machine, or CLAUDE_SKILLS_DIR is wrong."
}
if (-not (Test-Path -LiteralPath $Dest)) { New-Item -ItemType Directory -Path $Dest | Out-Null }

if (-not $NoPull) {
    $branch = (& git -C $Repo rev-parse --abbrev-ref HEAD).Trim()
    Write-Host "pulling $branch..."
    & git -C $Repo pull --ff-only
    if ($LASTEXITCODE -ne 0) { throw "git pull failed" }
    Write-Host ''
}

# --- install -----------------------------------------------------------------
$names = @()
foreach ($dir in Get-ChildItem -LiteralPath $Src -Directory -Filter 'tr-*') {
    $names += $dir.Name
    $target = Join-Path $Dest $dir.Name
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    Copy-Item -LiteralPath $dir.FullName -Destination $target -Recurse
    Write-Host "  installed  $($dir.Name)"
}

if ($names.Count -eq 0) { throw "No tr-* skills found in $Src" }

# --- prune -------------------------------------------------------------------
# A tr-* skill renamed or deleted upstream must actually go away, or the old copy
# keeps answering to its slash command.
$pruned = 0
foreach ($dir in Get-ChildItem -LiteralPath $Dest -Directory -Filter 'tr-*') {
    if ($names -notcontains $dir.Name) {
        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
        Write-Host "  PRUNED     $($dir.Name) (no longer in the repo)"
        $pruned++
    }
}

Write-Host ''
$suffix = if ($pruned -gt 0) { ", $pruned pruned" } else { '' }
Write-Host "$($names.Count) skill(s) installed$suffix into $Dest"
Write-Host 'Restart Claude Code to pick up the changes.'
