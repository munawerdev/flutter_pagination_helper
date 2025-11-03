# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2024-11-03

### Added
- Initial release of Flutter Pagination Helper
- `PaginatedListView` widget with infinite scrolling
- `PaginatedGridView` widget for grid layouts
- `PaginationMixin` - **State-management agnostic** pagination logic
- Support for offset-based pagination
- Support for page-based pagination
- Support for cursor-based pagination
- Pull-to-refresh functionality
- Customizable loading indicators
- Empty state widgets
- Separator support for list views
- Configurable load more threshold
- Type-safe generic implementation
- Comprehensive documentation and examples
- Error handling with optional error callbacks
- Built-in error state management

### Features
- **Universal Compatibility**: Works with ANY state management solution:
  - Flutter Bloc/Cubit
  - Provider/ChangeNotifier
  - Riverpod
  - GetX
  - setState
  - Custom solutions
- **Zero Dependencies**: No required state management dependencies
- Automatic pagination trigger when scrolling near bottom
- Prevention of duplicate load more calls
- Flexible API integration (works with any backend)
- Custom scroll controller support
- Customizable physics and padding
- Shrink wrap support
- Adaptive loading indicators (iOS/Android)
- Simple error handling with updateState callback

### Design Philosophy
- No coupling to specific state management frameworks
- Users provide their own `updateState` callback
- fetchData returns data directly (throws on error)
- Clean, simple API with minimal boilerplate
- Removed ApiResponse wrapper dependency

## [Unreleased]

### Planned
- Performance optimizations
- More examples and use cases
- Sliver variants for custom scroll views
- Advanced caching strategies
- Batch loading support