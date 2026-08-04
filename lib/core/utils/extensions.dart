import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── BuildContext ───────────────────────────────────────────────────────────
extension ContextX on BuildContext {
  ThemeData get theme     => Theme.of(this);
  TextTheme  get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors  => Theme.of(this).colorScheme;
  MediaQueryData get mq   => MediaQuery.of(this);
  double get screenWidth  => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  bool   get isDark       => Theme.of(this).brightness == Brightness.dark;

  void showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade800 : null,
      ),
    );
  }
}

// ── DateTime ───────────────────────────────────────────────────────────────
extension DateTimeX on DateTime {
  String get timeHm     => DateFormat('HH:mm').format(this);
  String get dateDMY    => DateFormat('d/M/yyyy').format(this);
  String get dateDM     => DateFormat('d MMM', 'el_GR').format(this);
  String get dayName    => DateFormat('EEEE', 'el_GR').format(this);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  bool get isToday    => isSameDay(DateTime.now());
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));

  String get relativeLabel {
    if (isToday)     return 'Σήμερα';
    if (isYesterday) return 'Χθες';
    return dateDM;
  }
}

// ── String ─────────────────────────────────────────────────────────────────
extension StringX on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  bool get isValidEmail =>
      RegExp(r'^[\w.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(this);

  bool get isValidPassword => length >= 8;
}

// ── int / double ───────────────────────────────────────────────────────────
extension DoubleX on double {
  /// Map score 0–10 to a mood emoji
  String get moodEmoji {
    if (this >= 8.5) return '😊';
    if (this >= 7.0) return '🙂';
    if (this >= 5.0) return '😐';
    if (this >= 3.0) return '😞';
    return '😢';
  }

  String get moodLabel {
    if (this >= 8.5) return 'Πολύ καλά';
    if (this >= 7.0) return 'Καλά';
    if (this >= 5.0) return 'Μέτρια';
    if (this >= 3.0) return 'Άσχημα';
    return 'Πολύ άσχημα';
  }
}

// ── Widget ─────────────────────────────────────────────────────────────────
extension WidgetX on Widget {
  Widget padAll(double v) => Padding(padding: EdgeInsets.all(v), child: this);
  Widget padH(double v)   => Padding(padding: EdgeInsets.symmetric(horizontal: v), child: this);
  Widget padV(double v)   => Padding(padding: EdgeInsets.symmetric(vertical: v), child: this);
}
