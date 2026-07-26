import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_error.dart';
import '../../widgets/auth_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _submitting = false;
  String? _formError;
  String? _usernameError;

  /// Set once `signUp` succeeds but returns no active session, meaning the
  /// Supabase project has email confirmation enabled — swaps the form out
  /// for a "check your email" message.
  bool _awaitingEmailConfirmation = false;

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  bool _isValidUsername(String v) => RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(v);

  Future<void> _submit() async {
    final displayName = _displayName.text.trim();
    final username = _username.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final confirmPassword = _confirmPassword.text;

    setState(() => _usernameError = null);

    if (displayName.isEmpty) {
      setState(() => _formError = 'Enter a display name.');
      return;
    }
    if (!_isValidUsername(username)) {
      setState(() => _formError =
          'Username must be 3-20 characters — letters, numbers, and underscores only.');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _formError = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _formError = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _formError = 'Passwords do not match.');
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      // Pre-submit availability check — a unique-constraint violation from
      // a failed insert would otherwise surface as a confusing raw Postgres
      // error instead of a clear inline message.
      final existing = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      if (existing != null) {
        setState(() {
          _submitting = false;
          _usernameError = 'That username is already taken.';
        });
        return;
      }

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'display_name': displayName},
      );

      if (!mounted) return;

      if (response.session == null) {
        // Email confirmation is enabled on this project: the account was
        // created but there's no active session until the user clicks the
        // confirmation link in their inbox.
        setState(() => _awaitingEmailConfirmation = true);
      }
      // If a session *was* returned, the user is signed in immediately and
      // the router's auth-driven redirect (see app_router.dart) takes over.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _formError = humanizeAuthError(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create your account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join Literature to read, write, and share.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 14, color: mutedColor),
                ),
                const SizedBox(height: 28),
                if (_awaitingEmailConfirmation) ...[
                  AuthMessageBanner(
                    isDark: isDark,
                    isError: false,
                    message:
                        'Check your email to confirm your account, then log in.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkAccentOnFill
                          : AppColors.accentOnFill,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => context.go('/login'),
                    child: Text('Go to Log In',
                        style: GoogleFonts.lato(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ] else ...[
                  if (_formError != null) ...[
                    AuthMessageBanner(message: _formError!, isDark: isDark),
                    const SizedBox(height: 16),
                  ],
                  AuthTextField(
                    controller: _displayName,
                    label: 'Display name',
                    isDark: isDark,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _username,
                    label: 'Username',
                    isDark: isDark,
                    prefix: '@',
                    errorText: _usernameError,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_usernameError != null) {
                        setState(() => _usernameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _email,
                    label: 'Email',
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _password,
                    label: 'Password',
                    isDark: isDark,
                    obscure: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _confirmPassword,
                    label: 'Confirm password',
                    isDark: isDark,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: _submit,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkAccentOnFill
                          : AppColors.accentOnFill,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Sign Up',
                            style: GoogleFonts.lato(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style: GoogleFonts.lato(fontSize: 13, color: mutedColor)),
                      TextButton(
                        onPressed: _submitting ? null : () => context.go('/login'),
                        child: Text(
                          'Log In',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkAccent : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
