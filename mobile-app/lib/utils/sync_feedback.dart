import 'package:flutter/material.dart';

/// Every optimistic write in this app (follow, post, comment, listing,
/// message…) updates local state immediately and only *afterwards* tries to
/// sync it to Supabase, so the UI never blocks on the network. Call this when
/// that sync call comes back `false` — the local change stays in place
/// either way (it's not rolled back), this just tells the user it hasn't
/// actually reached the server yet, instead of silently looking like it did.
void notifySyncFailure(BuildContext context) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Saved locally — couldn't sync to server"),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
