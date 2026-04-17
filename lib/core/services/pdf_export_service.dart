import 'package:aviso_vital_2/data/models/models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Genera y comparte PDFs de medicamentos y citas.
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

  /// Exporta la lista de medicamentos como PDF.
  Future<void> exportMedicamentos(
    List<Medicamento> medicamentos, {
    String? nombrePaciente,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: await PdfGoogleFonts.interRegular()),
        build: (ctx) => [
          _header('Lista de Medicamentos', nombrePaciente),
          pw.SizedBox(height: 20),
          _generatedAt(),
          pw.SizedBox(height: 24),
          if (medicamentos.isEmpty)
            _emptyState('No hay medicamentos registrados.')
          else
            ...medicamentos.map((m) => _medicationRow(m)),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'medicamentos_aviso_vital.pdf',
    );
  }

  /// Exporta la lista de citas como PDF.
  Future<void> exportCitas(
    List<Cita> citas, {
    String? nombrePaciente,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: await PdfGoogleFonts.interRegular()),
        build: (ctx) => [
          _header('Lista de Citas Médicas', nombrePaciente),
          pw.SizedBox(height: 20),
          _generatedAt(),
          pw.SizedBox(height: 24),
          if (citas.isEmpty)
            _emptyState('No hay citas registradas.')
          else
            ...citas.map((c) => _citaRow(c)),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'citas_aviso_vital.pdf',
    );
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
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Aviso Vital',
                    style: pw.TextStyle(
                      color: _amber,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (patient != null && patient.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Paciente: $patient',
              style: pw.TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _generatedAt() {
    final now = DateTime.now();
    final label =
        'Generado el ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} a las ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return pw.Text(
      label,
      style: pw.TextStyle(color: _muted, fontSize: 10),
    );
  }

  pw.Widget _emptyState(String msg) => pw.Center(
        child: pw.Text(msg, style: pw.TextStyle(color: _muted, fontSize: 12)),
      );

  pw.Widget _medicationRow(Medicamento m) {
    final stockColor = m.stockBajo ? _red : (m.stockActual >= m.stockMinimo * 2 ? _green : _yellow);

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
                style: pw.TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: stockColor,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(99)),
                ),
                child: pw.Text(
                  m.stockBajo ? 'Stock bajo' : 'Stock OK',
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${m.dosis}  ·  ${m.resumenTomas}',
            style: pw.TextStyle(color: _muted, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Stock actual: ${m.stockActual}  ·  Mínimo: ${m.stockMinimo}',
            style: pw.TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _citaRow(Cita c) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final fechaLabel =
        '${c.fecha.day.toString().padLeft(2, '0')} ${meses[c.fecha.month - 1]} ${c.fecha.year}';

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
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                  color: c.esHoy ? _amber : PdfColor.fromHex('334155')),
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
                pw.Text(
                  c.lugar,
                  style: pw.TextStyle(color: _muted, fontSize: 11),
                ),
                if (c.direccion != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    c.direccion!,
                    style: pw.TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Text(
                  fechaLabel,
                  style: pw.TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
