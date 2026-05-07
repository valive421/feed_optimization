import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bootstrap_provider.dart';

class BootstrapScreen extends ConsumerWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(supabaseHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('High Performance Feed'),
      ),
      body: Center(
        child: health.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => _StatusView(
            message: 'Supabase check failed: $error',
            onRetry: () => ref.invalidate(supabaseHealthProvider),
          ),
          data: (result) {
            if (result.isConnected) {
              return const _StatusView(
                message: 'Supabase connected',
              );
            }

            return _StatusView(
              message: 'Supabase error: ${result.message}',
              onRetry: () => ref.invalidate(supabaseHealthProvider),
            );
          },
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
