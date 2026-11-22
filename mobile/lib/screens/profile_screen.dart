import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final session = widget.auth.session!;
    _firstName = TextEditingController(text: session.firstName ?? '');
    _lastName = TextEditingController(text: session.lastName ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.auth.updateProfile(
        firstName: _firstName.text,
        lastName: _lastName.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre profil a été mis à jour.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’enregistrer le profil : $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.auth.session!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: Colors.transparent,
        foregroundColor: EmsiColors.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: EmsiColors.navy,
                child: Text(
                  _initials(_firstName.text, _lastName.text, session.email),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              session.displayName.isEmpty
                  ? 'Votre profil'
                  : session.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              session.email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: EmsiColors.muted),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: EmsiColors.navy.withValues(alpha: 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informations personnelles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 18),
                  _ProfileField(
                    controller: _firstName,
                    label: 'Prénom',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _ProfileField(
                    controller: _lastName,
                    label: 'Nom',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    child: Text(session.email),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: EmsiColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String first, String last, String email) {
    final initials =
        '${first.trim().isEmpty ? '' : first.trim()[0]}'
        '${last.trim().isEmpty ? '' : last.trim()[0]}';
    if (initials.isNotEmpty) return initials.toUpperCase();
    return email.isEmpty ? '?' : email[0].toUpperCase();
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );
}
