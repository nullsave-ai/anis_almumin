import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'db.dart';
import 'format.dart';
import 'native.dart';
import 'prayer_calculator.dart';

const prayerNames = {
  Prayer.fajr: 'الفجر', Prayer.sunrise: 'الشروق', Prayer.dhuhr: 'الظهر',
  Prayer.asr: 'العصر', Prayer.maghrib: 'المغرب', Prayer.isha: 'العشاء',
};
const madhabNames = {
  Madhab.hanafi: 'الحنفي', Madhab.shafii: 'الشافعي', Madhab.maliki: 'المالكي',
  Madhab.hanbali: 'الحنبلي', Madhab.jafari: 'الجعفري',
};
const methodNames = {
  Method.mwl: 'رابطة العالم الإسلامي', Method.egypt: 'الهيئة المصرية العامة للمساحة',
  Method.karachi: 'جامعة العلوم الإسلامية - كراتشي', Method.ummAlQura: 'أم القرى',
  Method.isna: 'الجمعية الإسلامية لأمريكا الشمالية', Method.jafari: 'الجعفري',
};
const cities = <(String, double, double)>[
  ('مكة المكرمة', 21.4225, 39.8262), ('المدينة المنورة', 24.4672, 39.6111),
  ('الرياض', 24.7136, 46.6753), ('القاهرة', 30.0444, 31.2357),
  ('دمشق', 33.5138, 36.2765), ('بغداد', 33.3152, 44.3661),
  ('عمّان', 31.9454, 35.9284), ('القدس', 31.7683, 35.2137),
  ('الكويت', 29.3759, 47.9774), ('دبي', 25.2048, 55.2708),
  ('الدوحة', 25.2854, 51.5310), ('الرباط', 34.0209, -6.8416),
];
const alarmPrayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];
const _keep = Object();

class Settings {
  final Madhab madhab;
  final Method method;
  final bool autoLoc, alerts, arabicDigits, use24h;
  final double lat, lng;
  final String city;
  final Map<Prayer, int> adj;
  final String? locError;
  const Settings({required this.madhab, required this.method, required this.autoLoc, required this.alerts, required this.arabicDigits, required this.use24h, required this.lat, required this.lng, required this.city, required this.adj, this.locError});

  factory Settings.fromMap(Map? m) {
    m ??= {};
    return Settings(
      madhab: Madhab.values[m['madhab'] ?? 1], method: Method.values[m['method'] ?? 0],
      autoLoc: m['auto'] ?? true, alerts: m['alerts'] ?? true, arabicDigits: m['ad'] ?? true, use24h: m['h24'] ?? false,
      lat: m['lat'] ?? 21.4225, lng: m['lng'] ?? 39.8262, city: m['city'] ?? 'مكة المكرمة',
      adj: {for (final k in Prayer.values) k: m['adj_${k.name}'] ?? 0},
    );
  }

  Map<String, Object> toMap() => {
        'madhab': madhab.index, 'method': method.index, 'auto': autoLoc, 'alerts': alerts, 'ad': arabicDigits, 'h24': use24h,
        'lat': lat, 'lng': lng, 'city': city,
        for (final e in adj.entries) 'adj_${e.key.name}': e.value,
      };

  /// يتغير فقط عندما يلزم إعادة جدولة التنبيهات.
  Object get scheduleKey => Object.hash(madhab, method, alerts, lat, lng, Object.hashAll(adj.values));

  Settings copyWith({Madhab? madhab, Method? method, bool? autoLoc, bool? alerts, bool? arabicDigits, bool? use24h, double? lat, double? lng, String? city, Map<Prayer, int>? adj, Object? locError = _keep}) => Settings(
        madhab: madhab ?? this.madhab, method: method ?? this.method, autoLoc: autoLoc ?? this.autoLoc,
        alerts: alerts ?? this.alerts, arabicDigits: arabicDigits ?? this.arabicDigits, use24h: use24h ?? this.use24h, lat: lat ?? this.lat, lng: lng ?? this.lng, city: city ?? this.city,
        adj: adj ?? this.adj, locError: identical(locError, _keep) ? this.locError : locError as String?,
      );
}

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() {
    final s = Settings.fromMap(box.get('s') as Map?);
    gArabicDigits = s.arabicDigits;
    return s;
  }

  void _set(Settings s) { gArabicDigits = s.arabicDigits; state = s; box.put('s', s.toMap()); }

  void setMadhab(Madhab m) => _set(state.copyWith(madhab: m));
  void setMethod(Method m) => _set(state.copyWith(method: m));
  void setAlerts(bool v) => _set(state.copyWith(alerts: v));
  void setDigits(bool arabic) => _set(state.copyWith(arabicDigits: arabic));
  void setUse24(bool v) => _set(state.copyWith(use24h: v));
  void setAdj(Prayer k, int v) => _set(state.copyWith(adj: {...state.adj, k: v.clamp(-30, 30)}));
  void setManual((String, double, double) c) => _set(state.copyWith(autoLoc: false, city: c.$1, lat: c.$2, lng: c.$3, locError: null));
  Future<void> useAuto() async { _set(state.copyWith(autoLoc: true)); await locate(force: true); }

  Future<void> locate({bool force = false}) async {
    if (!state.autoLoc) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - (box.get('fixAt', defaultValue: 0) as int) < 3 * 3600 * 1000) return;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _set(state.copyWith(locError: 'صلاحية الموقع غير ممنوحة'));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 12)));
      var city = state.city;
      try {
        await setLocaleIdentifier('ar');
        final pm = (await placemarkFromCoordinates(pos.latitude, pos.longitude)).first;
        city = (pm.locality?.isNotEmpty ?? false) ? pm.locality! : (pm.administrativeArea ?? city);
      } catch (_) { city = '${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}'; }
      box.put('fixAt', now);
      _set(state.copyWith(lat: pos.latitude, lng: pos.longitude, city: city, locError: null));
    } catch (_) { _set(state.copyWith(locError: 'تعذر تحديد الموقع، يتم استخدام آخر موقع محفوظ')); }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class Times {
  final Map<Prayer, DateTime> today;
  final DateTime tomorrowFajr;
  const Times(this.today, this.tomorrowFajr);

  ({Prayer p, DateTime t}) next(DateTime now) {
    for (final k in alarmPrayers) {
      if (today[k]!.isAfter(now)) return (p: k, t: today[k]!);
    }
    return (p: Prayer.fajr, t: tomorrowFajr);
  }
}

/// مشتق تلقائيا من الإعدادات؛ استخدم ref.invalidate(timesProvider) عند تغير اليوم.
final timesProvider = Provider<Times>((ref) {
  final s = ref.watch(settingsProvider);
  final now = DateTime.now();
  final p = paramsFor(s.madhab, s.method);
  return Times(computeTimes(now, s.lat, s.lng, p, s.adj),
      computeTimes(now.add(const Duration(days: 1)), s.lat, s.lng, p, s.adj)[Prayer.fajr]!);
});

Future<void> schedulePrayers(Settings s) async {
  try {
    if (!s.alerts) { await Native.cancelAll(); return; }
    final now = DateTime.now();
    final p = paramsFor(s.madhab, s.method);
    final items = <Map<String, Object>>[];
    for (var d = 0; d < 30; d++) {
      final date = DateTime(now.year, now.month, now.day + d);
      final times = computeTimes(date, s.lat, s.lng, p, s.adj);
      final base = date.difference(DateTime(2020)).inDays * 10;
      for (var i = 0; i < alarmPrayers.length; i++) {
        final t = times[alarmPrayers[i]]!;
        if (!t.isAfter(now)) continue;
        items.add({'id': base + i, 'at': t.millisecondsSinceEpoch, 'title': 'حان الآن موعد صلاة ${prayerNames[alarmPrayers[i]]}', 'body': s.city});
      }
    }
    await Native.schedule(items);
  } catch (_) {}
}
