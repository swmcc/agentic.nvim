# GitHub Labels

Labels for the agentic.nvim repository.

## Label Definitions

| Label | Color | Description |
|-------|-------|-------------|
| 🚀 mvp | `#0E8A16` | Core MVP feature or task |
| 🏗️ architecture | `#1D76DB` | Architecture and design |
| 🔧 backend | `#5319E7` | Backend adapter implementation |
| 🤓 lua | `#FBCA04` | Lua code and implementation |
| 🎨 ux | `#D93F0B` | User experience and interface |
| ❓ help-wanted | `#008672` | Community help welcome |
| 🔍 investigation | `#0052CC` | Research and investigation |
| 🐛 bug | `#B60205` | Bug fix |
| 📦 release | `#6F42C1` | Release and packaging |
| 📚 docs | `#0075CA` | Documentation |
| ✅ testing | `#1D7631` | Testing and validation |
| ⚡ enhancement | `#A2EEEF` | Feature enhancement |
| 🔌 api | `#D4C5F9` | Internal API |
| 🔄 workflow | `#F9D0C4` | Workflow engine |

## GitHub CLI Commands

Create all labels using the GitHub CLI:

```bash
# Navigate to repo directory
cd agentic.nvim

# Create labels
gh label create "🚀 mvp" --color "0E8A16" --description "Core MVP feature or task"
gh label create "🏗️ architecture" --color "1D76DB" --description "Architecture and design"
gh label create "🔧 backend" --color "5319E7" --description "Backend adapter implementation"
gh label create "🤓 lua" --color "FBCA04" --description "Lua code and implementation"
gh label create "🎨 ux" --color "D93F0B" --description "User experience and interface"
gh label create "❓ help-wanted" --color "008672" --description "Community help welcome"
gh label create "🔍 investigation" --color "0052CC" --description "Research and investigation"
gh label create "🐛 bug" --color "B60205" --description "Bug fix"
gh label create "📦 release" --color "6F42C1" --description "Release and packaging"
gh label create "📚 docs" --color "0075CA" --description "Documentation"
gh label create "✅ testing" --color "1D7631" --description "Testing and validation"
gh label create "⚡ enhancement" --color "A2EEEF" --description "Feature enhancement"
gh label create "🔌 api" --color "D4C5F9" --description "Internal API"
gh label create "🔄 workflow" --color "F9D0C4" --description "Workflow engine"
```

## Label Usage Guidelines

### Feature Development
- Use `🚀 mvp` for all core MVP features
- Combine with `🤓 lua` for Lua implementation tasks
- Add `🔧 backend` for adapter-specific work

### Architecture
- Use `🏗️ architecture` for design decisions
- Combine with `🔌 api` for API design
- Add `🔄 workflow` for workflow engine design

### Documentation
- Use `📚 docs` for all documentation tasks
- Combine with `🚀 mvp` if docs are MVP-blocking

### Issues and Bugs
- Use `🐛 bug` for bug reports
- Add `🔍 investigation` if root cause is unknown
- Include `❓ help-wanted` for community contributions

### Releases
- Use `📦 release` for release preparation
- Combine with `✅ testing` for release testing
