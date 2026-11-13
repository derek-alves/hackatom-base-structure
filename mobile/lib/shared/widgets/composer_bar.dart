import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_models.dart';

import 'package:design_system/design_system.dart';

typedef PickImage = Future<Attachment?> Function(ImageSource source);

String _mimeFor(String path) {
  final ext = path.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };
}

Future<Attachment?> pickImageWithImagePicker(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 80,
  );
  if (file == null) return null;
  final Uint8List bytes = await file.readAsBytes();
  return Attachment(bytes: bytes, mimeType: _mimeFor(file.path));
}

class ComposerSubmission {
  const ComposerSubmission({required this.text, required this.attachments});

  final String text;
  final List<Attachment> attachments;
}

class ComposerBar extends StatefulWidget {
  const ComposerBar({
    super.key,
    required this.onSubmit,
    this.enabled = true,
    this.pickImage = pickImageWithImagePicker,
  });

  final ValueChanged<ComposerSubmission> onSubmit;
  final bool enabled;
  final PickImage pickImage;

  @override
  State<ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends State<ComposerBar> {
  final _controller = TextEditingController();
  Attachment? _attachment;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend =>
      widget.enabled &&
      (_controller.text.trim().isNotEmpty || _attachment != null);

  Future<void> _pick(ImageSource source) async {
    final picked = await widget.pickImage(source);
    if (picked != null && mounted) setState(() => _attachment = picked);
  }

  void _submit() {
    if (!_canSend) return;
    widget.onSubmit(
      ComposerSubmission(
        text: _controller.text.trim(),
        attachments: [?_attachment],
      ),
    );
    _controller.clear();
    setState(() => _attachment = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(t.spacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_attachment != null)
                Padding(
                  padding: EdgeInsets.only(bottom: t.spacing.xs),
                  child: AppChip.input(
                    avatar: const Icon(Icons.image_outlined),
                    label: 'Imagem anexada',
                    onDeleted: widget.enabled
                        ? () => setState(() => _attachment = null)
                        : null,
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    key: const Key('composer-camera'),
                    tooltip: 'Câmera',
                    icon: const Icon(Icons.photo_camera_outlined),
                    onPressed: widget.enabled
                        ? () => _pick(ImageSource.camera)
                        : null,
                  ),
                  IconButton(
                    key: const Key('composer-gallery'),
                    tooltip: 'Galeria',
                    icon: const Icon(Icons.photo_library_outlined),
                    onPressed: widget.enabled
                        ? () => _pick(ImageSource.gallery)
                        : null,
                  ),
                  Expanded(
                    child: AppTextField(
                      controller: _controller,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                      hint: 'Escreva uma mensagem',
                    ),
                  ),
                  IconButton(
                    key: const Key('composer-send'),
                    tooltip: 'Enviar',
                    icon: const Icon(Icons.send),
                    onPressed: _canSend ? _submit : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
