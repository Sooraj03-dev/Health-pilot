import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pilot/providers/auth_provider.dart';

/// Shown when a user has signed up but their profile is not yet verified.
class PendingVerificationPage extends ConsumerWidget {
  const PendingVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
               mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verification Pending',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account is awaiting verification.\n'
                  'Please check your email or contact an administrator.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
