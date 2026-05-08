import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineAction {
  OfflineAction({required this.type, required this.postId, required this.userId, required this.timestamp});

  final String type;
  final String postId;
  final String userId;
  final int timestamp;

  Map<String, dynamic> toJson() => {
        'type': type,
        'postId': postId,
        'userId': userId,
        'timestamp': timestamp,
      };

  factory OfflineAction.fromJson(Map<String, dynamic> j) => OfflineAction(
        type: j['type'] as String,
        postId: j['postId'] as String,
        userId: j['userId'] as String,
        timestamp: j['timestamp'] as int,
      );
}

class OfflineQueue {
  OfflineQueue._(this._prefs, this._key);

  static const _defaultKey = 'offline_queue_v1';

  final SharedPreferences _prefs;
  final String _key;

  static Future<OfflineQueue> load({String key = _defaultKey}) async {
    final prefs = await SharedPreferences.getInstance();
    return OfflineQueue._(prefs, key);
  }

  List<OfflineAction> _readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => OfflineAction.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _writeAll(List<OfflineAction> actions) async {
    final raw = jsonEncode(actions.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  Future<void> enqueue(OfflineAction action) async {
    final list = _readAll();
    list.add(action);
    await _writeAll(list);
  }

  Future<List<OfflineAction>> drain() async {
    final list = _readAll();
    await _prefs.remove(_key);
    return list;
  }

  Future<int> count() async {
    final list = _readAll();
    return list.length;
  }
}
