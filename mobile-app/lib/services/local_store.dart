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
    await _instance!._purgeStaleDemoCacheOnce();
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
  static const _kBookBookmarks = 'book_bookmarks';
  static const _kBookLastPosition = 'book_last_position';
  static const _kPostLastPageIndex = 'post_last_page_index';
  static const _kDemoCachePurged = 'demo_cache_purged_v2';

  /// One-time cleanup for installs that cached posts/comments/cart/purchases/
  /// my-listings/follows back when their notifiers seeded from hardcoded
  /// demo data (see demo_data/) — any like/comment/purchase/follow/etc. made
  /// while that seed was still showing wrote the whole list, mocks included,
  /// to disk. Without this, those devices would keep reloading that stale
  /// snapshot forever even though the app itself no longer seeds from demo
  /// data. Runs once per install; a real empty result from Supabase after
  /// this is trusted as genuinely empty, not re-purged. (v2 widens v1's
  /// posts/comments-only purge to the other notifiers that also used to
  /// seed from demo data.)
  Future<void> _purgeStaleDemoCacheOnce() async {
    if (_prefs.getBool(_kDemoCachePurged) == true) return;
    for (final key in [
      _kPosts,
      _kComments,
      _kCart,
      _kPurchases,
      _kMyListings,
      _kFollows,
    ]) {
      await _prefs.remove(key);
    }
    await _prefs.setBool(_kDemoCachePurged, true);
  }

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
      _kBookBookmarks,
      _kBookLastPosition,
      _kPostLastPageIndex,
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
      return decoded.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } catch (_) {
      return null; // corrupt data — fall back to seed defaults
    }
  }

  void _writeList(String key, List<Map<String, dynamic>> list) {
    unawaited(_prefs.setString(key, jsonEncode(list)));
  }

  // ── Posts ───────────────────────────────────────────────────────────────────
  List<Post>? loadPosts() => _readList(_kPosts)?.map(Post.fromJson).toList();
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

  // ── Book bookmarks (bookId -> sorted list of bookmarked page indices) ───────
  List<int> loadBookBookmarks(String bookId) {
    final raw = _prefs.getString(_kBookBookmarks);
    if (raw == null) return [];
    try {
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final pages = decoded[bookId] as List?;
      return pages?.cast<int>() ?? [];
    } catch (_) {
      return []; // corrupt data — fall back to no bookmarks
    }
  }

  void saveBookBookmarks(String bookId, List<int> pageIndices) {
    final raw = _prefs.getString(_kBookBookmarks);
    Map<String, dynamic> decoded;
    try {
      decoded = raw == null
          ? {}
          : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      decoded = {};
    }
    if (pageIndices.isEmpty) {
      decoded.remove(bookId);
    } else {
      decoded[bookId] = pageIndices;
    }
    unawaited(_prefs.setString(_kBookBookmarks, jsonEncode(decoded)));
  }

  // ── Last read position (bookId -> flattened page index) — the "continue
  // reading" marker, distinct from the user-placed bookmarks above. Updated
  // silently on every page turn; read once on opening a book to offer
  // "Continue reading" vs. "Start over" (see BookReaderScreen/
  // _EbookReadScreen). Null means never opened, or finished/reset.
  int? loadBookLastPosition(String bookId) {
    final raw = _prefs.getString(_kBookLastPosition);
    if (raw == null) return null;
    try {
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final index = decoded[bookId] as num?;
      return index?.toInt();
    } catch (_) {
      return null; // corrupt data — fall back to no saved position
    }
  }

  void saveBookLastPosition(String bookId, int pageIndex) {
    final raw = _prefs.getString(_kBookLastPosition);
    Map<String, dynamic> decoded;
    try {
      decoded = raw == null
          ? {}
          : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      decoded = {};
    }
    decoded[bookId] = pageIndex;
    unawaited(_prefs.setString(_kBookLastPosition, jsonEncode(decoded)));
  }

  // ── Post reading last page (postId -> paginated page index) — the
  // full-screen post viewer's "continue reading" marker, same shape as the
  // book one above. Restored silently as the horizontal pager's starting
  // page when reopening the same post (no interruption dialog — swiping
  // back to page one to start over is one gesture away). Updated on every
  // page turn, see full_screen_post_viewer.dart.
  int? loadPostLastPageIndex(String postId) {
    final raw = _prefs.getString(_kPostLastPageIndex);
    if (raw == null) return null;
    try {
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final index = decoded[postId] as num?;
      return index?.toInt();
    } catch (_) {
      return null; // corrupt data — fall back to no saved position
    }
  }

  void savePostLastPageIndex(String postId, int pageIndex) {
    final raw = _prefs.getString(_kPostLastPageIndex);
    Map<String, dynamic> decoded;
    try {
      decoded = raw == null
          ? {}
          : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      decoded = {};
    }
    decoded[postId] = pageIndex;
    unawaited(_prefs.setString(_kPostLastPageIndex, jsonEncode(decoded)));
  }
}
