import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/audio/audio_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/profile/earnings_screen.dart';
import '../screens/profile/follow_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/post/post_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/messages/conversation_screen.dart';
import '../screens/marketplace/listing_detail_screen.dart';
import '../screens/marketplace/mkt_notifications_screen.dart';
import '../screens/marketplace/mkt_messages_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/viewer/full_screen_post_viewer.dart';
import '../screens/reader/book_reader_screen.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

/// Bridges the Supabase auth stream into a [Listenable] so GoRouter's
/// `refreshListenable` re-runs `redirect` on every sign-in/sign-out — without
/// this, the router would only re-check auth on the next explicit
/// navigation, leaving a stale screen up until then.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    _sub = SupabaseService.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authRefreshNotifier = _AuthRefreshNotifier();

const _authRoutes = {'/login', '/signup'};

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _authRefreshNotifier,
  redirect: (context, state) {
    final loggedIn = currentAuthSession != null;
    final onAuthRoute = _authRoutes.contains(state.matchedLocation);

    if (!loggedIn && !onAuthRoute) return '/login';
    if (loggedIn && onAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/audio',
      builder: (_, state) => AudioScreen(initialPostId: state.extra as String?),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (_, state) =>
          MarketplaceScreen(initialListingId: state.extra as String?),
    ),
    GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(
      path: '/profile/followers',
      builder: (_, _) => const FollowListScreen(kind: FollowListKind.followers),
    ),
    GoRoute(
      path: '/profile/following',
      builder: (_, _) => const FollowListScreen(kind: FollowListKind.following),
    ),
    GoRoute(
      path: '/profile/earnings',
      builder: (_, _) => const EarningsScreen(),
    ),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(
      path: '/post/new',
      builder: (_, state) {
        final extra = state.extra;
        if (extra is PostScreenArgs) return PostScreen.fromArgs(extra);
        return PostScreen(startWithAudio: extra == true);
      },
    ),
    GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
    GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen()),
    GoRoute(
      path: '/messages/:id',
      builder: (_, state) => ConversationScreen(
        conversationId: Uri.decodeComponent(state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/marketplace/notifications',
      builder: (_, _) => const MktNotificationsScreen(),
    ),
    GoRoute(
      path: '/marketplace/messages',
      builder: (_, _) => const MktMessagesScreen(),
    ),
    GoRoute(
      path: '/marketplace/listing/:id',
      builder: (_, state) =>
          ListingDetailScreen(listingId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/user/:userId',
      builder: (_, state) =>
          UserProfileScreen(userId: state.pathParameters['userId'] ?? ''),
    ),
    GoRoute(
      path: '/viewer/:index',
      builder: (_, state) {
        final index = int.tryParse(state.pathParameters['index'] ?? '0') ?? 0;
        return FullScreenPostViewer(initialIndex: index);
      },
    ),
    GoRoute(
      path: '/reader/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'] ?? '';
        final book = findBook(id) ?? mockBooks.first;
        return BookReaderScreen(book: book);
      },
    ),
  ],
);
