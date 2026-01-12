# Git Commit Conventions

> Standardized commit message format for consistent and readable git history.

## Commit Message Format

```
<emoji> <type>(<scope>): <subject>

<body>
```

## Commit Types & Emojis

| Emoji | Type | Description |
|-------|------|-------------|
| ✨ | `feat` | New feature |
| 🐛 | `fix` | Bug fix |
| ♻️ | `refactor` | Code refactoring (no feature/fix) |
| 💄 | `style` | UI/styling changes |
| 📝 | `docs` | Documentation only |
| ✅ | `test` | Adding or updating tests |
| 👷 | `ci` | CI/CD configuration |
| 🔧 | `chore` | Maintenance tasks, configs |
| ⚡ | `perf` | Performance improvements |
| 🔀 | `merge` | Merge commits |
| 🗑️ | `remove` | Removing code/files |
| 🚀 | `release` | Release/deployment |

## Scope Examples

| Scope | Usage |
|-------|-------|
| `dashboard` | Dashboard feature changes |
| `auth` | Authentication related |
| `users` | User management |
| `cohort-benchmark` | Cohort benchmark feature |
| `video-playback` | Video playback feature |
| `widgets` | Shared widget components |
| `domain` | Domain models/logic |
| `core` | Core utilities |
| `ci` | CI/CD workflows |
| `ui` | General UI changes |

## Subject Rules

- Use imperative mood: "Add feature" not "Added feature"
- No period at the end
- Max 50 characters
- Capitalize first letter

## Body Rules (Optional)

- Wrap at 72 characters
- Explain what and why, not how
- Use bullet points for multiple changes

## Examples

### Simple commit
```
✨ feat(dashboard): Add session filter dropdown
```

### With scope and body
```
♻️ refactor(widgets): Extract large widget files into modular components

- Split user_profile.dart into separate user models
- Extract session_overview_chart into sub-components
- Add shared layout components
```

### Merge commit
```
🔀 merge(develop): Widget modularization and dark theme unification

Summary of changes since v1.3.0:
- ♻️ Modularize domain models and extract large widget components
- 💄 Unify dark theme styling and improve core UI components
- ✨ Sync session/cohort selection state across pages
```

### Bug fix
```
🐛 fix(video-playback): Fix video player state management
```

### CI changes
```
👷 ci: Optimize GitHub Actions workflows

- Add Pub cache to Linux/macOS/Web workflows
- Remove duplicate Pub cache config
```

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready releases |
| `develop` | Development and integration branch |

## Merge Strategy

1. Develop on `develop` branch
2. Squash related commits into meaningful groups before merging to `main`
3. Use `--no-ff` merge to preserve branch history
4. Tag releases on `main` with semantic versioning (e.g., `v1.3.0`)

## Pre-Commit Checklist

- [ ] Commit message follows format
- [ ] Subject is clear and concise
- [ ] Scope accurately reflects changed area
- [ ] Body explains significant changes (if needed)
- [ ] All commits in English
