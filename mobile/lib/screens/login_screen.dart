import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/app_background.dart';
import '../widgets/brand_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!email.contains('@') || email.endsWith('@')) {
      setState(() => _error = 'Saisissez une adresse e-mail valide.');
      return;
    }
    if (_password.text.length < 6) {
      setState(
        () => _error = 'Le mot de passe doit contenir au moins 6 caractères.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_signUp) {
        final info = await widget.auth.signUp(_email.text, _password.text);
        if (info != null && mounted) setState(() => _info = info);
      } else {
        await widget.auth.signIn(_email.text, _password.text);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@') || email.endsWith('@')) {
      setState(() => _error = 'Saisissez votre adresse e-mail valide.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.auth.resetPassword(email);
      if (mounted) {
        setState(
          () => _info =
              'Consultez votre e-mail pour réinitialiser le mot de passe.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = AuthController.isConfigured;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const BrandHeader(),
                    const SizedBox(height: 8),
                    Image.asset(
                      'assets/emsi-robot-mascot.jpg',
                      height: 180,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: EmsiColors.navy.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _signUp ? 'Créer un compte' : 'Bonjour ! 👋',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            configured
                                ? (_signUp
                                      ? 'Inscrivez-vous pour poser vos questions sur EMSI.'
                                      : 'Connectez-vous pour parler à votre assistant EMSI.')
                                : 'Ajoutez SUPABASE_URL et SUPABASE_ANON_KEY au lancement Flutter (voir le README).',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: EmsiColors.muted,
                              height: 1.4,
                            ),
                          ),
                          if (configured) ...[
                            const SizedBox(height: 20),
                            _Field(
                              controller: _email,
                              hint: 'E-mail',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _password,
                              hint: 'Mot de passe',
                              obscure: true,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFC0392B),
                                ),
                              ),
                            ],
                            if (_info != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _info!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: EmsiColors.navy),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: _busy ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: EmsiColors.navy,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _signUp ? 'S’inscrire' : 'Se connecter',
                                      ),
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                      _signUp = !_signUp;
                                      _error = null;
                                      _info = null;
                                    }),
                              child: Text(
                                _signUp
                                    ? 'Déjà un compte ? Se connecter'
                                    : 'Pas de compte ? S’inscrire',
                              ),
                            ),
                            if (!_signUp)
                              TextButton(
                                onPressed: _busy ? null : _resetPassword,
                                child: const Text('Mot de passe oublié ?'),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
