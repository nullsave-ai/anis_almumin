/// يُحدَّث من SettingsNotifier عند تغيير إعداد الأرقام.
bool gArabicDigits = true;

String ar(Object v) {
  final s = v.toString();
  return gArabicDigits ? s.replaceAllMapped(RegExp('[0-9]'), (m) => String.fromCharCode(0x0660 + int.parse(m[0]!))) : s;
}
