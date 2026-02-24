import 'package:flutter/material.dart';
import '../../../core/app_setting_scope.dart';
import '../../../core/app_settings.dart';

class ReaderstyleSetting extends StatelessWidget {
  const ReaderstyleSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return Column(
      children: [
        RadioListTile<ReaderMode>(
          title: const Text('Vertical' ,style: TextStyle(color: Colors.white)),
          value: ReaderMode.vertical,
          groupValue: settings.readerMode,
          onChanged: (mode) {
            if (mode != null) {
              settings.setReaderMode(mode);
            }
          },
        ),

        RadioListTile<ReaderMode>(
          title: const Text('horizontal',style: TextStyle(color: Colors.white)),
          value: ReaderMode.horizontal,
          groupValue: settings.readerMode,
          onChanged: (mode) {
            if (mode != null) {
              settings.setReaderMode(mode);
            }
          },
        ),

        RadioListTile<ReaderMode>(
          title: const Text('Tap to change',style: TextStyle(color: Colors.white)),
          value: ReaderMode.tap,
          groupValue: settings.readerMode,
          onChanged: (mode) {
            if (mode != null) {
              settings.setReaderMode(mode);
            }
          },
        ),
      ],
    );
  }
}
