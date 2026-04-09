# Aviso Vital

Aplicación móvil desarrollada con Flutter orientada a mejorar el seguimiento de medicación y citas médicas en personas mayores, con una experiencia dual para cuidador o familiar administrador y para usuario mayor. El proyecto combina gestión clínica básica, recordatorios, simulación visual del móvil del usuario y soporte tanto para modo local con datos mock como para backend real con Supabase.

## Descripción del proyecto

Aviso Vital nace como una app centrada en accesibilidad, claridad visual y tranquilidad operativa. La idea principal es que una persona de apoyo pueda organizar medicación, citas y seguimiento, mientras que la persona mayor recibe una experiencia mucho más guiada, simple y legible.

La aplicación está construida con una arquitectura ligera y mantenible basada en:

- Flutter + Material 3 en modo oscuro.
- Repositorios para acceso a datos.
- Servicios para contexto de usuario, enlace entre perfiles y simulación en tiempo real.
- Modelos de dominio desacoplados de la UI.
- Compatibilidad con backend real en Supabase y fallback local con `MockData`.

## Objetivos funcionales

- Registrar y visualizar medicación activa.
- Programar tomas diarias y controlar su estado.
- Gestionar citas médicas con recordatorios anticipados.
- Mostrar al cuidador una visión administrativa de la actividad.
- Mostrar al usuario mayor una interfaz simplificada y accesible.
- Simular en tiempo real cómo se verían las notificaciones en el móvil de la persona mayor.

## Qué hace la aplicación

La app está dividida en dos experiencias:

### 1. Experiencia administrador

El administrador puede:

- iniciar sesión o crear cuenta;
- registrar medicamentos;
- editar dosis, frecuencia, horas e instrucciones;
- registrar citas médicas;
- revisar alertas y actividad reciente;
- acceder a una simulación del móvil del usuario mayor.

### 2. Experiencia usuario mayor

El usuario mayor puede:

- vincularse con un administrador mediante código;
- ver su próxima medicación;
- ver su próxima cita médica;
- consultar el progreso del día;
- abrir alertas de medicación y citas;
- confirmar una toma o posponerla;
- revisar una simulación visual del estado del dispositivo y de las notificaciones activas.

## Trabajo realizado

Este proyecto ya no es un esqueleto de Flutter: se ha convertido en una aplicación funcional con una capa de dominio clara, rutas definidas, integración con Supabase, soporte local y una UI refinada para el escenario principal.

### Implementación funcional ya desarrollada

- sistema de selección de rol entre administrador y usuario mayor;
- autenticación y bootstrap de sesión;
- vinculación local con administrador mediante código;
- panel principal para administrador;
- gestión de medicamentos;
- gestión de citas;
- historial y alertas recientes;
- home simplificado para usuario mayor;
- pantallas de detalle para alerta de medicación y alerta de cita;
- simulación en tiempo real del móvil del usuario;
- fallback de datos con `MockData` cuando no hay backend o sesión;
- estilo visual dark premium con tema compartido.

### Refactorización reciente destacada

En esta fase se ha hecho una mejora importante del sistema de simulación y del flujo de alertas:

- rediseño dark de las tarjetas de notificación del lock screen simulado;
- mejora de contraste, jerarquía visual y legibilidad para personas mayores;
- unificación del badge de acción `Pulse para abrir`;
- formateo consistente de dosis, por ejemplo `50 mg`;
- refactor de la pantalla de detalle de medicación para que el CTA principal quede visible abajo;
- soporte para múltiples notificaciones visibles en la simulación con scroll interno;
- corrección del comportamiento tras confirmar alertas:
  - medicación confirmada: desaparece;
  - cita confirmada de `24h` o `3h`: desaparece;
  - cita gestionada de `30 min`: se colapsa y permanece hasta la hora real de la cita;
- mejora de robustez de la simulación para que no se quede indefinidamente cargando;
- corrección de la mini tarjeta de citas del home de usuario para que muestre y abra la cita correcta;
- ajuste del recordatorio de `24h` para respetar el horario local incluso en cambios de hora.

## Arquitectura técnica

La arquitectura del proyecto es deliberadamente sencilla y clara. No se ha introducido una capa pesada de estado global porque el tamaño del proyecto y la naturaleza del flujo permiten resolverlo con repositorios, servicios y `StatefulWidget` de forma mantenible.

### Capas principales

#### 1. `app/`

Contiene el arranque de la aplicación y el enrutado:

- `lib/app/app.dart`: configura `MaterialApp`, tema global y bootstrap inicial.
- `lib/app/router/app_router.dart`: resuelve las rutas con `onGenerateRoute`.
- `lib/app/router/app_routes.dart`: define los nombres de ruta.
- `lib/app/router/app_transitions.dart`: centraliza transiciones de navegación.

#### 2. `core/services/`

Servicios transversales:

- `supabase_service.dart`: inicialización de Supabase y acceso al cliente.
- `care_plan_context_service.dart`: resuelve el contexto real de trabajo, incluyendo quién es el propietario del plan de cuidados y quién es el visor actual.
- `app_link_service.dart`: persistencia local de la vinculación con administrador mediante `SharedPreferences`.
- `realtime_simulation_service.dart`: motor que construye el snapshot de notificaciones visibles para la simulación.

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

- tema global;
- dimensiones, radios, sombras y espaciados;
- widgets compartidos;
- fondo premium;
- utilidades de formateo.

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

Este comportamiento híbrido ha sido útil durante el desarrollo para avanzar en diseño, lógica y experiencia sin bloquearse por dependencias externas.

## Esquema backend esperado

Aunque la app puede funcionar en local con mocks, el modelo está preparado para una persistencia real en Supabase. A nivel conceptual, las tablas principales esperadas son las siguientes:

### `usuarios`

Campos relevantes:

- `id`
- `nombre`
- `email`
- `rol`
- `id_administrador`
- `codigo_vinculacion`
- `created_at`
- `notificaciones_activas`
- `ultima_sincronizacion`

### `medicamentos`

Campos relevantes:

- `id`
- `id_usuario`
- `nombre`
- `dosis`
- `frecuencia`
- `horas_toma`
- `stock_actual`
- `stock_minimo`
- `color_pastilla`
- `forma_pastilla`
- `instrucciones`
- `notas`
- `activo`
- `created_at`
- `updated_at`

### `tomas`

Campos relevantes:

- `id`
- `id_usuario`
- `id_medicamento`
- `fecha_programada`
- `fecha_realizada`
- `estado`
- `notas`
- `created_at`

### `citas`

Campos relevantes:

- `id`
- `id_usuario`
- `especialidad`
- `lugar`
- `direccion`
- `telefono`
- `fecha`
- `hora`
- `estado`
- `recordatorio_24h`
- `recordatorio_3h`
- `notas`
- `created_at`

### `alertas`

Campos relevantes:

- `id`
- `id_usuario`
- `tipo`
- `titulo`
- `mensaje` o `descripcion`
- `fecha_alerta` o `fecha_hora`
- `leida` o `estado`
- `id_medicamento`
- `id_cita`

### Consideraciones de persistencia

- las fechas se serializan a UTC al persistir;
- los modelos convierten a hora local al leer;
- en las citas, la combinación real para negocio es `fecha + hora`;
- la simulación usa esta combinación para calcular visibilidad, expiración y colapso de recordatorios.

## Simulación en tiempo real

La simulación es una de las piezas más distintivas del proyecto. Su objetivo es representar en pantalla cómo vería una persona mayor las notificaciones activas en su teléfono en un momento real.

### Servicio principal

El motor está en:

- `lib/core/services/realtime_simulation_service.dart`

Este servicio:

- resuelve el contexto del usuario;
- carga medicamentos, tomas, citas y alertas;
- expira tomas atrasadas si han superado la ventana de respuesta;
- construye una lista de `LiveNotificationItem`;
- devuelve un `LiveSimulationSnapshot` con las notificaciones activas y próximas.

### Tipos de notificación soportados

- notificación de medicación;
- notificación de cita médica.

### Reglas de negocio actuales

#### Medicación

- una toma pendiente o pospuesta entra en la simulación;
- si se confirma, desaparece;
- si se pospone, reaparece más tarde;
- si no se responde dentro de la ventana prevista, puede expirar.

#### Citas

La app soporta recordatorios derivados a:

- `24h` antes;
- `3h` antes;
- `30 min` antes.

Comportamiento esperado:

- la alerta de `24h` aparece cuando toca y desaparece al confirmarse;
- la alerta de `3h` aparece cuando toca y desaparece al confirmarse;
- la alerta de `30 min` aparece cuando toca y, al gestionarse, se mantiene colapsada hasta la hora real de la cita.

### Aspectos técnicos relevantes de la simulación

- no depende exclusivamente de que la fila de alerta exista ya en base de datos;
- puede derivar recordatorios directamente desde las citas;
- soporta múltiples notificaciones simultáneas;
- la pantalla del móvil simulado tiene scroll interno;
- incorpora manejo de error y reintento para no quedarse cargando indefinidamente;
- el cálculo del recordatorio de `24h` se hace preservando la hora local del día anterior para evitar errores en cambios de horario.

## Diseño visual y accesibilidad

La app sigue una línea visual oscura, sobria y cálida. El objetivo no es solo estético, sino funcional: mejorar concentración, contraste y legibilidad para una audiencia sensible a pantallas recargadas.

### Principios visuales aplicados

- modo oscuro coherente en toda la app;
- superficies con bordes suaves y contraste suficiente;
- acento ámbar para medicación;
- acento naranja para citas;
- componentes de gran claridad táctil;
- jerarquía tipográfica clara;
- fondos con glow suave para transmitir calma y cuidado.

### Accesibilidad aplicada

- tamaños mínimos de tipografía reforzados en vistas críticas;
- áreas táctiles amplias;
- contraste alto sobre fondos oscuros;
- textos y CTAs simplificados;
- reducción de ruido visual en pantallas de alerta.

## Flujos principales de navegación

### Onboarding y acceso

- selección de rol;
- login administrador;
- creación de cuenta;
- login usuario;
- vinculación mediante código manual o flujo de conexión.

### Home de administrador

Desde el panel del administrador se accede a:

- dashboard;
- medicamentos;
- citas;
- alertas;
- actividad reciente.

### Home de usuario mayor

El home del usuario mayor muestra:

- saludo contextual;
- progreso diario;
- próxima medicación;
- próxima cita médica;
- acceso directo a la simulación en tiempo real;
- acciones rápidas.

## Pantallas relevantes

### `alerta_medicacion_screen.dart`

Pantalla centrada en una toma concreta. Su diseño prioriza:

- lectura inmediata;
- confirmación simple;
- CTA principal fijo en la parte inferior;
- opción de posponer;
- respuesta visual clara tras confirmar.

### `alerta_cita_screen.dart`

Pantalla de detalle de una cita desde un recordatorio. Permite gestionar el aviso y actualiza el comportamiento de la simulación según el tipo de recordatorio recibido.

### `simulacion_alertas_screen.dart`

Vista de simulación del lock screen del móvil:

- muestra tarjetas dark de notificación;
- unifica el lenguaje visual entre medicación y citas;
- permite ver varias alertas a la vez;
- refresca periódicamente el estado visible.

## Rutas principales

La navegación se centraliza en `AppRouter`. Algunas rutas clave son:

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

- Flutter SDK compatible con `sdk: ^3.11.1`
- Dart incluido con Flutter
- Xcode si se compila para iOS
- cuenta y proyecto de Supabase para modo backend

### Dependencias principales

- `flutter`
- `supabase_flutter`
- `shared_preferences`

### Variables de entorno

La app espera:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Puede ejecutarse con un archivo como:

```json
{
  "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
  "SUPABASE_ANON_KEY": "TU_ANON_KEY"
}
```

Ejemplo de arranque:

```bash
flutter pub get
flutter run --dart-define-from-file=env/dev.json
```

Si no se proporcionan variables válidas, la app entra en modo local y utiliza datos de ejemplo.

## Comandos útiles

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar la app

```bash
flutter run --dart-define-from-file=env/dev.json
```

### Analizar código

```bash
flutter analyze
```

### Ejecutar tests

```bash
flutter test
```

### Formatear código

```bash
dart format lib test
```

## Decisiones técnicas relevantes

### 1. Arquitectura ligera en lugar de sobreingeniería

No se ha forzado el uso de `Provider`, `Bloc` o arquitecturas más complejas. Para el alcance actual, el binomio repositorio + servicio + estado local es suficiente, legible y fácil de evolucionar.

### 2. Soporte híbrido real/mock

Gran parte del valor del proyecto está en que puede seguir funcionando sin backend totalmente operativo. Esto permite iterar rápidamente sobre UX, flujos y demostraciones.

### 3. Modelo de dominio desacoplado

Los modelos están preparados para mapear tanto desde datos mock como desde Supabase, reduciendo acoplamiento con la UI.

### 4. Simulación derivada del dominio

La simulación no se limita a pintar una lista estática; interpreta estados reales de tomas, citas y alertas para representar el comportamiento esperado de la app.

## Calidad y mantenimiento

El proyecto está preparado para seguir creciendo gracias a:

- organización por features;
- reutilización de widgets compartidos;
- tema centralizado;
- modelos consistentes;
- repositorios con API estable;
- utilidades de formateo reutilizables;
- reglas visuales homogéneas entre pantallas.

## Mejoras futuras recomendadas

- añadir tests unitarios para reglas de recordatorios y expiración;
- ampliar tests de widgets para flujos de alerta;
- incorporar estado reactivo más centralizado si el proyecto sigue creciendo;
- añadir notificaciones push reales;
- completar trazabilidad histórica de citas gestionadas;
- incorporar perfiles y permisos más finos entre cuidador y familiar.

## Resumen

Aviso Vital es una app Flutter enfocada en cuidado, adherencia y comunicación clara para personas mayores. El proyecto ya incorpora una base sólida de arquitectura, UI, navegación y lógica de negocio, y destaca especialmente por su simulación en tiempo real del móvil del usuario, el tratamiento accesible de alertas y la convivencia entre modo local y backend real.

La base actual es suficientemente sólida para continuar evolucionando tanto como prototipo académico de alta calidad como producto funcional en crecimiento.
