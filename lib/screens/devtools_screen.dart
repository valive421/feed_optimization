import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/devtools_provider.dart';

class DevToolsScreen extends ConsumerWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(devToolsProvider);
    final ctrl = ref.read(devToolsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('DevTools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            title: const Text('Show Performance Overlay'),
            subtitle: const Text('Frame timings and GPU/CPU bars'),
            value: state.showPerformanceOverlay,
            onChanged: (_) => ctrl.togglePerformanceOverlay(),
          ),
          if (kDebugMode) ...[
            SwitchListTile.adaptive(
              title: const Text('Repaint Rainbow'),
              subtitle: const Text('Highlight repaint regions'),
              value: state.repaintRainbow,
              onChanged: (_) => ctrl.toggleRepaintRainbow(),
            ),
            SwitchListTile.adaptive(
              title: const Text('Show Paint Bounds'),
              subtitle: const Text('Outline render boxes for layout debugging'),
              value: state.showPaintSize,
              onChanged: (_) => ctrl.togglePaintSize(),
            ),
            const SizedBox(height: 12),
            Text('Time Dilation: ${state.timeDilationFactor.toStringAsFixed(1)}x'),
            Slider(
              value: state.timeDilationFactor,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              label: '${state.timeDilationFactor.toStringAsFixed(1)}x',
              onChanged: (v) => ctrl.setTimeDilation(v),
            ),
          ] else ...[
            const ListTile(
              title: Text('Debug features available in debug mode only'),
            )
          ]
        ],
      ),
    );
  }
}
