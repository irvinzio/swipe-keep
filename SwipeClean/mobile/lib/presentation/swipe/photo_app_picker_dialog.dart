import 'package:flutter/material.dart';
import '../../domain/entities/photo_action_app.dart';

class PhotoAppPickerDialog extends StatefulWidget {
  final PhotoActionApp? initialValue;

  const PhotoAppPickerDialog({super.key, this.initialValue});

  @override
  State<PhotoAppPickerDialog> createState() => _PhotoAppPickerDialogState();
}

class _PhotoAppPickerDialogState extends State<PhotoAppPickerDialog> {
  late PhotoActionApp _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue ?? PhotoActionApp.systemPhotos;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose photo action app'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select which installed app SwipeClean should use as your photo action target for keep/delete workflow. You can change this later in settings.',
            ),
            const SizedBox(height: 12),
            ...PhotoActionApp.values.map(
              (app) => RadioListTile<PhotoActionApp>(
                title: Text(app.label),
                value: app,
                groupValue: _selected,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selected = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
