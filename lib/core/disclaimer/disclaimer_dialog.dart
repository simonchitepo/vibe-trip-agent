import 'package:flutter/material.dart';

Future<void> showDisclaimerDialog({
  required BuildContext context,
  required VoidCallback onAccept,
}) {
  final scheme = Theme.of(context).colorScheme;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Before you continue'),
      content: const Text(
        'This app uses AI to generate travel suggestions. '
            'Verify prices, availability, and entry requirements before booking.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: scheme.onSurface.withOpacity(0.8))),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAccept();
          },
          child: const Text('I understand'),
        ),
      ],
    ),
  );
}
