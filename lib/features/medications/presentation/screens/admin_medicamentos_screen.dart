import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/core/services/pdf_export_service.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'package:aviso_vital_2/shared/widgets/content_widgets.dart';
import 'package:aviso_vital_2/data/repositories/medications_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_section_scaffold.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_section_stat_card.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_widgets.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'medicamento_detalle_screen.dart';

/// Pantalla: Gestión de Medicamentos
class AdminMedicamentosScreen extends StatefulWidget {
  static const String routeName = AppRoutes.adminMedicamentos;
  final bool showBackButton;

  const AdminMedicamentosScreen({super.key, this.showBackButton = true});

  @override
  State<AdminMedicamentosScreen> createState() =>
      _AdminMedicamentosScreenState();
}

class _AdminMedicamentosScreenState extends State<AdminMedicamentosScreen> {
  static const _medicationsRepository = MedicationsRepository();
  static const _userRepository = UserRepository();
  static const _pdfExportService = PdfExportService();
  bool _isExporting = false;
  final _searchCtrl = TextEditingController();
  List<Medicamento> _medicamentos = const [];
  String _filtro = 'todos';
  String _busqueda = '';
  bool _isLoading = true;
  String? _loadError;

  static const _filtros = [
    FilterChipData(label: 'Todos', value: 'todos'),
    FilterChipData(label: 'Stock bajo', value: 'stock_bajo'),
    FilterChipData(label: 'Activos', value: 'activos'),
  ];

  List<Medicamento> get _medicamentosFiltrados {
    var lista = _medicamentos;
    if (_busqueda.isNotEmpty) {
      lista = lista
          .where(
            (m) =>
                m.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
                m.dosis.toLowerCase().contains(_busqueda.toLowerCase()),
          )
          .toList();
    }
    return switch (_filtro) {
      'stock_bajo' => lista.where((m) => m.stockBajo).toList(),
      'activos' => lista.where((m) => m.activo).toList(),
      _ => lista,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadMedicamentos();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedicamentos({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final medications = await _medicationsRepository.fetchAll(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _medicamentos = medications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _medicamentos = _medicationsRepository.getAll();
        _isLoading = false;
        _loadError =
            'No se pudieron cargar los medicamentos desde Supabase. '
            'Se muestran datos mock.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_loadError!)));
    }
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final user = _userRepository.getCurrentUser();
      await _pdfExportService.exportMedicamentos(
        _medicamentos,
        nombrePaciente: user.nombre,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar el PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteMedication(String id) async {
    try {
      await _medicationsRepository.delete(id);
      if (!mounted) return;
      await _loadMedicamentos();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el medicamento: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _medicamentosFiltrados;
    final allMedications = _medicamentos;
    final stockBajoCount = allMedications.where((med) => med.stockBajo).length;
    final user = _userRepository.getCurrentUser();
    final hasBottomNav = !isAdminWideLayout(context);
    final pendingToday = _medicationsRepository.getPendingTodayCount();

    return AdminSectionScaffold(
      title: 'Medicamentos',
      subtitle: '${allMedications.length} activos · ${user.nombre}',
      compactHeader: true,
      onBack: widget.showBackButton ? () => Navigator.maybePop(context) : null,
      headerTrailing: _isExporting
          ? const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              color: AppColors.textSecondary,
              tooltip: 'Exportar PDF',
              onPressed: _medicamentos.isEmpty ? null : _exportPdf,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceRaised,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.surfaceBorder),
                ),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(34, 34),
              ),
            ),
      stats: Row(
        children: [
          Expanded(
            child: AdminSectionStatCard(
              value: '${allMedications.length}',
              label: 'Total',
              color: AppColors.amber,
              icon: Icons.medication_rounded,
              compact: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AdminSectionStatCard(
              value: '$stockBajoCount',
              label: 'Stock bajo',
              color: stockBajoCount > 0 ? AppColors.danger : AppColors.success,
              icon: stockBajoCount > 0
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              compact: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AdminSectionStatCard(
              value: '$pendingToday',
              label: 'Pendientes hoy',
              color: AppColors.warning,
              icon: Icons.schedule_rounded,
              compact: true,
            ),
          ),
        ],
      ),
      filters: SearchFilterBar(
        controller: _searchCtrl,
        hint: 'Buscar medicamento...',
        compact: true,
        filters: _filtros,
        activeFilter: _filtro,
        onFilterChanged: (v) => setState(() => _filtro = v),
        onSearch: (v) => setState(() => _busqueda = v),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _loadError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: lista.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: EmptyStateCard.noMedications(
                            onAdd: () => _showAddForm(context),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              _loadMedicamentos(forceRefresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              // FAB (56px) + margen (16px) + bottom nav (56px) + extra (32px) = 160px
                              160,
                            ),
                            itemCount: lista.length,
                            itemBuilder: (_, i) => MedicationCard(
                              medicamento: lista[i],
                              showActions: true,
                              compact: true,
                              forceStockBar: true,
                              onTap: () =>
                                  _openMedDetail(lista[i]),
                              onEdit: () => _showEditForm(context, lista[i]),
                              onDelete: () => ConfirmDialog.show(
                                context,
                                title: 'Eliminar medicamento',
                                message:
                                    '¿Seguro que desea eliminar ${lista[i].nombre}?',
                                confirmLabel: 'Eliminar',
                                isDestructive: true,
                                onConfirm: () => _deleteMedication(lista[i].id),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      primaryGlowColor: AppColors.amber,
      secondaryGlowColor: AppColors.haloSoft,
      primaryGlowAlignment: const Alignment(1, -0.95),
      secondaryGlowAlignment: const Alignment(-0.95, 0.1),
      intensity: 0.68,
      floatingActionButton: AdminSectionFab(
        color: AppColors.amber,
        foregroundColor: AppColors.textOnAmber,
        hasBottomNav: hasBottomNav,
        compact: true,
        onPressed: () => _showAddForm(context),
      ),
    );
  }

  Future<void> _openMedDetail(Medicamento med) async {
    final result = await Navigator.pushNamed(
      context,
      MedicamentoDetalleScreen.routeName,
      arguments: {'id': med.id},
    );
    if (!mounted) return;
    if (result == 'edit') _showEditForm(context, med);
  }

  Future<void> _showAddForm(BuildContext context) =>
      _showMedForm(context, medicamento: null);

  Future<void> _showEditForm(BuildContext context, Medicamento med) =>
      _showMedForm(context, medicamento: med);

  Future<void> _showMedForm(
    BuildContext context, {
    Medicamento? medicamento,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MedicamentoForm(medicamento: medicamento),
    );
    if (changed == true && mounted) {
      await _loadMedicamentos();
    }
  }
}

// ── Formulario añadir/editar ──────────────────────────────────────

class _MedicamentoForm extends StatefulWidget {
  final Medicamento? medicamento;
  const _MedicamentoForm({this.medicamento});

  @override
  State<_MedicamentoForm> createState() => _MedicamentoFormState();
}

class _MedicamentoFormState extends State<_MedicamentoForm> {
  static const _medicationsRepository = MedicationsRepository();
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _dosisCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _instruccionesCtrl = TextEditingController();
  Color _colorPastilla = AppColors.pillColors[0];
  FormaPastilla _formaPastilla = FormaPastilla.redonda;
  final _stockMinimoCtrl = TextEditingController(text: '7');
  final _notasCtrl = TextEditingController();
  final _intervaloDiasCtrl = TextEditingController(text: '2');
  int _tomasAlDia = 1;
  List<String> _horasToma = const ['09:00'];
  // Frequency pattern — 'daily' | 'cadaDias' | 'diasSemana'
  String _frecuenciaPatron = 'daily';
  List<int> _diasSemana = const [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicamento != null) {
      final m = widget.medicamento!;
      _nombreCtrl.text = m.nombre;
      _dosisCtrl.text = m.dosis;
      _stockCtrl.text = '${m.stockActual}';
      _instruccionesCtrl.text = m.instrucciones ?? '';
      _stockMinimoCtrl.text = '${m.stockMinimo}';
      _notasCtrl.text = m.notas ?? '';
      _colorPastilla = m.colorPastilla;
      _formaPastilla = m.formaPastilla;
      _horasToma = List<String>.from(
        m.horasToma.isEmpty ? const ['09:00'] : m.horasToma,
      )..sort(_compareHours);
      _tomasAlDia = _horasToma.length;
      if (m.frecuencia == FrecuenciaMed.cadaDias) {
        _frecuenciaPatron = 'cadaDias';
        _intervaloDiasCtrl.text = '${m.intervaloDias}';
      } else if (m.frecuencia == FrecuenciaMed.diasSemana) {
        _frecuenciaPatron = 'diasSemana';
        _diasSemana = List<int>.from(m.diasSemana);
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dosisCtrl.dispose();
    _stockCtrl.dispose();
    _instruccionesCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _notasCtrl.dispose();
    _intervaloDiasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHour(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _timeOfDayFromString(_horasToma[index]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.amber),
          ),
          child: child!,
        ),
      ),
    );
    if (selected == null) return;

    setState(() {
      _horasToma[index] = _formatTimeOfDay(selected);
      _horasToma.sort(_compareHours);
    });
  }

  void _updateTomasAlDia(int value) {
    setState(() {
      _tomasAlDia = value;
      final current = List<String>.from(_horasToma);
      if (current.length < value) {
        for (var i = current.length; i < value; i++) {
          current.add(_defaultHourForIndex(i));
        }
      } else if (current.length > value) {
        current.removeRange(value, current.length);
      }
      current.sort(_compareHours);
      _horasToma = current;
    });
  }

  FrecuenciaMed _frequencyFromDoseCount(int count) {
    return switch (count) {
      3 => FrecuenciaMed.cada8h,
      2 => FrecuenciaMed.cada12h,
      1 => FrecuenciaMed.cada24h,
      _ => FrecuenciaMed.segunPrescripcion,
    };
  }

  String _defaultHourForIndex(int index) {
    const defaults = ['09:00', '14:00', '21:00', '23:00', '07:00', '17:00'];
    if (index < defaults.length) return defaults[index];
    return '09:00';
  }

  TimeOfDay _timeOfDayFromString(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.firstOrNull ?? '') ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _compareHours(String a, String b) {
    final aParts = a.split(':');
    final bParts = b.split(':');
    final aMinutes =
        ((int.tryParse(aParts.firstOrNull ?? '') ?? 0) * 60) +
        (int.tryParse(aParts.length > 1 ? aParts[1] : '') ?? 0);
    final bMinutes =
        ((int.tryParse(bParts.firstOrNull ?? '') ?? 0) * 60) +
        (int.tryParse(bParts.length > 1 ? bParts[1] : '') ?? 0);
    return aMinutes.compareTo(bMinutes);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_horasToma.length != _tomasAlDia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revise las horas de toma antes de guardar.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final existing = widget.medicamento;
      final frecuencia = switch (_frecuenciaPatron) {
        'cadaDias' => FrecuenciaMed.cadaDias,
        'diasSemana' => FrecuenciaMed.diasSemana,
        _ => _frequencyFromDoseCount(_tomasAlDia),
      };
      final intervaloDias =
          int.tryParse(_intervaloDiasCtrl.text.trim()) ?? 2;

      if (_frecuenciaPatron == 'diasSemana' && _diasSemana.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleccione al menos un día de la semana.'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final medication = Medicamento(
        id: existing?.id ?? '',
        idUsuario: existing?.idUsuario ?? '',
        nombre: _nombreCtrl.text.trim(),
        dosis: _dosisCtrl.text.trim(),
        frecuencia: frecuencia,
        horasToma: List.unmodifiable(_horasToma),
        stockActual: int.tryParse(_stockCtrl.text.trim()) ?? 0,
        stockMinimo: int.tryParse(_stockMinimoCtrl.text.trim()) ?? 7,
        colorPastilla: _colorPastilla,
        formaPastilla: _formaPastilla,
        instrucciones: _instruccionesCtrl.text.trim().isEmpty
            ? null
            : _instruccionesCtrl.text.trim(),
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        activo: existing?.activo ?? true,
        fechaCreacion: existing?.fechaCreacion ?? DateTime.now(),
        ultimaEdicion: existing == null ? null : DateTime.now(),
        intervaloDias: intervaloDias,
        diasSemana: List.unmodifiable(_diasSemana),
      );

      if (existing == null) {
        await _medicationsRepository.create(medication);
      } else {
        await _medicationsRepository.update(medication);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el medicamento: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medicamento != null;
    final isCompactHeight = MediaQuery.of(context).size.height < 780;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.modal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: EdgeInsets.only(
                            bottom: isCompactHeight
                                ? AppSpacing.lg
                                : AppSpacing.xl,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder,
                            borderRadius: AppRadius.chip,
                          ),
                        ),
                      ),

                      Text(
                        isEdit ? 'Editar medicamento' : 'Añadir medicamento',
                        style: AppTextStyles.h3,
                      ),
                      SizedBox(
                        height: isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
                      ),

                    _FormSection(
                      title: 'Datos básicos',
                      compact: isCompactHeight,
                      child: Column(
                        children: [
                          _FormField(
                            controller: _nombreCtrl,
                            label: 'Nombre',
                            hint: 'Ej: Enalapril',
                            compact: isCompactHeight,
                            validator: (v) =>
                                v?.isEmpty == true ? 'Requerido' : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _FormField(
                                  controller: _dosisCtrl,
                                  label: 'Dosis',
                                  hint: 'Ej: 10 mg',
                                  compact: isCompactHeight,
                                  validator: (v) =>
                                      v?.isEmpty == true ? 'Requerido' : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _FormField(
                                  controller: _stockCtrl,
                                  label: 'Stock',
                                  hint: 'Unidades',
                                  keyboardType: TextInputType.number,
                                  compact: isCompactHeight,
                                  validator: (v) =>
                                      v?.isEmpty == true ? 'Requerido' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FormField(
                            controller: _stockMinimoCtrl,
                            label: 'Stock mínimo',
                            hint: 'Ej: 7',
                            keyboardType: TextInputType.number,
                            compact: isCompactHeight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _FormSection(
                      title: 'Frecuencia',
                      compact: isCompactHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patrón de repetición',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _FrequencyPatternPicker(
                            selected: _frecuenciaPatron,
                            onChanged: (value) =>
                                setState(() => _frecuenciaPatron = value),
                            compact: isCompactHeight,
                          ),
                          if (_frecuenciaPatron == 'cadaDias') ...[
                            const SizedBox(height: AppSpacing.md),
                            _FormField(
                              controller: _intervaloDiasCtrl,
                              label: 'Cada cuántos días',
                              hint: 'Ej: 2 (día sí, día no)',
                              keyboardType: TextInputType.number,
                              compact: isCompactHeight,
                              validator: (v) {
                                final n = int.tryParse(v?.trim() ?? '');
                                if (n == null || n < 2) {
                                  return 'Introduce un número ≥ 2';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (_frecuenciaPatron == 'diasSemana') ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Días de la semana',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _WeekdayChips(
                              selected: _diasSemana,
                              onChanged: (days) =>
                                  setState(() => _diasSemana = days),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _FormSection(
                      title: 'Toma',
                      compact: isCompactHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tomas al dia',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          DropdownButtonFormField<int>(
                            initialValue: _tomasAlDia,
                            items: List.generate(
                              6,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text('${index + 1}'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value != null) _updateTomasAlDia(value);
                            },
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Horas exactas',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ...List.generate(
                            _horasToma.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _horasToma.length - 1
                                    ? 0
                                    : AppSpacing.sm,
                              ),
                              child: _HourPickerTile(
                                label: 'Toma ${index + 1}',
                                value: _horasToma[index],
                                compact: isCompactHeight,
                                onTap: () => _pickHour(index),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FormField(
                            controller: _instruccionesCtrl,
                            label: 'Instrucciones (opcional)',
                            hint: 'Ej: Tomar con agua después de comer',
                            maxLines: 2,
                            compact: isCompactHeight,
                            secondary: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _FormSection(
                      title: 'Notas',
                      compact: isCompactHeight,
                      child: _FormField(
                        controller: _notasCtrl,
                        label: 'Notas (opcional)',
                        hint: 'Ej: Revisar receta en la próxima cita',
                        maxLines: 2,
                        compact: isCompactHeight,
                        secondary: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _FormSection(
                      title: 'Apariencia',
                      compact: isCompactHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forma',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _FormaChip(
                                forma: FormaPastilla.redonda,
                                selected: _formaPastilla,
                                label: 'Redonda',
                                compact: true,
                                onTap: () => setState(
                                  () => _formaPastilla = FormaPastilla.redonda,
                                ),
                              ),
                              _FormaChip(
                                forma: FormaPastilla.ovalada,
                                selected: _formaPastilla,
                                label: 'Ovalada',
                                compact: true,
                                onTap: () => setState(
                                  () => _formaPastilla = FormaPastilla.ovalada,
                                ),
                              ),
                              _FormaChip(
                                forma: FormaPastilla.capsula,
                                selected: _formaPastilla,
                                label: 'Cápsula',
                                compact: true,
                                onTap: () => setState(
                                  () => _formaPastilla = FormaPastilla.capsula,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Color',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppColors.pillColors
                                .map(
                                  (c) => GestureDetector(
                                    onTap: () =>
                                        setState(() => _colorPastilla = c),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _colorPastilla == c
                                              ? AppColors.amber
                                              : AppColors.surfaceBorder,
                                          width: _colorPastilla == c ? 2.5 : 1,
                                        ),
                                        boxShadow: _colorPastilla == c
                                            ? [
                                                BoxShadow(
                                                  color:
                                                      AppColors.amber.withValues(
                                                    alpha: 0.16,
                                                  ),
                                                  blurRadius: 10,
                                                  spreadRadius: 0.5,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: _colorPastilla == c
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 15,
                                              color: Colors.black54,
                                            )
                                          : null,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),

          // ── Botones sticky — siempre visibles ─────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: isEdit ? 'Guardar cambios' : 'Guardar',
                    isLoading: _isLoading,
                    onPressed: _guardar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool compact;
  final bool secondary;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.compact = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: secondary ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1
                  ? (compact ? 14 : 16)
                  : (compact ? 14 : 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;
  final bool compact;

  const _FormSection({
    required this.title,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        child,
      ],
    );
  }
}

class _FormaChip extends StatelessWidget {
  final FormaPastilla forma, selected;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  const _FormaChip({
    required this.forma,
    required this.selected,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = forma == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.amberSubtle : AppColors.surfaceRaised,
          borderRadius: AppRadius.chip,
          border: Border.all(
            color: isSelected ? AppColors.amber : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.amber : AppColors.textSecondary,
            fontSize: compact ? 12 : null,
          ),
        ),
      ),
    );
  }
}

class _HourPickerTile extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;
  final VoidCallback onTap;

  const _HourPickerTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.input,
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 14 : 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.input,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: AppTextStyles.body),
                ],
              ),
            ),
            const Icon(
              Icons.access_time_rounded,
              color: AppColors.amber,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Frequency pattern selector ────────────────────────────────────

class _FrequencyPatternPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool compact;

  const _FrequencyPatternPicker({
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  static const _options = [
    ('daily', 'Diaria'),
    ('cadaDias', 'Cada N días'),
    ('diasSemana', 'Días específicos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final isSelected = opt.$1 == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt.$1 == 'diasSemana' ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () => onChanged(opt.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(
                  vertical: compact ? 8 : 10,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.amberSubtle
                      : AppColors.surfaceRaised,
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.amber
                        : AppColors.surfaceBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt.$2,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: isSelected
                        ? AppColors.amber
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Weekday chip selector ─────────────────────────────────────────

class _WeekdayChips extends StatelessWidget {
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  const _WeekdayChips({required this.selected, required this.onChanged});

  static const _days = [
    (1, 'L'),
    (2, 'M'),
    (3, 'X'),
    (4, 'J'),
    (5, 'V'),
    (6, 'S'),
    (7, 'D'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _days.map((day) {
        final isSelected = selected.contains(day.$1);
        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selected);
            if (isSelected) {
              updated.remove(day.$1);
            } else {
              updated.add(day.$1);
              updated.sort();
            }
            onChanged(updated);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.amber : AppColors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.amber
                    : AppColors.surfaceBorder,
                width: isSelected ? 0 : 1,
              ),
            ),
            child: Center(
              child: Text(
                day.$2,
                style: AppTextStyles.label.copyWith(
                  color: isSelected
                      ? Colors.black87
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
