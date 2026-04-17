import 'dart:async';
import 'package:aviso_vital_2/core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Eventos de cambio en tiempo real.
enum RealtimeChangeType { tomas, citas, alertas }

/// Servicio de Supabase Realtime — suscripción a cambios en tomas, citas y alertas.
///
/// Uso:
/// ```dart
/// final service = RealtimeService();
/// service.start();
/// service.changes.listen((type) { /* refresh */ });
/// // …
/// service.stop();
/// ```
class RealtimeService {
  RealtimeService();

  final _controller = StreamController<RealtimeChangeType>.broadcast();
  RealtimeChannel? _channel;
  bool _running = false;

  /// Stream de cambios. Emite el tipo de tabla afectada.
  Stream<RealtimeChangeType> get changes => _controller.stream;

  /// Abre los canales Realtime. No-op si Supabase no está inicializado.
  void start() {
    if (_running) return;
    if (!SupabaseService.isReady) return;

    _running = true;
    try {
      _channel = SupabaseService.client
          .channel('aviso_vital_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tomas',
            callback: (_) => _emit(RealtimeChangeType.tomas),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'citas',
            callback: (_) => _emit(RealtimeChangeType.citas),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'alertas',
            callback: (_) => _emit(RealtimeChangeType.alertas),
          )
          .subscribe((status, [error]) {
            if (kDebugMode) {
              debugPrint('[RealtimeService] status=$status error=$error');
            }
          });
    } catch (e) {
      if (kDebugMode) debugPrint('[RealtimeService] start failed: $e');
      _running = false;
    }
  }

  /// Cierra el canal y libera recursos.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    try {
      if (_channel != null && SupabaseService.isReady) {
        await SupabaseService.client.removeChannel(_channel!);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[RealtimeService] stop error: $e');
    }
    _channel = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _emit(RealtimeChangeType type) {
    if (!_controller.isClosed) _controller.add(type);
  }
}
