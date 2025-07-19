# Changelog

## [0.3.0] - 2025-07-19

### Fixed
- Fixed Dart formatting issues in `bin/flutter_asset_gen.dart`
- Applied `dart format .` to ensure consistent code formatting
- Resolved linting and formatting warnings

## [0.2.0] - 2025-07-19

### Added
- **Watch Mode** - Automatically regenerate assets when files change
  - `--watch` CLI flag for watch mode
  - Debounced file watching (300ms)
  - Recursive directory monitoring
  - Smart filtering (excludes temp files, hidden files)
  - Graceful shutdown with Ctrl+C
  - `watch_mode` configuration option

- **Enum Output** - Generate enum-based asset constants
  - `generate_enum` configuration option
  - Enum with path property and toString() method
  - Static values map for easy lookup
  - Full documentation and examples

- **Pubspec Validation** - Validate assets against pubspec.yaml
  - `validate_pubspec` configuration option
  - Check for missing assets in pubspec.yaml
  - Report unused assets in pubspec.yaml
  - `--no-validate` CLI flag to skip validation
  - Detailed validation reports with suggestions

- **Build Runner Integration** - Full build_runner support
  - `AssetGenBuilder` for build_runner integration
  - `build_runner_mode` configuration option
  - Support for build.yaml configuration
  - Seamless integration with existing build processes

- **Enhanced Configuration**
  - `pubspec_path` option for custom pubspec.yaml location
  - All new options supported in YAML configuration
  - Backward compatibility with existing configs

- **Improved CLI**
  - `--watch` flag for watch mode
  - `--no-validate` flag to skip validation
  - Enhanced help output with all new options
  - Better error handling and user feedback

- **Comprehensive Documentation**
  - Complete README with all new features
  - Usage examples for all output types
  - Configuration reference tables
  - Build runner integration guide
  - Validation and watch mode documentation

### Changed
- Enhanced `GenerationResult` to include validation results
- Updated default configuration to enable validation by default
- Improved error messages and user feedback
- Better handling of edge cases in file watching

### Fixed
- Improved file path handling across different platforms
- Better error handling in configuration loading
- Fixed issues with special characters in asset paths

## [0.1.0] - 2025-07-19

### Added
- Initial release with basic asset generation
- YAML configuration support
- Multiple asset roots support
- Smart filtering and exclusions
- Case style options (camel, snake, kebab)
- Grouping by root directory
- Map generation for all assets
- CLI with verbose and dry-run options
