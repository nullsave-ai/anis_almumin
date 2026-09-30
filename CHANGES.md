# CHANGES

## 1.1.0
- State: provider -> flutter_riverpod ^3.4.3 (Notifier). Prayer times are now a derived provider (timesProvider); no manual recompute.
- Storage: shared_preferences -> hive_ce ^2.19.3 (single box, pure Dart, synchronous reads, fast writes). Settings stored as one map.
- Native alarm storage: SharedPreferences -> Jetpack DataStore (androidx.datastore:datastore-preferences:1.1.7) with coroutines; BootReceiver uses goAsync.
- Lifecycle: WidgetsBindingObserver -> AppLifecycleListener.
- Alarm rescheduling in Dart only when Settings.scheduleKey changes (madhab, method, alerts, location, adjustments).
- Files: core/db.dart (new), core/state.dart, core/adhkar.dart, main.dart, ui/*, AlarmScheduler.kt, BootReceiver.kt, MainActivity.kt, build.yml, pubspec.yaml.
- Local (non-CI) build: add to android/app/build.gradle(.kts):
  dependencies { implementation("androidx.datastore:datastore-preferences:1.1.7"); implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0") }

## 1.0.0
- Initial: prayer times, adhkar, native AlarmManager scheduling.

## 1.2.0
- App renamed: أنيس المؤمن (label, MaterialApp title, pubspec name anis_almumin, package app.anis_almumin, channel app.anis_almumin/native).
- All displayed digits converted to Arabic-Indic via ar() in ui/common.dart; ISNA label localized.

## 1.3.0
- Settings > العرض: digits (Arabic-Indic / Latin) and clock (12h / 24h), persisted in Settings ('ad', 'h24').
- core/format.dart: ar() honors the digits setting (gArabicDigits, set by SettingsNotifier); ui/common.dart re-exports it.
- Home times use HH:mm or h:mm a per setting.
