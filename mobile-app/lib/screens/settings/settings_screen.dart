import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/edit_profile_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: Theme.of(context).appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: const LiteratureBottomNavBar(currentIndex: 4),
      body: ListView(
        children: [
          // ── Account ───────────────────────────────────────────────────
          _SectionHeader(label: 'Account', isDark: isDark),
          _Tile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            isDark: isDark,
            onTap: () => _showEditProfile(context),
          ),
          _Tile(
            icon: Icons.alternate_email_rounded,
            label: 'Change Username',
            isDark: isDark,
            onTap: () => _showChangeUsername(context, ref),
          ),
          _Tile(
            icon: Icons.mail_outline_rounded,
            label: 'Change Email',
            isDark: isDark,
            onTap: () => _showChangeEmail(context),
          ),
          _Tile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            isDark: isDark,
            onTap: () => _showChangePassword(context),
          ),

          // ── Appearance ────────────────────────────────────────────────
          _SectionHeader(label: 'Appearance', isDark: isDark),
          _ThemeTile(isDark: isDark),
          _FontSizeTile(isDark: isDark),

          // ── Notifications ─────────────────────────────────────────────
          _SectionHeader(label: 'Notifications', isDark: isDark),
          _SwitchTile(
            icon: Icons.notifications_outlined,
            label: 'Push Notifications',
            provider: notifPushProvider,
            isDark: isDark,
          ),
          _SwitchTile(
            icon: Icons.person_add_alt_1_outlined,
            label: 'New Followers',
            provider: notifFollowsProvider,
            isDark: isDark,
          ),
          _SwitchTile(
            icon: Icons.favorite_border_rounded,
            label: 'Likes & Reactions',
            provider: notifLikesProvider,
            isDark: isDark,
          ),
          _SwitchTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Comments',
            provider: notifCommentsProvider,
            isDark: isDark,
          ),
          _SwitchTile(
            icon: Icons.volunteer_activism_outlined,
            label: 'Tips Received',
            provider: notifTipsProvider,
            isDark: isDark,
          ),

          // ── Privacy ───────────────────────────────────────────────────
          _SectionHeader(label: 'Privacy', isDark: isDark),
          _SwitchTile(
            icon: Icons.lock_person_outlined,
            label: 'Private Account',
            subtitle: 'Only approved followers can see your posts',
            provider: privateAccountProvider,
            isDark: isDark,
          ),
          _DmPermissionTile(isDark: isDark),

          // ── Creator Tools ─────────────────────────────────────────────
          _SectionHeader(label: 'Creator', isDark: isDark),
          _SwitchTile(
            icon: Icons.volunteer_activism_rounded,
            label: 'Enable Tips',
            subtitle: 'Let readers support you directly',
            provider: tipsEnabledProvider,
            isDark: isDark,
          ),
          _SwitchTile(
            icon: Icons.account_balance_outlined,
            label: 'Auto Payout',
            subtitle: 'Automatically withdraw earnings monthly',
            provider: autoPayoutProvider,
            isDark: isDark,
          ),
          _Tile(
            icon: Icons.storefront_outlined,
            label: 'Manage Marketplace Listings',
            isDark: isDark,
            onTap: () => context.push('/marketplace'),
          ),

          // ── About ─────────────────────────────────────────────────────
          _SectionHeader(label: 'About', isDark: isDark),
          _Tile(
            icon: Icons.help_outline_rounded,
            label: 'Help Center',
            isDark: isDark,
            onTap: () => _openInfo(context, 'Help Center', _helpText),
          ),
          _Tile(
            icon: Icons.bug_report_outlined,
            label: 'Report a Bug',
            isDark: isDark,
            onTap: () => _showReportBug(context),
          ),
          _Tile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            isDark: isDark,
            onTap: () => _openInfo(context, 'Terms of Service', _termsText),
          ),
          _Tile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            isDark: isDark,
            onTap: () => _openInfo(context, 'Privacy Policy', _privacyText),
          ),
          _VersionTile(isDark: isDark),

          // ── Sign Out ──────────────────────────────────────────────────
          const SizedBox(height: 8),
          _SignOutButton(isDark: isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Account / about row handlers
// ─────────────────────────────────────────────────────────────────────────────

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );

void _showEditProfile(BuildContext context) => showEditProfileSheet(context);

void _showChangeUsername(BuildContext context, WidgetRef ref) {
  final current = ref.read(currentUserProvider);
  showDialog(
    context: context,
    builder: (_) => _InputDialog(
      title: 'Change Username',
      label: 'Username',
      initial: current?.username ?? '',
      prefix: '@',
      validate: (v) => v.trim().isEmpty ? 'Username can\'t be empty' : null,
      onSave: (v) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          final updated = user.copyWith(username: v.trim());
          ref.read(currentUserProvider.notifier).state = updated;
          LocalStore.instance.saveCurrentUser(updated);
        }
        _snack(context, 'Username updated to @${v.trim()}');
      },
    ),
  );
}

void _showChangeEmail(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => _InputDialog(
      title: 'Change Email',
      label: 'Email address',
      initial: '',
      keyboardType: TextInputType.emailAddress,
      validate: (v) {
        final t = v.trim();
        if (t.isEmpty) return 'Email can\'t be empty';
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
          return 'Enter a valid email address';
        }
        return null;
      },
      onSave: (v) => _snack(context, 'Verification sent to ${v.trim()}'),
    ),
  );
}

void _showChangePassword(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
}

void _showReportBug(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => _InputDialog(
      title: 'Report a Bug',
      label: 'Describe what went wrong',
      initial: '',
      maxLines: 4,
      validate: (v) =>
          v.trim().length < 5 ? 'Please add a little more detail' : null,
      onSave: (v) => _snack(context, 'Thanks — your report was sent.'),
    ),
  );
}

void _openInfo(BuildContext context, String title, String body) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => _InfoScreen(title: title, body: body),
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.lato(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Basic tappable tile
// ─────────────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(label,
          style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor)),
      trailing: Icon(Icons.chevron_right_rounded,
          size: 20,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Switch tile (Riverpod-backed)
// ─────────────────────────────────────────────────────────────────────────────

class _SwitchTile extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final StateProvider<bool> provider;
  final bool isDark;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.provider,
    required this.isDark,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    final iconColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(label,
          style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: GoogleFonts.lato(fontSize: 11, color: subColor))
          : null,
      trailing: Switch(
        value: value,
        onChanged: (v) => ref.read(provider.notifier).state = v,
        activeThumbColor: AppColors.accent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme tile — light / dark / system
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeTile extends ConsumerWidget {
  final bool isDark;
  const _ThemeTile({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final iconColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final modeLabel = switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.palette_outlined, size: 18, color: iconColor),
      ),
      title: Text('Theme',
          style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor)),
      subtitle: Text(modeLabel,
          style: GoogleFonts.lato(fontSize: 11, color: subColor)),
      trailing: _ThemeSegmentedControl(isDark: isDark),
    );
  }
}

class _ThemeSegmentedControl extends ConsumerWidget {
  final bool isDark;
  const _ThemeSegmentedControl({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final options = [
      (ThemeMode.light, Icons.light_mode_rounded),
      (ThemeMode.system, Icons.brightness_auto_rounded),
      (ThemeMode.dark, Icons.dark_mode_rounded),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final (m, ic) = o;
        final active = mode == m;
        return GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).setMode(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ic,
                size: 17,
                color: active
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Font size tile
// ─────────────────────────────────────────────────────────────────────────────

class _FontSizeTile extends ConsumerWidget {
  final bool isDark;
  const _FontSizeTile({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(fontSizeProvider);
    final iconColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final label = switch (size) {
      FontSizePref.small => 'Small',
      FontSizePref.medium => 'Medium',
      FontSizePref.large => 'Large',
    };

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.format_size_rounded, size: 18, color: iconColor),
      ),
      title: Text('Font Size',
          style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor)),
      subtitle: Text(label,
          style: GoogleFonts.lato(fontSize: 11, color: subColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: FontSizePref.values.map((s) {
          final active = size == s;
          return GestureDetector(
            onTap: () => ref.read(fontSizeProvider.notifier).state = s,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent
                    : (isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  switch (s) {
                    FontSizePref.small => 'S',
                    FontSizePref.medium => 'M',
                    FontSizePref.large => 'L',
                  },
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DM permission tile
// ─────────────────────────────────────────────────────────────────────────────

class _DmPermissionTile extends ConsumerWidget {
  final bool isDark;
  const _DmPermissionTile({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(dmPermissionProvider);
    final iconColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.mail_lock_outlined, size: 18, color: iconColor),
      ),
      title: Text('Who Can Message Me',
          style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor)),
      trailing: DropdownButton<DmPermission>(
        value: perm,
        underline: const SizedBox.shrink(),
        isDense: true,
        style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        items: const [
          DropdownMenuItem(value: DmPermission.everyone, child: Text('Everyone')),
          DropdownMenuItem(value: DmPermission.following, child: Text('Following')),
          DropdownMenuItem(value: DmPermission.nobody, child: Text('Nobody')),
        ],
        onChanged: (v) {
          if (v != null) ref.read(dmPermissionProvider.notifier).state = v;
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Version tile
// ─────────────────────────────────────────────────────────────────────────────

class _VersionTile extends StatelessWidget {
  final bool isDark;
  const _VersionTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.info_outline_rounded,
            size: 18,
            color: isDark ? AppColors.darkAccent : AppColors.accent),
      ),
      title: Text('Version',
          style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary)),
      trailing: Text('1.0.0',
          style: GoogleFonts.lato(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-out button
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final bool isDark;
  const _SignOutButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Sign Out',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700)),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.like),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Signed out'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.like),
        label: Text('Sign Out',
            style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.like)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.like.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared styled field (used by the dialogs below)
// ─────────────────────────────────────────────────────────────────────────────

TextField _styledField({
  required TextEditingController controller,
  required String label,
  required bool isDark,
  String? prefix,
  String? errorText,
  int maxLines = 1,
  TextInputType? keyboardType,
  bool obscure = false,
}) {
  final fill = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
  final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  return TextField(
    controller: controller,
    maxLines: obscure ? 1 : maxLines,
    obscureText: obscure,
    keyboardType: keyboardType,
    style: GoogleFonts.lato(fontSize: 14, color: textColor),
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      errorText: errorText,
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Single-field dialog (username / email / report a bug)
// ─────────────────────────────────────────────────────────────────────────────

class _InputDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initial;
  final String? prefix;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String value) validate;
  final void Function(String value) onSave;

  const _InputDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.prefix,
    this.maxLines = 1,
    this.keyboardType,
    required this.validate,
    required this.onSave,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _c;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final err = widget.validate(_c.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final value = _c.text;
    Navigator.pop(context);
    widget.onSave(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title: Text(widget.title,
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      content: _styledField(
        controller: _c,
        label: widget.label,
        isDark: isDark,
        prefix: widget.prefix,
        errorText: _error,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Change password dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_new.text.length < 6) {
      setState(() => _error = 'Use at least 6 characters');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Passwords don\'t match');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Password updated'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title: Text('Change Password',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _styledField(
              controller: _new,
              label: 'New password',
              isDark: isDark,
              obscure: true),
          const SizedBox(height: 12),
          _styledField(
              controller: _confirm,
              label: 'Confirm password',
              isDark: isDark,
              obscure: true,
              errorText: _error),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: _submit,
          child: const Text('Update'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info screen (Help / Terms / Privacy)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoScreen extends StatelessWidget {
  final String title;
  final String body;
  const _InfoScreen({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Text(body,
            style: GoogleFonts.lato(fontSize: 14, height: 1.6, color: textColor)),
      ),
    );
  }
}

const _helpText =
    'Welcome to Literature Help.\n\n'
    'Reading & writing\n'
    'Tap any post to open the full-screen reader. Swipe left or right to turn pages. '
    'Use the "+" button on Home to write a post or upload audio.\n\n'
    'Marketplace\n'
    'Browse books, manage your cart, library, and listings from the Marketplace tab. '
    'Owned books open in the reader; audiobooks open in the player.\n\n'
    'Account\n'
    'Edit your profile, manage notifications, and switch themes from Settings.\n\n'
    'Still stuck? Use "Report a Bug" to send us the details.';

const _termsText =
    'Terms of Service\n\n'
    'By using Literature, you agree to share only content you own or have the right to '
    'distribute. You retain ownership of everything you publish.\n\n'
    'Tips and marketplace sales are between you and other members; Literature provides '
    'the platform but is not party to those transactions.\n\n'
    'Be respectful. Harassment, plagiarism, and illegal content are not permitted and '
    'may result in account suspension.\n\n'
    'This is a demo application; these terms are illustrative.';

const _privacyText =
    'Privacy Policy\n\n'
    'We store your preferences and content on this device so the app works between '
    'sessions. Nothing is uploaded to a server in this build.\n\n'
    'You control who can message you and whether your account is private from the '
    'Privacy section in Settings.\n\n'
    'You can clear all locally stored data at any time by signing out.\n\n'
    'This is a demo application; this policy is illustrative.';
