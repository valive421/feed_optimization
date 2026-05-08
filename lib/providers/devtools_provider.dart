import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevToolsState {
  const DevToolsState({
    required this.showPerformanceOverlay,
    required this.repaintRainbow,
    required this.showPaintSize,
    required this.timeDilationFactor,
  });

  final bool showPerformanceOverlay;
  final bool repaintRainbow;
  final bool showPaintSize;
  final double timeDilationFactor;

  DevToolsState copyWith({
    bool? showPerformanceOverlay,
    bool? repaintRainbow,
    bool? showPaintSize,
    double? timeDilationFactor,
  }) {
    return DevToolsState(
      showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
      repaintRainbow: repaintRainbow ?? this.repaintRainbow,
      showPaintSize: showPaintSize ?? this.showPaintSize,
      timeDilationFactor: timeDilationFactor ?? this.timeDilationFactor,
    );
  }

  factory DevToolsState.initial() => const DevToolsState(
        showPerformanceOverlay: false,
        repaintRainbow: false,
        showPaintSize: false,
        timeDilationFactor: 1.0,
      );
}

class DevToolsController extends StateNotifier<DevToolsState> {
  DevToolsController() : super(DevToolsState.initial());

  void togglePerformanceOverlay() {
    state = state.copyWith(showPerformanceOverlay: !state.showPerformanceOverlay);
  }

  void toggleRepaintRainbow() {
    state = state.copyWith(repaintRainbow: !state.repaintRainbow);
  }

  void togglePaintSize() {
    state = state.copyWith(showPaintSize: !state.showPaintSize);
  }

  void setTimeDilation(double factor) {
    state = state.copyWith(timeDilationFactor: factor);
  }
}

final devToolsProvider = StateNotifierProvider<DevToolsController, DevToolsState>((ref) {
  return DevToolsController();
});
