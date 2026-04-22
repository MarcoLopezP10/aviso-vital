import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aviso_vital_2/app/app.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:aviso_vital_2/shared/i18n/app_language.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await AppLocaleController.instance.load();
  await SupabaseService.initialize();

  runApp(const AvisoVitalApp());
}
