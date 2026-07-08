import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Notifications ─────────────────────────────────────────────────────────────
final notifPushProvider       = StateProvider<bool>((_) => true);
final notifFollowsProvider    = StateProvider<bool>((_) => true);
final notifLikesProvider      = StateProvider<bool>((_) => true);
final notifCommentsProvider   = StateProvider<bool>((_) => true);
final notifTipsProvider       = StateProvider<bool>((_) => true);

// ── Privacy ───────────────────────────────────────────────────────────────────
final privateAccountProvider  = StateProvider<bool>((_) => false);

enum DmPermission { everyone, following, nobody }
final dmPermissionProvider    = StateProvider<DmPermission>((_) => DmPermission.everyone);

// ── Creator ───────────────────────────────────────────────────────────────────
final tipsEnabledProvider     = StateProvider<bool>((_) => true);
final autoPayoutProvider      = StateProvider<bool>((_) => false);

// ── Appearance ────────────────────────────────────────────────────────────────
enum FontSizePref { small, medium, large }
final fontSizeProvider        = StateProvider<FontSizePref>((_) => FontSizePref.medium);
