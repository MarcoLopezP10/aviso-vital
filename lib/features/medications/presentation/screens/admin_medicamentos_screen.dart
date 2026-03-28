import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
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

  Future<void> _loadMedicamentos() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final medications = await _medicationsRepository.fetchAll();
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
                          onRefresh: _loadMedicamentos,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              104,
                            ),
                            itemCount: lista.length,
                            itemBuilder: (_, i) => MedicationCard(
                              medicamento: lista[i],
                              showActions: true,
                              compact: true,
                              forceStockBar: true,
                              onTap: () => Navigator.pushNamed(
                                context,
                                MedicamentoDetalleScreen.routeName,
                                arguments: {'id': lista[i].id},
                              ),
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
  final _horaCtrl = TextEditingController();
  final _instruccionesCtrl = TextEditingController();
  FrecuenciaMed _frecuencia = FrecuenciaMed.cada24h;
  Color _colorPastilla = AppColors.pillColors[0];
  FormaPastilla _formaPastilla = FormaPastilla.redonda;
  final _stockMinimoCtrl = TextEditingController(text: '7');
  final _notasCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicamento != null) {
      final m = widget.medicamento!;
      _nombreCtrl.text = m.nombre;
      _dosisCtrl.text = m.dosis;
      _stockCtrl.text = '${m.stockActual}';
      _horaCtrl.text = m.horasToma.join(', ');
      _instruccionesCtrl.text = m.instrucciones ?? '';
      _stockMinimoCtrl.text = '${m.stockMinimo}';
      _notasCtrl.text = m.notas ?? '';
      _frecuencia = m.frecuencia;
      _colorPastilla = m.colorPastilla;
      _formaPastilla = m.formaPastilla;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dosisCtrl.dispose();
    _stockCtrl.dispose();
    _horaCtrl.dispose();
    _instruccionesCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final existing = widget.medicamento;
      final medication = Medicamento(
        id: existing?.id ?? '',
        idUsuario: existing?.idUsuario ?? '',
        nombre: _nombreCtrl.text.trim(),
        dosis: _dosisCtrl.text.trim(),
        frecuencia: _frecuencia,
        horasToma: _horaCtrl.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
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
                      bottom: isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
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
                  title: 'Toma',
                  compact: isCompactHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormField(
                        controller: _horaCtrl,
                        label: 'Horario de toma',
                        hint: 'Ej: 09:00, 21:00',
                        compact: isCompactHeight,
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
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Frecuencia',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: FrecuenciaMed.values
                            .map(
                              (f) => ChoiceChip(
                                label: Text(f.label),
                                selected: _frecuencia == f,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -2,
                                ),
                                onSelected: (_) =>
                                    setState(() => _frecuencia = f),
                              ),
                            )
                            .toList(),
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
                                onTap: () => setState(() => _colorPastilla = c),
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
                                              color: AppColors.amber.withValues(
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
                const SizedBox(height: AppSpacing.xl),

                PrimaryButton(
                  label: isEdit ? 'Guardar cambios' : 'Añadir medicamento',
                  isLoading: _isLoading,
                  onPressed: _guardar,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
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
