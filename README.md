# High Performance Feed

High Performance Feed is a Flutter application designed and implemented with performance-first principles: smooth scrolling, low memory footprint for images, optimistic UI for likes, and safe concurrency for user interactions. This README documents architecture choices, how to run and profile the app, and verification steps used to confirm the optimizations (especially `RepaintBoundary` and `memCacheWidth`).

# Demo Video


https://github.com/user-attachments/assets/6208fe1e-824a-4f9c-9ec3-96588a8127e8


## Quick Start

Prerequisites:
- Flutter SDK matching `>=3.11.5` (see `pubspec.yaml`).
- `flutter` on PATH, and a connected device or emulator.

Run locally (debug):

```bash
flutter pub get
flutter run
```

For meaningful performance profiling run in profile mode:

```bash
flutter run --profile
```

Open DevTools from VS Code or via the URL printed by `flutter run`.

## Environment

- The app uses a `.env` file for Supabase credentials. See `.env.example` for required keys: `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- The project includes a demo user id used during development: `user_123` (see `lib/core/constants.dart`).

## Architecture & State Management (Riverpod)

Short summary of the Riverpod approach used:

- We prefer `StateNotifier` + `StateNotifierProvider` for complex, testable mutable state (see `lib/providers/*`). Controllers encapsulate business logic and side-effects; views subscribe to provider state via `ConsumerWidget` or `WidgetRef`.
- Data fetching and side effects live in `repositories` (e.g., `lib/repositories/post_repository.dart`) and are invoked from `StateNotifier` controllers (e.g., `FeedController` in `lib/providers/feed_provider.dart`).
- Providers are designed to be small and focused: one provider per domain controller, plus `FutureProvider`/`StreamProvider` for simple async reads. This keeps UI code declarative and side-effect free.
- Optimistic updates are implemented in `FeedController.toggleLike`: the UI updates immediately, the RPC (`toggle_like`) is invoked, and a rollback occurs on failure. To avoid race conditions the controller also throttles like requests and queues the user's last intent.

Why Riverpod:
- Testability: controllers are plain Dart classes that are easy to unit test.
- Explicit dependencies: providers declare their requirements; no implicit global singletons.
- Performance: Riverpod minimizes rebuilds by scoping listeners to small slices of state.

## Key Performance Implementations

- `RepaintBoundary`: Complex widgets (post cards) are wrapped in `RepaintBoundary` to isolate repaint costs. This reduces unnecessary GPU work when only a subset of the UI changes.

- `memCacheWidth` / `memCacheHeight`: `OptimizedCachedImage` computes `memCacheWidth` and `memCacheHeight` using `MediaQuery.devicePixelRatio` to request appropriately sized bitmaps, which prevents large decoded bitmaps from being stored in memory.

### How these were verified

1. RepaintBoundary verification

- Use the in-app DevTools screen (debug builds) to enable `Repaint Rainbow` and `Show Paint Bounds`.
- Interact with the feed (scroll, like, open detail). With `Repaint Rainbow` enabled you should see only the affected cards repaint when their state changes (e.g., like toggles). This visually confirms `RepaintBoundary` isolates repaints.
- Capture a DevTools timeline trace while scrolling and compare raster vs UI thread work with and without `RepaintBoundary` to quantify savings.

2. memCacheWidth verification

- Run the app in `--profile` and open DevTools → Memory.
- While scrolling a feed of images, inspect the decoded image sizes and the memory table. Optimized requests should show decoded sizes matching the memCacheWidth/memCacheHeight instead of full-resolution originals.
- Compare the memory footprint between `OptimizedCachedImage` and an unoptimized control requesting raw images to confirm reduced memory usage and fewer GC events.

## Profiling Checklist

- Run `flutter run --profile` on a real device.
- Open DevTools → Performance → record while rapidly scrolling the feed.
- Use `Repaint Rainbow` to visually locate repaint hotspots.
- Use Memory profiler to validate decoded image sizes.

## Tests & Local Checks

- Static analysis: `flutter analyze` 
- Formatting: `dart format .`

## Notable Files

- `lib/main.dart` — app bootstrap and Supabase initialization.
- `lib/core/app.dart` — wired `devToolsProvider`, debug FAB and performance overlay toggle.
- `lib/providers/feed_provider.dart` — feed controller with optimistic likes, throttling, and queuing behavior.
- `lib/widgets/optimized_cached_image.dart` — computes and sets `memCacheWidth`/`memCacheHeight` to limit decoded bitmap sizes.
- `lib/widgets/post_card.dart` — UI with `RepaintBoundary` and `Hero` image transitions.

## Offline Interaction Handling

This app includes a lightweight offline interaction system to handle transient network loss for user actions (currently: likes).

- Components:
	- `lib/services/offline_queue.dart`: a small JSON-backed queue persisted in `SharedPreferences` (key `offline_queue_v1`) that stores pending actions across restarts.
	- `lib/providers/connectivity_provider.dart`: monitors network connectivity using `connectivity_plus` and exposes an online/offline boolean provider.
	- `lib/providers/feed_provider.dart`: integrates the queue and connectivity state. When offline, `toggleLike` enqueues a `toggle_like` action and applies an optimistic local UI change; when connectivity is restored the controller attempts to flush the queue and apply server-side RPCs.

- Behavior and tradeoffs:
	- Likes performed offline are shown optimistically immediately and marked as pending until the queue is processed.
	- The queue processing attempts RPCs and discards actions that fail; this keeps the queue from blocking but may lose actions if the server continually rejects them. To improve durability, consider re-enqueueing failed actions with exponential backoff and a retry cap.

- How to test manually:
	1. Run the app on a device/emulator.
 2. Disable network (airplane mode) or block connectivity.
 3. Perform several like/unlike actions in the feed; they should update the UI immediately.
 4. Re-enable network and observe the app processing the queued actions (the floating debug / DevTools indicator and logs may help). The actions are persisted across restarts.
---

If you'd like, I can also add:
- GitHub Actions CI for `flutter analyze` and formatting checks.
- A reproducible stress-test harness for automated scrolling and benchmarking.
