import 'dart:typed_data';

import 'package:aviso_vital_2/data/models/models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_html/html.dart' as html;

class PdfExportService {
  const PdfExportService();

  // ── Colors ─────────────────────────────────────────────────────────────────
  static final _amber = PdfColor.fromHex('FFC107');
  static final _orange = PdfColor.fromHex('FF6A00');
  static final _headerBg = PdfColor.fromHex('0D1B2E');
  static final _white = PdfColors.white;
  static final _stockOk = PdfColor.fromHex('4CAF50');
  static final _stockLow = PdfColor.fromHex('FF3B30');
  static final _bgAlt = PdfColor.fromHex('FAFAFA');
  static final _borderSoft = PdfColor.fromHex('EFEFEF');
  static final _textPrimary = PdfColor.fromHex('111111');
  static final _textMuted = PdfColor.fromHex('999999');
  static final _bgWeekend = PdfColor.fromHex('FAFAF7');
  static final _borderWeekend = PdfColor.fromHex('EEE8D8');
  static final _bgAppt = PdfColor.fromHex('FFF3E0');
  static final _borderAppt = PdfColor.fromHex('FFB74D');

  static const _logoAssetPath = 'assets/images/aviso_vital_logo.svg';

  static const _mesesLong = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const _mesesShort = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];

  static const _dayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _dayFull = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const _portraitMargin = pw.EdgeInsets.symmetric(
    horizontal: 60,
    vertical: 56,
  );

  static const _landscapeMargin = pw.EdgeInsets.symmetric(
    horizontal: 52,
    vertical: 40,
  );

  static const _landscapeContentH = 595.28 - 40.0 - 40.0;

  static const _calHeaderH = 90.0;
  static const _calDayNamesH = 34.0;
  static const _calLegendH = 42.0;
  static const _calFooterH = 36.0;
  static const _calGapsH = 16.0 + 4.0 + 12.0 + 20.0;

  static const _calGridH = _landscapeContentH -
      _calHeaderH -
      _calDayNamesH -
      _calLegendH -
      _calFooterH -
      _calGapsH;

  // Máximo de medicamentos por página de horario semanal.
  // Si tienes muchos medicamentos con muchas horas, baja este valor a 4.
  static const int _medsPerSchedulePage = 5;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> exportMedicamentos(
    List<Medicamento> medicamentos, {
    String? nombrePaciente,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontIt = await PdfGoogleFonts.interItalic();
    final logoSvg = await _loadLogoSvg();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      italic: fontIt,
    );

    final now = DateTime.now();

    final scheduleChunks = medicamentos.isNotEmpty
        ? _chunkList(medicamentos, _medsPerSchedulePage)
        : <List<Medicamento>>[];

    final total = medicamentos.isNotEmpty ? 1 + scheduleChunks.length : 1;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _portraitMargin,
        theme: theme,
        footer: (ctx) => _footer(ctx.pageNumber, total, now, font, fontBold, logoSvg),
        build: (ctx) => [
          _header(
            'Lista de Medicamentos',
            nombrePaciente,
            _amber,
            font,
            fontBold,
            logoSvg,
          ),
          pw.SizedBox(height: 20),
          if (medicamentos.isEmpty)
            _emptyState('No hay medicamentos registrados.', font)
          else ...[
            pw.Text(
              '${medicamentos.length} medicamento${medicamentos.length == 1 ? '' : 's'} activo${medicamentos.length == 1 ? '' : 's'}',
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColor.fromHex('888888'),
              ),
            ),
            pw.SizedBox(height: 20),
            ...medicamentos.asMap().entries.map(
                  (e) => _medCard(e.key, e.value, font, fontBold, fontIt),
                ),
            pw.SizedBox(height: 16),
            _medSummaryStrip(medicamentos, font, fontBold),
          ],
        ],
      ),
    );

    if (medicamentos.isNotEmpty) {
      for (var i = 0; i < scheduleChunks.length; i++) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: _landscapeMargin,
            build: (ctx) => _schedulePageContent(
              scheduleChunks[i],
              nombrePaciente,
              font,
              fontBold,
              now,
              i + 2,
              total,
              logoSvg,
            ),
          ),
        );
      }
    }

    await _savePdf(await doc.save(), 'medicamentos_aviso_vital.pdf');
  }

  Future<void> exportCitas(
    List<Cita> citas, {
    String? nombrePaciente,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontIt = await PdfGoogleFonts.interItalic();
    final logoSvg = await _loadLogoSvg();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
      italic: fontIt,
    );

    final now = DateTime.now();
    final total = citas.isNotEmpty ? 3 : 1;
    final month0 = DateTime(now.year, now.month);
    final month1 = DateTime(now.year, now.month + 1);

    final proximas = citas.where((c) => !c.esPasada).toList()
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

    final pasadas = citas.where((c) => c.esPasada).toList()
      ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _portraitMargin,
        theme: theme,
        footer: (ctx) => _footer(ctx.pageNumber, total, now, font, fontBold, logoSvg),
        build: (ctx) {
          final items = <pw.Widget>[
            _header(
              'Lista de Citas Médicas',
              nombrePaciente,
              _orange,
              font,
              fontBold,
              logoSvg,
            ),
            pw.SizedBox(height: 20),
          ];

          if (citas.isEmpty) {
            items.add(_emptyState('No hay citas registradas.', font));
          } else {
            if (proximas.isNotEmpty) {
              items.add(_sectionLabel(
                'PRÓXIMAS — ${proximas.length} CITA${proximas.length == 1 ? '' : 'S'}',
                _textMuted, font,
              ));
              items.add(pw.SizedBox(height: 10));
              for (int i = 0; i < proximas.length; i++) {
                items.add(_citaCard(proximas[i], false, font, fontBold, fontIt));
                if (i < proximas.length - 1) items.add(pw.SizedBox(height: 12));
              }
            }
            if (pasadas.isNotEmpty) {
              items.add(pw.SizedBox(height: 16));
              items.add(_sectionLabel(
                'PASADAS — ${pasadas.length} CITA${pasadas.length == 1 ? '' : 'S'}',
                PdfColor.fromHex('BBBBBB'), font,
              ));
              items.add(pw.SizedBox(height: 10));
              for (int i = 0; i < pasadas.length; i++) {
                items.add(_citaCard(pasadas[i], true, font, fontBold, fontIt));
                if (i < pasadas.length - 1) items.add(pw.SizedBox(height: 12));
              }
            }
            items.add(pw.SizedBox(height: 20));
            items.add(_citaSummaryStrip(citas, now, font, fontBold));
          }

          return items;
        },
      ),
    );

    if (citas.isNotEmpty) {
      for (final item in [
        (idx: 2, month: month0),
        (idx: 3, month: month1),
      ]) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: _landscapeMargin,
            build: (ctx) => _calendarPageContent(
              citas,
              item.month,
              nombrePaciente,
              font,
              fontBold,
              now,
              item.idx,
              total,
              logoSvg,
            ),
          ),
        );
      }
    }

    await _savePdf(await doc.save(), 'citas_aviso_vital.pdf');
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  Future<String?> _loadLogoSvg() async {
    try {
      return await rootBundle.loadString(_logoAssetPath);
    } catch (_) {
      return null;
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int size) {
    final chunks = <List<T>>[];

    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(
          i,
          i + size > list.length ? list.length : i + size,
        ),
      );
    }

    return chunks;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _savePdf(Uint8List bytes, String filename) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
    }
  }

  // ── Shared components ──────────────────────────────────────────────────────

  pw.Widget _header(
    String title,
    String? patient,
    PdfColor accent,
    pw.Font font,
    pw.Font fontBold,
    String? logoSvg,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        gradient: pw.LinearGradient(
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
          colors: [accent, accent, _headerBg, _headerBg],
          stops: const [0.0, 0.012, 0.012, 1.0],
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          _pdfBrandLogo(logoSvg, fontBold, size: 54),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AVISO VITAL',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: accent,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 24,
                    color: _white,
                    letterSpacing: -0.5,
                  ),
                ),
                if (patient != null && patient.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Paciente: $patient',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 13,
                      color: PdfColor(1, 1, 1, 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfBrandLogo(
    String? logoSvg,
    pw.Font fontBold, {
    double size = 52,
  }) {
    if (logoSvg != null && logoSvg.trim().isNotEmpty) {
      return pw.Container(
        width: size,
        height: size,
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        ),
        child: pw.SvgImage(
          svg: logoSvg,
          fit: pw.BoxFit.contain,
        ),
      );
    }

    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
          colors: [_amber, _orange],
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Center(
        child: pw.Text(
          'AV',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: size * 0.32,
            color: PdfColors.black,
          ),
        ),
      ),
    );
  }

  pw.Widget _footer(
    int page,
    int total,
    DateTime now,
    pw.Font font,
    pw.Font fontBold,
    String? logoSvg,
  ) {
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'
        ' · ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 18),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromHex('E8E8E8'), width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              _pdfBrandLogo(logoSvg, fontBold, size: 24),
              pw.SizedBox(width: 8),
              pw.Text(
                'Aviso Vital',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                  color: PdfColor.fromHex('999999'),
                ),
              ),
            ],
          ),
          pw.Text(
            'Generado el $dateStr',
            style: pw.TextStyle(
              font: font,
              fontSize: 11,
              color: PdfColor.fromHex('BBBBBB'),
            ),
          ),
          pw.Text(
            '$page de $total',
            style: pw.TextStyle(
              font: font,
              fontSize: 11,
              color: PdfColor.fromHex('999999'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _emptyState(String msg, pw.Font font) => pw.Center(
        child: pw.Text(
          msg,
          style: pw.TextStyle(font: font, fontSize: 13, color: _textMuted),
        ),
      );

  // ── PillShape ──────────────────────────────────────────────────────────────

  pw.Widget _pill(FormaPastilla forma, Color color, {double size = 14}) {
    final pdfColor = PdfColor.fromInt(color.toARGB32());
    final double w;
    final double h;
    final pw.BorderRadius radius;

    switch (forma) {
      case FormaPastilla.redonda:
        w = size;
        h = size;
        radius = pw.BorderRadius.circular(size / 2);
      case FormaPastilla.ovalada:
        w = size * 1.5;
        h = size;
        radius = pw.BorderRadius.circular(size / 2);
      case FormaPastilla.capsula:
        w = size * 1.8;
        h = size;
        radius = pw.BorderRadius.circular(size / 2);
    }

    return pw.Container(
      width: w,
      height: h,
      decoration: pw.BoxDecoration(
        color: pdfColor,
        borderRadius: radius,
        border: pw.Border.all(color: PdfColor.fromHex('CCCCCC'), width: 0.5),
      ),
    );
  }

  // ── Stock bar ──────────────────────────────────────────────────────────────

  pw.Widget _stockBar(int actual, int minimo, pw.Font font, pw.Font fontBold) {
    final fill = minimo == 0 ? 1.0 : (actual / (minimo * 3.0)).clamp(0.0, 1.0);
    final fillStop = fill.clamp(0.001, 0.999);
    final isOk = actual >= minimo;
    final fillColor = isOk ? _stockOk : _stockLow;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Stock actual: $actual uds',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColor.fromHex('444444'),
              ),
            ),
            pw.Text(
              'Mínimo: $minimo uds',
              style: pw.TextStyle(font: font, fontSize: 10, color: _textMuted),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 4,
          decoration: pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            gradient: pw.LinearGradient(
              begin: pw.Alignment.centerLeft,
              end: pw.Alignment.centerRight,
              colors: [fillColor, fillColor, _borderSoft, _borderSoft],
              stops: [0.0, fillStop, fillStop, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  // ── Medication card ────────────────────────────────────────────────────────

  pw.Widget _medCard(
    int index,
    Medicamento m,
    pw.Font font,
    pw.Font fontBold,
    pw.Font fontIt,
  ) {
    final bg = index % 2 == 0 ? _white : _bgAlt;
    final hours = m.horasToma.where((h) => h.trim().isNotEmpty).toList();
    final isOk = m.stockActual >= m.stockMinimo;
    final idxLbl = (index + 1).toString().padLeft(2, '0');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: _borderSoft, width: 1.5),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(44),
          1: pw.FlexColumnWidth(1),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2, right: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    _pill(m.formaPastilla, m.colorPastilla, size: 14),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      idxLbl,
                      style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textMuted),
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            m.nombre,
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 16,
                              color: _textPrimary,
                            ),
                          ),
                          pw.Text(
                            _doseLabel(m.dosis),
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 13,
                              color: PdfColor.fromHex('666666'),
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: isOk ? PdfColor.fromHex('E8F5E9') : PdfColor.fromHex('FFEBEE'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                        ),
                        child: pw.Text(
                          isOk ? 'Stock OK' : 'Stock bajo',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: isOk ? PdfColor.fromHex('2E7D32') : PdfColor.fromHex('C62828'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hours.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Horas: ${hours.join(' · ')}  ·  ${m.resumenTomas}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: PdfColor.fromHex('555555'),
                      ),
                    ),
                  ],
                  if (m.instrucciones != null && m.instrucciones!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      m.instrucciones!,
                      style: pw.TextStyle(
                        font: fontIt,
                        fontSize: 11,
                        color: PdfColor.fromHex('888888'),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  _stockBar(m.stockActual, m.stockMinimo, font, fontBold),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _doseLabel(String dose) {
    final t = dose.trim();
    if (t.isEmpty) return t;
    if (RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚ]').hasMatch(t)) return t;
    return '$t mg';
  }

  // ── Summary strips ─────────────────────────────────────────────────────────

  pw.Widget _medSummaryStrip(List<Medicamento> meds, pw.Font font, pw.Font fontBold) {
    final tomas = meds.fold<int>(
      0,
      (s, m) => s + m.horasToma.where((h) => h.trim().isNotEmpty).length,
    );
    final lowStock = meds.where((m) => m.stockBajo).length;

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('FFF8E1'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColor.fromHex('FFE082'), width: 1),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FixedColumnWidth(1),
          2: pw.FlexColumnWidth(1),
          3: pw.FixedColumnWidth(1),
          4: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: [
              _stripStatCell('${meds.length}', 'Total medicamentos', _amber, font, fontBold),
              pw.Container(height: 36, color: PdfColor.fromHex('FFE082')),
              _stripStatCell('$tomas', 'Tomas diarias', _amber, font, fontBold),
              pw.Container(height: 36, color: PdfColor.fromHex('FFE082')),
              _stripStatCell('$lowStock', 'Stock bajo', _amber, font, fontBold),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _citaSummaryStrip(List<Cita> citas, DateTime now, pw.Font font, pw.Font fontBold) {
    final proximas = citas.where((c) => !c.esPasada).length;
    final esteMes = citas.where((c) {
      return c.fecha.year == now.year && c.fecha.month == now.month;
    }).length;

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('FFF3E0'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColor.fromHex('FFB74D'), width: 1),
      ),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FixedColumnWidth(1),
          2: pw.FlexColumnWidth(1),
          3: pw.FixedColumnWidth(1),
          4: pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            children: [
              _stripStatCell('${citas.length}', 'Total citas', _orange, font, fontBold),
              pw.Container(height: 36, color: PdfColor.fromHex('FFB74D')),
              _stripStatCell('$proximas', 'Próximas', _orange, font, fontBold),
              pw.Container(height: 36, color: PdfColor.fromHex('FFB74D')),
              _stripStatCell('$esteMes', 'Este mes', _orange, font, fontBold),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _stripStatCell(
    String value,
    String label,
    PdfColor accent,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(font: fontBold, fontSize: 22, color: accent),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 11,
            color: PdfColor.fromHex('8B6914'),
          ),
        ),
      ],
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  pw.Widget _sectionLabel(String text, PdfColor color, pw.Font font) => pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 11,
          color: color,
          letterSpacing: 1,
        ),
      );

  // ── Cita card ──────────────────────────────────────────────────────────────

  pw.Widget _citaCard(Cita c, bool isPast, pw.Font font, pw.Font fontBold, pw.Font fontIt) {
    final isToday = c.esHoy;
    final cardBg = isToday ? _bgAppt : (isPast ? _bgAlt : _white);
    final borderColor = isToday ? _orange : _borderSoft;
    final dateColor = isToday ? _orange : (isPast ? _textMuted : _textPrimary);

    // pw.Row + pw.Expanded is safe here: Row has bounded width from the page,
    // so Expanded distributes width (never height). No pw.Table to avoid the
    // pdf-package SpanningWidget behavior that splits table rows across pages
    // while the outer Container decoration renders as a full empty box.
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: pw.BoxDecoration(
        color: cardBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: borderColor, width: 1.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Date column
          pw.Container(
            width: 48,
            padding: const pw.EdgeInsets.only(right: 14),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: borderColor, width: 2),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${c.fecha.day}',
                  style: pw.TextStyle(font: fontBold, fontSize: 22, color: dateColor),
                ),
                pw.Text(
                  _mesesShort[c.fecha.month - 1],
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: isToday ? _orange : _textMuted,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          // Content — Expanded in Row is safe (distributes width, not height)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  c.especialidad,
                  style: pw.TextStyle(font: fontBold, fontSize: 15, color: _textPrimary),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  c.lugar,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    color: PdfColor.fromHex('555555'),
                  ),
                ),
                if (c.direccion != null && c.direccion!.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    c.direccion!,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                      color: PdfColor.fromHex('888888'),
                    ),
                  ),
                ],
                if (c.notas != null && c.notas!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('F5F5F5'),
                      border: pw.Border(
                        left: pw.BorderSide(color: _orange, width: 3),
                      ),
                    ),
                    child: pw.Text(
                      'Nota: ${c.notas!}',
                      style: pw.TextStyle(
                        font: fontIt,
                        fontSize: 11,
                        color: PdfColor.fromHex('555555'),
                      ),
                    ),
                  ),
                ],
                if (c.telefono != null && c.telefono!.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Tel: ${c.telefono!}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11,
                      color: PdfColor.fromHex('888888'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Time pill
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: isToday ? PdfColor.fromHex('FFF0E0') : PdfColor.fromHex('F2F2F2'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              c.hora,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 18,
                color: isToday ? _orange : _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Schedule page, medicamentos ────────────────────────────────────────────

  pw.Widget _schedulePageContent(
    List<Medicamento> meds,
    String? patient,
    pw.Font font,
    pw.Font fontBold,
    DateTime now,
    int pageNum,
    int totalPages,
    String? logoSvg,
  ) {
    final legendItems = meds.map((m) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(right: 12, bottom: 5),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            _pill(m.formaPastilla, m.colorPastilla, size: 10),
            pw.SizedBox(width: 4),
            pw.Text(
              m.nombre,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: PdfColor.fromHex('444444'),
              ),
            ),
            pw.SizedBox(width: 3),
            pw.Text(
              _doseLabel(m.dosis),
              style: pw.TextStyle(font: font, fontSize: 9, color: _textMuted),
            ),
          ],
        ),
      );
    }).toList();

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _headerBg),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: pw.Text(
              'Medicamento',
              style: pw.TextStyle(font: fontBold, fontSize: 11, color: _white),
            ),
          ),
          for (int d = 0; d < 7; d++)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: pw.Center(
                child: pw.Text(
                  _dayShort[d],
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    color: d >= 5 ? _amber : _white,
                  ),
                ),
              ),
            ),
        ],
      ),
      for (int i = 0; i < meds.length; i++) _scheduleRow(meds[i], i, font, fontBold),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header('Horario Semanal de Tomas', patient, _amber, font, fontBold, logoSvg),
        pw.SizedBox(height: 12),
        pw.Wrap(spacing: 0, runSpacing: 4, children: legendItems),
        pw.SizedBox(height: 12),
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(150),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(1),
            4: pw.FlexColumnWidth(1),
            5: pw.FlexColumnWidth(1),
            6: pw.FlexColumnWidth(1),
            7: pw.FlexColumnWidth(1),
          },
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _borderSoft, width: 1.2),
            verticalInside: pw.BorderSide(color: _borderSoft, width: 1.2),
          ),
          children: tableRows,
        ),
        pw.SizedBox(height: 12),
        _footer(pageNum, totalPages, now, font, fontBold, logoSvg),
      ],
    );
  }

  pw.TableRow _scheduleRow(Medicamento m, int index, pw.Font font, pw.Font fontBold) {
    final hours = m.horasToma.where((h) => h.trim().isNotEmpty).toList();
    final bg = index % 2 == 0 ? _bgAlt : _white;
    final pillColor = PdfColor.fromInt(m.colorPastilla.toARGB32());
    final textColor = _chipTextColor(m.colorPastilla);

    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
          color: bg,
          child: pw.Row(
            children: [
              _pill(m.formaPastilla, m.colorPastilla, size: 12),
              pw.SizedBox(width: 6),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    m.nombre,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: _textPrimary,
                    ),
                  ),
                  pw.Text(
                    _doseLabel(m.dosis),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: PdfColor.fromHex('777777'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (int weekday = 1; weekday <= 7; weekday++)
          _scheduleDayCell(m, weekday, hours, pillColor, textColor, bg, font, fontBold),
      ],
    );
  }

  pw.Widget _scheduleDayCell(
    Medicamento m,
    int weekday,
    List<String> hours,
    PdfColor pillColor,
    PdfColor textColor,
    PdfColor bg,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final cellBg = weekday >= 6 ? PdfColor.fromHex('FFFBF0') : bg;
    final active = _isTakenOnWeekday(m, weekday);

    if (!active || hours.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        color: cellBg,
        child: pw.Center(
          child: pw.Text(
            '—',
            style: pw.TextStyle(font: font, fontSize: 10, color: _textMuted),
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      color: cellBg,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: hours.map((h) {
          return pw.Container(
            width: 50,
            margin: const pw.EdgeInsets.only(bottom: 4),
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: pw.BoxDecoration(
              color: pillColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Center(
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8.5,
                  color: textColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  PdfColor _chipTextColor(Color c) {
    final rgb = c.toARGB32() & 0xFFFFFF;
    return rgb > 0xAAAAAA ? PdfColor.fromHex('333333') : PdfColors.white;
  }

  bool _isTakenOnWeekday(Medicamento m, int weekday) {
    if (m.frecuencia == FrecuenciaMed.diasSemana) {
      return m.diasSemana.contains(weekday);
    }

    // Mantiene tu comportamiento anterior.
    // Si tu enum tiene valores como diaria, alterna, unica, etc., aquí se puede
    // hacer un switch más específico.
    return true;
  }

  // ── Calendar page, citas ───────────────────────────────────────────────────

  pw.Widget _calendarPageContent(
    List<Cita> citas,
    DateTime month,
    String? patient,
    pw.Font font,
    pw.Font fontBold,
    DateTime now,
    int pageNum,
    int totalPages,
    String? logoSvg,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final weekCount = ((firstWeekday - 1 + daysInMonth) / 7).ceil();
    final monthTitle = '${_mesesLong[month.month - 1]} ${month.year}';
    final rowH = (_calGridH / weekCount).floorToDouble();

    final citasByDay = <int, List<Cita>>{};
    for (final c in citas) {
      if (c.fecha.year == month.year && c.fecha.month == month.month) {
        citasByDay.putIfAbsent(c.fecha.day, () => []).add(c);
      }
    }

    for (final citasDia in citasByDay.values) {
      citasDia.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    }

    const colWidths = {
      0: pw.FlexColumnWidth(1),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1),
      3: pw.FlexColumnWidth(1),
      4: pw.FlexColumnWidth(1),
      5: pw.FlexColumnWidth(1),
      6: pw.FlexColumnWidth(1),
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _header('Calendario — $monthTitle', patient, _orange, font, fontBold, logoSvg),
        pw.SizedBox(height: 16),
        pw.Table(
          columnWidths: colWidths,
          children: [
            pw.TableRow(
              children: List.generate(7, (i) {
                final isWk = i >= 5;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: isWk ? _orange : PdfColor.fromHex('E8E8E8'),
                        width: 2,
                      ),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      _dayFull[i],
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 13,
                        color: isWk ? _orange : PdfColor.fromHex('555555'),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          columnWidths: colWidths,
          children: List.generate(weekCount, (week) {
            return pw.TableRow(
              children: List.generate(7, (col) {
                final day = week * 7 + col - (firstWeekday - 1) + 1;
                if (day < 1 || day > daysInMonth) {
                  return pw.SizedBox(
                    height: rowH,
                    child: pw.Container(margin: const pw.EdgeInsets.all(2)),
                  );
                }

                final isToday = now.year == month.year && now.month == month.month && now.day == day;
                final dayCitas = citasByDay[day] ?? [];

                return pw.SizedBox(
                  height: rowH,
                  child: _calCell(day, isToday, dayCitas, col >= 5, font, fontBold),
                );
              }),
            );
          }),
        ),
        pw.SizedBox(height: 12),
        _calLegend(font),
        pw.SizedBox(height: 20),
        _footer(pageNum, totalPages, now, font, fontBold, logoSvg),
      ],
    );
  }

  pw.Widget _calCell(
    int day,
    bool isToday,
    List<Cita> citas,
    bool isWeekend,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final hasCita = citas.isNotEmpty;
    final PdfColor bg;
    final PdfColor border;
    final double borderW;
    final PdfColor dayColor;
    final double daySize;
    final pw.Font dayFont;

    if (isToday) {
      bg = _headerBg;
      border = _orange;
      borderW = 2;
      dayColor = _white;
      daySize = 20;
      dayFont = fontBold;
    } else if (hasCita) {
      bg = _bgAppt;
      border = _borderAppt;
      borderW = 2;
      dayColor = _orange;
      daySize = 18;
      dayFont = fontBold;
    } else if (isWeekend) {
      bg = _bgWeekend;
      border = _borderWeekend;
      borderW = 1;
      dayColor = _textMuted;
      daySize = 15;
      dayFont = font;
    } else {
      bg = _white;
      border = PdfColor.fromHex('E8E8E8');
      borderW = 1;
      dayColor = _textMuted;
      daySize = 15;
      dayFont = font;
    }

    return pw.Container(
      margin: const pw.EdgeInsets.all(2),
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: border, width: borderW),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$day',
            style: pw.TextStyle(font: dayFont, fontSize: daySize, color: dayColor),
          ),
          if (hasCita) ...[
            pw.SizedBox(height: 3),
            ...citas.take(3).map((c) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 2),
                padding: const pw.EdgeInsets.fromLTRB(5, 2, 5, 2),
                decoration: pw.BoxDecoration(
                  color: _orange,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      c.hora,
                      style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: _white),
                    ),
                    pw.Text(
                      c.especialidad,
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 7.5,
                        color: PdfColor(1, 1, 1, 0.9),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (citas.length > 3)
              pw.Text(
                '+${citas.length - 3} más',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 7.5,
                  color: isToday ? _white : _orange,
                ),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _calLegend(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F9F9F9'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          _legendItem('Cita programada', _bgAppt, _borderAppt, font),
          pw.SizedBox(width: 20),
          _legendItem('Hoy', _headerBg, _orange, font),
          pw.SizedBox(width: 20),
          _legendItem('Fin de semana', _bgWeekend, _borderWeekend, font),
        ],
      ),
    );
  }

  pw.Widget _legendItem(String label, PdfColor bg, PdfColor border, pw.Font font) {
    return pw.Row(
      children: [
        pw.Container(
          width: 16,
          height: 16,
          decoration: pw.BoxDecoration(
            color: bg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            border: pw.Border.all(color: border, width: 2),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            color: PdfColor.fromHex('555555'),
          ),
        ),
      ],
    );
  }
}
