#!/usr/bin/env pwsh
<#
.SYNOPSIS
Quick setup script for Spec Kit Disconnected Edition

.DESCRIPTION
Copies Spec Kit Disconnected to a target project directory.

.PARAMETER TargetPath
The path to the target project where Spec Kit will be installed.

.EXAMPLE
./install-speckit.ps1 -TargetPath "C:\MyProject"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Spec Kit Disconnected Edition - Installer ===" -ForegroundColor Cyan
Write-Host ""

# Validate target path
if (-not (Test-Path $TargetPath)) {
    Write-Host "Creating target directory: $TargetPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

$specifyDest = Join-Path $TargetPath '.specify'
$vscodeDest = Join-Path $TargetPath '.vscode'

# Check if already exists
if ((Test-Path $specifyDest) -and -not $Force) {
    Write-Host "WARNING: .specify directory already exists at $specifyDest" -ForegroundColor Yellow
    $response = Read-Host "Overwrite? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Installation cancelled." -ForegroundColor Red
        exit 1
    }
}

# Copy .specify folder
Write-Host "Copying .specify folder..." -ForegroundColor Green
$specifySource = Join-Path $scriptDir '.specify'
if (Test-Path $specifyDest) { Remove-Item -Recurse -Force $specifyDest }
Copy-Item -Recurse -Path $specifySource -Destination $specifyDest

# Copy .vscode folder (merge if exists)
Write-Host "Setting up .vscode settings..." -ForegroundColor Green
$vscodeSource = Join-Path $scriptDir '.vscode'
if (-not (Test-Path $vscodeDest)) {
    Copy-Item -Recurse -Path $vscodeSource -Destination $vscodeDest
} else {
    # Merge settings.json if .vscode exists
    $settingsSource = Join-Path $vscodeSource 'settings.json'
    $settingsDest = Join-Path $vscodeDest 'settings.json'
    if (Test-Path $settingsDest) {
        Write-Host "  Note: Existing .vscode/settings.json found. Please manually merge agent settings." -ForegroundColor Yellow
    } else {
        Copy-Item -Path $settingsSource -Destination $settingsDest
    }
}

# Create specs directory
$specsDir = Join-Path $TargetPath 'specs'
if (-not (Test-Path $specsDir)) {
    Write-Host "Creating specs directory..." -ForegroundColor Green
    New-Item -ItemType Directory -Path $specsDir | Out-Null
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Spec Kit Disconnected Edition installed to: $TargetPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open the project in VS Code"
Write-Host "2. Create a new feature:"
Write-Host '   $env:SPECIFY_FEATURE = "001-my-feature"' -ForegroundColor White
Write-Host "   .\.specify\scripts\powershell\create-new-feature.ps1 'My feature description'" -ForegroundColor White
Write-Host "3. Or use the /speckit.specify agent command with your AI assistant"
Write-Host ""
Write-Host "For offline environments without Git:" -ForegroundColor Yellow
Write-Host "  Set SPECIFY_FEATURE environment variable before running commands"
Write-Host ""
