#Requires -Version 5.1
<#
.SYNOPSIS
    Install the data-to-chart skill.
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

function Write-Info { param([string]$Message) Write-Host "  $Message" }
function Write-Warn { param([string]$Message) Write-Host "  ! $Message" -ForegroundColor Yellow }
function Write-Err  { param([string]$Message) Write-Host "  x $Message" -ForegroundColor Red; exit 1 }

function Get-PythonCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) { return "python" }
    if (Get-Command py     -ErrorAction SilentlyContinue) { return "py" }
    return $null
}

function Test-Python {
    $py = Get-PythonCommand
    if (-not $py) {
        Write-Warn "python not found on PATH. Install Python 3.10+ before using the skill."
        return $null
    }
    $ver = & $py -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $ver) {
        Write-Warn "Could not determine Python version (using '$py')."
        return $py
    }
    Write-Info "Python: $ver ($py)"
    $parts = $ver.Trim() -split '\.'
    if ($parts.Count -ge 2) {
        $major = [int]$parts[0]
        $minor = [int]$parts[1]
        if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 10)) {
            Write-Warn "Python 3.10+ required; found $ver."
        }
    }
    return $py
}

function Test-Plotly {
    $py = Get-PythonCommand
    if (-not $py) { return }
    & $py -c "import plotly" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Info "Plotly: installed"
    } else {
        Write-Warn "Plotly not found. Install dependencies with:"
        Write-Warn "    $py -m pip install -r `"$ScriptDir\requirements.txt`""
    }
}

function Test-UserPathContains {
    param([string]$PathToCheck)
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (-not $userPath) { return $false }
    $normalized = $PathToCheck.TrimEnd('\')
    return (($userPath -split ';') | Where-Object { $_.TrimEnd('\') -ieq $normalized }).Count -gt 0
}

function Add-UserPath {
    param([string]$PathToAdd)
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath) { $newPath = "$userPath;$PathToAdd" } else { $newPath = $PathToAdd }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

function Confirm-PathModification {
    param([string]$Prompt)
    if ($Yes) { return $true }
    if ([Console]::IsInputRedirected) { return $false }
    $ans = Read-Host "$Prompt [y/N]"
    return $ans -match '^[Yy]$'
}

function Copy-Bundle {
    param([string]$Destination)
    foreach ($f in @("SKILL.md", "render_chart.py", "requirements.txt")) {
        $src = Join-Path $ScriptDir $f
        if (-not (Test-Path $src)) { Write-Err "Missing required file: $src" }
    }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    foreach ($f in @("SKILL.md", "render_chart.py", "requirements.txt")) {
        Copy-Item (Join-Path $ScriptDir $f) -Destination $Destination -Force
    }
    $examplesSrc = Join-Path $ScriptDir "examples"
    if (Test-Path $examplesSrc) {
        $examplesDest = Join-Path $Destination "examples"
        if (Test-Path $examplesDest) { Remove-Item $examplesDest -Recurse -Force }
        Copy-Item $examplesSrc -Destination $Destination -Recurse -Force
    }
}

function Install-Global {
    param([string]$PythonCmd)
    Write-Host "Installing $SkillName (global)..."
    Copy-Bundle -Destination $GlobalSkillDir
    Write-Info "Skill installed: $GlobalSkillDir"
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    $rendererPath = Join-Path $GlobalSkillDir "render_chart.py"
    $wrapperContent = "@echo off`r`n$PythonCmd `"$rendererPath`" %*"
    Set-Content -Path $WrapperPath -Value $wrapperContent -Encoding ASCII
    Write-Info "Wrapper installed: $WrapperPath"
}

function Install-Project {
    Write-Host "Installing $SkillName (project-local)..."
    Copy-Bundle -Destination $ProjectSkillDir
    Write-Info "Skill installed: $ProjectSkillDir"
}

$pythonCmd = Test-Python
Test-Plotly

if ($Project) {
    Install-Project
    Write-Host ""
    Write-Host "Done. (project-local — no wrapper installed)"
    exit 0
}

if (-not $pythonCmd) {
    Write-Warn "python not found; wrapper will use 'python'."
    $pythonCmd = "python"
}

Install-Global -PythonCmd $pythonCmd
Write-Host ""

if (Test-UserPathContains -PathToCheck $BinDir) {
    Write-Info "PATH: $BinDir is already on your user PATH"
} else {
    Write-Warn "$BinDir is NOT on your user PATH."
    if (Confirm-PathModification -Prompt "Add $BinDir to your user PATH?") {
        Add-UserPath -PathToAdd $BinDir
        Write-Info "Added to user PATH: $BinDir"
    } else {
        Write-Warn "Not added. To add manually:"
        Write-Warn "    [Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$BinDir', 'User')"
    }
}

Write-Host ""
Write-Host "Done."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. If '$BinDir' is not on your PATH, add it (see above)."
Write-Host "  2. Open a new terminal."
Write-Host "  3. Try: $SkillName --input examples\bar.json --output chart.html"