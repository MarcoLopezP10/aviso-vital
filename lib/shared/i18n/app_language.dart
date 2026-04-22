import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  es(Locale('es'), 'ES'),
  en(Locale('en'), 'EN');

  final Locale locale;
  final String label;

  const AppLanguage(this.locale, this.label);

  static AppLanguage fromCode(String? code) =>
      code == AppLanguage.en.locale.languageCode
      ? AppLanguage.en
      : AppLanguage.es;
}

class AppLocaleController {
  AppLocaleController._();

  static const _storageKey = 'aviso_vital_language';
  static final AppLocaleController instance = AppLocaleController._();

  final ValueNotifier<AppLanguage> language = ValueNotifier(AppLanguage.es);

  AppLanguage get current => language.value;
  Locale get locale => current.locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    language.value = AppLanguage.fromCode(prefs.getString(_storageKey));
  }

  Future<void> setLanguage(AppLanguage next) async {
    if (language.value == next) return;
    language.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, next.locale.languageCode);
  }
}

extension AppLanguageContext on BuildContext {
  AppStrings get t => AppStrings.of(this);
}

class AppStrings {
  final AppLanguage language;

  const AppStrings._(this.language);

  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return AppStrings._(AppLanguage.fromCode(code));
  }

  static AppStrings get current =>
      AppStrings._(AppLocaleController.instance.current);

  bool get isEnglish => language == AppLanguage.en;

  String text(String spanish) {
    if (!isEnglish) return spanish;
    return _englishTexts[spanish] ?? spanish;
  }

  static const Map<String, String> _englishTexts = {
    'Inicio': 'Home',
    'Medicamentos': 'Medications',
    'Medicamento': 'Medication',
    'Citas': 'Appointments',
    'Alertas': 'Alerts',
    'Panel de control': 'Control panel',
    'Seguimiento activo': 'Active monitoring',
    'Resumen diario del cuidado': 'Daily care summary',
    'Estado dispositivo': 'Device status',
    'Estado del dispositivo': 'Device status',
    'Cerrar sesión': 'Log out',
    'Salir': 'Exit',
    '¿Está seguro de que quiere salir?': 'Are you sure you want to exit?',
    'Cancelar': 'Cancel',
    'Guardar': 'Save',
    'Guardar cambios': 'Save changes',
    'Editar': 'Edit',
    'Eliminar': 'Delete',
    'Eliminar cita': 'Delete appointment',
    'Eliminar medicamento': 'Delete medication',
    'Confirmada': 'Confirmed',
    'Confirmadas': 'Confirmed',
    'Omitida': 'Missed',
    'Expirada': 'Expired',
    'Pendiente': 'Pending',
    'Stock bajo': 'Low stock',
    'Hoy': 'Today',
    'Ayer': 'Yesterday',
    'Total': 'Total',
    'Todos': 'All',
    'Activos': 'Active',
    'Próximas': 'Upcoming',
    'Pasadas': 'Past',
    'Lo importante de hoy': 'Today at a glance',
    'Resumen general': 'General summary',
    'Gestión': 'Management',
    'Actividad reciente': 'Recent activity',
    'Ver todo': 'View all',
    'Ver historial': 'View history',
    'Historial de alertas': 'Alert history',
    'Medicación': 'Medication',
    'Adherencia': 'Adherence',
    'Adherencia esta semana': 'This week adherence',
    'Pendientes hoy': 'Pending today',
    'Sin confirmar': 'Unconfirmed',
    'En orden': 'In order',
    'Reposición': 'Restock',
    'Correcto': 'Correct',
    'Cita hoy': 'Appointment today',
    'Sin citas': 'No appointments',
    'Administrador inicial': 'Initial administrator',
    'Citas Médicas': 'Medical appointments',
    'Exportar PDF': 'Export PDF',
    'PDF descargado correctamente': 'PDF downloaded successfully',
    'Buscar especialidad o centro...': 'Search specialty or center...',
    'Buscar medicamento...': 'Search medication...',
    'Sin medicamentos': 'No medications',
    'Añada el primer medicamento para empezar a gestionar las alertas':
        'Add the first medication to start managing alerts',
    'Añadir medicamento': 'Add medication',
    'Editar medicamento': 'Edit medication',
    'Sin citas próximas': 'No upcoming appointments',
    'No hay citas programadas. Añada una cuando la tenga.':
        'There are no scheduled appointments. Add one when you have it.',
    'Añadir cita': 'Add appointment',
    'Editar cita': 'Edit appointment',
    'Sin alertas recientes': 'No recent alerts',
    'Aquí aparecerá el historial de confirmaciones y omisiones':
        'Confirmation and missed-dose history will appear here',
    'Sin actividad reciente': 'No recent activity',
    'La actividad aparecerá aquí en tiempo real':
        'Activity will appear here in real time',
    'Dispositivo no vinculado': 'Device not linked',
    'Vincule el móvil de Carmen para empezar a enviarle alertas':
        'Link Carmen’s phone to start sending alerts',
    'Vincular dispositivo': 'Link device',
    'Dispositivo conectado': 'Device connected',
    'Sin conexión': 'Offline',
    'Alertas activas': 'Active alerts',
    'Desvincular dispositivo': 'Unlink device',
    'Sin usuario vinculado': 'No linked user',
    'Usuario vinculado': 'Linked user',
    'Conectado': 'Connected',
    'Sin usuario mayor vinculado todavía': 'No older user linked yet',
    'CÓDIGO DE VINCULACIÓN': 'LINK CODE',
    'Código activo': 'Active code',
    'Copiar': 'Copy',
    'ESTADO DE ALERTAS': 'ALERT STATUS',
    'Alertas de medicación': 'Medication alerts',
    'Alertas de citas médicas': 'Medical appointment alerts',
    'Alertas de stock bajo': 'Low stock alerts',
    'Código copiado al portapapeles': 'Code copied to clipboard',
    'No se pudo cargar el perfil del administrador.':
        'Could not load the administrator profile.',
    'Modo Usuario': 'User mode',
    'Conéctese con su\nadministrador': 'Connect with your\nadministrator',
    'La vinculación real entre administrador y usuario se hace siempre con el código manual de Aviso Vital.':
        'The real link between administrator and user is always made with the manual Aviso Vital code.',
    'Pida al administrador su código de vinculación.':
        'Ask the administrator for their link code.',
    'Introduzca ese código en la siguiente pantalla.':
        'Enter that code on the next screen.',
    'A partir de ahí verá sus recordatorios en tiempo real.':
        'From there you will see your reminders in real time.',
    'Introducir código del administrador': 'Enter administrator code',
    'El acceso por QR queda desactivado para evitar vinculaciones de prueba.':
        'QR access is disabled to avoid test links.',
    'Código manual': 'Manual code',
    'Introduzca el código\nde su administrador':
        'Enter your administrator’s\ncode',
    'El administrador puede encontrarlo en la pantalla de inicio':
        'The administrator can find it on the home screen',
    'Formato del código': 'Code format',
    'Pegar código': 'Paste code',
    'Código incorrecto o no disponible. Inténtelo de nuevo.':
        'Incorrect or unavailable code. Try again.',
    'Verificar código': 'Verify code',
    'Introduzca el código real de vinculación del perfil en Supabase':
        'Enter the real profile link code from Supabase',
    'Escanear código QR': 'Scan QR code',
    'Coloque el código dentro del escáner': 'Place the code inside the scanner',
    'Simular detección QR': 'Simulate QR detection',
    'Su cuidador ya puede ayudarle a gestionar medicamentos y citas médicas':
        'Your caregiver can now help manage medications and medical appointments',
    'Continuar': 'Continue',
    '¿Qué ocurrirá ahora?': 'What happens now?',
    'Recibirá avisos cuando sea la hora de tomar su medicación':
        'You will receive alerts when it is time to take your medication',
    'Le recordaremos sus citas médicas con antelación':
        'We will remind you of medical appointments in advance',
    'Solo tendrá que pulsar un botón para confirmar':
        'You will only need to tap one button to confirm',
    'Detalle de cita': 'Appointment details',
    'Cita no encontrada': 'Appointment not found',
    'Centro': 'Center',
    'Dirección': 'Address',
    'Teléfono': 'Phone',
    'RECORDATORIOS': 'REMINDERS',
    'NOTAS': 'NOTES',
    'Activo': 'Active',
    'Desactivado': 'Disabled',
    '24 horas antes': '24 hours before',
    '3 horas antes': '3 hours before',
    'Datos de la cita': 'Appointment details',
    'Especialidad': 'Specialty',
    'Ej: Cardiología': 'E.g. Cardiology',
    'Centro / Hospital': 'Center / Hospital',
    'Ej: Centro de Salud Norte': 'E.g. North Health Center',
    'Dirección (opcional)': 'Address (optional)',
    'Ej: Calle Mayor 12, Planta 2': 'E.g. Main Street 12, Floor 2',
    'Teléfono (opcional)': 'Phone (optional)',
    'Ej: 912345678': 'E.g. 912345678',
    'Programación': 'Schedule',
    'Fecha': 'Date',
    'Hora': 'Time',
    'Seleccionar': 'Select',
    'Recordatorios': 'Reminders',
    'Aviso previo para preparar la cita':
        'Advance alert to prepare the appointment',
    'Recordatorio cercano a la salida': 'Reminder close to departure',
    'Notas': 'Notes',
    'Notas (opcional)': 'Notes (optional)',
    'Ej: Traer resultados del análisis': 'E.g. Bring test results',
    'Selecciona fecha y hora para la cita.':
        'Select a date and time for the appointment.',
    'Medicamento no encontrado': 'Medication not found',
    'Información': 'Information',
    'Tomas': 'Doses',
    'Patrón': 'Pattern',
    'Horario': 'Schedule',
    'Instrucciones': 'Instructions',
    'Registro': 'Record',
    'Añadido': 'Added',
    'Última edición': 'Last edit',
    'STOCK': 'STOCK',
    'Stock bajo — recuerda reponerlo pronto':
        'Low stock — remember to restock soon',
    'Datos básicos': 'Basic data',
    'Nombre': 'Name',
    'Ej: Enalapril': 'E.g. Enalapril',
    'Dosis': 'Dose',
    'Ej: 10 mg': 'E.g. 10 mg',
    'Stock': 'Stock',
    'Unidades': 'Units',
    'Stock mínimo': 'Minimum stock',
    'Ej: 7': 'E.g. 7',
    'Frecuencia': 'Frequency',
    'Patrón de repetición': 'Repeat pattern',
    'Cada cuántos días': 'Every how many days',
    'Ej: 2 (día sí, día no)': 'E.g. 2 (every other day)',
    'Días de la semana': 'Days of the week',
    'Toma': 'Dose',
    'Tomas al dia': 'Doses per day',
    'Horas exactas': 'Exact times',
    'Instrucciones (opcional)': 'Instructions (optional)',
    'Ej: Tomar con agua después de comer': 'E.g. Take with water after eating',
    'Ej: Revisar receta en la próxima cita':
        'E.g. Review prescription at the next appointment',
    'Apariencia': 'Appearance',
    'Forma': 'Shape',
    'Redonda': 'Round',
    'Ovalada': 'Oval',
    'Cápsula': 'Capsule',
    'Color': 'Color',
    'Revise las horas de toma antes de guardar.':
        'Review the dose times before saving.',
    'Seleccione al menos un día de la semana.':
        'Select at least one day of the week.',
    'Diaria': 'Daily',
    'Cada N días': 'Every N days',
    'Días específicos': 'Specific days',
    'Cada 8h': 'Every 8h',
    'Cada 12h': 'Every 12h',
    'Cada 24h': 'Every 24h',
    'Según prescripción': 'As prescribed',
    'Correo electrónico o teléfono': 'Email or phone',
    'Introduzca el código': 'Enter the code',
    'Registrarse': 'Sign up',
    'Siguiente': 'Next',
    '¿Ha olvidado su contraseña?': 'Forgot your password?',
    '¿Ya tiene cuenta? Inicie sesión': 'Already have an account? Sign in',
    '¿No tiene cuenta? Regístrese': 'No account? Sign up',
    'Cambiar de proveedor': 'Change provider',
    'Crear cuenta': 'Create account',
    'Iniciar sesión': 'Sign in',
    'Mostrar': 'Show',
    'Ocultar': 'Hide',
    'Acceso seguro con Apple': 'Secure access with Apple',
    'Acceso seguro y sincronización de medicación, citas y alertas.':
        'Secure access and synchronization for medication, appointments and alerts.',
    'Cree su cuenta con Facebook': 'Create your account with Facebook',
    'Acceda con su cuenta de Facebook': 'Access with your Facebook account',
    'Cree su cuenta con Apple': 'Create your account with Apple',
    'Continúe con su Apple ID': 'Continue with your Apple ID',
    'con Google para sincronizar su cuenta de Aviso Vital':
        'with Google to sync your Aviso Vital account',
    'con Google para seguir con sus recordatorios':
        'with Google to continue with your reminders',
    'Al continuar aceptas los términos de uso y la política de privacidad de Aviso Vital.':
        'By continuing, you accept the terms of use and privacy policy of Aviso Vital.',
    'Tomas completadas': 'Doses completed',
    'Todo al día, no tiene tomas pendientes':
        'All set, you have no pending doses',
    'Le avisaremos cuando llegue la hora': 'We will alert you when it is time',
    'Adherencia semanal': 'Weekly adherence',
  };

  String get appName => 'Aviso Vital';
  String get languageTooltip =>
      isEnglish ? 'Change language' : 'Cambiar idioma';

  String get supabaseConfigTitle => isEnglish
      ? 'Incomplete Supabase configuration'
      : 'Configuración de Supabase incompleta';
  String get supabaseConfigExample => isEnglish
      ? 'Example: flutter run --dart-define-from-file=env/dev.json'
      : 'Ejemplo: flutter run --dart-define-from-file=env/dev.json';

  String get chooseAccess => isEnglish
      ? 'Choose how you want to access Aviso Vital.'
      : 'Elija cómo quiere acceder a Aviso Vital.';
  String get clearReminders =>
      isEnglish ? 'Clear reminders' : 'Recordatorios claros';
  String get organizedAppointments =>
      isEnglish ? 'Organized appointments' : 'Citas organizadas';
  String get dailySupport => isEnglish ? 'Daily support' : 'Apoyo diario';
  String get selectProfile =>
      isEnglish ? 'Select your profile' : 'Seleccione su perfil';
  String get userRoleTitle => isEnglish ? 'I am a user' : 'Soy usuario';
  String get userRoleSubtitle => isEnglish
      ? 'I receive reminders and alerts'
      : 'Recibo recordatorios y avisos';
  String get adminRoleTitle =>
      isEnglish ? 'I am an administrator' : 'Soy administrador';
  String get adminRoleSubtitle => isEnglish
      ? 'I manage medication and appointments'
      : 'Gestiono medicación y citas';

  String get email => 'Email';
  String get password => isEnglish ? 'Password' : 'Contraseña';
  String get confirmPassword =>
      isEnglish ? 'Confirm password' : 'Confirmar contraseña';
  String get adminCode =>
      isEnglish ? 'Administrator code' : 'Código del administrador';
  String get enterEmail =>
      isEnglish ? 'Enter your email' : 'Introduzca su email';
  String get invalidEmail => isEnglish ? 'Invalid email' : 'Email no válido';
  String get requiredField => isEnglish ? 'Required' : 'Requerido';
  String get enterPassword =>
      isEnglish ? 'Enter your password' : 'Introduzca su contraseña';
  String get createPassword =>
      isEnglish ? 'Enter a password' : 'Introduce una contraseña';
  String get minSixChars =>
      isEnglish ? 'Minimum 6 characters' : 'Mínimo 6 caracteres';
  String get confirmPasswordError =>
      isEnglish ? 'Confirm your password' : 'Confirme la contraseña';
  String get passwordsDontMatch =>
      isEnglish ? 'Passwords do not match' : 'Las contraseñas no coinciden';
  String get createAccount => isEnglish ? 'Create account' : 'Crear cuenta';
  String get signIn => isEnglish ? 'Sign in' : 'Iniciar sesión';
  String get noAccountPrompt =>
      isEnglish ? 'No account? ' : '¿No tiene cuenta? ';
  String get hasAccountPrompt =>
      isEnglish ? 'Already have an account? ' : '¿Ya tiene cuenta? ';
  String get continueWith => isEnglish ? 'or continue with' : 'o continuar con';
  String get or => isEnglish ? 'or' : 'o';
  String continueWithProvider(String provider) =>
      isEnglish ? 'Continue with $provider' : 'Continuar con $provider';

  String get adminAccess =>
      isEnglish ? 'Administrator access' : 'Acceso Administrador';
  String get userAccess => isEnglish ? 'User access' : 'Acceso Usuario';
  String get welcomeBack =>
      isEnglish ? 'Welcome\nback' : 'Bienvenido\nde nuevo';
  String get adminLoginDescription => isEnglish
      ? 'Manage medication, appointments and alerts from a clear, secure panel.'
      : 'Gestiona medicación, citas y alertas desde un panel claro y seguro.';
  String get forgotPassword =>
      isEnglish ? 'Forgot your password?' : '¿Ha olvidado la contraseña?';
  String get adminSignIn => isEnglish ? 'Sign in' : 'Iniciar Sesión';
  String get userLoginTitle =>
      isEnglish ? 'Your alert\nspace' : 'Su espacio\nde avisos';
  String get userLoginDescription => isEnglish
      ? 'Access your reminders and the real-time simulation with your account.'
      : 'Acceda a sus recordatorios y a la simulación en tiempo real con su cuenta.';
  String get userSignIn => isEnglish ? 'Enter as user' : 'Entrar como usuario';
  String get adminSignupTitle =>
      isEnglish ? 'Create an\naccount' : 'Crear una\ncuenta';
  String get adminSignupDescription => isEnglish
      ? 'Create your access to manage medication, appointments and alerts with the same clear visual panel.'
      : 'Crea tu acceso para gestionar medicación, citas y alertas con la misma claridad visual del panel.';
  String get userSignupEyebrow => isEnglish ? 'User sign up' : 'Alta Usuario';
  String get userSignupTitle =>
      isEnglish ? 'Create account\nand link' : 'Crear cuenta\ny vincular';
  String get userSignupDescription => isEnglish
      ? 'Create your account and link it to the administrator using their link code.'
      : 'Cree su cuenta y enlácela al administrador usando su código de vinculación.';
  String get enterAdminCode => isEnglish
      ? 'Enter the administrator code'
      : 'Introduzca el código del administrador';
  String get adminCodeLength => isEnglish
      ? 'The code must have 6 characters'
      : 'El código debe tener 6 caracteres';
  String get createUserAccount =>
      isEnglish ? 'Create user account' : 'Crear cuenta de usuario';
  String get accountCreated => isEnglish
      ? 'Account created successfully.'
      : 'Cuenta creada correctamente.';
  String get accountAlreadyExists => isEnglish
      ? 'An account with that email already exists.'
      : 'Ya existe una cuenta con ese email.';
  String get loginInvalidCredentials => isEnglish
      ? 'Incorrect email or password.'
      : 'Email o contraseña incorrectos.';
  String get emailNotConfirmed => isEnglish
      ? 'Confirm your email before signing in.'
      : 'Confirme su email antes de iniciar sesión.';
  String operationFailed(String message) => isEnglish
      ? 'Could not complete the operation: $message'
      : 'No se pudo completar la operación: $message';
  String get passwordTooShort => isEnglish
      ? 'The password does not meet the minimum length.'
      : 'La contraseña no cumple la longitud mínima requerida.';
  String get createAccountFailed =>
      isEnglish ? 'Could not create the account' : 'No se pudo crear la cuenta';
  String get privacyPrefix => isEnglish
      ? 'By creating an account you accept the '
      : 'Al crear una cuenta acepta las ';
  String get privacyPolicy =>
      isEnglish ? 'Privacy Policy' : 'Políticas de Privacidad';

  String get nextMedication =>
      isEnglish ? 'Next medication' : 'Próxima medicación';
  String get nextAppointment =>
      isEnglish ? 'Next medical appointment' : 'Próxima cita médica';
  String get nextDose => isEnglish ? 'Next dose' : 'Próxima toma';
  String get at => isEnglish ? 'At' : 'A las';
  String get noMedicationToday => isEnglish
      ? 'No medication pending today'
      : 'No tiene medicación pendiente hoy';
  String get mobileSimulation =>
      isEnglish ? 'Mobile simulation' : 'Simulación del móvil';
  String get mobileSimulationSubtitle =>
      isEnglish ? 'See active alerts' : 'Ver pantalla de avisos';
  String get logout => isEnglish ? 'Log out' : 'Cerrar sesión';
  String get today => isEnglish ? 'Today' : 'Hoy';
  String get yesterday => isEnglish ? 'Yesterday' : 'Ayer';
  String get back => isEnglish ? 'Back' : 'Volver';
  String get now => isEnglish ? 'Now' : 'Ahora';
  String get soon => isEnglish ? 'soon' : 'próximamente';
  String inDays(int days) {
    if (days == 1) return isEnglish ? 'In 1 day' : 'En 1 día';
    return isEnglish ? 'In $days days' : 'En $days días';
  }

  String get allSet => isEnglish ? 'All set' : 'Todo al día';
  String todayAt(String hour) =>
      isEnglish ? 'Today at $hour' : 'Hoy a las $hour';
  String weekdayDayAt(DateTime date, String hour) => isEnglish
      ? '${weekday(date.weekday)} ${date.day} at $hour'
      : '${weekday(date.weekday)} ${date.day} a las $hour';
  String minutesUntil(int minutes) {
    if (minutes == 1) return isEnglish ? 'in 1 minute' : 'en 1 minuto';
    return isEnglish ? 'in $minutes minutes' : 'en $minutes minutos';
  }

  String hoursUntil(int hours, int minutes) {
    if (minutes == 0) {
      if (hours == 1) return isEnglish ? 'in 1 hour' : 'en 1 hora';
      return isEnglish ? 'in $hours hours' : 'en $hours horas';
    }
    final hourLabel = hours == 1
        ? (isEnglish ? '1 hour' : '1 hora')
        : (isEnglish ? '$hours hours' : '$hours horas');
    final minuteLabel = minutes == 1
        ? (isEnglish ? '1 minute' : '1 minuto')
        : (isEnglish ? '$minutes minutes' : '$minutes minutos');
    return isEnglish
        ? 'in $hourLabel and $minuteLabel'
        : 'en $hourLabel y $minuteLabel';
  }

  String registeredCount(int count, String name) =>
      isEnglish ? '$count registered · $name' : '$count registradas · $name';

  String activeCount(int count, String name) =>
      isEnglish ? '$count active · $name' : '$count activos · $name';

  String activeMedications(int count) =>
      isEnglish ? '$count active' : '$count activos';

  String upcomingAppointmentsCount(int count) =>
      isEnglish ? '$count upcoming' : '$count próximas';

  String incidentsCount(int count) =>
      isEnglish ? '$count incidents' : '$count incidencias';

  String appointmentDeleteMessage(String specialty) => isEnglish
      ? 'Do you want to delete the $specialty appointment?'
      : '¿Desea eliminar la cita de $specialty?';

  String medicationDeleteMessage(String name) => isEnglish
      ? 'Are you sure you want to delete $name?'
      : '¿Seguro que desea eliminar $name?';

  String medicationDeleteDetailMessage(String name) => isEnglish
      ? 'Are you sure you want to delete $name? This action cannot be undone.'
      : '¿Seguro que desea eliminar $name? Esta acción no se puede deshacer.';

  String fileGenerationError(Object error) => isEnglish
      ? 'Could not generate the file: $error'
      : 'No se pudo generar el archivo: $error';

  String appointmentDeleteError(Object error) => isEnglish
      ? 'Could not delete the appointment: $error'
      : 'No se pudo eliminar la cita: $error';

  String medicationDeleteError(Object error) => isEnglish
      ? 'Could not delete the medication: $error'
      : 'No se pudo eliminar el medicamento: $error';

  String appointmentSaveError(Object error) => isEnglish
      ? 'Could not save the appointment: $error'
      : 'No se pudo guardar la cita: $error';

  String medicationSaveError(Object error) => isEnglish
      ? 'Could not save the medication: $error'
      : 'No se pudo guardar el medicamento: $error';

  String appointmentLoadLocalFallback() => isEnglish
      ? 'Could not load appointments from Supabase. Showing local data.'
      : 'No se pudieron cargar las citas desde Supabase. Se muestran datos locales.';

  String medicationLoadLocalFallback() => isEnglish
      ? 'Could not load medications from Supabase. Showing mock data.'
      : 'No se pudieron cargar los medicamentos desde Supabase. Se muestran datos mock.';

  String verifyCodeError(Object error) => isEnglish
      ? 'Could not verify the code: $error'
      : 'No se pudo verificar el código: $error';

  String minimumValue(int value) =>
      isEnglish ? 'Minimum $value' : 'Mínimo $value';

  String minimumStock(int value) =>
      isEnglish ? 'Minimum: $value' : 'Mínimo: $value';

  String units(int value) => isEnglish ? '$value units' : '$value unidades';

  String everyDays(int days) {
    if (days == 1) return isEnglish ? 'Every 1 day' : 'Cada 1 día';
    return isEnglish ? 'Every $days days' : 'Cada $days días';
  }

  String doseNumber(int number) => isEnglish ? 'Dose $number' : 'Toma $number';

  String confirmedStat(int count) =>
      isEnglish ? '$count confirmed' : '$count confirmadas';

  String omittedStat(int count) =>
      isEnglish ? '$count missed' : '$count omitidas';

  String pendingStat(int count) =>
      isEnglish ? '$count pending' : '$count pendientes';

  String pendingDosesToday(int pending) {
    if (pending == 1) return isEnglish ? '1 pending' : '1 pendiente';
    return isEnglish ? '$pending pending' : '$pending pendientes';
  }

  String confirmedOfTotalToday(int confirmed, int total) => isEnglish
      ? '$confirmed of $total doses today'
      : '$confirmed de $total tomas hoy';

  String lastSyncTime(DateTime value) => isEnglish
      ? 'Last sync: ${relativeTime(value)}'
      : 'Última sync: ${relativeTime(value)}';

  String linkedOn(DateTime value) => isEnglish
      ? 'Linked on ${shortNumericDate(value)}'
      : 'Vinculado el ${shortNumericDate(value)}';

  String relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return isEnglish ? 'right now' : 'ahora mismo';
    if (diff.inMinutes < 60) {
      return isEnglish
          ? '${diff.inMinutes} min ago'
          : 'hace ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return isEnglish ? '${diff.inHours} h ago' : 'hace ${diff.inHours} h';
    }
    if (diff.inDays < 7) {
      return isEnglish ? '${diff.inDays} days ago' : 'hace ${diff.inDays} días';
    }
    if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return isEnglish ? '$weeks weeks ago' : 'hace $weeks semanas';
    }
    return isEnglish
        ? 'a long time ago · check the connection'
        : 'hace mucho tiempo · revisa la conexión';
  }

  String shortNumericDate(DateTime value) => isEnglish
      ? '${value.month}/${value.day}/${value.year}'
      : '${value.day}/${value.month}/${value.year}';

  String shortMonth(int month) {
    final es = [
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
    final en = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return isEnglish ? en[month - 1] : es[month - 1];
  }

  String shortWeekday(int weekday) {
    final es = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final en = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return isEnglish ? en[weekday] : es[weekday];
  }

  String weekdaySemantic(int weekdayNumber, int confirmed, int total) =>
      isEnglish
      ? '${weekday(weekdayNumber)}: $confirmed of $total doses confirmed'
      : '${weekday(weekdayNumber)}: $confirmed de $total tomas confirmadas';

  String get testScreen => isEnglish ? 'Test screen' : 'Pantalla de pruebas';
  String get retry => isEnglish ? 'Retry' : 'Reintentar';
  String get simulationLoadError => isEnglish
      ? 'Could not load the simulation'
      : 'No se pudo cargar la simulación';
  String simulationLoadErrorDetail(String message) => isEnglish
      ? 'The screen no longer stays stuck loading. You can retry now.\n\nDetail: $message'
      : 'La pantalla ya no se queda bloqueada cargando. Puede reintentar ahora.\n\nDetalle: $message';
  String lastSync(String value) =>
      isEnglish ? 'Last update: $value' : 'Última actualización: $value';
  String get unsynced => isEnglish ? 'not synced' : 'sin sincronizar';
  String get viewReminder => isEnglish ? 'View reminder' : 'Ver recordatorio';
  String get viewAppointment => isEnglish ? 'View appointment' : 'Ver cita';
  String expiresAt(String hour) => isEnglish ? 'Expires $hour' : 'Expira $hour';

  String displayName(String value) => text(value);

  String alertTitle(String title) {
    if (!isEnglish) return title;
    final normalized = title.trim();
    for (final entry in const {
      ' confirmado': ' confirmed',
      ' confirmada': ' confirmed',
      ' omitida': ' missed',
      ' expirada': ' expired',
      ' pospuesta': ' snoozed',
      ' pendiente': ' pending',
    }.entries) {
      if (normalized.endsWith(entry.key)) {
        return normalized.replaceFirst(
          RegExp('${RegExp.escape(entry.key)}\$'),
          entry.value,
        );
      }
    }
    if (normalized.startsWith('Cita en 30 min: ')) {
      return normalized.replaceFirst(
        'Cita en 30 min: ',
        'Appointment in 30 min: ',
      );
    }
    if (normalized.startsWith('Cita mañana: ')) {
      return normalized.replaceFirst('Cita mañana: ', 'Appointment tomorrow: ');
    }
    if (normalized.startsWith('Cita hoy: ')) {
      return normalized.replaceFirst('Cita hoy: ', 'Appointment today: ');
    }
    if (normalized.startsWith('Stock bajo: ')) {
      return normalized.replaceFirst('Stock bajo: ', 'Low stock: ');
    }
    return text(normalized);
  }

  String alertDescription(String description) {
    if (!isEnglish) return description;
    final normalized = description.trim();
    if (normalized.startsWith('Toma confirmada a las ')) {
      return normalized.replaceFirst(
        'Toma confirmada a las ',
        'Dose confirmed at ',
      );
    }
    if (normalized == 'La toma quedó registrada como omitida') {
      return 'Dose recorded as missed';
    }
    if (normalized == 'No se respondió en los 15 minutos disponibles') {
      return 'No response within the 15 available minutes';
    }
    if (normalized == 'Se reprogramo 15 minutos despues' ||
        normalized == 'Se reprogramó 15 minutos después') {
      return 'Rescheduled 15 minutes later';
    }
    if (normalized.startsWith('Pendiente desde las ')) {
      return normalized.replaceFirst('Pendiente desde las ', 'Pending since ');
    }
    if (normalized.startsWith('Recordatorio final · ')) {
      return normalized
          .replaceFirst('Recordatorio final · ', 'Final reminder · ')
          .replaceAll(' a las ', ' at ');
    }
    if (normalized.startsWith('Recordatorio 24h · ')) {
      return normalized
          .replaceFirst('Recordatorio 24h · ', '24h reminder · ')
          .replaceAll(' a las ', ' at ');
    }
    if (normalized.startsWith('Recordatorio 3h · ')) {
      return normalized
          .replaceFirst('Recordatorio 3h · ', '3h reminder · ')
          .replaceAll(' a las ', ' at ');
    }
    if (normalized.contains(' no confirmó la toma de la tarde')) {
      return normalized.replaceFirst(
        ' no confirmó la toma de la tarde',
        ' did not confirm the afternoon dose',
      );
    }
    if (normalized.contains(' confirmó la toma de ')) {
      return normalized.replaceFirst(' confirmó la toma de ', ' confirmed ');
    }
    if (normalized.startsWith('Quedan ')) {
      final match = RegExp(
        r'^Quedan (\d+) pastillas de (.+)$',
      ).firstMatch(normalized);
      if (match != null) {
        return '${match.group(1)} pills of ${match.group(2)} remaining';
      }
      return normalized.replaceFirst('Quedan ', 'Remaining: ');
    }
    return text(normalized);
  }

  String get expiredMedicationNoResponse => isEnglish
      ? 'No response within the 15 available minutes'
      : 'No se respondió en los 15 minutos disponibles';

  String get noPendingMedication =>
      isEnglish ? 'No pending medication.' : 'No hay medicación pendiente.';
  String medicationLoadError(String error) => isEnglish
      ? 'Could not load pending medication. $error'
      : 'No se pudo cargar la medicación pendiente. $error';
  String get medicationReminder =>
      isEnglish ? 'Medication reminder' : 'Recordatorio de medicación';
  String medicationTimeFor(String name) => isEnglish
      ? '$name, it is time for your medication'
      : '$name, es hora de su medicación';
  String get takeWithWater =>
      isEnglish ? 'Take it with water' : 'Tómela con agua';
  String get reviewMedicationCalm => isEnglish
      ? 'Review the dose calmly and confirm when you have taken it.'
      : 'Revise la toma con calma y confirme cuando la haya tomado.';
  String get saving => isEnglish ? 'Saving...' : 'Guardando...';
  String get taken => isEnglish ? 'I have taken it' : 'Ya la he tomado';
  String get reminderIn10 =>
      isEnglish ? 'Reminder in 10 min' : 'Recordatorio en 10 min';
  String get remindIn10 =>
      isEnglish ? 'Remind me in 10 min' : 'Recordármelo en 10 min';
  String get noScheduledDoses =>
      isEnglish ? 'No scheduled doses' : 'Sin tomas programadas';
  String nextDoseAt(String hour) =>
      isEnglish ? 'Next: $hour' : 'Siguiente: $hour';

  String get noUpcomingAppointments =>
      isEnglish ? 'No upcoming appointments.' : 'No hay citas próximas.';
  String appointmentLoadError(String error) => isEnglish
      ? 'Could not load the appointment. $error'
      : 'No se pudo cargar la cita. $error';
  String appointmentTiming(String value) =>
      isEnglish ? 'Appointment $value' : 'Cita $value';
  String get medicalAppointment =>
      isEnglish ? 'You have a medical appointment' : 'Tiene una cita médica';
  String appointmentAlertTitle(String value) => isEnglish
      ? 'Medical appointment ${value.toLowerCase()}'
      : 'Cita médica ${value.toLowerCase()}';
  String get appointmentReminderConfirmed =>
      isEnglish ? 'Reminder confirmed' : 'Recordatorio confirmado';
  String get appointmentReminderChip =>
      isEnglish ? 'Appointment reminder' : 'Recordatorio de cita';
  String get confirmReminder =>
      isEnglish ? 'Confirm reminder' : 'Confirmar recordatorio';
  String get understoodThanks =>
      isEnglish ? 'Understood, thanks' : 'Entendido, gracias';
  String get noted => isEnglish ? 'Noted' : 'Anotado';
  String get appointmentRememberDocuments => isEnglish
      ? 'Remember to bring your documents\nand arrive early.'
      : 'Recuerde llevar su documentación\ny llegar con tiempo.';

  String greetingForHour(int hour) {
    if (isEnglish) {
      if (hour < 12) return 'Good morning';
      if (hour < 20) return 'Good afternoon';
      return 'Good evening';
    }
    if (hour < 12) return 'Buenos días';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String weekday(int weekday) {
    final es = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final en = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return isEnglish ? en[weekday - 1] : es[weekday - 1];
  }

  String month(int month) {
    final es = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return isEnglish ? en[month - 1] : es[month - 1];
  }

  String fullDate(DateTime date) => isEnglish
      ? '${weekday(date.weekday)}, ${month(date.month)} ${date.day}'
      : '${weekday(date.weekday)}, ${date.day} de ${month(date.month)}';
}
