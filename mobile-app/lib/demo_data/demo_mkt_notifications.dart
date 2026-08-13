// Demo/sample marketplace notifications — there is no notifications backend
// at all (no Supabase table), so unlike posts/comments/marketplace listings
// this has nothing real to be replaced by. Kept here for reference/tests
// only; the running app's list is empty until a real notifications backend
// exists.
import '../screens/marketplace/mkt_notifications_screen.dart';

final demoMktNotifs = <MktNotif>[
  MktNotif(id: 'n1', type: MktNotifType.sale, title: 'New Sale!',
      body: 'Priya Nair purchased "The Glass House" for \$14.99',
      at: DateTime.now().subtract(const Duration(minutes: 8))),
  MktNotif(id: 'n2', type: MktNotifType.sale, title: 'New Sale!',
      body: 'Anonymous purchased "Echoes in the Dark" for \$9.99',
      at: DateTime.now().subtract(const Duration(hours: 2))),
  MktNotif(id: 'n3', type: MktNotifType.shipped, title: 'Order Shipped',
      body: 'Your order #ORD-48291 is on its way — expected in 3–5 days',
      at: DateTime.now().subtract(const Duration(hours: 5))),
  MktNotif(id: 'n4', type: MktNotifType.review, title: 'New Review',
      body: 'Marcus Osei left ★★★★★ on "The Glass House"',
      at: DateTime.now().subtract(const Duration(hours: 7)), isRead: true),
  MktNotif(id: 'n5', type: MktNotifType.priceDrop, title: 'Price Drop Alert',
      body: '"Salt & Smoke" by Marcus Osei dropped to \$9.99',
      at: DateTime.now().subtract(const Duration(hours: 10)), isRead: true),
  MktNotif(id: 'n6', type: MktNotifType.trending, title: 'Trending Now',
      body: '"The Glass House" is in the top 10 this week',
      at: DateTime.now().subtract(const Duration(days: 1)), isRead: true),
  MktNotif(id: 'n7', type: MktNotifType.purchase, title: 'Purchase Confirmed',
      body: 'You purchased "Between the Lines" — check your Library',
      at: DateTime.now().subtract(const Duration(days: 2)), isRead: true),
  MktNotif(id: 'n8', type: MktNotifType.sale, title: 'New Sale!',
      body: 'luna_reads purchased "Midnight Verses" for \$11.99',
      at: DateTime.now().subtract(const Duration(days: 3)), isRead: true),
  MktNotif(id: 'n9', type: MktNotifType.refund, title: 'Refund Processed',
      body: 'Refund of \$6.99 for "Solitudes" has been issued',
      at: DateTime.now().subtract(const Duration(days: 4)), isRead: true),
];
