import 'dart:io';

/// Service: reads the XDG user directories (`~/.config/user-dirs.dirs`).
class PlacesService {
  const PlacesService({this._environment});

  final Map<String, String>? _environment;

  Map<String, String> get _env => _environment ?? Platform.environment;

  String get homeDirectory => _env['HOME'] ?? '/';

  /// Returns `XDG_*_DIR` keys mapped to absolute paths.
  Future<Map<String, String>> userDirectories() async {
    final configHome = _env['XDG_CONFIG_HOME'] ?? '$homeDirectory/.config';
    final file = File('$configHome/user-dirs.dirs');
    if (!await file.exists()) return const {};
    final dirs = <String, String>{};
    final pattern = RegExp(r'^(XDG_\w+_DIR)="(.*)"$');
    for (final line in await file.readAsLines()) {
      final match = pattern.firstMatch(line.trim());
      if (match == null) continue;
      dirs[match.group(1)!] = match
          .group(2)!
          .replaceFirst(r'$HOME', homeDirectory);
    }
    return dirs;
  }

  Future<bool> isDirectory(String path) => Directory(path).exists();
}
