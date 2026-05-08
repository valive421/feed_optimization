# Performance Profiling Checklist

Quick steps to profile the app and verify Iteration 9 toggles.

1. Run the app in profile mode (recommended):

```
flutter run --profile
```

2. Open Flutter DevTools:

- From VS Code: `Dart: Open DevTools` or the `Open DevTools` button in the debug toolbar.
- From terminal: open the URL printed by `flutter run` when running in profile mode.

3. Use the in-app DevTools button (debug builds only):

- Tap the floating developer button bottom-right to open the `DevTools` screen.
- Toggle `Show Performance Overlay` to display GPU/CPU bars.
- Toggle `Repaint Rainbow` to highlight repaint regions (debug builds only).
- Toggle `Show Paint Bounds` to outline render boxes.
- Adjust `Time Dilation` (debug builds only) to slow animations for inspection.

4. Stress tests / smoke checks:

- Use a connected device or emulator with developer options disabled for system animations.
- Perform rapid scrolling through the feed to inspect frame timings.
- Use DevTools' timeline to capture a trace and inspect raster vs UI thread workloads.

5. Notes & best practices:

- Use `--profile` for realistic timings; `--debug` enables more debug-only toggles but adds overhead.
- `Repaint Rainbow` and `Show Paint Bounds` are debug-only helpers; they will not be available in release/profile modes.
- If you change provider shapes or `const` objects, perform a hot restart.
