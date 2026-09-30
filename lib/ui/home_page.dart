import 'dart:ui' show FontFeature;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/adhkar.dart';
import '../core/prayer_calculator.dart';
import '../core/state.dart';
import 'adhkar_page.dart';
import 'common.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final t = ref.watch(timesProvider);
    final now = DateTime.now();
    final n = t.next(now);
    final afterMaghrib = t.today[Prayer.maghrib]!.isBefore(now);
    final h = HijriCalendar.fromDate(afterMaghrib ? now.add(const Duration(days: 1)) : now);
    final timeFmt = DateFormat(s.use24h ? 'HH:mm' : 'h:mm a', 'ar');
    return centered(ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        const Icon(Icons.location_on_outlined, size: 18, color: kAccent),
        const SizedBox(width: 6),
        Expanded(child: Text(s.city, style: const TextStyle(color: kText, fontSize: 16))),
      ]),
      const SizedBox(height: 6),
      Text(ar('${h.hDay} ${h.longMonthName} ${h.hYear}') + ' هـ', style: const TextStyle(color: kGold, fontSize: 20, fontWeight: FontWeight.w600)),
      Text(ar(DateFormat('EEEE، d MMMM y', 'ar').format(now)), style: const TextStyle(color: kMuted, fontSize: 14)),
      if (s.locError != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(s.locError!, style: const TextStyle(color: kGold, fontSize: 12))),
      const SizedBox(height: 18),
      Glass(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Text('الصلاة القادمة', style: TextStyle(color: kMuted, fontSize: 14)),
            const SizedBox(height: 6),
            Text(prayerNames[n.p]!, style: const TextStyle(color: kText, fontSize: 34, fontWeight: FontWeight.w700)),
            Text(ar(timeFmt.format(n.t)), style: const TextStyle(color: kAccent, fontSize: 18)),
            const SizedBox(height: 12),
            Countdown(target: n.t),
          ]),
        ),
      const SizedBox(height: 14),
      Glass(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(children: [
          for (final k in Prayer.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Expanded(
                      child: Text(prayerNames[k]!,
                          style: TextStyle(fontSize: 17, color: n.p == k ? kAccent : (k == Prayer.sunrise ? kMuted : kText), fontWeight: n.p == k ? FontWeight.w700 : FontWeight.w400))),
                  Text(ar(timeFmt.format(t.today[k]!)), style: TextStyle(fontSize: 17, color: n.p == k ? kAccent : (k == Prayer.sunrise ? kMuted : kText))),
                ]),
              ),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Shortcut('أذكار الصباح', Icons.wb_twilight, 'morning')),
        const SizedBox(width: 12),
        Expanded(child: _Shortcut('أذكار المساء', Icons.nights_stay_outlined, 'evening')),
      ]),
    ]));
  }
}

class _Shortcut extends ConsumerWidget {
  final String label, id;
  final IconData icon;
  const _Shortcut(this.label, this.icon, this.id);
  @override
  Widget build(BuildContext context, WidgetRef ref) => Glass(
        onTap: () => openCategory(context, ref.read(catsProvider).firstWhere((c) => c.id == id), lastPos(id)),
        child: Column(children: [Icon(icon, color: kGold), const SizedBox(height: 8), Text(label, style: const TextStyle(color: kText, fontSize: 15))]),
      );
}

class Countdown extends ConsumerStatefulWidget {
  final DateTime target;
  const Countdown({super.key, required this.target});
  @override
  ConsumerState<Countdown> createState() => _CountdownState();
}

class _CountdownState extends ConsumerState<Countdown> {
  Timer? _t;
  Duration _left = Duration.zero;
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: _start, onInactive: () => _t?.cancel());
    _start();
  }

  void _start() {
    _t?.cancel();
    _tick();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final d = widget.target.difference(DateTime.now());
    if (d <= Duration.zero) {
      _t?.cancel();
      ref.invalidate(timesProvider);
      return;
    }
    setState(() => _left = d);
  }

  @override
  void didUpdateWidget(Countdown old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) _start();
  }

  @override
  void dispose() {
    _life.dispose();
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final d = _left;
    return Text(ar('${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'),
        textDirection: TextDirection.ltr,
        style: const TextStyle(color: kText, fontSize: 30, fontWeight: FontWeight.w300, fontFeatures: [FontFeature.tabularFigures()]));
  }
}
