import 'dart:typed_data';

import 'package:aviso_vital_2/data/models/models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

/// Genera y descarga PDFs de medicamentos y citas.
///
/// En web: descarga el archivo directamente via blob URL (sin diálogo de
/// impresión). En móvil/escritorio: usa el visor nativo del paquete printing.
class PdfExportService {
  const PdfExportService();

  // ── Colors ────────────────────────────────────────────────────────
  static final _amber   = PdfColor.fromHex('F59E0B');
  static final _dark    = PdfColor.fromHex('0F172A');
  static final _surface = PdfColor.fromHex('1E293B');
  static final _text    = PdfColor.fromHex('F1F5F9');
  static final _muted   = PdfColor.fromHex('94A3B8');
  static final _green   = PdfColor.fromHex('22C55E');
  static final _red     = PdfColor.fromHex('EF4444');
  static final _yellow  = PdfColor.fromHex('EAB308');
  static final _white   = PdfColors.white;

  // Color palette for weekly schedule (one color per medication)
  static final _palette = [
    PdfColor.fromHex('4F46E5'),
    PdfColor.fromHex('059669'),
    PdfColor.fromHex('DC2626'),
    PdfColor.fromHex('7C3AED'),
    PdfColor.fromHex('EA580C'),
    PdfColor.fromHex('0891B2'),
    PdfColor.fromHex('DB2777'),
    PdfColor.fromHex('65A30D'),
  ];

  // ── Public API ────────────────────────────────────────────────────

  /// Exporta la lista de medicamentos como PDF (2 páginas si hay datos).
  Future<void> exportMedicamentos(
    List<Medicamento> medicamentos, {
    String? nombrePaciente,
  }) async {
    final doc = pw.Document();
    final font     = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final theme    = pw.ThemeData.withFont(base: font, bold: boldFont);

    // Página 1 — lista de medicamentos
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: theme,
        build: (ctx) => [
          _header('Lista de Medicamentos', nombrePaciente),
          pw.SizedBox(height: 20),
          _generatedAt(),
          pw.SizedBox(height: 24),
          if (medicamentos.isEmpty)
            _emptyState('No hay medicamentos registrados.')
          else
            ...medicamentos.map(_medicationRow),
        ],
      ),
    );

    // Página 2 — horario semanal
    if (medicamentos.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: theme,
          build: (ctx) => [
            _header('Horario Semanal', nombrePaciente),
            _weeklyScheduleSection(medicamentos),
          ],
        ),
      );
    }

    await _savePdf(await doc.save(), 'medicamentos_aviso_vital.pdf');
  }

  /// Exporta la lista de citas como PDF (2 páginas si hay datos).
  Future<void> exportCitas(
    List<Cita> citas, {
    String? nombrePaciente,
  }) async {
    final doc = pw.Document();
    final font     = await PdfGoogleFonts.interRegular();
    final boldFont = await PdfGoogleFonts.interBold();
    final theme    = pw.ThemeData.withFont(base: font, bold: boldFont);

    // Página 1 — lista de citas
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: theme,
        build: (ctx) => [
          _header('Lista de Citas Médicas', nombrePaciente),
          pw.SizedBox(height: 20),
          _generatedAt(),
          pw.SizedBox(height: 24),
          if (citas.isEmpty)
            _emptyState('No hay citas registradas.')
          else
            ...citas.map(_citaRow),
        ],
      ),
    );

    // Página 2 — calendario mensual
    if (citas.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: theme,
          build: (ctx) => [
            _header('Calendario de Citas', nombrePaciente),
            _monthlyCalendar(citas),
          ],
        ),
      );
    }

    await _savePdf(await doc.save(), 'citas_aviso_vital.pdf');
  }

  // ── Descarga / visor de PDF ───────────────────────────────────────

  Future<void> _savePdf(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url  = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
    }
  }

  // ── Shared layout widgets ─────────────────────────────────────────

  pw.Widget _header(String title, String? patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _dark,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 4,
                height: 32,
                decoration: pw.BoxDecoration(
                  color: _amber,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Aviso Vital',
                    style: pw.TextStyle(color: _amber, fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    title,
                    style: pw.TextStyle(color: _white, fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          if (patient != null && patient.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Paciente: $patient', style: pw.TextStyle(color: _muted, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  pw.Widget _generatedAt() {
    final now = DateTime.now();
    final label =
        'Generado el ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
        ' a las ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return pw.Text(label, style: pw.TextStyle(color: _muted, fontSize: 10));
  }

  pw.Widget _emptyState(String msg) =>
      pw.Center(child: pw.Text(msg, style: pw.TextStyle(color: _muted, fontSize: 12)));

  // ── Medication row ────────────────────────────────────────────────

  pw.Widget _medicationRow(Medicamento m) {
    // Badge: 3 states — sin stock / stock bajo / stock OK
    final PdfColor badgeColor;
    final String  badgeLabel;
    if (m.sinStock) {
      badgeColor = _red;
      badgeLabel = 'Sin stock';
    } else if (m.stockBajo) {
      badgeColor = _yellow;
      badgeLabel = 'Stock bajo';
    } else {
      badgeColor = _green;
      badgeLabel = 'Stock OK';
    }

    final hours = m.horasToma.where((h) => h.trim().isNotEmpty).toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(
          color: m.stockBajo ? _red : PdfColor.fromHex('334155'),
          width: m.stockBajo ? 1.2 : 0.6,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                m.nombre,
                style: pw.TextStyle(color: _text, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: badgeColor,
                  // Fixed: circular(8) instead of circular(99) to avoid SVG path artifacts
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  badgeLabel,
                  style: pw.TextStyle(color: _white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${m.dosis}  ·  ${m.resumenTomas}',
            style: pw.TextStyle(color: _muted, fontSize: 11),
          ),
          if (hours.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Horas: ${hours.join('  ·  ')}',
              style: pw.TextStyle(color: _muted, fontSize: 10),
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'Stock actual: ${m.stockActual}  ·  Mínimo: ${m.stockMinimo}',
            style: pw.TextStyle(color: _muted, fontSize: 10),
          ),
          if (m.instrucciones != null && m.instrucciones!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              m.instrucciones!,
              style: pw.TextStyle(color: _muted, fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  // ── Weekly schedule (medicamentos page 2) ─────────────────────────

  pw.Widget _weeklyScheduleSection(List<Medicamento> medicamentos) {
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    // Legend — up to 4 per row
    final legendRows = <pw.Widget>[];
    for (int i = 0; i < medicamentos.length; i += 4) {
      final end = (i + 4).clamp(0, medicamentos.length);
      final items = <pw.Widget>[];
      for (int j = i; j < end; j++) {
        final color = _palette[j % _palette.length];
        items.add(
          pw.Expanded(
            child: pw.Row(
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Text(
                    medicamentos[j].nombre,
                    style: pw.TextStyle(color: _text, fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Pad to 4 columns
      while (items.length < 4) {
        items.add(pw.Expanded(child: pw.SizedBox()));
      }
      legendRows.add(pw.Row(children: items));
      if (end < medicamentos.length) legendRows.add(pw.SizedBox(height: 4));
    }

    // Table
    final tableRows = <pw.TableRow>[
      // Header
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _dark),
        children: [
          _scheduleHeaderCell('Medicamento'),
          for (final d in dayLabels) _scheduleHeaderCell(d, center: true),
        ],
      ),
      // Data rows
      for (int i = 0; i < medicamentos.length; i++)
        _medicationScheduleRow(medicamentos[i], _palette[i % _palette.length]),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          'Leyenda',
          style: pw.TextStyle(color: _muted, fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        ...legendRows,
        pw.SizedBox(height: 16),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(2.5),
            1: pw.FlexColumnWidth(1.0),
            2: pw.FlexColumnWidth(1.0),
            3: pw.FlexColumnWidth(1.0),
            4: pw.FlexColumnWidth(1.0),
            5: pw.FlexColumnWidth(1.0),
            6: pw.FlexColumnWidth(1.0),
            7: pw.FlexColumnWidth(1.0),
          },
          border: pw.TableBorder.all(color: PdfColor.fromHex('334155'), width: 0.5),
          children: tableRows,
        ),
      ],
    );
  }

  pw.Widget _scheduleHeaderCell(String text, {bool center = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(color: _amber, fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.TableRow _medicationScheduleRow(Medicamento m, PdfColor color) {
    final hours = m.horasToma.where((h) => h.trim().isNotEmpty).toList();
    return pw.TableRow(
      children: [
        // Med name with left color bar
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Row(
            children: [
              pw.Container(
                width: 3,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    m.nombre,
                    style: pw.TextStyle(color: _text, fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(m.dosis, style: pw.TextStyle(color: _muted, fontSize: 7)),
                ],
              ),
            ],
          ),
        ),
        // Day cells (weekday 1=Mon … 7=Sun)
        for (int weekday = 1; weekday <= 7; weekday++)
          _scheduleDayCell(m, weekday, hours, color),
      ],
    );
  }

  pw.Widget _scheduleDayCell(Medicamento m, int weekday, List<String> hours, PdfColor color) {
    final active = _isTakenOnWeekday(m, weekday);
    if (!active || hours.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: pw.BoxDecoration(color: _dark),
        child: pw.Center(
          child: pw.Text('—', style: pw.TextStyle(color: _muted, fontSize: 8)),
        ),
      );
    }
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _surface,
        border: pw.Border(left: pw.BorderSide(color: color, width: 2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: hours
            .map(
              (h) => pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(color: _text, fontSize: 6),
              ),
            )
            .toList(),
      ),
    );
  }

  bool _isTakenOnWeekday(Medicamento m, int weekday) {
    if (m.frecuencia == FrecuenciaMed.diasSemana && m.diasSemana.isNotEmpty) {
      return m.diasSemana.contains(weekday);
    }
    return true; // diaria / cada N días / según prescripción → todos los días
  }

  // ── Cita row ──────────────────────────────────────────────────────

  pw.Widget _citaRow(Cita c) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(
          color: c.esHoy ? _amber : PdfColor.fromHex('334155'),
          width: c.esHoy ? 1.2 : 0.6,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Date badge
          pw.Container(
            width: 52,
            height: 52,
            decoration: pw.BoxDecoration(
              color: _dark,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: c.esHoy ? _amber : PdfColor.fromHex('334155')),
            ),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '${c.fecha.day}',
                  style: pw.TextStyle(
                    color: c.esHoy ? _amber : _text,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  meses[c.fecha.month - 1].toUpperCase(),
                  style: pw.TextStyle(
                    color: c.esHoy ? _amber : _muted,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      c.especialidad,
                      style: pw.TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      c.hora,
                      style: pw.TextStyle(
                        color: c.esHoy ? _amber : _muted,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text(c.lugar, style: pw.TextStyle(color: _muted, fontSize: 11)),
                if (c.direccion != null && c.direccion!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(c.direccion!, style: pw.TextStyle(color: _muted, fontSize: 10)),
                ],
                if (c.telefono != null && c.telefono!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Tel: ${c.telefono!}',
                    style: pw.TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
                if (c.notas != null && c.notas!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    c.notas!,
                    style: pw.TextStyle(color: _muted, fontSize: 9, fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly calendar (citas page 2) ──────────────────────────────

  pw.Widget _monthlyCalendar(List<Cita> citas) {
    const mesesLong = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    final now = DateTime.now();

    // Use month of earliest upcoming cita, else current month
    final upcoming = citas.where((c) => !c.esPasada).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final refMonth = upcoming.isNotEmpty
        ? DateTime(upcoming.first.fecha.year, upcoming.first.fecha.month)
        : DateTime(now.year, now.month);

    final daysInMonth = DateTime(refMonth.year, refMonth.month + 1, 0).day;
    final firstWeekday = DateTime(refMonth.year, refMonth.month, 1).weekday;

    // Days in this month that have citas
    final citaDays = citas
        .where((c) => c.fecha.year == refMonth.year && c.fecha.month == refMonth.month)
        .map((c) => c.fecha.day)
        .toSet();

    final totalSlots = firstWeekday - 1 + daysInMonth;
    final rowCount = (totalSlots / 7).ceil();

    final calendarRows = <pw.TableRow>[
      // Header row
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _dark),
        children: dayLabels
            .map(
              (d) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Center(
                  child: pw.Text(
                    d,
                    style: pw.TextStyle(color: _amber, fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            )
            .toList(),
      ),
      // Day rows
      for (int row = 0; row < rowCount; row++)
        pw.TableRow(
          children: List.generate(7, (col) {
            final dayNum = row * 7 + col - (firstWeekday - 1) + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(color: _dark),
              );
            }
            final hasCita  = citaDays.contains(dayNum);
            final isToday  = now.year == refMonth.year &&
                now.month == refMonth.month &&
                now.day == dayNum;
            return pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: hasCita ? _amber : (isToday ? _surface : _dark),
                border: pw.Border.all(color: PdfColor.fromHex('334155'), width: 0.3),
              ),
              child: pw.Center(
                child: pw.Text(
                  '$dayNum',
                  style: pw.TextStyle(
                    color: hasCita ? _dark : (isToday ? _amber : _muted),
                    fontSize: 9,
                    fontWeight: hasCita || isToday ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text(
          '${mesesLong[refMonth.month - 1]} ${refMonth.year}',
          style: pw.TextStyle(color: _text, fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('334155'), width: 0.3),
          children: calendarRows,
        ),
        pw.SizedBox(height: 12),
        // Legend
        pw.Row(
          children: [
            pw.Container(
              width: 12,
              height: 12,
              decoration: pw.BoxDecoration(color: _amber),
            ),
            pw.SizedBox(width: 6),
            pw.Text('Cita programada', style: pw.TextStyle(color: _muted, fontSize: 9)),
            pw.SizedBox(width: 20),
            pw.Container(
              width: 12,
              height: 12,
              decoration: pw.BoxDecoration(
                color: _surface,
                border: pw.Border.all(color: _amber, width: 0.8),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text('Hoy', style: pw.TextStyle(color: _muted, fontSize: 9)),
          ],
        ),
      ],
    );
  }
}
