import 'dart:math';

enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }
enum Madhab { hanafi, shafii, maliki, hanbali, jafari }
enum Method { mwl, egypt, karachi, ummAlQura, isna, jafari }

class Params {
  final double fajr, isha, maghrib, asr;
  final int ishaMin;
  const Params(this.fajr, this.isha, {this.maghrib = 0.833, this.ishaMin = 0, this.asr = 1});
}

/// المذهب يؤثر فعليا: الحنفي = ظل مثلين للعصر، الجعفري = زوايا الفجر/المغرب/العشاء الجعفرية.
Params paramsFor(Madhab madhab, Method method) {
  final m = madhab == Madhab.jafari ? Method.jafari : method;
  final asr = madhab == Madhab.hanafi ? 2.0 : 1.0;
  switch (m) {
    case Method.mwl: return Params(18, 17, asr: asr);
    case Method.egypt: return Params(19.5, 17.5, asr: asr);
    case Method.karachi: return Params(18, 18, asr: asr);
    case Method.ummAlQura: return Params(18.5, 0, ishaMin: 90, asr: asr);
    case Method.isna: return Params(15, 15, asr: asr);
    case Method.jafari: return Params(16, 14, maghrib: 4, asr: asr);
  }
}

double _r(double d) => d * pi / 180;
double _d(double r) => r * 180 / pi;
double _fix(double a, double m) {
  a = a - m * (a / m).floorToDouble();
  return a < 0 ? a + m : a;
}

({double decl, double eqt}) _sun(double jd) {
  final d = jd - 2451545.0;
  final g = _fix(357.529 + 0.98560028 * d, 360);
  final q = _fix(280.459 + 0.98564736 * d, 360);
  final l = _fix(q + 1.915 * sin(_r(g)) + 0.020 * sin(_r(2 * g)), 360);
  final e = 23.439 - 0.00000036 * d;
  final ra = _fix(_d(atan2(cos(_r(e)) * sin(_r(l)), cos(_r(l)))) / 15, 24);
  return (decl: _d(asin(sin(_r(e)) * sin(_r(l)))), eqt: q / 15 - ra);
}

double _julian(int y, int m, int d) {
  if (m <= 2) { y -= 1; m += 12; }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + d + b - 1524.5;
}

double _mid(double jd, double t) => _fix(12 - _sun(jd + t).eqt, 24);

double _ang(double jd, double lat, double a, double t, bool ccw) {
  final decl = _sun(jd + t).decl;
  final n = (-sin(_r(a)) - sin(_r(decl)) * sin(_r(lat))) / (cos(_r(decl)) * cos(_r(lat)));
  if (n.abs() > 1) return double.nan;
  final v = _d(acos(n)) / 15;
  return _mid(jd, t) + (ccw ? -v : v);
}

double _asr(double jd, double lat, double f, double t) {
  final decl = _sun(jd + t).decl;
  final a = -_d(atan(1 / (f + tan(_r((lat - decl).abs())))));
  return _ang(jd, lat, a, t, false);
}

Map<Prayer, DateTime> computeTimes(DateTime date, double lat, double lng, Params p, Map<Prayer, int> adj) {
  final tz = DateTime(date.year, date.month, date.day, 12).timeZoneOffset.inMinutes / 60;
  final jd = _julian(date.year, date.month, date.day) - lng / 360;
  final t = <Prayer, double>{Prayer.fajr: 5, Prayer.sunrise: 6, Prayer.dhuhr: 12, Prayer.asr: 13, Prayer.maghrib: 18, Prayer.isha: 18};
  double f(Prayer k) => t[k]! / 24;
  for (var i = 0; i < 2; i++) {
    final n = <Prayer, double>{
      Prayer.dhuhr: _mid(jd, f(Prayer.dhuhr)),
      Prayer.fajr: _ang(jd, lat, p.fajr, f(Prayer.fajr), true),
      Prayer.sunrise: _ang(jd, lat, 0.833, f(Prayer.sunrise), true),
      Prayer.asr: _asr(jd, lat, p.asr, f(Prayer.asr)),
      Prayer.maghrib: _ang(jd, lat, p.maghrib, f(Prayer.maghrib), false),
    };
    n[Prayer.isha] = p.ishaMin > 0
        ? n[Prayer.maghrib]! + p.ishaMin / 60
        : _ang(jd, lat, p.isha, f(Prayer.isha), false);
    n.forEach((k, v) { if (!v.isNaN) t[k] = v; });
  }
  final utc0 = DateTime.utc(date.year, date.month, date.day);
  return {
    for (final k in Prayer.values)
      k: utc0
          .add(Duration(seconds: ((_fix(t[k]! + tz - lng / 15, 24) - tz) * 3600 + (adj[k] ?? 0) * 60).round()))
          .toLocal()
  };
}
