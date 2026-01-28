# Spec Kit - Disconnected Edition

A fully offline, self-contained version of Spec Kit for spec-driven development in environments without GitHub connectivity.

## Overview

This version of Spec Kit is designed for **disconnected/locked-down environments** where:
- GitHub APIs are blocked by proxy/firewall
- Git operations may be unavailable
- No internet connectivity is available

## Key Differences from Standard Spec Kit

| Feature | Standard Spec Kit | Disconnected Edition |
|---------|-------------------|---------------------|
| Agent location | `.github/agents/` | `.specify/agents/` |
| Prompt location | `.github/prompts/` | `.specify/prompts/` |
| Issue creation | GitHub Issues API | Local `issues/` directory |
| Git dependency | Required | Optional (fallback support) |
| Branch detection | Git branch name | `SPECIFY_FEATURE` env var or directory naming |

## Quick Start

### 1. Copy to Your Project

Copy the entire `.specify/` folder and `.vscode/` folder to your project root:

```powershell
Copy-Item -Recurse path\to\spec-kit-disconnected\.specify your-project\.specify
Copy-Item -Recurse path\to\spec-kit-disconnected\.vscode your-project\.vscode
```

### 2. Set Feature Name (Non-Git Environments)

If you're not using Git, set the feature name via environment variable:

```powershell
$env:SPECIFY_FEATURE = "001-my-feature-name"
```

Or the scripts will detect the latest feature from the `specs/` directory.

### 3. Initialize a New Feature

Option A - Using the specify agent command in your AI assistant:
```
/speckit.specify "Create a user authentication system"
```

Option B - Manually:
```powershell
.\.specify\scripts\powershell\create-new-feature.ps1 "Create a user authentication system"
```

## Directory Structure

```
your-project/
├── .specify/
│   ├── agents/              # AI agent definitions (local, not .github)
│   │   ├── speckit.analyze.agent.md
│   │   ├── speckit.checklist.agent.md
│   │   ├── speckit.clarify.agent.md
│   │   ├── speckit.constitution.agent.md
│   │   ├── speckit.implement.agent.md
│   │   ├── speckit.plan.agent.md
│   │   ├── speckit.specify.agent.md
│   │   ├── speckit.tasks.agent.md
│   │   └── speckit.taskstoissues.agent.md  # Creates local issues
│   ├── memory/
│   │   └── constitution.md  # Project constitution/principles
│   ├── prompts/             # Reusable prompt templates
│   ├── scripts/
│   │   └── powershell/      # PowerShell scripts with offline support
│   └── templates/           # Document templates
├── .vscode/
│   └── settings.json        # VS Code settings for local agents
└── specs/                   # Feature specifications (created per feature)
    └── 001-feature-name/
        ├── spec.md
        ├── plan.md
        ├── tasks.md
        ├── issues/          # Local issue tracking (disconnected mode)
        └── checklists/
```

## Workflow Commands

All commands work offline. Use them with your AI assistant:

| Command | Purpose |
|---------|---------|
| `/speckit.specify` | Create feature specification from description |
| `/speckit.clarify` | Clarify ambiguities in specification |
| `/speckit.plan` | Generate technical implementation plan |
| `/speckit.tasks` | Break plan into executable tasks |
| `/speckit.taskstoissues` | Convert tasks to local issue files |
| `/speckit.checklist` | Generate quality checklists |
| `/speckit.analyze` | Analyze consistency across artifacts |
| `/speckit.implement` | Execute implementation per task list |
| `/speckit.constitution` | Create/update project constitution |

## Local Issue Tracking

Instead of GitHub Issues, this version creates local issue files:

```
specs/001-feature-name/issues/
├── ISSUE-001-setup-project.md
├── ISSUE-002-create-models.md
└── ISSUE-003-implement-api.md
```

Each issue file contains:
- Title and description
- Labels (from task markers)
- Status (Open/In Progress/Done)
- Dependencies
- Completion checklist

## Configuration

### VS Code Settings

The `.vscode/settings.json` configures agent file locations:

```json
{
  "github.copilot.chat.agentInstructions": ".specify/agents/"
}
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `SPECIFY_FEATURE` | Override feature name detection (useful without Git) |

## Offline Script Features

All PowerShell scripts in `.specify/scripts/powershell/` support offline operation:

- **`create-new-feature.ps1`**: Creates features with fallback to directory numbering
- **`check-prerequisites.ps1`**: Validates prerequisites without Git
- **`setup-plan.ps1`**: Initializes plan files
- **`common.ps1`**: Shared functions with offline support
- **`update-agent-context.ps1`**: Updates local agent context files

## Using Without Git

When Git is not available:

1. Set `SPECIFY_FEATURE` environment variable, or
2. The scripts will auto-detect from `specs/` directory structure
3. Branch creation is skipped with a warning
4. All other functionality works normally

Example:
```powershell
# Set feature manually
$env:SPECIFY_FEATURE = "002-new-feature"

# Or let auto-detection find latest in specs/
# (Scripts scan specs/ for highest numbered directory)
```

## AI Assistant Compatibility

This disconnected edition works with:
- GitHub Copilot (via `.specify/agents/`)
- Claude Code (via CLAUDE.md)
- Other AI assistants (agent context files supported)

The agents read their instructions from `.specify/agents/` instead of `.github/agents/`.

## Migration from Standard Spec Kit

If migrating from standard Spec Kit:

1. Move `.github/agents/*.agent.md` → `.specify/agents/`
2. Move `.github/prompts/*.prompt.md` → `.specify/prompts/`
3. Update any hardcoded `.github/` paths in your scripts
4. Test offline by disconnecting network and running workflows

## Troubleshooting

### "Unable to determine current feature"
Set the `SPECIFY_FEATURE` environment variable:
```powershell
$env:SPECIFY_FEATURE = "001-my-feature"
```

### "Plan template not found"
Ensure `.specify/templates/` contains all template files.

### Scripts not finding files
All scripts expect to run from repository root. Use absolute paths when possible.

## License

Same as original Spec Kit - see LICENSE file.
