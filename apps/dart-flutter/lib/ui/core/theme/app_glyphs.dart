import 'package:material_ui/material_ui.dart';

import '../../../domain/models/file_entry.dart';
import '../../../domain/models/place.dart';
import 'app_colors.dart';

/// Nerd Font glyphs (Font Awesome range) used as icons.
abstract final class AppGlyphs {
  static const folder = '\u{F07B}';
  static const file = '\u{F15B}';
  static const fileText = '\u{F15C}';
  static const fileImage = '\u{F1C5}';
  static const fileArchive = '\u{F1C6}';
  static const fileAudio = '\u{F1C7}';
  static const fileVideo = '\u{F1C8}';
  static const fileCode = '\u{F1C9}';
  static const filePdf = '\u{F1C1}';
  static const symlink = '\u{F481}';
  static const other = '\u{F128}';

  static const back = '\u{F060}';
  static const forward = '\u{F061}';
  static const up = '\u{F062}';
  static const refresh = '\u{F021}';
  static const eye = '\u{F06E}';
  static const eyeSlash = '\u{F070}';
  static const chevronRight = '\u{F054}';
  static const warning = '\u{F071}';

  /// Optical-centre correction in em (`design/tokens.json` →
  /// `glyphCentering`): how far to shift a glyph left to centre its ink.
  static double opticalOffset(String glyph) => switch (glyph) {
    back || forward => 0.094,
    up => 0.036,
    refresh => 0.122,
    eye => 0.209,
    eyeSlash => 0.268,
    _ => 0,
  };

  static String forPlace(PlaceKind kind) => switch (kind) {
    PlaceKind.home => '\u{F015}',
    PlaceKind.desktop => '\u{F108}',
    PlaceKind.documents => '\u{F15C}',
    PlaceKind.downloads => '\u{F019}',
    PlaceKind.pictures => '\u{F03E}',
    PlaceKind.music => '\u{F001}',
    PlaceKind.videos => '\u{F03D}',
    PlaceKind.root => '\u{F0A0}',
  };

  /// Glyph + colour for an entry (aqua folders, purple links, gold media).
  static (String, Color) forEntry(FileEntry entry) => switch (entry.kind) {
    EntryKind.directory => (folder, AppColors.aqua),
    EntryKind.symlinkToDirectory ||
    EntryKind.symlinkToFile => (symlink, AppColors.purple),
    EntryKind.other => (other, AppColors.textSecondary),
    EntryKind.file => _forExtension(entry.extension),
  };

  static (String, Color) _forExtension(String? ext) => switch (ext) {
    'png' ||
    'jpg' ||
    'jpeg' ||
    'gif' ||
    'svg' ||
    'webp' ||
    'bmp' => (fileImage, AppColors.gold),
    'mp3' || 'flac' || 'ogg' || 'wav' || 'm4a' => (fileAudio, AppColors.gold),
    'mp4' || 'mkv' || 'webm' || 'avi' || 'mov' => (fileVideo, AppColors.gold),
    'zip' ||
    'tar' ||
    'gz' ||
    'xz' ||
    'zst' ||
    'bz2' ||
    '7z' ||
    'rar' ||
    'deb' ||
    'rpm' => (fileArchive, AppColors.textSecondary),
    'pdf' => (filePdf, AppColors.textSecondary),
    'txt' ||
    'md' ||
    'log' ||
    'conf' ||
    'ini' ||
    'cfg' => (fileText, AppColors.textSecondary),
    'rs' ||
    'c' ||
    'h' ||
    'cpp' ||
    'hpp' ||
    'zig' ||
    'dart' ||
    'py' ||
    'js' ||
    'ts' ||
    'sh' ||
    'json' ||
    'toml' ||
    'yaml' ||
    'yml' ||
    'html' ||
    'css' => (fileCode, AppColors.textSecondary),
    _ => (file, AppColors.textSecondary),
  };
}
