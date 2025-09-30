import 'package:flutter/material.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Review'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'We\'re reviewing your vendor account',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '''Thanks for signing up! Your profile has been submitted for approval. You'll get access as soon as an admin approves your account.''',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Tip: Complete any remaining profile details to speed up review.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                // Allow the user to refresh by rebuilding the screen
                // Navigator can be used to pop/push to trigger a refresh if needed.
                // For now, a simple setState is not possible in StatelessWidget; so we pop to root.
                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
