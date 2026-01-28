
# Spec Kit Disconnected - PowerShell Scripts Reference

Complete documentation for all PowerShell scripts in `.specify/scripts/powershell/`.

All scripts support **offline/disconnected operation** and work without Git connectivity.

---

## Key Changes from Standard Spec Kit

| Aspect | Standard | Disconnected |
|--------|----------|--------------|
| Agent location | `.github/agents/` | `.specify/agents/` |
| Prompt location | `.github/prompts/` | `.specify/prompts/` |
| Issue creation | GitHub Issues API | Local `issues/` directory |
| Git requirement | Required | Optional (fallback support) |

---

## create-new-feature.ps1

Creates a new feature with spec directory structure.

### Usage

```powershell
.\create-new-feature.ps1 [-Json] [-ShortName <name>] [-Number N] <feature description>
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| Feature Description | String | Yes | Natural language description of the feature |
| `-Json` | Switch | No | Output results in JSON format |
| `-ShortName` | String | No | Custom short name (2-4 words) for the branch/folder |
| `-Number` | Int | No | Override auto-detected feature number |
| `-Help` | Switch | No | Show help message |

### Examples

```powershell
# Basic usage
.\create-new-feature.ps1 "Add user authentication system"

# With custom short name
.\create-new-feature.ps1 -ShortName "user-auth" "Add user authentication system"

# JSON output (for AI agent consumption)
.\create-new-feature.ps1 -Json "Add user authentication system"

# Specify feature number manually
.\create-new-feature.ps1 -Number 5 "Add payment processing"
```

### Output

Creates:
```
specs/001-feature-name/
├── spec.md           # From spec-template.md
├── issues/           # For local issue tracking
└── checklists/       # For quality checklists
```

### Offline Behavior

- **With Git**: Creates and checks out a new branch
- **Without Git**: Skips branch creation, sets `SPECIFY_FEATURE` environment variable
- Auto-detects next feature number from `specs/` directory

---

## check-prerequisites.ps1

Validates prerequisites and returns feature paths for other scripts/agents.

### Usage

```powershell
.\check-prerequisites.ps1 [-Json] [-RequireTasks] [-IncludeTasks] [-PathsOnly] [-Help]
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Json` | Switch | No | Output in JSON format |
| `-RequireTasks` | Switch | No | Require tasks.md to exist (for implementation phase) |
| `-IncludeTasks` | Switch | No | Include tasks.md in AVAILABLE_DOCS list |
| `-PathsOnly` | Switch | No | Only output paths, skip validation |
| `-Help` | Switch | No | Show help message |

### Examples

```powershell
# Basic check (requires plan.md)
.\check-prerequisites.ps1 -Json

# Check for implementation (requires plan.md + tasks.md)
.\check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks

# Get paths only without validation
.\check-prerequisites.ps1 -PathsOnly
```

### JSON Output Structure

```json
{
  "FEATURE_DIR": "C:/project/specs/001-feature",
  "AVAILABLE_DOCS": ["research.md", "data-model.md", "contracts/"]
}
```

### Paths-Only Output

```json
{
  "REPO_ROOT": "C:/project",
  "BRANCH": "001-feature-name",
  "FEATURE_DIR": "C:/project/specs/001-feature-name",
  "FEATURE_SPEC": "C:/project/specs/001-feature-name/spec.md",
  "IMPL_PLAN": "C:/project/specs/001-feature-name/plan.md",
  "TASKS": "C:/project/specs/001-feature-name/tasks.md",
  "ISSUES_DIR": "C:/project/specs/001-feature-name/issues"
}
```

---

## setup-plan.ps1

Initializes the implementation plan file from template.

### Usage

```powershell
.\setup-plan.ps1 [-Json] [-Help]
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Json` | Switch | No | Output results in JSON format |
| `-Help` | Switch | No | Show help message |

### Examples

```powershell
# Basic usage
.\setup-plan.ps1

# JSON output
.\setup-plan.ps1 -Json
```

### Output

Copies `.specify/templates/plan-template.md` to `specs/<feature>/plan.md`

### JSON Output Structure

```json
{
  "FEATURE_SPEC": "C:/project/specs/001-feature/spec.md",
  "IMPL_PLAN": "C:/project/specs/001-feature/plan.md",
  "SPECS_DIR": "C:/project/specs/001-feature",
  "BRANCH": "001-feature-name",
  "HAS_GIT": false
}
```

---

## update-agent-context.ps1

Updates AI agent context files with technology information from plan.md.

### Usage

```powershell
.\update-agent-context.ps1 [-AgentType <type>]
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-AgentType` | String | No | Specific agent to update. If omitted, updates all existing agents |

### Valid Agent Types

| Type | File Location | Description |
|------|---------------|-------------|
| `copilot` | `.specify/agents/copilot-instructions.md` | GitHub Copilot (local) |
| `claude` | `CLAUDE.md` | Claude Code |
| `gemini` | `GEMINI.md` | Gemini CLI |
| `cursor-agent` | `.cursor/rules/specify-rules.mdc` | Cursor IDE |
| `qwen` | `QWEN.md` | Qwen Code |
| `opencode` | `AGENTS.md` | opencode |
| `codex` | `AGENTS.md` | Codex CLI |
| `windsurf` | `.windsurf/rules/specify-rules.md` | Windsurf |
| `kilocode` | `.kilocode/rules/specify-rules.md` | Kilo Code |

### Examples

```powershell
# Update specific agent
.\update-agent-context.ps1 -AgentType copilot

# Update all existing agent files
.\update-agent-context.ps1
```

### What It Extracts from plan.md

- **Language/Version**: e.g., "Python 3.11"
- **Primary Dependencies**: e.g., "FastAPI, SQLAlchemy"
- **Storage**: e.g., "PostgreSQL"
- **Project Type**: e.g., "web"

---

## common.ps1

Shared functions used by all other scripts. Not called directly.

### Functions

| Function | Description |
|----------|-------------|
| `Get-RepoRoot` | Finds repository root (Git or .specify marker) |
| `Get-CurrentBranch` | Gets current feature from Git, env var, or specs/ |
| `Test-HasGit` | Checks if Git is available |
| `Test-FeatureBranch` | Validates feature branch naming |
| `Get-FeatureDir` | Constructs feature directory path |
| `Get-FeaturePathsEnv` | Returns all feature-related paths |
| `Test-FileExists` | Checks and reports file existence |
| `Test-DirHasFiles` | Checks if directory has files |
| `Show-OfflineTips` | Displays offline usage tips |

### Feature Detection Priority

1. `SPECIFY_FEATURE` environment variable
2. Git branch name (if Git available)
3. Highest numbered directory in `specs/`
4. Fallback to "main"

---

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `SPECIFY_FEATURE` | Override feature detection | `$env:SPECIFY_FEATURE = "001-my-feature"` |

---

## Common Workflows

### Creating a New Feature (Offline)

```powershell
# Set feature name (optional - auto-detected if specs/ exists)
$env:SPECIFY_FEATURE = "001-user-auth"

# Create feature structure
.\.specify\scripts\powershell\create-new-feature.ps1 "User authentication"

# Initialize plan
.\.specify\scripts\powershell\setup-plan.ps1
```

### Checking Prerequisites Before Implementation

```powershell
# Verify all required files exist
$prereqs = .\.specify\scripts\powershell\check-prerequisites.ps1 -Json -RequireTasks | ConvertFrom-Json

if ($prereqs.AVAILABLE_DOCS -contains "tasks.md") {
    Write-Host "Ready for implementation!"
}
```

### Updating Agent Context After Planning

```powershell
# Update all agents with new technology info
.\.specify\scripts\powershell\update-agent-context.ps1

# Or update specific agent
.\.specify\scripts\powershell\update-agent-context.ps1 -AgentType copilot
```

---

## Error Handling

All scripts:
- Exit with code `1` on error
- Exit with code `0` on success
- Display helpful error messages with suggested fixes
- Work gracefully when Git is unavailable
