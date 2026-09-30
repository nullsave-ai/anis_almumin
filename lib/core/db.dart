import 'package:hive_ce_flutter/hive_ce_flutter.dart';

late final Box box;

Future<void> initDb() async {
  await Hive.initFlutter();
  box = await Hive.openBox('athkar');
}
