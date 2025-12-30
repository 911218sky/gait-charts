# Git Commit Guidelines

## 🌐 Language

All commit messages **MUST** be in **English** for:
- 🤝 International team collaboration
- 📜 Consistent and professional git history
- 🔍 Easy understanding for future maintainers

## 📝 Format

```
<type>(<scope>): <short description>

[optional body with more details]
```

## 🏷️ Commit Types

| Type | Emoji | Description |
|------|-------|-------------|
| `feat` | ✨ | New feature |
| `fix` | 🐛 | Bug fix |
| `refactor` | ♻️ | Code refactoring (no functional change) |
| `docs` | 📝 | Documentation changes |
| `style` | 💄 | Code style/formatting changes |
| `perf` | ⚡ | Performance improvements |
| `test` | ✅ | Adding or updating tests |
| `chore` | 🔧 | Build process, dependencies, or tooling |
| `ci` | 👷 | CI/CD configuration changes |

## 📋 Examples

```
feat(video): add H.264 encoding support with FFmpeg fallback

- Add FFmpegConverter utility class for video transcoding
- Support HTTP Range Requests for video streaming
- Auto-detect available codecs with fallback chain
```

```
fix(api): resolve session deletion not removing video files
```

```
refactor(processor): extract video codec selection logic
```

## ✅ Rules

| # | Rule |
|---|------|
| 1 | First line under 72 characters |
| 2 | Use imperative mood ("add" not "added") |
| 3 | No period at end of subject line |
| 4 | Blank line between subject and body |
| 5 | Body explains WHAT and WHY, not HOW |
