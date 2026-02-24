import 'package:flutter/material.dart';
import 'package:tapcomic/data/db/app_db2.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final String username = 'Guest';

  Future<void> _reloadData() async {
    await AppDb.resetAndSeed();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data reloaded')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          

          const SizedBox(height: 24),

          const Divider(color: Colors.white24),

          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.white),
            title: const Text(
              'Reload data',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Reload mock / local database',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: _reloadData,
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text(
              'Reset database',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text(
              'Developer only',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () async {
              await AppDb.resetAndSeed();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database reset')),
              );
            },
          ),
        ],
      ),
    );
  }
}
