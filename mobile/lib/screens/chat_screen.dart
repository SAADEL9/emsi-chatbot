import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/app_background.dart';
import '../widgets/brand_header.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _Message {
  _Message(
    this.text, {
    this.isUser = false,
    this.isError = false,
    this.image,
    this.imageUrls = const [],
    DateTime? at,
  }) : at = at ?? DateTime.now();
  final String text;
  final bool isUser;
  final bool isError;
  final Uint8List? image;
  final List<String> imageUrls;
  final DateTime at;
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  bool _busy = false;

  SessionInfo get _session => widget.auth.session!;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addMessage(_Message message) {
    if (!mounted) return;
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    _addMessage(_Message(text, isUser: true));
    setState(() => _busy = true);
    try {
      final reply = await ApiService.sendMessage(
        text,
        _session.id,
        accessToken: _session.accessToken,
      );
      _addMessage(_Message(reply.answer, imageUrls: reply.images));
    } catch (e) {
      _addMessage(_Message('$e', isError: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final choice = await showModalBottomSheet<FileType>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Photo ou image'),
              subtitle: const Text('PNG ou JPG'),
              onTap: () => Navigator.pop(ctx, FileType.image),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Document PDF'),
              onTap: () => Navigator.pop(ctx, FileType.custom),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final result = await FilePicker.pickFile(
      type: choice,
      allowedExtensions: choice == FileType.custom ? ['pdf'] : null,
    );
    if (result == null) return;

    setState(() => _busy = true);
    try {
      final size = await result.length();
      if (size != null && size > ApiService.maxUploadBytes) {
        _addMessage(
          _Message(
            'Fichier trop volumineux (max ${ApiService.maxUploadBytes ~/ (1024 * 1024)} Mo)',
            isError: true,
          ),
        );
        return;
      }
      final bytes = await result.readAsBytes();
      final isImage = choice != FileType.custom;
      _addMessage(
        _Message(result.name, isUser: true, image: isImage ? bytes : null),
      );
      final name = await ApiService.uploadFile(
        bytes,
        result.name,
        accessToken: _session.accessToken,
      );
      _addMessage(_Message('« $name » est indexé — posez-moi une question.'));
    } catch (e) {
      _addMessage(_Message('Échec de l’envoi : $e', isError: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _session.email,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Connecté avec Supabase',
                style: TextStyle(color: EmsiColors.muted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await widget.auth.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la déconnexion : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerProfileHeader(session: _session),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: const Text('Assistant EMSI'),
                selected: true,
                selectedColor: EmsiColors.navy,
                selectedTileColor: EmsiColors.canvas,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Mon profil'),
                onTap: () {
                  Navigator.pop(context);
                  _openSettings();
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Se déconnecter'),
                onTap: () {
                  Navigator.pop(context);
                  _signOut();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Builder(
                builder: (context) => BrandHeader(
                  onMenu: () => Scaffold.of(context).openDrawer(),
                  onSettings: _openSettings,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    if (_messages.isEmpty) ...[
                      const _Hero(),
                      const SizedBox(height: 8),
                      const _WelcomeCard(),
                    ],
                    for (final message in _messages) _Bubble(message: message),
                    if (_busy) const _TypingBubble(),
                  ],
                ),
              ),
              _ComposerBar(
                controller: _controller,
                busy: _busy,
                onSend: _send,
                onUpload: _upload,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  const _DrawerProfileHeader({required this.session});
  final SessionInfo session;

  @override
  Widget build(BuildContext context) {
    final email = session.email.trim();
    final initial = email.isEmpty ? '?' : email[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [EmsiColors.navy, EmsiColors.navyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                color: EmsiColors.navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'EMSI Chatbot',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Image.asset(
        'assets/emsi-robot-mascot.jpg',
        height: 260,
        filterQuality: FilterQuality.high,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
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
            'Bonjour ! 👋',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontSize: 25),
          ),
          const SizedBox(height: 10),
          const Text(
            'Je suis l’EMSI Chatbot, votre assistant pour répondre à toutes vos questions sur EMSI, vos études et bien plus encore !',
            textAlign: TextAlign.center,
            style: TextStyle(color: EmsiColors.ink, fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: EmsiColors.online),
              SizedBox(width: 6),
              Text(
                'En ligne',
                style: TextStyle(color: EmsiColors.muted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.busy,
    required this.onSend,
    required this.onUpload,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFD7E0F1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: EmsiColors.navy.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Joindre un fichier',
              onPressed: busy ? null : onUpload,
              icon: const Icon(Icons.attach_file, color: EmsiColors.navy),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !busy,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Posez votre question...',
                  hintStyle: TextStyle(color: EmsiColors.muted),
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _RoundButton(
              icon: Icons.send_rounded,
              filled: true,
              onPressed: busy ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onPressed, this.filled = false});
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? EmsiColors.navy : Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: EmsiColors.navy.withValues(alpha: 0.2),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: filled ? Colors.white : EmsiColors.navy),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [_BotAvatar(), SizedBox(width: 8), _Dots()]),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(),
          SizedBox(width: 4),
          _Dot(),
          SizedBox(width: 4),
          _Dot(),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(radius: 4, backgroundColor: EmsiColors.muted);
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7E0F1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: EmsiColors.navy.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/emsi-robot-mascot.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: EmsiColors.navy,
            child: Icon(Icons.smart_toy_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  String _time(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final m = message;
    final bg = m.isError
        ? const Color(0xFFFDECEC)
        : m.isUser
        ? EmsiColors.bubbleUser
        : Colors.white;
    final fg = m.isError
        ? const Color(0xFF8C2F2F)
        : m.isUser
        ? Colors.white
        : EmsiColors.ink;
    const radius = Radius.circular(20);
    final hasVisual = m.image != null || m.imageUrls.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: m.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: m.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!m.isUser) ...[const _BotAvatar(), const SizedBox(width: 8)],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  padding: hasVisual
                      ? const EdgeInsets.all(6)
                      : const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.only(
                      topLeft: radius,
                      topRight: radius,
                      bottomLeft: m.isUser ? radius : const Radius.circular(6),
                      bottomRight: m.isUser ? const Radius.circular(6) : radius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EmsiColors.navy.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            m.image!,
                            width: 220,
                            cacheWidth: 440,
                            fit: BoxFit.cover,
                          ),
                        ),
                      for (final url in m.imageUrls)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              '${ApiService.baseUrl}$url',
                              width: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      if (m.text.isNotEmpty)
                        Padding(
                          padding: hasVisual
                              ? const EdgeInsets.fromLTRB(8, 6, 8, 4)
                              : EdgeInsets.zero,
                          child: Text(
                            m.text,
                            style: TextStyle(color: fg, height: 1.35),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (m.isUser) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: EmsiColors.navy,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: m.isUser ? 0 : 44,
              right: m.isUser ? 44 : 0,
            ),
            child: Text(
              _time(m.at),
              style: const TextStyle(fontSize: 11, color: EmsiColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
