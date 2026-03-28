import 'package:flutter/material.dart';
import 'package:aviso_vital_2/app/router/app_routes.dart';
import 'package:aviso_vital_2/shared/theme/app_theme.dart';
import 'package:aviso_vital_2/shared/widgets/shared_widgets.dart';
import 'package:aviso_vital_2/shared/widgets/content_widgets.dart';
import 'package:aviso_vital_2/data/repositories/appointments_repository.dart';
import 'package:aviso_vital_2/data/repositories/user_repository.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_section_scaffold.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_section_stat_card.dart';
import 'package:aviso_vital_2/features/admin_home/presentation/widgets/admin_widgets.dart';
import 'package:aviso_vital_2/data/models/models.dart';
import 'cita_detalle_screen.dart';

/// Pantalla: Gestión de Citas Médicas
class AdminCitasScreen extends StatefulWidget {
  static const String routeName = AppRoutes.adminCitas;
  final bool showBackButton;

  const AdminCitasScreen({super.key, this.showBackButton = true});

  @override
  State<AdminCitasScreen> createState() => _AdminCitasScreenState();
}

class _AdminCitasScreenState extends State<AdminCitasScreen> {
  static const _appointmentsRepository = AppointmentsRepository();
  static const _userRepository = UserRepository();
  final _searchCtrl = TextEditingController();
  String _filtro = 'proximas';
  List<Cita> _citas = const [];
  bool _isLoading = true;
  String? _loadError;

  static const _filtros = [
    FilterChipData(label: 'Próximas', value: 'proximas'),
    FilterChipData(label: 'Hoy', value: 'hoy'),
    FilterChipData(label: 'Pasadas', value: 'pasadas'),
  ];

  List<Cita> get _citasFiltradas {
    final busqueda = _searchCtrl.text.toLowerCase();
    var lista = _citas;
    if (busqueda.isNotEmpty) {
      lista = lista
          .where(
            (c) =>
                c.especialidad.toLowerCase().contains(busqueda) ||
                c.lugar.toLowerCase().contains(busqueda),
          )
          .toList();
    }
    return switch (_filtro) {
      'hoy' => lista.where((c) => c.esHoy).toList(),
      'pasadas' => lista.where((c) => c.esPasada).toList(),
      _ => lista.where((c) => !c.esPasada).toList(),
    };
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final appointments = await _appointmentsRepository.fetchAll();
      if (!mounted) return;
      setState(() {
        _citas = appointments;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _citas = _appointmentsRepository.getAll();
        _isLoading = false;
        _loadError =
            'No se pudieron cargar las citas desde Supabase. '
            'Se muestran datos locales.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_loadError!)));
    }
  }

  Future<void> _deleteAppointment(String id) async {
    try {
      await _appointmentsRepository.delete(id);
      if (!mounted) return;
      await _loadAppointments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la cita: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _citasFiltradas;
    final allAppointments = _citas;
    final user = _userRepository.getCurrentUser();
    final citasHoy = allAppointments.where((c) => c.esHoy).length;
    final proximas = allAppointments
        .where((c) => !c.esPasada && !c.esHoy)
        .length;
    final hasBottomNav = !isAdminWideLayout(context);
    final isCompactMobile =
        MediaQuery.of(context).size.width < 430 ||
        MediaQuery.of(context).size.height < 860;

    return AdminSectionScaffold(
      title: 'Citas Médicas',
      subtitle: '${allAppointments.length} registradas · ${user.nombre}',
      onBack: widget.showBackButton ? () => Navigator.maybePop(context) : null,
      compactHeader: true,
      stats: Row(
        children: [
          Expanded(
            child: AdminSectionStatCard(
              value: '$citasHoy',
              label: 'Hoy',
              color: AppColors.orange,
              icon: Icons.today_rounded,
              compact: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AdminSectionStatCard(
              value: '$proximas',
              label: 'Próximas',
              color: AppColors.info,
              icon: Icons.event_rounded,
              compact: true,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AdminSectionStatCard(
              value: '${allAppointments.length}',
              label: 'Total',
              color: AppColors.amber,
              icon: Icons.list_rounded,
              compact: true,
            ),
          ),
        ],
      ),
      filters: SearchFilterBar(
        controller: _searchCtrl,
        hint: 'Buscar especialidad o centro...',
        filters: _filtros,
        activeFilter: _filtro,
        onFilterChanged: (v) => setState(() => _filtro = v),
        onSearch: (_) => setState(() {}),
        compact: true,
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
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: EmptyStateCard.noAppointments(
                            onAdd: () => _showAddForm(context),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAppointments,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              isCompactMobile ? AppSpacing.lg : AppSpacing.xl,
                              AppSpacing.xs,
                              isCompactMobile ? AppSpacing.lg : AppSpacing.xl,
                              hasBottomNav ? 128 : AppSpacing.xl,
                            ),
                            itemCount: lista.length,
                            itemBuilder: (_, i) => AppointmentCard(
                              cita: lista[i],
                              showActions: true,
                              compact: true,
                              onTap: () => Navigator.pushNamed(
                                context,
                                CitaDetalleScreen.routeName,
                                arguments: {'id': lista[i].id},
                              ),
                              onEdit: () =>
                                  _showAddForm(context, cita: lista[i]),
                              onDelete: () => ConfirmDialog.show(
                                context,
                                title: 'Eliminar cita',
                                message:
                                    '¿Desea eliminar la cita de ${lista[i].especialidad}?',
                                confirmLabel: 'Eliminar',
                                isDestructive: true,
                                onConfirm: () =>
                                    _deleteAppointment(lista[i].id),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      primaryGlowColor: AppColors.orange,
      secondaryGlowColor: AppColors.haloSoft,
      primaryGlowAlignment: const Alignment(1, -0.92),
      secondaryGlowAlignment: const Alignment(-1, 0.18),
      intensity: 0.66,
      floatingActionButton: AdminSectionFab(
        color: AppColors.orange,
        foregroundColor: Colors.white,
        hasBottomNav: hasBottomNav,
        compact: true,
        onPressed: () => _showAddForm(context),
      ),
    );
  }

  Future<void> _showAddForm(BuildContext context, {Cita? cita}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CitaForm(cita: cita),
    );
    if (changed == true && mounted) {
      await _loadAppointments();
    }
  }
}

class _CitaForm extends StatefulWidget {
  final Cita? cita;
  const _CitaForm({this.cita});

  @override
  State<_CitaForm> createState() => _CitaFormState();
}

class _CitaFormState extends State<_CitaForm> {
  static const _appointmentsRepository = AppointmentsRepository();
  final _formKey = GlobalKey<FormState>();
  final _especialidadCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  DateTime? _fecha;
  TimeOfDay? _hora;
  bool _rec24h = true, _rec3h = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final appointment = widget.cita;
    if (appointment != null) {
      _especialidadCtrl.text = appointment.especialidad;
      _lugarCtrl.text = appointment.lugar;
      _direccionCtrl.text = appointment.direccion ?? '';
      _telefonoCtrl.text = appointment.telefono ?? '';
      _notasCtrl.text = appointment.notas ?? '';
      _fecha = appointment.fecha;
      final parts = appointment.hora.split(':');
      _hora = TimeOfDay(
        hour: int.tryParse(parts.firstOrNull ?? '') ?? 10,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
      );
      _rec24h = appointment.recordatorio24h;
      _rec3h = appointment.recordatorio3h;
    }
  }

  @override
  void dispose() {
    _especialidadCtrl.dispose();
    _lugarCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.orange),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _fecha = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.orange),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _hora = t);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _fecha == null || _hora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fecha y hora para la cita.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final existing = widget.cita;
      final date = DateTime(
        _fecha!.year,
        _fecha!.month,
        _fecha!.day,
        _hora!.hour,
        _hora!.minute,
      );

      final appointment = Cita(
        id: existing?.id ?? '',
        idUsuario: existing?.idUsuario ?? '',
        especialidad: _especialidadCtrl.text.trim(),
        lugar: _lugarCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty
            ? null
            : _direccionCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty
            ? null
            : _telefonoCtrl.text.trim(),
        fecha: date,
        hora:
            '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}',
        estado: _statusFromDate(date),
        recordatorio24h: _rec24h,
        recordatorio3h: _rec3h,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        fechaCreacion: existing?.fechaCreacion ?? DateTime.now(),
      );

      if (existing == null) {
        await _appointmentsRepository.create(appointment);
      } else {
        await _appointmentsRepository.update(appointment);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la cita: $error')),
      );
    }
  }

  EstadoCita _statusFromDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return EstadoCita.hoy;
    }
    return date.isBefore(now) ? EstadoCita.pasada : EstadoCita.proxima;
  }

  @override
  Widget build(BuildContext context) {
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
                  widget.cita == null ? 'Añadir cita' : 'Editar cita',
                  style: AppTextStyles.h3,
                ),
                SizedBox(
                  height: isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
                ),

                _FormSection(
                  title: 'Datos de la cita',
                  compact: isCompactHeight,
                  child: Column(
                    children: [
                      _FormField(
                        controller: _especialidadCtrl,
                        label: 'Especialidad',
                        hint: 'Ej: Cardiología',
                        compact: isCompactHeight,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FormField(
                        controller: _lugarCtrl,
                        label: 'Centro / Hospital',
                        hint: 'Ej: Centro de Salud Norte',
                        compact: isCompactHeight,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FormField(
                        controller: _direccionCtrl,
                        label: 'Dirección (opcional)',
                        hint: 'Ej: Calle Mayor 12, Planta 2',
                        compact: isCompactHeight,
                        secondary: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FormField(
                        controller: _telefonoCtrl,
                        label: 'Teléfono (opcional)',
                        hint: 'Ej: 912345678',
                        compact: isCompactHeight,
                        secondary: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
                ),

                _FormSection(
                  title: 'Programación',
                  compact: isCompactHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _PickerButton(
                          label: 'Fecha',
                          value: _fecha != null
                              ? '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'
                              : 'Seleccionar',
                          icon: Icons.calendar_today_rounded,
                          compact: isCompactHeight,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PickerButton(
                          label: 'Hora',
                          value: _hora != null
                              ? '${_hora!.hour.toString().padLeft(2, '0')}:${_hora!.minute.toString().padLeft(2, '0')}'
                              : 'Seleccionar',
                          icon: Icons.access_time_rounded,
                          compact: isCompactHeight,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
                ),

                _FormSection(
                  title: 'Recordatorios',
                  compact: isCompactHeight,
                  child: Container(
                    padding: EdgeInsets.all(
                      isCompactHeight ? AppSpacing.sm : AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.surface, AppColors.surfaceFloating],
                      ),
                      borderRadius: AppRadius.card,
                      border: Border.all(
                        color: AppColors.surfaceBorder.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Column(
                      children: [
                        _SwitchRow(
                          label: '24 horas antes',
                          subtitle: 'Aviso previo para preparar la cita',
                          value: _rec24h,
                          compact: isCompactHeight,
                          onChanged: (v) => setState(() => _rec24h = v),
                        ),
                        Divider(
                          height: isCompactHeight ? 12 : 16,
                          color: AppColors.surfaceBorder.withValues(alpha: 0.7),
                        ),
                        _SwitchRow(
                          label: '3 horas antes',
                          subtitle: 'Recordatorio cercano a la salida',
                          value: _rec3h,
                          compact: isCompactHeight,
                          onChanged: (v) => setState(() => _rec3h = v),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: isCompactHeight ? AppSpacing.lg : AppSpacing.xl,
                ),

                _FormSection(
                  title: 'Notas',
                  compact: isCompactHeight,
                  child: _FormField(
                    controller: _notasCtrl,
                    label: 'Notas (opcional)',
                    hint: 'Ej: Traer resultados del análisis',
                    maxLines: 2,
                    compact: isCompactHeight,
                    secondary: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                PrimaryButton(
                  label: widget.cita == null
                      ? 'Añadir cita'
                      : 'Guardar cambios',
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
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
  final bool compact;
  final bool secondary;
  final String? Function(String?)? validator;
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.compact = false,
    this.secondary = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: secondary ? AppColors.textTertiary : AppColors.textSecondary,
          fontSize: compact ? 12 : null,
        ),
      ),
      SizedBox(height: compact ? 4 : 6),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: maxLines > 1 ? (compact ? 14 : 16) : (compact ? 14 : 18),
          ),
        ),
      ),
    ],
  );
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTextStyles.overline.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
      SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
      child,
    ],
  );
}

class _PickerButton extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool compact;
  final VoidCallback onTap;
  const _PickerButton({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          fontSize: compact ? 12 : null,
        ),
      ),
      SizedBox(height: compact ? 4 : 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: compact ? 50 : 54,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.input,
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.textTertiary,
                size: compact ? 17 : 18,
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: compact ? 14 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final bool compact;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.label,
    this.subtitle,
    required this.value,
    this.compact = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontSize: compact ? 13 : null,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: compact ? 11 : null,
                ),
              ),
            ],
          ],
        ),
      ),
      Transform.scale(
        scale: compact ? 0.86 : 0.94,
        child: Switch(value: value, onChanged: onChanged),
      ),
    ],
  );
}
