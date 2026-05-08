import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ConnectivityController extends StateNotifier<bool> {
  ConnectivityController({String? testUrl})
      : _testUrl = testUrl ?? 'https://www.google.com/',
        super(true) {
    _init();
  }

  final String _testUrl;
  Timer? _timer;

  Future<void> _init() async {
    await _checkOnce();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkOnce());
  }

  Future<void> _checkOnce() async {
    try {
      final resp = await http.get(Uri.parse(_testUrl)).timeout(const Duration(seconds: 3));
      state = resp.statusCode >= 200 && resp.statusCode < 500;
    } on SocketException {
      state = false;
    } on TimeoutException {
      state = false;
    } catch (_) {
      state = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityController, bool>((ref) {
  return ConnectivityController();
});
