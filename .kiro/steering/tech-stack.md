---
inclusion: always
---

# Technology Stack

## Core Framework

### Flutter & Dart
- **Flutter**: 3.x (latest stable)
- **Dart**: 3.x (latest stable)
- **Target Platforms**: Desktop (primary), Web, Android

### State Management
- **Riverpod**: 3.x (AsyncNotifier, Notifier patterns)
- **No other state management**: Provider, Bloc, GetX are forbidden

## UI & Design

### Design System
- **Material Design**: 3.x with custom theming
- **Theme Mode**: Dark mode as default
- **Typography**: Google Fonts Inter
- **Icons**: Material Icons with custom additions

### Responsive Design
- **Desktop**: NavigationRail for wide screens
- **Mobile**: NavigationBar for narrow screens
- **Breakpoints**: Follow Material Design 3 guidelines

## Networking & Data

### HTTP Client
- **Dio**: Latest stable version
- **Interceptors**: Auth, compression, signed headers
- **Error Handling**: Custom ApiException mapping
- **Retry Logic**: Exponential backoff with jitter

### Data Serialization
- **JSON**: Manual serialization with type safety
- **Models**: Immutable classes with fromJson factories
- **Validation**: Built-in validation in domain models

### File Handling
- **Platform-specific**: Conditional imports for IO/Web
- **Downloads**: Platform-appropriate download mechanisms
- **File Types**: BAG files, video files, JSON exports

## Development Tools

### Code Quality
- **Linting**: analysis_options.yaml with strict rules
- **Formatting**: dart format with 2-space indentation
- **Static Analysis**: Dart analyzer with custom rules

### Testing
- **Unit Tests**: Core business logic testing
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end workflow testing
- **Test Framework**: Built-in Flutter testing

### Build & Deployment
- **GitHub Actions**: CI/CD pipeline
- **Platforms**: Windows, macOS, Linux, Web, Android
- **Artifacts**: Platform-specific installers and packages

## Architecture Patterns

### Domain-Driven Design (DDD)
- **Layers**: Presentation, Domain, Data
- **Features**: Feature-based module organization
- **Dependencies**: Unidirectional dependency flow

### Design Patterns
- **Repository Pattern**: Data access abstraction
- **Provider Pattern**: Dependency injection via Riverpod
- **Observer Pattern**: Reactive state management
- **Factory Pattern**: Model creation and parsing

## Key Dependencies

### Core Flutter Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  riverpod: ^3.x
  flutter_riverpod: ^3.x
  dio: ^5.x
  google_fonts: ^6.x
```

### Platform-Specific Packages
```yaml
  # Desktop
  window_manager: ^0.x
  
  # File handling
  file_selector: ^1.x
  path_provider: ^2.x
  
  # Security
  flutter_secure_storage: ^9.x
  
  # Video
  video_player: ^2.x
```

### Development Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.x
  build_runner: ^2.x
```

## Forbidden Technologies

### State Management
- ❌ Provider package (use Riverpod instead)
- ❌ Bloc/Cubit
- ❌ GetX
- ❌ MobX
- ❌ Redux

### HTTP Clients
- ❌ http package (use Dio instead)
- ❌ Chopper
- ❌ Retrofit

### UI Libraries
- ❌ Cupertino widgets (Material Design only)
- ❌ Third-party UI libraries (use Material 3)

## Performance Considerations

### Memory Management
- Use const constructors where possible
- Dispose controllers and streams properly
- Implement efficient list rendering for large datasets

### Network Optimization
- Request compression
- Response caching where appropriate
- Pagination for large data sets
- Connection pooling via Dio

### Rendering Optimization
- Efficient widget rebuilds via Riverpod
- Image caching and optimization
- Lazy loading for large lists
- Debounced user inputs

## Security Standards

### Data Protection
- Secure storage for sensitive data
- Input validation and sanitization
- HTTPS-only communication
- JWT token management

### Authentication
- Admin-only authentication system
- Token refresh mechanisms
- Secure credential storage
- Session management

## Platform-Specific Considerations

### Desktop (Primary Target)
- Window management and sizing
- Native file dialogs
- Keyboard shortcuts
- System tray integration (if needed)

### Web
- Responsive design for various screen sizes
- Browser compatibility (modern browsers)
- CORS handling
- Web-specific file downloads

### Android (Secondary)
- Material Design 3 compliance
- Touch-friendly interface
- Android-specific permissions
- APK optimization