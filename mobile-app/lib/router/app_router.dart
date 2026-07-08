import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/audio/audio_screen.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/post/post_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/messages/messages_screen.dart';
import '../screens/messages/conversation_screen.dart';
import '../screens/marketplace/listing_detail_screen.dart';
import '../screens/marketplace/marketplace_hub_screen.dart';
import '../screens/marketplace/mkt_notifications_screen.dart';
import '../screens/marketplace/mkt_messages_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../screens/viewer/full_screen_post_viewer.dart';
import '../screens/reader/book_reader_screen.dart';
import '../models/book.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/audio',
      builder: (_, state) => AudioScreen(
        initialPostId: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (_, state) => MarketplaceScreen(
        initialListingId: state.extra as String?,
      ),
    ),
    GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
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
      path: '/messages/:name',
      builder: (_, state) => ConversationScreen(
        peerName: Uri.decodeComponent(state.pathParameters['name'] ?? ''),
      ),
    ),
    GoRoute(path: '/marketplace/hub', builder: (_, _) => const MarketplaceHubScreen()),
    GoRoute(path: '/marketplace/notifications', builder: (_, _) => const MktNotificationsScreen()),
    GoRoute(path: '/marketplace/messages', builder: (_, _) => const MktMessagesScreen()),
    GoRoute(
      path: '/marketplace/listing/:id',
      builder: (_, state) => ListingDetailScreen(
        listingId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/user/:userId',
      builder: (_, state) => UserProfileScreen(
        userId: state.pathParameters['userId'] ?? '',
      ),
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
