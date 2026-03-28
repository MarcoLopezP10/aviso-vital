import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aviso_vital_2/app/app.dart';
import 'package:aviso_vital_2/core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SupabaseService.initialize();

  runApp(const AvisoVitalApp());
}
