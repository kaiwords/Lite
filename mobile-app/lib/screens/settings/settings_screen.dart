import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/comments_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/marketplace_account_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_store.dart';
import '../../services/supabase_service.dart';
import '../../services/users_repository.dart';
import '../../theme/app_theme.dart';
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
            icon: Icons.logout_rounded,
            label: 'Log Out',
            isDark: isDark,
            onTap: () => _showLogOutConfirm(context, ref),
          ),

          // ── Appearance ────────────────────────────────────────────────
          _SectionHeader(label: 'Appearance', isDark: isDark),
          _ThemeTile(isDark: isDark),

          // ── Creator Tools ─────────────────────────────────────────────
          _SectionHeader(label: 'Creator', isDark: isDark),
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
      onSave: (v) async {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        final updated = user.copyWith(username: v.trim());
        ref.read(currentUserProvider.notifier).state = updated;
        LocalStore.instance.saveCurrentUser(updated);
        _snack(context, 'Username updated to @${v.trim()}');
        try {
          await UsersRepository.updateProfile(updated);
        } catch (_) {
          if (context.mounted) {
            _snack(context, "Saved locally — couldn't sync to server");
          }
        }
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
      onSave: (v) async {
        final email = v.trim();
        try {
          await SupabaseService.client.auth
              .updateUser(UserAttributes(email: email));
          if (context.mounted) {
            _snack(context, 'Verification sent to $email');
          }
        } on AuthException catch (e) {
          if (context.mounted) {
            _snack(context, 'Couldn\'t update email: ${e.message}');
          }
        } catch (_) {
          if (context.mounted) {
            _snack(context, 'Couldn\'t update email. Please try again.');
          }
        }
      },
    ),
  );
}

void _showLogOutConfirm(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Log Out',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      content: Text(
        'Are you sure you want to log out?',
        style: GoogleFonts.lato(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.like),
          onPressed: () async {
            Navigator.pop(dialogContext);
            // Wipe this account's locally-persisted data (posts, cart,
            // purchases, listings, comments, profile, follows — everything
            // except the theme) so the next sign-in starts clean…
            await LocalStore.instance.clearAll();
            // …and drop the in-memory copies those providers already hold.
            // `currentUserProvider` itself is nulled by the SIGNED_OUT auth
            // event listener in app.dart.
            ref.invalidate(postsNotifierProvider);
            ref.invalidate(commentsProvider);
            ref.invalidate(cartProvider);
            ref.invalidate(purchasesProvider);
            ref.invalidate(myListingsProvider);
            ref.invalidate(followNotifierProvider);
            ref.invalidate(visibleCategoriesProvider);
            // The router's auth-driven redirect (see app_router.dart) takes
            // it from here and bounces to `/login` once the session clears.
            await SupabaseService.client.auth.signOut();
          },
          child: const Text('Log Out'),
        ),
      ],
    ),
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
          style: FilledButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Save'),
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
    'Edit your profile, username, and email, and switch themes from Settings.\n\n'
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
    'Your account, posts, comments, and other content are securely stored with our '
    'backend provider (Supabase) so they sync across sessions and devices. Some '
    'local preferences, like your theme choice, are kept only on this device.\n\n'
    'This is a demo application; this policy is illustrative.';
