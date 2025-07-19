import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'config.dart';
import 'generator.dart';

/// Watches asset directories for changes and automatically regenerates assets.
///
/// This class provides file system watching capabilities to automatically
/// regenerate asset constants when files are added, modified, or deleted
/// in the configured asset directories.
///
/// ## Example
///
/// ```dart
/// final config = AssetGenConfig.defaults().copyWith(
///   watchMode: true,
///   roots: ['assets', 'images'],
/// );
///
/// final watcher = AssetWatcher(config);
/// await watcher.start();
///
/// // Later, to stop watching
/// await watcher.stop();
/// ```
///
/// ## Features
///
/// - **Debounced watching**: Prevents excessive regeneration on rapid changes
/// - **Smart filtering**: Excludes temporary files and hidden files
/// - **Recursive monitoring**: Watches all subdirectories
/// - **Graceful shutdown**: Proper cleanup of file system watchers
class AssetWatcher {
  /// The configuration to use for asset generation.
  final AssetGenConfig config;

  /// Active file system watcher subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  /// Directories being watched.
  final List<Directory> _watchedDirs = [];

  /// Whether the watcher is currently running.
  bool _isRunning = false;

  /// Timer for debouncing rapid file changes.
  Timer? _debounceTimer;

  /// Creates a new [AssetWatcher] with the specified configuration.
  ///
  /// [config] The configuration to use for asset generation and watching.
  AssetWatcher(this.config);

  /// Starts watching asset directories for changes.
  ///
  /// This method will:
  /// 1. Perform an initial asset generation
  /// 2. Set up file system watchers for all configured directories
  /// 3. Begin monitoring for file changes
  /// 4. Automatically regenerate assets when changes are detected
  ///
  /// ## Example
  ///
  /// ```dart
  /// final watcher = AssetWatcher(config);
  /// await watcher.start();
  ///
  /// // The watcher will now monitor directories and regenerate
  /// // assets automatically when files change
  /// ```
  ///
  /// ## Features
  ///
  /// - **Initial generation**: Generates assets immediately when started
  /// - **Recursive watching**: Monitors all subdirectories
  /// - **Debounced changes**: Waits 300ms after changes before regenerating
  /// - **Smart filtering**: Ignores temporary and hidden files
  /// - **Error handling**: Continues watching even if individual files fail
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    print('🔍 Starting watch mode...');
    print('Watching directories: ${config.roots.join(', ')}');
    print('Output: ${config.output}');
    print('Press Ctrl+C to stop\n');

    // Initial generation
    await _generateAssets();

    // Watch each root directory
    for (final root in config.roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) {
        print('⚠️  Directory $root does not exist, skipping...');
        continue;
      }

      _watchedDirs.add(dir);
      final subscription =
          dir.watch(events: FileSystemEvent.all, recursive: true).listen(
        (event) {
          _handleFileEvent(event);
        },
        onError: (error) {
          print('❌ Watch error for $root: $error');
        },
      );
      _subscriptions.add(subscription);
    }

    // Keep the process alive
    await Future.delayed(Duration.zero);
  }

  /// Handles file system events and triggers regeneration if needed.
  ///
  /// This method is called for every file system event in watched directories.
  /// It filters out irrelevant events and debounces rapid changes to prevent
  /// excessive regeneration.
  ///
  /// ## Filtering
  ///
  /// The following files are ignored:
  /// - Hidden files (starting with `.`)
  /// - Temporary files (ending with `.tmp`, `.swp`, `~`)
  /// - The output file itself
  /// - Files that don't match the configured extensions
  /// - Files that match exclusion patterns
  ///
  /// [event] The file system event that occurred.
  void _handleFileEvent(FileSystemEvent event) {
    // Skip temporary files and hidden files
    final fileName = p.basename(event.path);
    if (fileName.startsWith('.') ||
        fileName.endsWith('.tmp') ||
        fileName.endsWith('.swp') ||
        fileName.endsWith('~')) {
      return;
    }

    // Skip if it's the output file itself
    if (event.path == config.output) {
      return;
    }

    // Check if the file should be included based on config
    if (config.includeExtensions != null) {
      final ext = p.extension(event.path).toLowerCase();
      if (!config.includeExtensions!.contains(ext)) {
        return;
      }
    }

    // Check if the file should be excluded
    final relPath = p.relative(event.path, from: '.');
    if (config.exclude.any((pattern) => _matchesPattern(relPath, pattern))) {
      return;
    }

    // Debounce rapid changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _generateAssets();
    });
  }

  /// Checks if a path matches a glob-like pattern.
  ///
  /// Supports simple glob patterns with `*` wildcards.
  ///
  /// [path] The path to check.
  /// [pattern] The pattern to match against.
  ///
  /// Returns true if the path matches the pattern.
  bool _matchesPattern(String path, String pattern) {
    // Simple glob-like pattern matching
    if (pattern.contains('*')) {
      final regex = pattern.replaceAll('.', r'\.').replaceAll('*', '.*');
      return RegExp(regex).hasMatch(path);
    }
    return path.contains(pattern);
  }

  /// Generates assets using the current configuration.
  ///
  /// This method is called when file changes are detected and after
  /// the debounce timer expires. It handles errors gracefully and
  /// provides user feedback about the generation process.
  Future<void> _generateAssets() async {
    try {
      final result = await generateAssets(
        config: config,
        verbose: true,
      );

      if (result.skipped) {
        print('⏭️  No changes detected (${result.count} assets)');
      } else {
        print('✅ Generated ${result.count} assets → ${config.output}');
      }

      if (result.warnings.isNotEmpty) {
        for (final warning in result.warnings) {
          print('⚠️  $warning');
        }
      }
    } catch (e) {
      print('❌ Generation error: $e');
    }
  }

  /// Stops watching directories and cleans up resources.
  ///
  /// This method should be called when you want to stop the file watching
  /// process. It will:
  /// 1. Cancel the debounce timer
  /// 2. Cancel all file system watcher subscriptions
  /// 3. Clean up internal state
  ///
  /// ## Example
  ///
  /// ```dart
  /// final watcher = AssetWatcher(config);
  /// await watcher.start();
  ///
  /// // Later, when you want to stop
  /// await watcher.stop();
  /// ```
  ///
  /// ## Graceful Shutdown
  ///
  /// It's recommended to call this method when your application is shutting
  /// down to ensure proper cleanup of file system watchers.
  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;

    print('\n🛑 Stopping watch mode...');

    _debounceTimer?.cancel();

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    print('✅ Watch mode stopped');
  }
}
