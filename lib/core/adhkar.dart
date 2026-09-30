import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db.dart';

class Dhikr {
  final String id, text, source;
  final int count;
  const Dhikr(this.id, this.text, this.source, this.count);
}

class DhikrCat {
  final String id, title;
  final List<Dhikr> items;
  const DhikrCat(this.id, this.title, this.items);
}

Future<List<DhikrCat>> loadCats() async {
  final j = jsonDecode(await rootBundle.loadString('assets/adhkar.json')) as Map<String, dynamic>;
  final items = {
    for (final e in (j['items'] as Map<String, dynamic>).entries)
      e.key: Dhikr(e.key, e.value['text'], e.value['source'], e.value['count'])
  };
  return [for (final c in j['categories']) DhikrCat(c['id'], c['title'], [for (final i in c['items']) items[i]!])];
}

/// تُحقن قيمتها في main عبر overrides.
final catsProvider = Provider<List<DhikrCat>>((_) => throw UnimplementedError());

final _tashkeel = RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]');
String _norm(String s) => s.replaceAll(_tashkeel, '').replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');

List<(DhikrCat, int)> searchCats(List<DhikrCat> cats, String q) {
  final n = _norm(q.trim());
  return [for (final c in cats) for (var i = 0; i < c.items.length; i++) if (_norm(c.items[i].text).contains(n)) (c, i)];
}

DhikrCat favCat(List<DhikrCat> cats, Set<String> favs) {
  final seen = <String>{};
  return DhikrCat('fav', 'المفضلة', [for (final c in cats) for (final i in c.items) if (favs.contains(i.id) && seen.add(i.id)) i]);
}

int lastPos(String cat) => box.get('last:$cat', defaultValue: 0) as int;
void setLast(String cat, int i) => box.put('last:$cat', i);

class Progress {
  final Map<String, int> counts;
  final Set<String> favs;
  const Progress(this.counts, this.favs);
  int count(String cat, String id) => counts['$cat:$id'] ?? 0;
  bool isFav(String id) => favs.contains(id);
}

class ProgressNotifier extends Notifier<Progress> {
  @override
  Progress build() {
    final day = DateTime.now().toString().substring(0, 10);
    if (box.get('day') != day) {
      box.deleteAll(box.keys.where((k) => k is String && k.startsWith('c:')).toList());
      box.put('day', day);
    }
    return Progress(
      {for (final k in box.keys) if (k is String && k.startsWith('c:')) k.substring(2): box.get(k) as int},
      (box.get('favs', defaultValue: <String>[]) as List).cast<String>().toSet(),
    );
  }

  void tap(String cat, Dhikr d) {
    final n = state.count(cat, d.id);
    if (n >= d.count) return;
    box.put('c:$cat:${d.id}', n + 1);
    HapticFeedback.selectionClick();
    state = Progress({...state.counts, '$cat:${d.id}': n + 1}, state.favs);
  }

  void reset(String cat, Dhikr d) {
    box.delete('c:$cat:${d.id}');
    state = Progress({...state.counts}..remove('$cat:${d.id}'), state.favs);
  }

  void toggleFav(String id) {
    final f = {...state.favs};
    f.contains(id) ? f.remove(id) : f.add(id);
    box.put('favs', f.toList());
    state = Progress(state.counts, f);
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);
