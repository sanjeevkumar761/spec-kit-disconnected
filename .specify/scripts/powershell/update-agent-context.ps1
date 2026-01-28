#!/usr/bin/env pwsh
<#
.SYNOPSIS
Update agent context files with information from plan.md - Disconnected Edition

.DESCRIPTION
Updates local agent context files. Uses .specify/agents/ instead of .github/agents/
for disconnected environments.

.PARAMETER AgentType
Optional agent key to update a single agent.

.EXAMPLE
./update-agent-context.ps1 -AgentType copilot

.EXAMPLE
./update-agent-context.ps1   # Updates all existing agent files
#>
param(
    [Parameter(Position=0)]
    [ValidateSet('claude','gemini','copilot','cursor-agent','qwen','opencode','codex','windsurf','kilocode')]
    [string]$AgentType
)

$ErrorActionPreference = 'Stop'

# Import common helpers
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir 'common.ps1')

# Acquire environment paths
$envData = Get-FeaturePathsEnv
$REPO_ROOT     = $envData.REPO_ROOT
$CURRENT_BRANCH = $envData.CURRENT_BRANCH
$HAS_GIT       = $envData.HAS_GIT
$IMPL_PLAN     = $envData.IMPL_PLAN
$NEW_PLAN = $IMPL_PLAN

# Agent file paths - Note: copilot uses .specify/agents/ in disconnected mode
$CLAUDE_FILE   = Join-Path $REPO_ROOT 'CLAUDE.md'
$GEMINI_FILE   = Join-Path $REPO_ROOT 'GEMINI.md'
$COPILOT_FILE  = Join-Path $REPO_ROOT '.specify/agents/copilot-instructions.md'
$CURSOR_FILE   = Join-Path $REPO_ROOT '.cursor/rules/specify-rules.mdc'
$QWEN_FILE     = Join-Path $REPO_ROOT 'QWEN.md'
$AGENTS_FILE   = Join-Path $REPO_ROOT 'AGENTS.md'
$WINDSURF_FILE = Join-Path $REPO_ROOT '.windsurf/rules/specify-rules.md'
$KILOCODE_FILE = Join-Path $REPO_ROOT '.kilocode/rules/specify-rules.md'

$TEMPLATE_FILE = Join-Path $REPO_ROOT '.specify/templates/agent-file-template.md'

# Parsed plan data placeholders
$script:NEW_LANG = ''
$script:NEW_FRAMEWORK = ''
$script:NEW_DB = ''
$script:NEW_PROJECT_TYPE = ''

function Write-Info { param([string]$Message) Write-Host "INFO: $Message" }
function Write-Success { param([string]$Message) Write-Host "$([char]0x2713) $Message" -ForegroundColor Green }
function Write-WarningMsg { param([string]$Message) Write-Warning $Message }
function Write-Err { param([string]$Message) Write-Host "ERROR: $Message" -ForegroundColor Red }

function Validate-Environment {
    if (-not $CURRENT_BRANCH) {
        Write-Err 'Unable to determine current feature'
        if ($HAS_GIT) { 
            Write-Info "Make sure you're on a feature branch" 
        } else { 
            Write-Info 'Set SPECIFY_FEATURE environment variable or create a feature first' 
        }
        exit 1
    }
    if (-not (Test-Path $NEW_PLAN)) {
        Write-Err "No plan.md found at $NEW_PLAN"
        Write-Info 'Ensure you are working on a feature with a corresponding spec directory'
        if (-not $HAS_GIT) { 
            Write-Info 'Use: $env:SPECIFY_FEATURE=your-feature-name or create a new feature first' 
        }
        exit 1
    }
    if (-not (Test-Path $TEMPLATE_FILE)) {
        Write-Err "Template file not found at $TEMPLATE_FILE"
        Write-Info 'Ensure .specify/templates/agent-file-template.md exists'
        exit 1
    }
}

function Extract-PlanField {
    param([string]$FieldPattern, [string]$PlanFile)
    if (-not (Test-Path $PlanFile)) { return '' }
    $regex = "^\*\*$([Regex]::Escape($FieldPattern))\*\*: (.+)$"
    Get-Content -LiteralPath $PlanFile -Encoding utf8 | ForEach-Object {
        if ($_ -match $regex) { 
            $val = $Matches[1].Trim()
            if ($val -notin @('NEEDS CLARIFICATION','N/A')) { return $val }
        }
    } | Select-Object -First 1
}

function Parse-PlanData {
    param([string]$PlanFile)
    if (-not (Test-Path $PlanFile)) { Write-Err "Plan file not found: $PlanFile"; return $false }
    Write-Info "Parsing plan data from $PlanFile"
    $script:NEW_LANG        = Extract-PlanField -FieldPattern 'Language/Version' -PlanFile $PlanFile
    $script:NEW_FRAMEWORK   = Extract-PlanField -FieldPattern 'Primary Dependencies' -PlanFile $PlanFile
    $script:NEW_DB          = Extract-PlanField -FieldPattern 'Storage' -PlanFile $PlanFile
    $script:NEW_PROJECT_TYPE = Extract-PlanField -FieldPattern 'Project Type' -PlanFile $PlanFile

    if ($NEW_LANG) { Write-Info "Found language: $NEW_LANG" }
    if ($NEW_FRAMEWORK) { Write-Info "Found framework: $NEW_FRAMEWORK" }
    if ($NEW_DB -and $NEW_DB -ne 'N/A') { Write-Info "Found database: $NEW_DB" }
    return $true
}

function Format-TechnologyStack {
    param([string]$Lang, [string]$Framework)
    $parts = @()
    if ($Lang -and $Lang -ne 'NEEDS CLARIFICATION') { $parts += $Lang }
    if ($Framework -and $Framework -notin @('NEEDS CLARIFICATION','N/A')) { $parts += $Framework }
    if (-not $parts) { return '' }
    return ($parts -join ' + ')
}

function Get-ProjectStructure { 
    param([string]$ProjectType)
    if ($ProjectType -match 'web') { return "backend/`nfrontend/`ntests/" } 
    else { return "src/`ntests/" } 
}

function Get-CommandsForLanguage { 
    param([string]$Lang)
    switch -Regex ($Lang) {
        'Python' { return "cd src; pytest; ruff check ." }
        'Rust' { return "cargo test; cargo clippy" }
        'JavaScript|TypeScript' { return "npm test; npm run lint" }
        default { return "# Add commands for $Lang" }
    }
}

function New-AgentFile {
    param([string]$TargetFile, [string]$ProjectName, [datetime]$Date)
    if (-not (Test-Path $TEMPLATE_FILE)) { Write-Err "Template not found"; return $false }
    
    $content = Get-Content -LiteralPath $TEMPLATE_FILE -Raw -Encoding utf8
    $content = $content -replace '\[PROJECT NAME\]',$ProjectName
    $content = $content -replace '\[DATE\]',$Date.ToString('yyyy-MM-dd')
    
    $techStack = ""
    if ($NEW_LANG -and $NEW_FRAMEWORK) {
        $techStack = "- $NEW_LANG + $NEW_FRAMEWORK ($CURRENT_BRANCH)"
    } elseif ($NEW_LANG) {
        $techStack = "- $NEW_LANG ($CURRENT_BRANCH)"
    }
    $content = $content -replace '\[EXTRACTED FROM ALL PLAN.MD FILES\]',$techStack
    
    $projectStructure = Get-ProjectStructure -ProjectType $NEW_PROJECT_TYPE
    $content = $content -replace '\[ACTUAL STRUCTURE FROM PLANS\]',$projectStructure
    
    $commands = Get-CommandsForLanguage -Lang $NEW_LANG
    $content = $content -replace '\[ONLY COMMANDS FOR ACTIVE TECHNOLOGIES\]',$commands
    $content = $content -replace '\[LANGUAGE-SPECIFIC, ONLY FOR LANGUAGES IN USE\]',"Follow standard conventions"
    
    $recentChanges = ""
    if ($NEW_LANG) { $recentChanges = "- ${CURRENT_BRANCH}: Added ${NEW_LANG}" }
    $content = $content -replace '\[LAST 3 FEATURES AND WHAT THEY ADDED\]',$recentChanges

    $parent = Split-Path -Parent $TargetFile
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
    Set-Content -LiteralPath $TargetFile -Value $content -NoNewline -Encoding utf8
    return $true
}

function Update-AgentFile {
    param([string]$TargetFile, [string]$AgentName)
    Write-Info "Updating $AgentName context file: $TargetFile"
    $projectName = Split-Path $REPO_ROOT -Leaf
    $date = Get-Date

    $dir = Split-Path -Parent $TargetFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

    if (-not (Test-Path $TargetFile)) {
        if (New-AgentFile -TargetFile $TargetFile -ProjectName $projectName -Date $date) { 
            Write-Success "Created new $AgentName context file" 
        } else { 
            return $false 
        }
    } else {
        Write-Success "Updated existing $AgentName context file"
    }
    return $true
}

function Update-SpecificAgent {
    param([string]$Type)
    switch ($Type) {
        'claude'   { Update-AgentFile -TargetFile $CLAUDE_FILE   -AgentName 'Claude Code' }
        'gemini'   { Update-AgentFile -TargetFile $GEMINI_FILE   -AgentName 'Gemini CLI' }
        'copilot'  { Update-AgentFile -TargetFile $COPILOT_FILE  -AgentName 'Copilot (Local)' }
        'cursor-agent' { Update-AgentFile -TargetFile $CURSOR_FILE -AgentName 'Cursor IDE' }
        'qwen'     { Update-AgentFile -TargetFile $QWEN_FILE     -AgentName 'Qwen Code' }
        'opencode' { Update-AgentFile -TargetFile $AGENTS_FILE   -AgentName 'opencode' }
        'codex'    { Update-AgentFile -TargetFile $AGENTS_FILE   -AgentName 'Codex CLI' }
        'windsurf' { Update-AgentFile -TargetFile $WINDSURF_FILE -AgentName 'Windsurf' }
        'kilocode' { Update-AgentFile -TargetFile $KILOCODE_FILE -AgentName 'Kilo Code' }
        default { Write-Err "Unknown agent type '$Type'"; return $false }
    }
}

function Update-AllExistingAgents {
    $found = $false
    $ok = $true
    
    # Check local copilot file first (disconnected mode)
    if (Test-Path $COPILOT_FILE) { 
        if (-not (Update-AgentFile -TargetFile $COPILOT_FILE -AgentName 'Copilot (Local)')) { $ok = $false }
        $found = $true 
    }
    if (Test-Path $CLAUDE_FILE)   { if (-not (Update-AgentFile -TargetFile $CLAUDE_FILE   -AgentName 'Claude Code')) { $ok = $false }; $found = $true }
    if (Test-Path $GEMINI_FILE)   { if (-not (Update-AgentFile -TargetFile $GEMINI_FILE   -AgentName 'Gemini CLI')) { $ok = $false }; $found = $true }
    if (Test-Path $CURSOR_FILE)   { if (-not (Update-AgentFile -TargetFile $CURSOR_FILE   -AgentName 'Cursor IDE')) { $ok = $false }; $found = $true }
    
    if (-not $found) {
        Write-Info 'No existing agent files found, creating default Claude file...'
        if (-not (Update-AgentFile -TargetFile $CLAUDE_FILE -AgentName 'Claude Code')) { $ok = $false }
    }
    return $ok
}

function Main {
    Validate-Environment
    Write-Info "=== Updating agent context files for feature $CURRENT_BRANCH ==="
    Write-Info "Mode: Disconnected (using .specify/agents/)"
    
    if (-not (Parse-PlanData -PlanFile $NEW_PLAN)) { 
        Write-Err 'Failed to parse plan data'
        exit 1 
    }
    
    $success = $true
    if ($AgentType) {
        Write-Info "Updating specific agent: $AgentType"
        if (-not (Update-SpecificAgent -Type $AgentType)) { $success = $false }
    } else {
        Write-Info 'Updating all existing agent files...'
        if (-not (Update-AllExistingAgents)) { $success = $false }
    }
    
    Write-Host ''
    Write-Info 'Summary:'
    if ($NEW_LANG) { Write-Host "  - Language: $NEW_LANG" }
    if ($NEW_FRAMEWORK) { Write-Host "  - Framework: $NEW_FRAMEWORK" }
    
    if ($success) { 
        Write-Success 'Agent context update completed successfully'
        exit 0 
    } else { 
        Write-Err 'Agent context update completed with errors'
        exit 1 
    }
}

Main
