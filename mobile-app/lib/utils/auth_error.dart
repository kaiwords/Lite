import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns a Supabase [AuthException] into a short, human-readable message.
/// Supabase's own `message` field is usually already readable (e.g. "Invalid
/// login credentials"), so this mostly just rewrites the handful of messages
/// that read awkwardly out of context, and falls back to the raw message
/// for anything else.
String humanizeAuthError(AuthException e) {
  final msg = e.message.toLowerCase();

  if (msg.contains('already registered') || msg.contains('already exists')) {
    return 'An account with this email already exists. Try logging in instead.';
  }
  if (msg.contains('invalid login credentials')) {
    return 'Incorrect email or password.';
  }
  if (msg.contains('email not confirmed')) {
    return 'Please confirm your email first — check your inbox for the confirmation link.';
  }
  if (msg.contains('password should be at least') || msg.contains('at least 6')) {
    return 'Password must be at least 6 characters.';
  }
  if (msg.contains('unable to validate email') || msg.contains('invalid email')) {
    return 'Enter a valid email address.';
  }
  if (msg.contains('rate limit')) {
    return 'Too many attempts — please wait a moment and try again.';
  }
  return e.message;
}
