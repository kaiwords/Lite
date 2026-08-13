import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

// A seller-picked book cover photo is always a local file path today (no
// upload backend yet), same convention as User.avatarUrl/coverImageUrl (see
// profile_screen.dart's `_profileImage`). Returns null on web (file_picker
// has no local filesystem there) or when unset, so callers can fall back to
// the designed (color + text) cover.
File? coverImageFile(String? path) {
  if (path == null || path.isEmpty) return null;
  if (kIsWeb) return null;
  return File(path);
}
