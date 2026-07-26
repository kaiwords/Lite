import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

class LiteratureApp extends ConsumerWidget {
  const LiteratureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Keep `currentUserProvider` in sync with the real Supabase session:
    // whenever auth state changes, fetch the matching `public.users` row on
    // sign-in (including the initial-session restore right after app start)
    // and clear it on sign-out. The router's own redirect logic (driven by
    // the same auth stream via its `refreshListenable`) handles bouncing the
    // user to/from `/login` — this listener only owns the profile data.
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider,
        (previous, next) {
      final session = next.value?.session;
      if (session == null) {
        ref.read(currentUserProvider.notifier).state = null;
        return;
      }
      _syncCurrentUser(ref, session.user.id);
    });

    return MaterialApp.router(
      title: 'Literature',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

/// Fetches the signed-in user's `public.users` row and pushes it into
/// [currentUserProvider]. Swallows errors (e.g. a transient network hiccup)
/// rather than surfacing them — the next auth event (a token refresh, say)
/// will retry, and there's no good place to show an error from a listener
/// that isn't tied to a specific screen.
Future<void> _syncCurrentUser(WidgetRef ref, String userId) async {
  try {
    final row = await SupabaseService.client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row != null) {
      ref.read(currentUserProvider.notifier).state =
          LitUser.fromSupabaseRow(row);
    }
  } catch (_) {
    // See doc comment above.
  }
}
