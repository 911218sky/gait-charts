---
inclusion: always
---

# Gait Charts Dashboard Development Guidelines

> Enable AI and developers to extend features consistently without reading full history, maintaining UI/architecture consistency and avoiding performance/state management pitfalls.

## 🚨 Core Principles (Violations = Unacceptable)

1. **Layer Separation is Sacred**: `domain` = rules/calculations/models, `data` = IO/HTTP, `presentation` = UI & interactions
2. **Riverpod 3 Only**: No other state management libraries allowed
3. **No Side Effects in build()**: No recalculations, JSON parsing, sorting, aggregation, showSnackBar, or navigation in `build()`

## 🌐 Language Guidelines

- Comments, UI text, README in **Traditional Chinese**
- Keep technical terms in English: `session`, `lap`, `offset`, `payload`, `debounce`

## 📁 Directory Structure (DDD / Feature-based)

```
lib/
├── app/                    # App-level (MaterialApp, theme, home entry)
├── core/                   # Reusable shared layer
│   ├── config/             # Cross-feature config (AppConfig)
│   ├── network/            # dioProvider, API retry, exception mapping
│   ├── providers/          # Global providers
│   └── widgets/            # Cross-feature shared UI (AsyncRequestView)
└── features/<feature>/     # Feature modules
    ├── data/               # API service, repository
    ├── domain/             # Pure models, calculation logic (no Flutter dependency)
    └── presentation/
        ├── providers/      # Notifier / AsyncNotifier
        ├── views/          # Large view compositions
        └── widgets/        # Small components
```

### 🔗 Dependency Direction (Enforced)

| Direction | Allowed |
|-----------|---------|
| `presentation` → `domain`, `data` | ✅ |
| `data` → `domain`, `core` | ✅ |
| `domain` → Flutter / UI | ❌ |
| `core` → Single feature business rule | ❌ |

## 🌐 Network Guidelines (Dio)

| Rule | Description |
|------|-------------|
| ❌ Forbidden | UI directly using `Dio()` or handling `DioException` |
| ✅ Use | `dioProvider` (`lib/core/network/api_client.dart`) |
| ✅ Errors | `mapDioError` (`lib/core/network/api_exception.dart`) |
| ✅ Retry | `withApiRetry(...)` |
| ✅ Base URL | `lib/core/config/app_config.dart` |

## 🔄 Riverpod Guidelines

### 📍 Placement

| Type | Location |
|------|----------|
| Global | `lib/app` or `lib/core/providers` |
| Feature-specific | `lib/features/<feature>/presentation/providers` |

### 📝 Naming

- Providers end with `...Provider`
- Notifiers end with `...Notifier`
- Provide `<feature>_providers.dart` barrel export

### ⚠️ Error Handling

- UI async state uses `AsyncRequestView`
- Don't catch Dio exceptions in UI; convert to `ApiException` in data layer
- Handle side effects with `ref.listen()`, not in `build()`

## 🎨 UI / Theme

| Rule | Description |
|------|-------------|
| Default | Dark mode (`ThemeMode.dark`) |
| Colors | Use `context.colorScheme`, `context.theme` (ThemeContextExtension) |
| ❌ Forbidden | Hardcoded color constants (except in `lib/app/theme.dart`) |
| Wide screen | `NavigationRail` |
| Small screen | `NavigationBar` |
| Animations | 150–300ms |

## 📦 Domain Model

- **Immutable**: `final` fields, prefer `const` constructors
- **JSON**: `factory Xxx.fromJson` with internal type safety
- **Aggregation/sorting/filter**: Place in `domain` or derived providers

## 💻 Code Style

| Rule | Description |
|------|-------------|
| Indentation | 2-space |
| Constants | Use `const` whenever possible |
| Trailing commas | Keep for multi-line |
| File names | `snake_case.dart` |
| Public API | Use `///` doc comments |

## 🔄 Development Workflow

1. Identify feature (existing or new)
2. Start with domain (models/calculations)
3. Then data (API service → repository)
4. Finally presentation (provider → view/widget)
5. Reference existing patterns before extending

## ✅ Pre-Change Checklist

- [ ] domain/data/presentation boundaries are clear
- [ ] Provider placement and naming are correct
- [ ] No side effects triggered in `build()`
- [ ] Network errors go through `mapDioError`
- [ ] No hardcoded colors
- [ ] No heavy calculations in `build()`
- [ ] New logic has unit tests