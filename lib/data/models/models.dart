import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════
// MODELOS DE DATOS — Aviso Vital
// Desacoplados de la UI. Preparados para mapear con Supabase.
// ════════════════════════════════════════════════════════════════════

/// Perfil de usuario en la app
enum RolUsuario { mayor, administrador }

enum TipoAccesoUsuario {
  app('App'),
  google('Google'),
  apple('Apple'),
  facebook('Facebook');

  final String label;
  const TipoAccesoUsuario(this.label);
}

/// Estado de una toma de medicamento
enum EstadoToma { pendiente, confirmada, omitida, pospuesta, expirada }

/// Frecuencia de un medicamento
enum FrecuenciaMed {
  cada8h('Cada 8h'),
  cada12h('Cada 12h'),
  cada24h('Cada 24h'),
  segunPrescripcion('Según prescripción');

  final String label;
  const FrecuenciaMed(this.label);
}

/// Forma de la pastilla — para visualización
enum FormaPastilla { redonda, ovalada, capsula }

/// Tipo de alerta
enum TipoAlerta { medicacion, cita, stockBajo, sistema }

/// Estado de una alerta
enum EstadoAlerta { pendiente, confirmada, omitida, vista, expirada }

/// Estado de un recordatorio de cita
enum EstadoCita { proxima, hoy, pasada, cancelada }

DateTime _dateFromJson(Object? value, {DateTime? fallback}) {
  if (value is DateTime) return value;

  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    if (fallback != null) return fallback;
    throw const FormatException('Fecha vacia en el mapeo del modelo.');
  }

  return DateTime.parse(raw).toLocal();
}

int _intFromJson(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolFromJson(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return fallback;
  return normalized == 'true' || normalized == '1';
}

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }

  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  return const <String>[];
}

T _enumFromJson<T extends Enum>(
  Iterable<T> values,
  Object? value, {
  required T fallback,
  String Function(T value)? labelOf,
}) {
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return fallback;

  for (final item in values) {
    if (item.name.toLowerCase() == normalized) return item;
    if (labelOf != null && labelOf(item).trim().toLowerCase() == normalized) {
      return item;
    }
  }

  return fallback;
}

Color _colorFromJson(
  Object? value, {
  Color fallback = const Color(0xFFFFFFFF),
}) {
  if (value is int) return Color(value);

  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return fallback;

  if (raw.startsWith('#')) {
    final hex = raw.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }

  final parsed = int.tryParse(raw);
  return parsed == null ? fallback : Color(parsed);
}

String _colorToJson(Color color) {
  final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#${hex.substring(2)}';
}

// ────────────────────────────────────────────────────────────────────

/// Usuario de la app (tanto mayor como administrador)
class Usuario {
  final String id;
  final String nombre;
  final String email;
  final RolUsuario rol;
  final TipoAccesoUsuario tipoAcceso;
  final String? idAdministrador;
  final String? codigoVinculacion;
  final DateTime fechaCreacion;
  final bool notificacionesActivas;
  final DateTime? ultimaSincronizacion;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.tipoAcceso = TipoAccesoUsuario.app,
    this.idAdministrador,
    this.codigoVinculacion,
    required this.fechaCreacion,
    this.notificacionesActivas = true,
    this.ultimaSincronizacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'].toString(),
    nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    rol: _enumFromJson(
      RolUsuario.values,
      json['rol'] ?? json['tipo'],
      fallback: RolUsuario.mayor,
    ),
    tipoAcceso: _enumFromJson(
      TipoAccesoUsuario.values,
      json['auth_provider'] ?? json['tipo_acceso'] ?? json['provider'],
      fallback: TipoAccesoUsuario.app,
      labelOf: (value) => value.label,
    ),
    idAdministrador: json['id_administrador']?.toString(),
    codigoVinculacion: json['codigo_vinculacion']?.toString(),
    fechaCreacion: _dateFromJson(
      json['created_at'] ?? json['fecha_creacion'],
      fallback: DateTime.now(),
    ),
    notificacionesActivas: _boolFromJson(
      json['notificaciones_activas'],
      fallback: true,
    ),
    ultimaSincronizacion:
        (json['ultima_sincronizacion'] ?? json['updated_at']) == null
        ? null
        : _dateFromJson(json['ultima_sincronizacion'] ?? json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol.name,
    'auth_provider': tipoAcceso.name,
    'id_administrador': idAdministrador,
    'codigo_vinculacion': codigoVinculacion,
    'created_at': fechaCreacion.toUtc().toIso8601String(),
    'notificaciones_activas': notificacionesActivas,
    'ultima_sincronizacion': ultimaSincronizacion?.toUtc().toIso8601String(),
  };

  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    RolUsuario? rol,
    TipoAccesoUsuario? tipoAcceso,
    String? idAdministrador,
    String? codigoVinculacion,
    DateTime? fechaCreacion,
    bool? notificacionesActivas,
    DateTime? ultimaSincronizacion,
  }) => Usuario(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    email: email ?? this.email,
    rol: rol ?? this.rol,
    tipoAcceso: tipoAcceso ?? this.tipoAcceso,
    idAdministrador: idAdministrador ?? this.idAdministrador,
    codigoVinculacion: codigoVinculacion ?? this.codigoVinculacion,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    notificacionesActivas: notificacionesActivas ?? this.notificacionesActivas,
    ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion,
  );
}

// ────────────────────────────────────────────────────────────────────

/// Medicamento gestionado por el administrador
class Medicamento {
  final String id;
  final String idUsuario;
  final String nombre;
  final String dosis;
  final FrecuenciaMed frecuencia;
  final List<String> horasToma; // ['08:00', '20:00']
  final int stockActual;
  final int stockMinimo;
  final Color colorPastilla;
  final FormaPastilla formaPastilla;
  final String? instrucciones;
  final String? notas;
  final bool activo;
  final DateTime fechaCreacion;
  final DateTime? ultimaEdicion;

  const Medicamento({
    required this.id,
    required this.idUsuario,
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    required this.horasToma,
    required this.stockActual,
    this.stockMinimo = 7,
    required this.colorPastilla,
    this.formaPastilla = FormaPastilla.redonda,
    this.instrucciones,
    this.notas,
    this.activo = true,
    required this.fechaCreacion,
    this.ultimaEdicion,
  });

  bool get stockBajo => stockActual <= stockMinimo;
  bool get sinStock => stockActual == 0;
  int get tomasAlDia =>
      horasToma.where((item) => item.trim().isNotEmpty).length;
  String get resumenTomas =>
      tomasAlDia == 1 ? '1 toma al dia' : '$tomasAlDia tomas al dia';

  factory Medicamento.fromJson(Map<String, dynamic> json) => Medicamento(
    id: json['id'].toString(),
    idUsuario: (json['id_usuario'] ?? '').toString(),
    nombre: (json['nombre'] ?? '').toString(),
    dosis: (json['dosis'] ?? '').toString(),
    frecuencia: _enumFromJson(
      FrecuenciaMed.values,
      json['frecuencia'],
      fallback: FrecuenciaMed.segunPrescripcion,
      labelOf: (value) => value.label,
    ),
    horasToma: _stringListFromJson(json['horas_toma'] ?? json['hora_toma']),
    stockActual: _intFromJson(json['stock_actual']),
    stockMinimo: _intFromJson(json['stock_minimo'], fallback: 7),
    colorPastilla: _colorFromJson(
      json['color_pastilla'],
      fallback: const Color(0xFFFFFFFF),
    ),
    formaPastilla: _enumFromJson(
      FormaPastilla.values,
      json['forma_pastilla'],
      fallback: FormaPastilla.redonda,
    ),
    instrucciones: json['instrucciones']?.toString(),
    notas: json['notas']?.toString(),
    activo: _boolFromJson(json['activo'], fallback: true),
    fechaCreacion: _dateFromJson(
      json['created_at'] ?? json['fecha_creacion'],
      fallback: DateTime.now(),
    ),
    ultimaEdicion: (json['updated_at'] ?? json['ultima_edicion']) == null
        ? null
        : _dateFromJson(json['updated_at'] ?? json['ultima_edicion']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_usuario': idUsuario,
    'nombre': nombre,
    'dosis': dosis,
    'frecuencia': frecuencia.name,
    'horas_toma': horasToma,
    'stock_actual': stockActual,
    'stock_minimo': stockMinimo,
    'color_pastilla': _colorToJson(colorPastilla),
    'forma_pastilla': formaPastilla.name,
    'instrucciones': instrucciones,
    'notas': notas,
    'activo': activo,
    'created_at': fechaCreacion.toUtc().toIso8601String(),
    'updated_at': ultimaEdicion?.toUtc().toIso8601String(),
  };

  Medicamento copyWith({
    String? id,
    String? idUsuario,
    String? nombre,
    String? dosis,
    FrecuenciaMed? frecuencia,
    List<String>? horasToma,
    int? stockActual,
    int? stockMinimo,
    Color? colorPastilla,
    FormaPastilla? formaPastilla,
    String? instrucciones,
    String? notas,
    bool? activo,
    DateTime? fechaCreacion,
    DateTime? ultimaEdicion,
  }) => Medicamento(
    id: id ?? this.id,
    idUsuario: idUsuario ?? this.idUsuario,
    nombre: nombre ?? this.nombre,
    dosis: dosis ?? this.dosis,
    frecuencia: frecuencia ?? this.frecuencia,
    horasToma: horasToma ?? this.horasToma,
    stockActual: stockActual ?? this.stockActual,
    stockMinimo: stockMinimo ?? this.stockMinimo,
    colorPastilla: colorPastilla ?? this.colorPastilla,
    formaPastilla: formaPastilla ?? this.formaPastilla,
    instrucciones: instrucciones ?? this.instrucciones,
    notas: notas ?? this.notas,
    activo: activo ?? this.activo,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    ultimaEdicion: ultimaEdicion ?? this.ultimaEdicion,
  );
}

// ────────────────────────────────────────────────────────────────────

/// Registro de una toma de medicamento
class Toma {
  final String id;
  final String idUsuario;
  final String idMedicamento;
  final DateTime fechaProgramada;
  final DateTime? fechaConfirmacion;
  final EstadoToma estado;
  final String? nota;
  final DateTime? fechaCreacion;

  const Toma({
    required this.id,
    required this.idUsuario,
    required this.idMedicamento,
    required this.fechaProgramada,
    this.fechaConfirmacion,
    required this.estado,
    this.nota,
    this.fechaCreacion,
  });

  factory Toma.fromJson(Map<String, dynamic> json) => Toma(
    id: json['id'].toString(),
    idUsuario: (json['id_usuario'] ?? '').toString(),
    idMedicamento: (json['id_medicamento'] ?? '').toString(),
    fechaProgramada: _dateFromJson(json['fecha_programada']),
    fechaConfirmacion:
        (json['fecha_realizada'] ?? json['fecha_confirmacion']) == null
        ? null
        : _dateFromJson(json['fecha_realizada'] ?? json['fecha_confirmacion']),
    estado: _enumFromJson(
      EstadoToma.values,
      json['estado'],
      fallback: EstadoToma.pendiente,
    ),
    nota: (json['notas'] ?? json['nota'])?.toString(),
    fechaCreacion: json['created_at'] == null
        ? null
        : _dateFromJson(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_usuario': idUsuario,
    'id_medicamento': idMedicamento,
    'fecha_programada': fechaProgramada.toUtc().toIso8601String(),
    'fecha_realizada': fechaConfirmacion?.toUtc().toIso8601String(),
    'estado': estado.name,
    'notas': nota,
    'created_at': fechaCreacion?.toUtc().toIso8601String(),
  };

  bool get esHoy {
    final now = DateTime.now();
    return fechaProgramada.year == now.year &&
        fechaProgramada.month == now.month &&
        fechaProgramada.day == now.day;
  }

  Toma copyWith({
    String? id,
    String? idUsuario,
    String? idMedicamento,
    DateTime? fechaProgramada,
    DateTime? fechaConfirmacion,
    EstadoToma? estado,
    String? nota,
    DateTime? fechaCreacion,
  }) => Toma(
    id: id ?? this.id,
    idUsuario: idUsuario ?? this.idUsuario,
    idMedicamento: idMedicamento ?? this.idMedicamento,
    fechaProgramada: fechaProgramada ?? this.fechaProgramada,
    fechaConfirmacion: fechaConfirmacion ?? this.fechaConfirmacion,
    estado: estado ?? this.estado,
    nota: nota ?? this.nota,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
  );
}

// ────────────────────────────────────────────────────────────────────

/// Cita médica
class Cita {
  final String id;
  final String idUsuario;
  final String especialidad;
  final String lugar;
  final String? direccion;
  final String? telefono;
  final DateTime fecha;
  final String hora; // '11:30'
  final EstadoCita estado;
  final bool recordatorio24h;
  final bool recordatorio3h;
  final String? notas;
  final DateTime fechaCreacion;

  const Cita({
    required this.id,
    required this.idUsuario,
    required this.especialidad,
    required this.lugar,
    this.direccion,
    this.telefono,
    required this.fecha,
    required this.hora,
    this.estado = EstadoCita.proxima,
    this.recordatorio24h = true,
    this.recordatorio3h = true,
    this.notas,
    required this.fechaCreacion,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    final fecha = _dateFromJson(json['fecha']);
    final hora = (json['hora'] ?? '').toString();

    return Cita(
      id: json['id'].toString(),
      idUsuario: (json['id_usuario'] ?? '').toString(),
      especialidad: (json['especialidad'] ?? '').toString(),
      lugar: (json['lugar'] ?? '').toString(),
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      fecha: fecha,
      hora: hora.isNotEmpty
          ? hora
          : '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
      estado: _enumFromJson(
        EstadoCita.values,
        json['estado'],
        fallback: EstadoCita.proxima,
      ),
      recordatorio24h: _boolFromJson(json['recordatorio_24h'], fallback: true),
      recordatorio3h: _boolFromJson(json['recordatorio_3h'], fallback: true),
      notas: json['notas']?.toString(),
      fechaCreacion: _dateFromJson(
        json['created_at'] ?? json['fecha_creacion'],
        fallback: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_usuario': idUsuario,
    'especialidad': especialidad,
    'lugar': lugar,
    'direccion': direccion,
    'telefono': telefono,
    'fecha': fecha.toUtc().toIso8601String(),
    'hora': hora,
    'estado': estado.name,
    'recordatorio_24h': recordatorio24h,
    'recordatorio_3h': recordatorio3h,
    'notas': notas,
    'created_at': fechaCreacion.toUtc().toIso8601String(),
  };

  bool get esHoy {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }

  DateTime get fechaHora {
    final parts = hora.split(':');
    final parsedHour = int.tryParse(parts.isNotEmpty ? parts.first : '');
    final parsedMinute = int.tryParse(parts.length > 1 ? parts[1] : '');
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      parsedHour ?? fecha.hour,
      parsedMinute ?? fecha.minute,
    );
  }

  bool get esPasada => fechaHora.isBefore(DateTime.now());

  Cita copyWith({
    String? id,
    String? idUsuario,
    String? especialidad,
    String? lugar,
    String? direccion,
    String? telefono,
    DateTime? fecha,
    String? hora,
    EstadoCita? estado,
    bool? recordatorio24h,
    bool? recordatorio3h,
    String? notas,
    DateTime? fechaCreacion,
  }) => Cita(
    id: id ?? this.id,
    idUsuario: idUsuario ?? this.idUsuario,
    especialidad: especialidad ?? this.especialidad,
    lugar: lugar ?? this.lugar,
    direccion: direccion ?? this.direccion,
    telefono: telefono ?? this.telefono,
    fecha: fecha ?? this.fecha,
    hora: hora ?? this.hora,
    estado: estado ?? this.estado,
    recordatorio24h: recordatorio24h ?? this.recordatorio24h,
    recordatorio3h: recordatorio3h ?? this.recordatorio3h,
    notas: notas ?? this.notas,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
  );
}

// ────────────────────────────────────────────────────────────────────

/// Alerta enviada al usuario mayor
class Alerta {
  final String id;
  final String idUsuario;
  final TipoAlerta tipo;
  final String titulo;
  final String? descripcion;
  final DateTime fechaHora;
  final EstadoAlerta estado;
  final String? idMedicamento;
  final String? idCita;

  const Alerta({
    required this.id,
    required this.idUsuario,
    required this.tipo,
    required this.titulo,
    this.descripcion,
    required this.fechaHora,
    required this.estado,
    this.idMedicamento,
    this.idCita,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
    id: json['id'].toString(),
    idUsuario: (json['id_usuario'] ?? '').toString(),
    tipo: _enumFromJson(
      TipoAlerta.values,
      json['tipo'],
      fallback: TipoAlerta.sistema,
    ),
    titulo: (json['titulo'] ?? '').toString(),
    descripcion: (json['descripcion'] ?? json['mensaje'])?.toString(),
    fechaHora: _dateFromJson(
      json['fecha_hora'] ?? json['fecha_alerta'] ?? json['created_at'],
      fallback: DateTime.now(),
    ),
    estado: _enumFromJson(
      EstadoAlerta.values,
      json['estado'] ?? (json['leida'] == true ? 'vista' : 'pendiente'),
      fallback: EstadoAlerta.pendiente,
    ),
    idMedicamento: json['id_medicamento']?.toString(),
    idCita: json['id_cita']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'id_usuario': idUsuario,
    'tipo': tipo.name,
    'titulo': titulo,
    'descripcion': descripcion,
    'fecha_hora': fechaHora.toUtc().toIso8601String(),
    'estado': estado.name,
    'id_medicamento': idMedicamento,
    'id_cita': idCita,
  };

  bool get esHoy {
    final now = DateTime.now();
    return fechaHora.year == now.year &&
        fechaHora.month == now.month &&
        fechaHora.day == now.day;
  }

  Alerta copyWith({
    String? id,
    String? idUsuario,
    TipoAlerta? tipo,
    String? titulo,
    String? descripcion,
    DateTime? fechaHora,
    EstadoAlerta? estado,
    String? idMedicamento,
    String? idCita,
  }) => Alerta(
    id: id ?? this.id,
    idUsuario: idUsuario ?? this.idUsuario,
    tipo: tipo ?? this.tipo,
    titulo: titulo ?? this.titulo,
    descripcion: descripcion ?? this.descripcion,
    fechaHora: fechaHora ?? this.fechaHora,
    estado: estado ?? this.estado,
    idMedicamento: idMedicamento ?? this.idMedicamento,
    idCita: idCita ?? this.idCita,
  );
}

// ────────────────────────────────────────────────────────────────────

/// Resumen de adherencia semanal
class ResumenAdherencia {
  final int tomasConfirmadas;
  final int tomasOmitidas;
  final int tomasPendientes;
  final int citasEstaSemana;
  final int incidencias;

  const ResumenAdherencia({
    required this.tomasConfirmadas,
    required this.tomasOmitidas,
    required this.tomasPendientes,
    required this.citasEstaSemana,
    required this.incidencias,
  });

  double get adherencia {
    final total = tomasConfirmadas + tomasOmitidas;
    if (total == 0) return 1.0;
    return tomasConfirmadas / total;
  }

  int get totalTomas => tomasConfirmadas + tomasOmitidas + tomasPendientes;
}
