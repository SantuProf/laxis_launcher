import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetItem {
  final String id;
  final String type;
  final DateTime createdAt;
  // normalized position 0..1 relative to homescreen area
  final double posX;
  final double posY;

  WidgetItem({required this.id, required this.type, DateTime? createdAt, double? posX, double? posY})
      : createdAt = createdAt ?? DateTime.now(),
        posX = posX ?? 0.5,
        posY = posY ?? 0.18;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
    'createdAt': createdAt.toIso8601String(),
    'posX': posX,
    'posY': posY,
      };

  factory WidgetItem.fromJson(Map<String, dynamic> json) => WidgetItem(
        id: json['id'] as String,
        type: json['type'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    posX: (json['posX'] as num?)?.toDouble(),
    posY: (json['posY'] as num?)?.toDouble(),
      );
}

class WidgetsManager extends ChangeNotifier {
  static const _prefsKey = 'home_widgets';
  static final WidgetsManager _instance = WidgetsManager._internal();

  factory WidgetsManager() => _instance;

  WidgetsManager._internal() {
    _load();
  }

  final List<WidgetItem> _items = [];

  List<WidgetItem> get items => List.unmodifiable(_items);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _items.clear();
      for (final e in list) {
        _items.add(WidgetItem.fromJson(Map<String, dynamic>.from(e as Map)));
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('WidgetsManager: failed to load - $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> addWidget(String type) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = WidgetItem(id: id, type: type);
    _items.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> addWidgetWithPosition(String type, double posX, double posY) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = WidgetItem(id: id, type: type, posX: posX, posY: posY);
    _items.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> updateWidgetPosition(String id, double posX, double posY) async {
    final idx = _items.indexWhere((w) => w.id == id);
    if (idx == -1) return;
    final old = _items[idx];
    _items[idx] = WidgetItem(id: old.id, type: old.type, createdAt: old.createdAt, posX: posX, posY: posY);
    await _save();
    notifyListeners();
  }

  Future<void> removeWidget(String id) async {
    _items.removeWhere((w) => w.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }
}
