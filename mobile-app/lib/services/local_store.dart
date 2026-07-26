import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/comment.dart';
import '../models/marketplace.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../providers/marketplace_account_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local persistence for user-mutable state (posts, cart, purchases, my-listings)
// backed by shared_preferences. Lists are stored as JSON strings.
//
// [init] must be awaited in main() before runApp so the providers can read the
// cached values synchronously when they are first created.
// ─────────────────────────────────────────────────────────────────────────────

class LocalStore {
  LocalStore._(this._prefs);

  final SharedPreferences _prefs;
  static LocalStore? _instance;
  static LocalStore get instance => _instance!;

  static Future<void> init() async {
    _instance ??= LocalStore._(await SharedPreferences.getInstance());
  }

  static const _kPosts = 'posts';
  static const _kCart = 'cart';
  static const _kPurchases = 'purchases';
  static const _kMyListings = 'my_listings';
  static const _kComments = 'comments';
  static const _kCurrentUser = 'current_user';
  static const _kThemeMode = 'theme_mode';
  static const _kFollows = 'follows';
  static const _kVisibleCategories = 'visible_categories';

  /// Wipes every persisted key except the theme preference. Called on logout
  /// so the next signed-in account doesn't inherit this one's cached posts,
  /// cart, purchases, listings, comments, profile, or follows.
  Future<void> clearAll() async {
    for (final key in [
      _kPosts,
      _kCart,
      _kPurchases,
      _kMyListings,
      _kComments,
      _kCurrentUser,
      _kFollows,
      _kVisibleCategories,
    ]) {
      await _prefs.remove(key);
    }
  }

  // ── Generic helpers ────────────────────────────────────────────────────────
  List<Map<String, dynamic>>? _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    } catch (_) {
      return null; // corrupt data — fall back to seed defaults
    }
  }

  void _writeList(String key, List<Map<String, dynamic>> list) {
    unawaited(_prefs.setString(key, jsonEncode(list)));
  }

  // ── Posts ───────────────────────────────────────────────────────────────────
  List<Post>? loadPosts() =>
      _readList(_kPosts)?.map(Post.fromJson).toList();
  void savePosts(List<Post> posts) =>
      _writeList(_kPosts, posts.map((p) => p.toJson()).toList());

  // ── Cart ──────────────────────────────────────────────────────────────────
  List<MarketplaceListing>? loadCart() =>
      _readList(_kCart)?.map(MarketplaceListing.fromJson).toList();
  void saveCart(List<MarketplaceListing> cart) =>
      _writeList(_kCart, cart.map((l) => l.toJson()).toList());

  // ── Purchases ───────────────────────────────────────────────────────────────
  List<Purchase>? loadPurchases() =>
      _readList(_kPurchases)?.map(Purchase.fromJson).toList();
  void savePurchases(List<Purchase> purchases) =>
      _writeList(_kPurchases, purchases.map((p) => p.toJson()).toList());

  // ── My Listings ─────────────────────────────────────────────────────────────
  List<MarketplaceListing>? loadMyListings() =>
      _readList(_kMyListings)?.map(MarketplaceListing.fromJson).toList();
  void saveMyListings(List<MarketplaceListing> listings) =>
      _writeList(_kMyListings, listings.map((l) => l.toJson()).toList());

  // ── Comments ────────────────────────────────────────────────────────────────
  List<Comment>? loadComments() =>
      _readList(_kComments)?.map(Comment.fromJson).toList();
  void saveComments(List<Comment> comments) =>
      _writeList(_kComments, comments.map((c) => c.toJson()).toList());

  // ── Current user (editable profile) ─────────────────────────────────────────
  LitUser? loadCurrentUser() {
    final raw = _prefs.getString(_kCurrentUser);
    if (raw == null) return null;
    try {
      return LitUser.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  void saveCurrentUser(LitUser user) =>
      unawaited(_prefs.setString(_kCurrentUser, jsonEncode(user.toJson())));

  // ── Theme mode (stored as ThemeMode.name: system | light | dark) ────────────
  String? loadThemeMode() => _prefs.getString(_kThemeMode);
  void saveThemeMode(String mode) =>
      unawaited(_prefs.setString(_kThemeMode, mode));

  // ── Followed user ids ───────────────────────────────────────────────────────
  List<String>? loadFollows() => _prefs.getStringList(_kFollows);
  void saveFollows(Set<String> ids) =>
      unawaited(_prefs.setStringList(_kFollows, ids.toList()));

  // ── Visible feed categories (stored as FeedCategory.name list) ──────────────
  List<String>? loadVisibleCategories() =>
      _prefs.getStringList(_kVisibleCategories);
  void saveVisibleCategories(List<String> names) =>
      unawaited(_prefs.setStringList(_kVisibleCategories, names));
}
