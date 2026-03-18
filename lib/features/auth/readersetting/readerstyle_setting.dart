import 'package:flutter/material.dart';
import '../../../core/app_setting_scope.dart';
import '../../../core/app_settings.dart';

class ReaderstyleSetting extends StatelessWidget {
  const ReaderstyleSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),

        const Text(
          "Reader Mode",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        _modeCard(
          context,
          title: "Vertical",
          icon: Icons.view_stream,
          mode: ReaderMode.vertical,
          current: settings.readerMode,
          onTap: () => settings.setReaderMode(ReaderMode.vertical),
        ),

        _modeCard(
          context,
          title: "Horizontal",
          icon: Icons.view_carousel,
          mode: ReaderMode.horizontal,
          current: settings.readerMode,
          onTap: () => settings.setReaderMode(ReaderMode.horizontal),
        ),

        _modeCard(
          context,
          title: "Tap to change",
          icon: Icons.touch_app,
          mode: ReaderMode.tap,
          current: settings.readerMode,
          onTap: () => settings.setReaderMode(ReaderMode.tap),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _modeCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ReaderMode mode,
    required ReaderMode current,
    required VoidCallback onTap,
  }) {
    final bool selected = mode == current;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.greenAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [

            Icon(
              icon,
              color: selected ? Colors.greenAccent : Colors.white70,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.greenAccent : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
              )
          ],
        ),
      ),
    );
  }
}