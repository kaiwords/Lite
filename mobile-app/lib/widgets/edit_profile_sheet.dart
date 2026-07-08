import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../services/local_store.dart';
import '../theme/app_theme.dart';

/// Opens the editable-profile bottom sheet (display name / username / bio).
/// Saves to [currentUserProvider] and persists.
Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const EditProfileSheet(),
  );
}

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final u = ref.read(currentUserProvider);
    _name = TextEditingController(text: u?.displayName ?? '');
    _username = TextEditingController(text: u?.username ?? '');
    _bio = TextEditingController(text: u?.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    final u = ref.read(currentUserProvider);
    if (u == null) return;
    final name = _name.text.trim();
    final username = _username.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (name.isEmpty || username.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Name and username can\'t be empty'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final updated = u.copyWith(
      displayName: name,
      username: username,
      bio: _bio.text.trim(),
    );
    ref.read(currentUserProvider.notifier).state = updated;
    LocalStore.instance.saveCurrentUser(updated);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Profile updated'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  TextField _field(TextEditingController c, String label, bool isDark,
      {String? prefix, int maxLines = 1}) {
    final fill =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: GoogleFonts.lato(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final divColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: divColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Edit Profile',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: titleColor)),
              const SizedBox(height: 16),
              _field(_name, 'Display name', isDark),
              const SizedBox(height: 12),
              _field(_username, 'Username', isDark, prefix: '@'),
              const SizedBox(height: 12),
              _field(_bio, 'Bio', isDark, maxLines: 3),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _save,
                child: Text('Save',
                    style: GoogleFonts.lato(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
