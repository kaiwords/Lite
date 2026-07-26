import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_error.dart';
import '../../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await SupabaseService.client.auth
          .signInWithPassword(email: email, password: password);
      // On success, the router's auth-driven redirect (see app_router.dart)
      // takes over and navigates to '/' automatically — nothing to do here.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = humanizeAuthError(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Literature',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 14, color: mutedColor),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  AuthMessageBanner(message: _error!, isDark: isDark),
                  const SizedBox(height: 16),
                ],
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
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _submit,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.darkAccentOnFill : AppColors.accentOnFill,
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
                      : Text('Log In',
                          style: GoogleFonts.lato(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: GoogleFonts.lato(fontSize: 13, color: mutedColor)),
                    TextButton(
                      onPressed: _submitting ? null : () => context.go('/signup'),
                      child: Text(
                        'Sign Up',
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
            ),
          ),
        ),
      ),
    );
  }
}
