import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _Message {
  _Message(this.text, {this.isUser = false, this.isError = false, this.image});
  final String text;
  final bool isUser;
  final bool isError;
  final Uint8List? image;
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addMessage(_Message message) {
    setState(() => _messages.add(message));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
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
      final answer = await ApiService.sendMessage(text, 'mobile-user');
      _addMessage(_Message(answer));
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
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Photo or image'),
              subtitle: const Text('PNG or JPG'),
              onTap: () => Navigator.pop(ctx, FileType.image),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF document'),
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
            'File is too large (max ${ApiService.maxUploadBytes ~/ (1024 * 1024)} MB)',
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
      final name = await ApiService.uploadFile(bytes, result.name);
      _addMessage(_Message('Indexed "$name" — ask me anything about it.'));
    } catch (e) {
      _addMessage(_Message('Upload failed: $e', isError: true));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emsi chatBot'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Agentic RAG over your course material',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _Bubble(message: _messages[i]),
                  ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Attach PDF or image',
                    onPressed: _busy ? null : _upload,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your course…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.forum_outlined,
                size: 40,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask about your course',
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'I search your PDFs and images, then answer with sources. '
              'Use + to upload a document or photo first.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = message;
    final bg = m.isError
        ? scheme.errorContainer
        : m.isUser
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final fg = m.isError
        ? scheme.onErrorContainer
        : m.isUser
        ? scheme.onPrimary
        : scheme.onSurface;
    const radius = Radius.circular(18);
    const tail = Radius.circular(4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: m.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!m.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              padding: m.image == null
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                  : const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: m.isUser ? radius : tail,
                  bottomRight: m.isUser ? tail : radius,
                ),
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
                  if (m.text.isNotEmpty)
                    Padding(
                      padding: m.image == null
                          ? EdgeInsets.zero
                          : const EdgeInsets.fromLTRB(8, 6, 8, 4),
                      child: Text(
                        m.text,
                        style: TextStyle(color: fg, height: 1.35),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
