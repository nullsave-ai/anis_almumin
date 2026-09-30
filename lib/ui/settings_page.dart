import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/native.dart';
import '../core/prayer_calculator.dart';
import '../core/state.dart';
import 'common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Widget _title(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 8), child: Text(t, style: const TextStyle(color: kGold, fontSize: 14)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final jafari = s.madhab == Madhab.jafari;
    return centered(ListView(padding: const EdgeInsets.all(20), children: [
      _title('الحساب'),
      Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('المذهب', style: TextStyle(color: kText)),
        DropdownButton<Madhab>(
          isExpanded: true, value: s.madhab, dropdownColor: kBg2, underline: const SizedBox(),
          items: [for (final m in Madhab.values) DropdownMenuItem(value: m, child: Text(madhabNames[m]!))],
          onChanged: (v) => n.setMadhab(v!),
        ),
        const Text('يؤثر الحنفي على وقت العصر، ويعتمد الجعفري زوايا الفجر والمغرب والعشاء الجعفرية.', style: TextStyle(color: kMuted, fontSize: 12, height: 1.6)),
        const SizedBox(height: 14),
        const Text('طريقة الحساب', style: TextStyle(color: kText)),
        DropdownButton<Method>(
          isExpanded: true, value: jafari ? Method.jafari : s.method, dropdownColor: kBg2, underline: const SizedBox(),
          items: [for (final m in Method.values) if (m != Method.jafari || jafari) DropdownMenuItem(value: m, child: Text(methodNames[m]!))],
          onChanged: jafari ? null : (v) => n.setMethod(v!),
        ),
      ])),
      _title('الموقع'),
      Glass(child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('تحديد الموقع تلقائيا'), subtitle: Text(s.city, style: const TextStyle(color: kMuted)), value: s.autoLoc, onChanged: (v) => v ? n.useAuto() : n.setManual((s.city, s.lat, s.lng))),
        if (!s.autoLoc)
          DropdownButton<String>(
            isExpanded: true, hint: const Text('اختر المدينة'), dropdownColor: kBg2, underline: const SizedBox(),
            value: cities.any((c) => c.$1 == s.city) ? s.city : null,
            items: [for (final c in cities) DropdownMenuItem(value: c.$1, child: Text(c.$1))],
            onChanged: (v) => n.setManual(cities.firstWhere((c) => c.$1 == v)),
          ),
      ])),
      _title('العرض'),
      Glass(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('الأرقام'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            segments: const [ButtonSegment(value: true, label: Text('عربية ٠١٢')), ButtonSegment(value: false, label: Text('إنجليزية 012'))],
            selected: {s.arabicDigits},
            onSelectionChanged: (v) => n.setDigits(v.first),
          ),
        ),
        const SizedBox(height: 14),
        const Text('نظام الوقت'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            segments: [ButtonSegment(value: false, label: Text(ar('12 ساعة'))), ButtonSegment(value: true, label: Text(ar('24 ساعة')))],
            selected: {s.use24h},
            onSelectionChanged: (v) => n.setUse24(v.first),
          ),
        ),
      ])),
      _title('التعديل اليدوي (بالدقائق)'),
      Glass(child: Column(children: [
        for (final k in Prayer.values)
          Row(children: [
            Expanded(child: Text(prayerNames[k]!)),
            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => n.setAdj(k, (s.adj[k] ?? 0) - 1)),
            SizedBox(width: 36, child: Text(ar(s.adj[k] ?? 0), textAlign: TextAlign.center, textDirection: TextDirection.ltr)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => n.setAdj(k, (s.adj[k] ?? 0) + 1)),
          ]),
      ])),
      _title('التنبيهات'),
      Glass(child: Column(children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('تنبيهات الصلاة'), value: s.alerts, onChanged: n.setAlerts),
        const _Perms(),
      ])),
    ]));
  }
}

class _Perms extends StatefulWidget {
  const _Perms();
  @override
  State<_Perms> createState() => _PermsState();
}

class _PermsState extends State<_Perms> {
  Map<String, bool> st = {};
  late final AppLifecycleListener _life;
  @override
  void initState() { super.initState(); _life = AppLifecycleListener(onResume: _load); _load(); }
  @override
  void dispose() { _life.dispose(); super.dispose(); }
  Future<void> _load() async { final r = await Native.status(); if (mounted) setState(() => st = r); }

  Widget _row(String t, bool? ok, String method) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(t),
        trailing: ok == true ? const Icon(Icons.check_circle, color: kAccent) : TextButton(onPressed: () => Native.call(method), child: const Text('تفعيل')),
      );

  @override
  Widget build(BuildContext context) => Column(children: [
        _row('إذن الإشعارات', st['notif'], 'requestNotifications'),
        _row('التنبيهات الدقيقة', st['exact'], 'openExactSettings'),
        _row('استثناء توفير البطارية (اختياري)', st['battery'], 'openBatterySettings'),
      ]);
}
