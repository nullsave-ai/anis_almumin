import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/adhkar.dart';
import '../core/state.dart';
import 'common.dart';

void openCategory(BuildContext c, DhikrCat cat, int start) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => DhikrPager(cat: cat, start: start)));

class AdhkarPage extends ConsumerStatefulWidget {
  const AdhkarPage({super.key});
  @override
  ConsumerState<AdhkarPage> createState() => _AdhkarPageState();
}

class _AdhkarPageState extends ConsumerState<AdhkarPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider.select((s) => s.arabicDigits));
    final cats = ref.watch(catsProvider);
    final favs = ref.watch(progressProvider.select((p) => p.favs));
    return centered(Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: TextField(
          onChanged: (v) => setState(() => q = v),
          decoration: InputDecoration(
            hintText: 'بحث في الأذكار',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: const Color(0x0FFFFFFF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: q.trim().isEmpty
            ? ListView(padding: const EdgeInsets.all(20), children: [
                for (final c in [...cats, favCat(cats, favs)])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Glass(
                      onTap: () => openCategory(context, c, c.id == 'fav' ? 0 : lastPos(c.id)),
                      child: Row(children: [
                        Expanded(child: Text(c.title, style: const TextStyle(color: kText, fontSize: 18))),
                        Text(ar(c.items.length), style: const TextStyle(color: kMuted)),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_left, color: kMuted),
                      ]),
                    ),
                  ),
              ])
            : ListView(padding: const EdgeInsets.all(20), children: [
                for (final (c, i) in searchCats(cats, q))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Glass(
                      onTap: () => openCategory(context, c, i),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.items[i].text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kText, fontSize: 16, height: 1.8)),
                        const SizedBox(height: 4),
                        Text(c.title, style: const TextStyle(color: kGold, fontSize: 12)),
                      ]),
                    ),
                  ),
              ]),
      ),
    ]));
  }
}

class DhikrPager extends ConsumerStatefulWidget {
  final DhikrCat cat;
  final int start;
  const DhikrPager({super.key, required this.cat, required this.start});
  @override
  ConsumerState<DhikrPager> createState() => _DhikrPagerState();
}

class _DhikrPagerState extends ConsumerState<DhikrPager> {
  late final PageController pc = PageController(initialPage: widget.start.clamp(0, (widget.cat.items.length - 1).clamp(0, 999)));
  int page = 0;

  @override
  void initState() {
    super.initState();
    page = pc.initialPage;
  }

  @override
  void dispose() { pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    ref.watch(settingsProvider.select((s) => s.arabicDigits));
    final st = ref.watch(progressProvider);
    final act = ref.read(progressProvider.notifier);
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text(cat.title), actions: [
          Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(ar('${page + 1} / ${cat.items.length}'), style: const TextStyle(color: kMuted)))),
        ]),
        body: cat.items.isEmpty
            ? const Center(child: Text('لا توجد أذكار مفضلة', style: TextStyle(color: kMuted)))
            : centered(PageView.builder(
                controller: pc,
                itemCount: cat.items.length,
                onPageChanged: (i) {
                  setState(() => page = i);
                  if (cat.id != 'fav') setLast(cat.id, i);
                },
                itemBuilder: (_, i) {
                  final d = cat.items[i];
                  final n = st.count(cat.id, d.id);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: Glass(
                              padding: const EdgeInsets.all(24),
                              child: Column(children: [
                                Text(d.text, textAlign: TextAlign.center, style: const TextStyle(color: kText, fontSize: 22, height: 2)),
                                const SizedBox(height: 16),
                                Text(d.source, style: const TextStyle(color: kGold, fontSize: 13)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        IconButton(iconSize: 28, color: st.isFav(d.id) ? kGold : kMuted, icon: Icon(st.isFav(d.id) ? Icons.bookmark : Icons.bookmark_border), onPressed: () => act.toggleFav(d.id)),
                        GestureDetector(
                          onTap: () {
                            act.tap(cat.id, d);
                            if (n + 1 >= d.count && i < cat.items.length - 1) {
                              Future.delayed(const Duration(milliseconds: 350), () {
                                if (mounted && pc.hasClients && page == i) pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                              });
                            }
                          },
                          child: SizedBox(
                            width: 108, height: 108,
                            child: Stack(alignment: Alignment.center, children: [
                              SizedBox.expand(child: CircularProgressIndicator(value: n / d.count, strokeWidth: 5, color: kAccent, backgroundColor: const Color(0x1FFFFFFF))),
                              Text(ar('$n / ${d.count}'), style: const TextStyle(color: kText, fontSize: 20)),
                            ]),
                          ),
                        ),
                        IconButton(iconSize: 28, color: kMuted, icon: const Icon(Icons.refresh), onPressed: () => act.reset(cat.id, d)),
                      ]),
                    ]),
                  );
                },
              )),
      ),
    );
  }
}
