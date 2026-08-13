// Demo/sample alert items — there is no notifications backend at all (no
// Supabase table), so unlike posts/comments/marketplace listings this has
// nothing real to be replaced by. Kept here for reference/tests only; the
// running app's alert list is empty until a real notifications backend
// exists.
import '../screens/alerts/alerts_screen.dart';

const demoAlerts = [
  // ── This week ──────────────────────────────────────────────────────────
  AlertItem(type: AlertType.tip, actor: 'Priya Nair', detail: 'sent you a \$5 tip on "Between the Lines"', ago: Duration(minutes: 12), postId: 'p1'),
  AlertItem(type: AlertType.like, actor: 'Marcus Osei', detail: 'liked your poem "Between the Lines"', ago: Duration(hours: 1), postId: 'p1'),
  AlertItem(type: AlertType.comment, actor: 'Javier Morales', detail: 'commented: "This moved me deeply."', ago: Duration(hours: 2), postId: 'p1'),
  AlertItem(type: AlertType.follow, actor: 'luna_reads', detail: 'started following you', ago: Duration(hours: 3), isRead: true),
  AlertItem(type: AlertType.newPost, actor: 'Priya Nair', detail: 'published a new article: "On Solitude and the Creative Mind"', ago: Duration(hours: 5), isRead: true, postId: 'p6'),
  AlertItem(type: AlertType.like, actor: 'sarah_bookclub', detail: 'liked your poem "Morning Without You"', ago: Duration(hours: 7), isRead: true, postId: 'p4'),
  AlertItem(type: AlertType.tip, actor: 'Anonymous', detail: 'sent you a \$2 tip on "The Glass House"', ago: Duration(days: 1), isRead: true, postId: 'p5'),
  AlertItem(type: AlertType.comment, actor: 'Eleanor Voss', detail: 'replied to your comment', ago: Duration(days: 1), isRead: true, postId: 'p2'),
  AlertItem(type: AlertType.follow, actor: 'ink_and_fire', detail: 'started following you', ago: Duration(days: 2), isRead: true),

  // ── Last week ──────────────────────────────────────────────────────────
  AlertItem(type: AlertType.newPost, actor: 'Adriana Voss', detail: 'published a new chapter of "The Ember Throne"', ago: Duration(days: 8), isRead: true),
  AlertItem(type: AlertType.like, actor: 'Marcus Osei', detail: 'liked your story "The Glass House"', ago: Duration(days: 9), isRead: true, postId: 'p5'),
  AlertItem(type: AlertType.tip, actor: 'Eleanor Voss', detail: 'sent you a \$3 tip on "Morning Without You"', ago: Duration(days: 10), isRead: true, postId: 'p4'),
  AlertItem(type: AlertType.follow, actor: 'quiet_quill', detail: 'started following you', ago: Duration(days: 12), isRead: true),

  // ── 2 weeks ago ────────────────────────────────────────────────────────
  AlertItem(type: AlertType.comment, actor: 'Javier Morales', detail: 'replied to your comment', ago: Duration(days: 16), isRead: true, postId: 'p2'),
  AlertItem(type: AlertType.like, actor: 'luna_reads', detail: 'liked your poem "Between the Lines"', ago: Duration(days: 18), isRead: true, postId: 'p1'),
  AlertItem(type: AlertType.newPost, actor: 'Priya Nair', detail: 'published a new poem "Between the Lines"', ago: Duration(days: 19), isRead: true, postId: 'p1'),
];
