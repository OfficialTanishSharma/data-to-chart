#Requires -Version 5.1
<#
.SYNOPSIS
    Remove the data-to-chart skill.
#>

[CmdletBinding()]
param(
    [switch]$Project,
    [switch]$Yes,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
if ($Help) { Get-Help $PSCommandPath -Detailed; exit 0 }

$ScriptDir       = $PSScriptRoot
$SkillName       = "data-to-chart"
$GlobalSkillDir  = Join-Path $env:USERPROFILE ".claude\skills\$SkillName"
$BinDir          = Join-Path $env:USERPROFILE ".local\bin"
$WrapperPath     = Join-Path $BinDir "$SkillName.cmd"
$ProjectSkillDir = Join-Path $ScriptDir ".claude\skills\$SkillName"

$script:RemovedAny = $false

function Write-Info { param([string]$Message) Write-Host "  $Message" }
function Write-Warn { param([string]$Message) Write-Host "  ! $Message" -ForegroundColor Yellow }

function Remove-SkillDir {
    param([string]$Path)
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force
        Write-Info "Removed: $Path"
        $script:RemovedAny = $true
    } else {
        Write-Info "Not found (skipping): $Path"
    }
}

function Remove-Wrapper {
    param([string]$Path)
    if (Test-Path $Path) {
        Remove-Item $Path -Force
        Write-Info "Removed: $Path"
        $script:RemovedAny = $true
    } else {
        Write-Info "Not found (skipping): $Path"
    }
}

function Confirm-Action {
    param([string]$Prompt)
    if ($Yes) { return $true }
    if ([Console]::IsInputRedirected) { return $false }
    $ans = Read-Host "$Prompt [y/N]"
    return $ans -match '^[Yy]$'
}

if ($Project) {
    if (-not (Confirm-Action -Prompt "Remove project-local $SkillName?")) {
        Write-Host "Aborted."; exit 0
    }
    Write-Host "Uninstalling $SkillName (project-local)..."
    Remove-SkillDir -Path $ProjectSkillDir
} else {
    if (-not (Confirm-Action -Prompt "Remove global $SkillName install?")) {
        Write-Host "Aborted."; exit 0
    }
    Write-Host "Uninstalling $SkillName (global)..."
    Remove-SkillDir -Path $GlobalSkillDir
    Remove-Wrapper  -Path $WrapperPath
}

Write-Host ""
if ($script:RemovedAny) {
    Write-Host "Done."
    Write-Host ""
    Write-Host "Note: we never modified your PATH or shell rc files."
} else {
    Write-Host "Nothing to remove."
}