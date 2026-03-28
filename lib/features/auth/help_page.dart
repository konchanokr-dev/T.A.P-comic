import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HelpItem(icon: Icons.menu_book, question: 'How to read a comic?', answer: 'Go to the Home page, tap on any comic cover to open the detail page, then select a chapter to start reading.'),
          _HelpItem(icon: Icons.swap_horiz, question: 'How to change reading mode?', answer: 'While reading, tap the screen to show the menu, then tap the Settings icon at the bottom to switch between Vertical, Horizontal, and Tap modes.'),
          _HelpItem(icon: Icons.favorite_border, question: 'How to follow a comic?', answer: 'Open the comic detail page and tap the Follow button on the cover image. You can find your followed comics in the Library tab.'),
          _HelpItem(icon: Icons.history, question: 'How does reading history work?', answer: 'TapComic automatically saves your reading progress. When you reopen a chapter, it will resume from where you left off.'),
          _HelpItem(icon: Icons.chat_bubble_outline, question: 'How to comment?', answer: 'Scroll to the bottom of a chapter or comic detail page to find the comment section. You can also tap the chat button while reading to comment on a specific page.'),
        ],
      ),
    );
  }
}

class _HelpItem extends StatefulWidget {
  final IconData icon;
  final String question;
  final String answer;
  const _HelpItem({required this.icon, required this.question, required this.answer});

  @override
  State<_HelpItem> createState() => _HelpItemState();
}

class _HelpItemState extends State<_HelpItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: theme.colorScheme.onSurface.withOpacity(0.7), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface.withOpacity(0.54)),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 12),
                Text(widget.answer,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}