import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About Us'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.menu_book_rounded, size: 56, color: theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('TapComic',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('v1.0.0',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.54), fontSize: 14)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About This Project',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('TapComic is a comic reading application developed as a student project by group ACP2025-03.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.6)),
                const SizedBox(height: 8),
                Text('This project was built with Flutter (Frontend) and Spring Boot (Backend) as part of our coursework.',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Development Team',
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _TeamItem(role: 'Group', name: 'ACP2025-03'),
                _TeamItem(role: 'Stack', name: 'Flutter + Spring Boot'),
                _TeamItem(role: 'Year', name: '2025'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamItem extends StatelessWidget {
  final String role;
  final String name;
  const _TeamItem({required this.role, required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(role,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.54), fontSize: 13)),
          ),
          Text(name, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
        ],
      ),
    );
  }
}