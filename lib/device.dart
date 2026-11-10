import 'package:flutter/services.dart';

/// Ponte para recursos Android que o exercício usa diretamente.
class Device {
  static const _channel = MethodChannel('aprender_c1/device');

  static Future<T?> call<T>(String method, [Map<String, Object?>? args]) =>
      _channel.invokeMethod<T>(method, args);

  static Future<bool> getBool(String key) async =>
      await call<bool>('getBool', {'key': key}) ?? false;

  static Future<void> setBool(String key, bool value) async {
    await call<void>('setBool', {'key': key, 'value': value});
  }

  static Future<void> toast(String message) async {
    await call<void>('toast', {'text': message});
  }
}
