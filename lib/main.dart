import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation ──────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Status bar style ─────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // ── Hive (local storage) ─────────────────────────────────────────────
  await Hive.initFlutter();
  // TODO: Register Hive adapters here when adding offline models

  // ── Greek locale ─────────────────────────────────────────────────────
  await initializeDateFormatting('el_GR', null);

  runApp(
    const ProviderScope(
      child: MindBridgeApp(),
    ),
  );
}
