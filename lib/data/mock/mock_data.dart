import 'package:flutter/material.dart';
import 'package:aviso_vital_2/data/models/models.dart';

/// MockData — datos de ejemplo para desarrollo y prototipo TFG
///
/// Completamente desacoplados de la UI.
/// Reemplazar con llamadas a Supabase cuando esté listo el backend.
///
/// Fallback local para previews, tests y escenarios sin sesión activa.
abstract class MockData {
  // ── Usuarios ──────────────────────────────────────────────────────

  static final Usuario usuarioMayor = Usuario(
    id: 'usr_carmen_001',
    nombre: 'Carmen García',
    email: 'carmen@example.com',
    rol: RolUsuario.mayor,
    idAdministrador: 'usr_luis_001',
    codigoVinculacion: 'AV-8847',
    fechaCreacion: DateTime(2024, 1, 15),
    notificacionesActivas: true,
    ultimaSincronizacion: DateTime.now().subtract(const Duration(minutes: 12)),
  );

  static final Usuario administrador = Usuario(
    id: 'usr_luis_001',
    nombre: 'Luis García',
    email: 'luis@example.com',
    rol: RolUsuario.administrador,
    fechaCreacion: DateTime(2024, 1, 10),
  );

  // ── Medicamentos ──────────────────────────────────────────────────

  static final List<Medicamento> medicamentos = [
    Medicamento(
      id: 'med_001',
      idUsuario: 'usr_carmen_001',
      nombre: 'Enalapril',
      dosis: '10 mg',
      frecuencia: FrecuenciaMed.cada24h,
      horasToma: ['09:00'],
      stockActual: 28,
      stockMinimo: 7,
      colorPastilla: const Color(0xFFFFFFFF),
      formaPastilla: FormaPastilla.redonda,
      instrucciones: 'Tomar en ayunas',
      activo: true,
      fechaCreacion: DateTime(2024, 1, 20),
    ),
    Medicamento(
      id: 'med_002',
      idUsuario: 'usr_carmen_001',
      nombre: 'Metformina',
      dosis: '500 mg',
      frecuencia: FrecuenciaMed.cada12h,
      horasToma: ['08:00', '20:00'],
      stockActual: 6,
      stockMinimo: 7,
      colorPastilla: const Color(0xFFFFC107),
      formaPastilla: FormaPastilla.ovalada,
      instrucciones: 'Tomar con agua después de comer',
      activo: true,
      fechaCreacion: DateTime(2024, 1, 20),
    ),
    Medicamento(
      id: 'med_003',
      idUsuario: 'usr_carmen_001',
      nombre: 'Atorvastatina',
      dosis: '20 mg',
      frecuencia: FrecuenciaMed.cada24h,
      horasToma: ['21:00'],
      stockActual: 30,
      stockMinimo: 7,
      colorPastilla: const Color(0xFFFF6A00),
      formaPastilla: FormaPastilla.redonda,
      instrucciones: 'Tomar por la noche',
      activo: true,
      fechaCreacion: DateTime(2024, 2, 5),
    ),
    Medicamento(
      id: 'med_004',
      idUsuario: 'usr_carmen_001',
      nombre: 'Omeprazol',
      dosis: '20 mg',
      frecuencia: FrecuenciaMed.cada24h,
      horasToma: ['08:00'],
      stockActual: 14,
      stockMinimo: 7,
      colorPastilla: const Color(0xFF4A9EFF),
      formaPastilla: FormaPastilla.capsula,
      instrucciones: 'Tomar 30 min antes del desayuno',
      activo: true,
      fechaCreacion: DateTime(2024, 3, 1),
    ),
  ];

  // ── Citas ─────────────────────────────────────────────────────────

  static final List<Cita> citas = [
    Cita(
      id: 'cita_001',
      idUsuario: 'usr_carmen_001',
      especialidad: 'Cardiología',
      lugar: 'Centro de Salud Norte',
      direccion: 'Calle Mayor 12, Planta 2',
      hora: '11:30',
      fecha: DateTime.now(),
      estado: EstadoCita.hoy,
      recordatorio24h: true,
      recordatorio3h: true,
      notas: 'Traer resultados del último análisis',
      fechaCreacion: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Cita(
      id: 'cita_002',
      idUsuario: 'usr_carmen_001',
      especialidad: 'Endocrinología',
      lugar: 'Hospital General',
      direccion: 'Avenida de la Constitución 45',
      hora: '10:00',
      fecha: DateTime.now().add(const Duration(days: 7)),
      estado: EstadoCita.proxima,
      recordatorio24h: true,
      recordatorio3h: false,
      fechaCreacion: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Cita(
      id: 'cita_003',
      idUsuario: 'usr_carmen_001',
      especialidad: 'Revisión general',
      lugar: 'Centro de Salud Norte',
      hora: '09:15',
      fecha: DateTime.now().add(const Duration(days: 21)),
      estado: EstadoCita.proxima,
      recordatorio24h: true,
      recordatorio3h: true,
      fechaCreacion: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Cita(
      id: 'cita_004',
      idUsuario: 'usr_carmen_001',
      especialidad: 'Traumatología',
      lugar: 'Hospital General',
      hora: '16:30',
      fecha: DateTime.now().subtract(const Duration(days: 14)),
      estado: EstadoCita.pasada,
      fechaCreacion: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  // ── Tomas ─────────────────────────────────────────────────────────

  static final List<Toma> tomasHoy = [
    Toma(
      id: 'toma_001',
      idUsuario: 'usr_carmen_001',
      idMedicamento: 'med_001',
      fechaProgramada: DateTime.now().copyWith(hour: 9, minute: 0),
      fechaConfirmacion: DateTime.now().copyWith(hour: 9, minute: 4),
      estado: EstadoToma.confirmada,
    ),
    Toma(
      id: 'toma_002',
      idUsuario: 'usr_carmen_001',
      idMedicamento: 'med_004',
      fechaProgramada: DateTime.now().copyWith(hour: 8, minute: 0),
      fechaConfirmacion: DateTime.now().copyWith(hour: 8, minute: 2),
      estado: EstadoToma.confirmada,
    ),
    Toma(
      id: 'toma_003',
      idUsuario: 'usr_carmen_001',
      idMedicamento: 'med_002',
      fechaProgramada: DateTime.now().copyWith(hour: 14, minute: 0),
      estado: EstadoToma.pendiente,
    ),
    Toma(
      id: 'toma_004',
      idUsuario: 'usr_carmen_001',
      idMedicamento: 'med_003',
      fechaProgramada: DateTime.now().copyWith(hour: 21, minute: 0),
      estado: EstadoToma.pendiente,
    ),
  ];

  // ── Alertas ───────────────────────────────────────────────────────

  static final List<Alerta> alertasRecientes = [
    Alerta(
      id: 'alerta_001',
      idUsuario: 'usr_carmen_001',
      tipo: TipoAlerta.medicacion,
      titulo: 'Enalapril confirmado',
      descripcion: 'Carmen confirmó la toma de Enalapril 10mg',
      fechaHora: DateTime.now().copyWith(hour: 9, minute: 4),
      estado: EstadoAlerta.confirmada,
      idMedicamento: 'med_001',
    ),
    Alerta(
      id: 'alerta_002',
      idUsuario: 'usr_carmen_001',
      tipo: TipoAlerta.medicacion,
      titulo: 'Metformina omitida',
      descripcion: 'Carmen no confirmó la toma de la tarde',
      fechaHora: DateTime.now()
          .subtract(const Duration(days: 1))
          .copyWith(hour: 14),
      estado: EstadoAlerta.omitida,
      idMedicamento: 'med_002',
    ),
    Alerta(
      id: 'alerta_003',
      idUsuario: 'usr_carmen_001',
      tipo: TipoAlerta.stockBajo,
      titulo: 'Stock bajo: Metformina',
      descripcion: 'Quedan 6 pastillas de Metformina 500mg',
      fechaHora: DateTime.now().subtract(const Duration(days: 1)),
      estado: EstadoAlerta.vista,
      idMedicamento: 'med_002',
    ),
    Alerta(
      id: 'alerta_004',
      idUsuario: 'usr_carmen_001',
      tipo: TipoAlerta.cita,
      titulo: 'Cita mañana: Cardiología',
      descripcion: 'Recordatorio 24h — Centro de Salud Norte a las 11:30',
      fechaHora: DateTime.now().subtract(const Duration(hours: 13)),
      estado: EstadoAlerta.vista,
      idCita: 'cita_001',
    ),
    Alerta(
      id: 'alerta_005',
      idUsuario: 'usr_carmen_001',
      tipo: TipoAlerta.medicacion,
      titulo: 'Omeprazol confirmado',
      descripcion: 'Carmen confirmó la toma matutina',
      fechaHora: DateTime.now().copyWith(hour: 8, minute: 2),
      estado: EstadoAlerta.confirmada,
      idMedicamento: 'med_004',
    ),
  ];

  // ── Adherencia ────────────────────────────────────────────────────

  static const ResumenAdherencia adherenciaSemanal = ResumenAdherencia(
    tomasConfirmadas: 18,
    tomasOmitidas: 3,
    tomasPendientes: 2,
    citasEstaSemana: 1,
    incidencias: 1,
  );

  // ── Helpers ───────────────────────────────────────────────────────

  /// Medicamento de la próxima toma pendiente
  static Medicamento? get proximoMedicamento {
    final pendiente =
        tomasHoy.where((t) => t.estado == EstadoToma.pendiente).toList()
          ..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
    if (pendiente.isEmpty) return null;
    final idMed = pendiente.first.idMedicamento;
    try {
      return medicamentos.firstWhere((m) => m.id == idMed);
    } catch (_) {
      return null;
    }
  }

  /// Cita de hoy si existe
  static Cita? get citaHoy {
    try {
      return citas.firstWhere((c) => c.esHoy);
    } catch (_) {
      return null;
    }
  }

  /// Medicamentos con stock bajo
  static List<Medicamento> get medicamentosStockBajo =>
      medicamentos.where((m) => m.stockBajo && m.activo).toList();

  /// Número de tomas pendientes hoy
  static int get tomasPendientesHoy =>
      tomasHoy.where((t) => t.estado == EstadoToma.pendiente).length;

  /// Número de citas próximas (no pasadas)
  static int get citasProximas => citas.where((c) => !c.esPasada).length;

  /// Número de omisiones recientes en el historial de alertas
  static int get omisionesRecientes => alertasRecientes
      .where(
        (a) =>
            a.estado == EstadoAlerta.omitida ||
            a.estado == EstadoAlerta.expirada,
      )
      .length;

  /// Hora de la próxima toma pendiente, o cadena vacía si no hay ninguna
  static String get horaProximaToma {
    final pendientes =
        tomasHoy.where((t) => t.estado == EstadoToma.pendiente).toList()
          ..sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
    if (pendientes.isEmpty) return '';
    final h = pendientes.first.fechaProgramada;
    return '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}';
  }
}
