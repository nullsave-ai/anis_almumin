import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/adhkar.dart';
import 'core/db.dart';
import 'core/native.dart';
import 'core/state.dart';
import 'ui/adhkar_page.dart';
import 'ui/common.dart';
import 'ui/home_page.dart';
import 'ui/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  HijriCalendar.setLocal('ar');
  await initDb();
  final cats = await loadCats();
  runApp(ProviderScope(overrides: [catsProvider.overrideWithValue(cats)], child: const Root()));
}

class Root extends ConsumerStatefulWidget {
  const Root({super.key});
  @override
  ConsumerState<Root> createState() => _RootState();
}

class _RootState extends ConsumerState<Root> {
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: _sync);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try { await Native.call('requestNotifications'); } catch (_) {}
      _sync(force: true);
    });
  }

  Future<void> _sync({bool force = false}) async {
    final before = ref.read(settingsProvider).scheduleKey;
    await ref.read(settingsProvider.notifier).locate(force: force);
    ref.invalidate(timesProvider);
    if (ref.read(settingsProvider).scheduleKey == before) await schedulePrayers(ref.read(settingsProvider));
  }

  @override
  void dispose() { _life.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (p, s) {
      if (p != null && p.scheduleKey != s.scheduleKey) schedulePrayers(s);
    });
    return MaterialApp(
      title: 'أنيس المؤمن',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(primary: kAccent, surface: kBg1),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: kText, displayColor: kText),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  static const pages = [HomePage(), AdhkarPage(), SettingsPage()];
  @override
  Widget build(BuildContext context) => AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: pages[i],
          bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0x66000000),
            selectedIndex: i,
            onDestinationSelected: (v) => setState(() => i = v),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.access_time), label: 'الصلاة'),
              NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'الأذكار'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
            ],
          ),
        ),
      );
}
