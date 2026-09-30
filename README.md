<div align="center">

# 🏥 Aviso Vital

**Helping elderly patients stay on top of their health — one reminder at a time.**

[![Live Demo](https://img.shields.io/badge/🌐_Live_Demo-aviso--vital.vercel.app-00C853?style=for-the-badge)](https://aviso-vital.vercel.app)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)

*Final Degree Project (TFG) · CUNEF University · B.Sc. Computer Engineering*

</div>

---

## 📋 Overview

Aviso Vital is a **full-stack accessible web application** designed to solve **medication adherence problems in elderly patients**. It provides a dual experience — a **caregiver/admin panel** for managing medications and appointments, and a **simplified elder view** with large fonts, high contrast, voice alerts, and a real-time notification simulator showing exactly what the patient sees on their phone.

> 🎯 **Problem:** Medication non-adherence in the elderly leads to hospitalizations, health complications, and reduced quality of life. Existing apps are too complex for this demographic.
>
> 💡 **Solution:** An accessibility-first app designed *with* elderly users, not just *for* them — featuring usability testing with 5+ real participants.

### ✨ Highlights

| | |
|---|---|
| 💊 **Medication Manager** | Schedule, track and manage daily medications with customizable reminders and pill visualization |
| 📅 **Appointment Tracker** | Medical appointments with 24h / 3h / 30min cascading reminders |
| 👨‍👩‍👧 **Family Dashboard** | Real-time remote monitoring for caregivers — adherence stats, low stock alerts, today's activity |
| 📱 **Live Notification Simulator** | See exactly what the elderly user would see on their phone — in real time |
| 📄 **PDF Export** | Generate medication and appointment reports for doctors or family |
| 🌐 **Bilingual** | Full ES/EN internationalization |
| ♿ **WCAG AA+ Accessible** | Large touch targets (48×48px min), clamped TextScaler, high-contrast dark UI |


### 🚀 Try It Live

👉 **[aviso-vital.vercel.app](https://aviso-vital.vercel.app)**

---

## Descripción del proyecto

Aviso Vital nace como una app centrada en accesibilidad, claridad visual y tranquilidad operativa. La idea principal es que una persona de apoyo pueda organizar medicación, citas y seguimiento, mientras que la persona mayor recibe una experiencia mucho más guiada, simple y legible.

La aplicación está construida con una arquitectura ligera y mantenible basada en:

- Flutter + Material 3 en modo oscuro.
- Repositorios para acceso a datos con caché multinivel.
- Servicios para contexto de usuario, enlace entre perfiles y simulación en tiempo real.
- Modelos de dominio desacoplados de la UI.
- Sistema de internacionalización ES/EN integrado.
- Diseño responsive para móvil, tablet y escritorio (Vercel Web).
- Compatibilidad con backend real en Supabase y fallback local con `MockData`.

## Objetivos funcionales

- Registrar y visualizar medicación activa.
- Programar tomas diarias y controlar su estado.
- Gestionar citas médicas con recordatorios anticipados.
- Exportar informes en PDF de medicamentos y citas.
- Mostrar al cuidador una visión administrativa de la actividad.
- Mostrar al usuario mayor una interfaz simplificada y accesible.
- Simular en tiempo real cómo se verían las notificaciones en el móvil de la persona mayor.

## Qué hace la aplicación

La app está dividida en dos experiencias:

### 1. Experiencia administrador

El administrador puede:

- iniciar sesión o crear cuenta;
- registrar medicamentos con dosis, frecuencia, color y forma de pastilla;
- editar dosis, horas e instrucciones;
- registrar citas médicas;
- revisar alertas y actividad reciente;
- exportar informes de medicamentos y citas en PDF;
- acceder a una simulación del móvil del usuario mayor.

### 2. Experiencia usuario mayor

El usuario mayor puede:

- vincularse con un administrador mediante código;
- ver su próxima medicación con nombre y hora en gran tamaño;
- ver su próxima cita médica;
- consultar el progreso del día;
- abrir alertas de medicación y citas;
- confirmar una toma o posponerla;
- revisar una simulación visual del estado del dispositivo y de las notificaciones activas.

## Trabajo realizado

### Implementación funcional

- sistema de selección de rol entre administrador y usuario mayor;
- autenticación y bootstrap de sesión;
- vinculación local con administrador mediante código;
- panel principal para administrador con stats y actividad reciente;
- gestión de medicamentos;
- gestión de citas;
- historial y alertas recientes;
- home simplificado para usuario mayor;
- pantallas de detalle para alerta de medicación y alerta de cita;
- simulación en tiempo real del móvil del usuario;
- exportación de informes en PDF (medicamentos y citas);
- fallback de datos con `MockData` cuando no hay backend o sesión;
- estilo visual dark premium con tema compartido;
- internacionalización completa ES/EN;
- diseño responsive para web, tablet y escritorio.

### Refactorización y mejoras recientes

#### Diseño responsive para Vercel Web

- nuevo `AppBreakpoints` centralizado en `app_dimensions.dart` como fuente única de verdad para breakpoints (`mobile: 480`, `tablet: 700`, `desktop: 1024`);
- home de usuario mayor: contenido centrado con `maxWidth: 600` y padding horizontal adaptativo;
- tarjeta de próxima medicación (`NextMedicationCard`): tipografía adaptativa con `LayoutBuilder` — nombre de medicamento de 24 a 36 pt, hora de 28 a 40 pt según ancho disponible; `minHeight` adaptativo para pantallas muy estrechas;
- pantallas de administrador: contenido centrado con `maxWidth: 900` en `AdminSectionScaffold` y `AdminDashboardPage`;
- cabeceras de admin con protección `overflow: ellipsis` en título y subtítulo;
- `MaterialApp` con `TextScaler` clampeado a `[1.0, 1.3]` para proteger el layout con configuraciones de texto grande del sistema;
- `web/manifest.json`: orientación cambiada a `"any"` para soportar rotación en tablet y escritorio;
- padding inferior dinámico en el dashboard de admin que incluye `MediaQuery.padding.bottom`.

#### Correcciones en exportación PDF

- `_citaCard`: reemplazado `pw.Table` (que implementa `SpanningWidget` y causaba rectángulos vacíos al final de página) por `pw.Row` + `pw.Expanded`;
- hora de cita: formato pastilla con `borderRadius: 8`, tipografía 18 pt, eliminada la etiqueta `Hora` redundante;
- todas las tomas medidas como ítems independientes en `MultiPage.build` para evitar el error `Widget won't fit — height Infinity`;
- calendario: `pw.Spacer()` reemplazado por `pw.SizedBox` y grid de semanas con altura fija;
- resumen de adherencia: strip de stats con `pw.Table` y `FlexColumnWidth` en lugar de `pw.Expanded` anidado.

#### Mejoras de UI y texto

- selección de rol: etiquetas simplificadas a `Usuario` y `Administrador` (eliminado el prefijo `Soy`);
- login de usuario: eliminado el botón `¿Olvidaste tu contraseña?` (solo disponible en el login de administrador);
- simulación: rediseño dark de tarjetas de lock screen con logo real de Aviso Vital, nombre de medicamento y hora reforzados visualmente.

#### Seguridad y configuración

- `env/dev.json` añadido al `.gitignore` — las credenciales de Supabase nunca se suben al repositorio;
- el archivo debe existir localmente pero nunca en el historial de git.

## Arquitectura técnica

La arquitectura del proyecto es deliberadamente sencilla y clara. No se ha introducido una capa pesada de estado global porque el tamaño del proyecto y la naturaleza del flujo permiten resolverlo con repositorios, servicios y `StatefulWidget` de forma mantenible.

### Capas principales

#### 1. `app/`

Contiene el arranque de la aplicación y el enrutado:

- `lib/app/app.dart`: configura `MaterialApp`, tema global, `TextScaler` clampeado y bootstrap inicial.
- `lib/app/router/app_router.dart`: resuelve las rutas con `onGenerateRoute`.
- `lib/app/router/app_routes.dart`: define los nombres de ruta.
- `lib/app/router/app_transitions.dart`: centraliza transiciones de navegación.

#### 2. `core/services/`

Servicios transversales:

- `supabase_service.dart`: inicialización de Supabase y acceso al cliente.
- `care_plan_context_service.dart`: resuelve el contexto real de trabajo, incluyendo quién es el propietario del plan de cuidados y quién es el visor actual.
- `app_link_service.dart`: persistencia local de la vinculación con administrador mediante `SharedPreferences`.
- `realtime_service.dart`: suscripción a cambios en Supabase Realtime para `tomas`, `citas`, `alertas` y `medicamentos`.
- `realtime_simulation_service.dart`: motor que construye el snapshot de notificaciones visibles para la simulación.
- `pdf_export_service.dart`: generación de informes PDF de medicamentos y citas con descarga nativa en web.

#### 3. `data/models/`

Modelos de dominio y enums:

- `Usuario`
- `Medicamento`
- `Toma`
- `Cita`
- `Alerta`
- `ResumenAdherencia`

También define enums relevantes como:

- `RolUsuario`
- `EstadoToma`
- `FrecuenciaMed`
- `TipoAlerta`
- `EstadoAlerta`
- `EstadoCita`

#### 4. `data/repositories/`

Repositorios responsables del acceso a datos y de mantener una API estable para la UI:

- `AuthRepository`
- `UserRepository`
- `DeviceRepository`
- `MedicationsRepository`
- `AppointmentsRepository`
- `AlertsRepository`

Cada repositorio intenta trabajar con Supabase cuando está disponible y, en caso contrario, opera con datos mock y cachés locales en memoria.

#### 5. `features/`

La UI está organizada por áreas funcionales:

- `admin_home`
- `alerts`
- `appointments`
- `auth`
- `device_status`
- `medications`
- `onboarding`
- `user_home`

#### 6. `shared/`

Recursos reutilizables:

- `theme/app_colors.dart`: sistema de color completo en modo oscuro.
- `theme/app_dimensions.dart`: `AppBreakpoints`, `AppSpacing`, `AppRadius`, `AppDurations`, `AppShadows`.
- `theme/app_text_styles.dart`: jerarquía tipográfica centralizada.
- `i18n/app_language.dart`: internacionalización ES/EN con `AppStrings` y `AppLocaleController`.
- `widgets/`: widgets compartidos reutilizables.
- `utils/`: validadores, mapeadores de error y utilidades de formateo.

## Estructura del proyecto

```text
lib/
├── app/
│   ├── app.dart
│   └── router/
├── core/
│   └── services/
├── data/
│   ├── mock/
│   ├── models/
│   └── repositories/
├── features/
│   ├── admin_home/
│   ├── alerts/
│   ├── appointments/
│   ├── auth/
│   ├── device_status/
│   ├── medications/
│   ├── onboarding/
│   └── user_home/
├── shared/
│   ├── i18n/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── main.dart
```

## Modelo de dominio

### Usuario

Representa tanto al administrador como a la persona mayor. Incluye rol, relación con administrador, código de vinculación y datos de sincronización.

### Medicamento

Incluye:

- nombre;
- dosis;
- frecuencia;
- horas de toma;
- stock actual;
- stock mínimo;
- forma y color de pastilla;
- instrucciones y notas.

### Toma

Representa una toma programada de un medicamento. Es clave para la simulación y para el progreso diario.

Estados relevantes:

- `pendiente`
- `confirmada`
- `pospuesta`
- `omitida`
- `expirada`

### Cita

Representa una cita médica con especialidad, lugar, fecha y hora, y banderas de recordatorio.

Estados relevantes:

- `proxima`
- `hoy`
- `pasada`
- `cancelada`

### Alerta

Modela notificaciones o incidencias relacionadas con:

- medicación;
- citas;
- stock bajo;
- sistema.

## Flujo de contexto y ownership

Uno de los puntos importantes del proyecto es que el usuario que usa la app no siempre coincide con el usuario propietario del plan de cuidados.

`CarePlanContextService` resuelve:

- quién está autenticado;
- si el visor es administrador o persona mayor;
- cuál es el `ownerUserId` real sobre el que consultar medicación, citas y tomas;
- si la sesión es real o una vinculación local sin login completo.

Esto permite mantener la misma capa de repositorios para múltiples escenarios:

- administrador autenticado gestionando a la persona mayor vinculada;
- usuario mayor autenticado;
- usuario mayor enlazado localmente por código.

## Gestión de datos y modo de ejecución

### Modo con Supabase

Cuando la app se lanza con variables de entorno válidas:

- se inicializa `SupabaseService`;
- los repositorios consultan tablas reales;
- se mantiene caché local para mejorar experiencia y fallback de navegación;
- las pantallas trabajan sobre los datos remotos.

### Modo local con mocks

Si Supabase no está configurado:

- la app sigue siendo navegable;
- se utilizan datos de `MockData`;
- la simulación y varios flujos principales siguen funcionando;
- esto permite demos, desarrollo de UI y pruebas de interacción sin backend.

## Esquema backend esperado

### `usuarios`

Campos relevantes: `id`, `nombre`, `email`, `rol`, `id_administrador`, `codigo_vinculacion`, `created_at`, `notificaciones_activas`, `ultima_sincronizacion`.

### `medicamentos`

Campos relevantes: `id`, `id_usuario`, `nombre`, `dosis`, `frecuencia`, `horas_toma`, `stock_actual`, `stock_minimo`, `color_pastilla`, `forma_pastilla`, `instrucciones`, `notas`, `activo`, `created_at`, `updated_at`.

### `tomas`

Campos relevantes: `id`, `id_usuario`, `id_medicamento`, `fecha_programada`, `fecha_realizada`, `estado`, `notas`, `created_at`.

### `citas`

Campos relevantes: `id`, `id_usuario`, `especialidad`, `lugar`, `direccion`, `telefono`, `fecha`, `hora`, `estado`, `recordatorio_24h`, `recordatorio_3h`, `notas`, `created_at`.

### `alertas`

Campos relevantes: `id`, `id_usuario`, `tipo`, `titulo`, `mensaje`, `fecha_hora`, `estado`, `id_medicamento`, `id_cita`.

### Consideraciones de persistencia

- las fechas se serializan a UTC al persistir;
- los modelos convierten a hora local al leer;
- en las citas, la combinación real para negocio es `fecha + hora`;
- la simulación usa esta combinación para calcular visibilidad, expiración y colapso de recordatorios.

## Simulación en tiempo real

La simulación es una de las piezas más distintivas del proyecto. Su objetivo es representar en pantalla cómo vería una persona mayor las notificaciones activas en su teléfono en un momento real.

El motor está en `lib/core/services/realtime_simulation_service.dart` y:

- resuelve el contexto del usuario;
- carga medicamentos, tomas, citas y alertas con opción de forzar refresco;
- expira tomas atrasadas si han superado la ventana de respuesta;
- construye una lista de `LiveNotificationItem`;
- devuelve un `LiveSimulationSnapshot` con las notificaciones activas y próximas.

La pantalla de simulación (`simulacion_alertas_screen.dart`) se conecta además a `RealtimeService` para escuchar cambios remotos en `tomas`, `citas`, `alertas` y `medicamentos`. También mantiene un refresco de respaldo cada 30 segundos.

### Tipos de notificación soportados

- notificación de medicación;
- notificación de cita médica.

### Reglas de negocio

#### Medicación

- toma pendiente o pospuesta entra en la simulación desde la hora programada;
- al confirmar desaparece; al posponer reaparece más tarde;
- ventana de expiración: 15 minutos.

#### Citas

- recordatorios a 24h, 3h y 30 min;
- las alertas de 24h y 3h desaparecen al confirmarse;
- la alerta de 30 min, al gestionarse, se mantiene colapsada hasta la hora real de la cita;
- recordatorios no finales permanecen visibles 15 minutos si no se gestionan.

## Diseño visual y accesibilidad

La app sigue una línea visual oscura, sobria y cálida optimizada para personas mayores.

### Principios visuales

- modo oscuro coherente en toda la app;
- acento ámbar para medicación y naranja para citas;
- jerarquía tipográfica clara con tamaños grandes en vistas críticas;
- fondos con glow suave para transmitir calma y cuidado;
- componentes con gran claridad táctil (mínimo 48×48 px);
- contraste WCAG AA+ en todos los textos.

### Accesibilidad aplicada

- `TextScaler` clampeado a `[1.0, 1.3]` en `MaterialApp` para respetar preferencias del usuario sin romper el layout;
- áreas táctiles amplias en todos los botones interactivos;
- textos y CTAs simplificados;
- hora de medicación y cita reforzada visualmente para lectura rápida;
- `Semantics` con `label` y `tooltip` en acciones clave.

## Flujos principales de navegación

### Onboarding y acceso

- selección de rol (`Usuario` / `Administrador`);
- login administrador (con opción de recuperar contraseña);
- creación de cuenta;
- login usuario;
- vinculación mediante código manual o flujo de conexión.

### Home de administrador

Dashboard con stats de adherencia, medicamentos con stock bajo y cita del día. Desde aquí se accede a medicamentos, citas, alertas y actividad reciente.

### Home de usuario mayor

Muestra saludo contextual, progreso diario, próxima medicación con nombre y hora en gran tamaño adaptativo, próxima cita médica y acceso directo a la simulación.

## Rutas principales

La navegación se centraliza en `AppRouter`. Rutas clave:

- `/home-admin`
- `/home-usuario`
- `/admin-medicamentos`
- `/admin-citas`
- `/admin-alertas`
- `/simulacion-alertas`
- `/alerta-medicacion`
- `/alerta-cita`

## Configuración del entorno

### Requisitos

- Flutter SDK `^3.11.1`
- Dart incluido con Flutter
- Xcode si se compila para iOS
- Cuenta y proyecto de Supabase para modo backend

### Dependencias principales

| Paquete | Versión | Uso |
|---------|---------|-----|
| `supabase_flutter` | ^2.0.0 | Backend y autenticación |
| `flutter_secure_storage` | ^9.2.2 | Almacenamiento seguro |
| `shared_preferences` | ^2.5.3 | Preferencias locales |
| `pdf` | ^3.10.0 | Generación de PDFs |
| `printing` | ^5.12.0 | Impresión y descarga |
| `flutter_svg` | ^2.0.0 | Logo e iconos SVG |
| `universal_html` | ^2.3.0 | Descarga de PDF en web |

### Variables de entorno

La app espera:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Crea el archivo `env/dev.json` localmente (está en `.gitignore`, nunca se sube al repositorio):

```json
{
  "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
  "SUPABASE_ANON_KEY": "TU_ANON_KEY"
}
```

Si no se proporcionan variables válidas, la app entra en modo local y utiliza datos de ejemplo.

## Web y despliegue en Vercel

El proyecto está preparado para compilar como Flutter Web y desplegarse en Vercel como aplicación estática.

Archivos relevantes:

- `vercel.json`: configura el build, la carpeta de salida y el rewrite de SPA hacia `index.html`.
- `scripts/vercel-build.sh`: instala o reutiliza Flutter, ejecuta `flutter pub get` y compila web.
- `web/index.html`: metadata web actualizada para Aviso Vital.
- `web/manifest.json`: nombre, descripción, colores y orientación PWA (`"orientation": "any"`).

### Variables necesarias en Vercel

En **Vercel → Settings → Environment Variables** deben configurarse:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Flutter Web las lee en tiempo de build mediante `--dart-define`, tal como hace el script de Vercel:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

### Rewrites de SPA

`vercel.json` envía todas las rutas a `index.html` para que rutas internas como `/home-usuario` o `/simulacion-alertas` funcionen al abrir o recargar directamente desde el navegador.

## Comandos útiles

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar la app (con Supabase)

```bash
flutter run --dart-define-from-file=env/dev.json
```

### Ejecutar en Chrome

```bash
flutter run -d chrome --dart-define-from-file=env/dev.json
```

### Analizar código

```bash
flutter analyze
```

### Ejecutar tests

```bash
flutter test
```

### Compilar web localmente

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL="https://TU-PROYECTO.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="TU_ANON_KEY"
```

### Formatear código

```bash
dart format lib test
```

### Estado actual del análisis

```
flutter analyze → No issues found ✅
```

## Decisiones técnicas relevantes

### 1. Arquitectura ligera en lugar de sobreingeniería

No se ha forzado el uso de `Provider`, `Bloc` o arquitecturas más complejas. Para el alcance actual, el binomio repositorio + servicio + estado local es suficiente, legible y fácil de evolucionar.

### 2. Soporte híbrido real/mock

La app puede seguir funcionando sin backend totalmente operativo. Esto permite iterar rápidamente sobre UX, flujos y demostraciones.

### 3. Modelo de dominio desacoplado

Los modelos están preparados para mapear tanto desde datos mock como desde Supabase, reduciendo acoplamiento con la UI.

### 4. Simulación derivada del dominio

La simulación no pinta una lista estática; interpreta estados reales de tomas, citas y alertas para representar el comportamiento esperado de la app.

### 5. Responsive sin romper lógica

Todo el diseño responsive se implementa únicamente en la capa de presentación mediante `AppBreakpoints`, `ConstrainedBox` con `maxWidth` y `LayoutBuilder`. La lógica de negocio y los repositorios no se han modificado.

## Mejoras futuras recomendadas

- añadir tests unitarios para reglas de recordatorios y expiración;
- ampliar tests de widgets para flujos de alerta;
- incorporar estado reactivo más centralizado si el proyecto sigue creciendo;
- añadir notificaciones push reales;
- completar trazabilidad histórica de citas gestionadas;
- incorporar perfiles y permisos más finos entre cuidador y familiar;
- error tracking centralizado (por ejemplo, Sentry).

## Resumen

Aviso Vital es una app Flutter enfocada en cuidado, adherencia y comunicación clara para personas mayores. Combina una base técnica sólida (arquitectura por features, repositorios con caché, backend Supabase, PDF export, i18n completa y diseño responsive) con una experiencia visual cuidada y accesible optimizada para su audiencia. Destaca especialmente por la simulación en tiempo real del móvil del usuario y el tratamiento accesible de alertas de medicación y citas.

---

<div align="center">

## 📄 Academic Context

| | |
|---|---|
| **Project** | Final Degree Project (Trabajo de Fin de Grado) |
| **University** | CUNEF University, Madrid |
| **Degree** | B.Sc. Computer Engineering |
| **Period** | September 2025 – June 2026 |
| **Author** | Marco Lopez Prieto |

---

## 📫 Contact

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/marco-lopez-prieto-320810384/)
[![Email](https://img.shields.io/badge/Email-EA4335?style=for-the-badge&logo=gmail&logoColor=white)](mailto:marco.lopez@student.ie.edu)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MarcoLopezP10)

</div>
nebulaONE logoPowered by cloudforce
