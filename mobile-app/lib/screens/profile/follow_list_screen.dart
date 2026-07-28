import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/sync_feedback.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Followers / Following — full screen with search
// ─────────────────────────────────────────────────────────────────────────────

enum FollowListKind { followers, following }

class FollowListScreen extends ConsumerStatefulWidget {
  final FollowListKind kind;
  const FollowListScreen({super.key, required this.kind});

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);
    final title = widget.kind == FollowListKind.followers
        ? 'Followers'
        : 'Following';

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // There's no reverse-follower tracking yet (the backend only records who
    // the signed-in user follows), so both lists fall back to the seeded
    // users the same way the old Followers/Following sheet did — Followers
    // shows everyone else, Following shows the first two.
    final all = widget.kind == FollowListKind.followers
        ? mockUsers.where((u) => u.id != currentUser.id).toList()
        : mockUsers.where((u) => u.id != currentUser.id).take(2).toList();

    final query = _query.trim().toLowerCase();
    final users = query.isEmpty
        ? all
        : all
              .where(
                (u) =>
                    u.displayName.toLowerCase().contains(query) ||
                    u.username.toLowerCase().contains(query),
              )
              .toList();

    final followed = ref.watch(followNotifierProvider);
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final div = isDark ? AppColors.darkDivider : AppColors.divider;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          '$title (${all.length})',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SearchField(
              controller: _searchController,
              isDark: isDark,
              hint: 'Search $title',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: all.isEmpty
                ? _EmptyState(
                    isDark: isDark,
                    title: title == 'Followers'
                        ? 'No followers yet'
                        : 'Not following anyone yet',
                    subtitle: null,
                  )
                : users.isEmpty
                ? _EmptyState(
                    isDark: isDark,
                    title: 'No matches',
                    subtitle: 'Try a different name or username',
                  )
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: div),
                    itemBuilder: (_, i) => _UserRow(
                      user: users[i],
                      isDark: isDark,
                      isFollowing: followed.contains(users[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final text = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: div),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(Icons.search_rounded, size: 19, color: muted),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.lato(fontSize: 14, color: text),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.lato(fontSize: 14, color: muted),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: muted),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String title;
  final String? subtitle;
  const _EmptyState({required this.isDark, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_rounded, size: 48, color: muted),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: GoogleFonts.lato(fontSize: 13, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _UserRow extends ConsumerWidget {
  final LitUser user;
  final bool isDark;
  final bool isFollowing;
  const _UserRow({
    required this.user,
    required this.isDark,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final div = isDark ? AppColors.darkDivider : AppColors.divider;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: () => context.push('/user/${user.id}'),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.surfaceVariant,
        child: Text(
          user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              user.displayName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified_rounded, size: 13, color: AppColors.accent),
          ],
        ],
      ),
      subtitle: Text(
        '@${user.username}',
        style: GoogleFonts.lato(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        ),
      ),
      trailing: GestureDetector(
        onTap: () async {
          final notifier = ref.read(followNotifierProvider.notifier);
          final ok = isFollowing
              ? await notifier.unfollow(user.id)
              : await notifier.follow(user.id);
          if (!ok && context.mounted) notifySyncFailure(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.transparent : AppColors.accent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isFollowing ? div : AppColors.accent),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isFollowing
                  ? (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary)
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
