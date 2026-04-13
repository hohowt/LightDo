import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const _key = 'lightdo_device_id';

  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateId();
    await prefs.setString(_key, id);
    return id;
  }

  String _generateId() {
    final rng = Random.secure();
    return List.generate(8, (_) => rng.nextInt(16).toRadixString(16)).join();
  }
}
