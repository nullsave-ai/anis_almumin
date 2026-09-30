import 'package:flutter/services.dart';

class Native {
  static const _c = MethodChannel('app.anis_almumin/native');
  static Future<void> schedule(List<Map<String, Object>> items) => _c.invokeMethod('schedule', {'items': items});
  static Future<void> cancelAll() => _c.invokeMethod('cancelAll');
  static Future<void> call(String m) => _c.invokeMethod(m);
  static Future<Map<String, bool>> status() async =>
      Map<String, bool>.from(await _c.invokeMethod('status') as Map);
}
