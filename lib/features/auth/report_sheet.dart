import 'package:flutter/material.dart';
import 'package:tapcomic/data/repos/report_repo.dart';

const _reportReasons = [
  ('Harassment', 'harassment'),
  (' Offensive', 'offensive'),
  (' Spoiler', 'spoiler'),
  (' Spam', 'spam'),
];

Future<void> showReportSheet(
  BuildContext context, {
  required String userUuid,
  required int commentId,
}) async {
  final theme = Theme.of(context);

  final String? selectedReason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                'Report comment',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'choose report topic',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ..._reportReasons.map(
                (r) => ListTile(
                  title: Text(
                    r.$1,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  onTap: () => Navigator.pop(ctx, r.$2),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'cancle',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (selectedReason == null) return;

  try {
    await ReportRepo().reportComment(
      uuid: userUuid,
      commentId: commentId,
      reason: selectedReason,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('report success')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('report fail please try again')),
    );
  }
}