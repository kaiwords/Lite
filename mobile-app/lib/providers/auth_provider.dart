import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../services/local_store.dart';
import '../services/supabase_service.dart';

/// The app's real signed-in user profile (or `null` once we know the user is
/// signed out).
///
/// Kept as a plain [StateProvider] (not a StateNotifierProvider /
/// AsyncNotifierProvider) on purpose: several existing screens mutate it in
/// place after a local profile edit via
/// `ref.read(currentUserProvider.notifier).state = updatedUser`
/// (see settings_screen.dart's change-username dialog and
/// edit_profile_sheet.dart) — that pattern needs a [StateController], which
/// only a StateProvider exposes.
///
/// The value is kept in sync with real Supabase auth state by a listener in
/// `app.dart` (`LiteratureApp`), which watches [authStateChangesProvider]
/// and fetches the matching `public.users` row whenever the session changes.
final currentUserProvider = StateProvider<LitUser?>(
    (ref) => LocalStore.instance.loadCurrentUser());

/// Fires on every Supabase auth change — sign in, sign out, token refresh,
/// and (importantly) the `initialSession` event supabase_flutter emits right
/// after `Supabase.initialize()` restores a persisted session. The listener
/// in `app.dart` uses this to keep [currentUserProvider] in sync, and
/// `app_router.dart` mirrors the same stream into its `refreshListenable` so
/// route guards re-evaluate without needing a full app restart.
final authStateChangesProvider = StreamProvider<AuthState>(
    (ref) => SupabaseService.client.auth.onAuthStateChange);

/// Synchronous "is someone logged in right now" check for places — like the
/// router's `redirect` callback — that can't wait on a stream/provider and
/// need the current session synchronously at redirect-check time.
Session? get currentAuthSession => SupabaseService.client.auth.currentSession;
