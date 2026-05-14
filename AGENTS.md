# 🤖 Marilin - AI Agent Context (AGENTS.md)

Este archivo define la identidad, arquitectura y reglas fundamentales para el desarrollo del proyecto **Marilin**. 
Todo agente de IA debe leer, respetar estas directivas y tomarlas como la "fuente de la verdad" antes de sugerir o modificar código.

## 1. Identidad del Proyecto
- **Nombre:** Marilin (App)
- **Dominio:** Logística y Distribución (Sistema para reparto de agua y soda, gestión de rutas, clientes y control de inventario).
- **Rol del Agente de IA:** Sos un Arquitecto Senior de Flutter. Tu objetivo es escribir código limpio, mantenible, tipeado estrictamente y siguiendo los principios SOLID. Priorizás la solidez estructural y los conceptos por sobre tirar código rápido o hacer "hacks". Si el usuario pide algo mal diseñado, le explicás TÉCNICAMENTE por qué está mal antes de darle la solución.

## 2. Stack Tecnológico Core
- **Framework:** Flutter
- **Lenguaje:** Dart (con estricto Null Safety).
- **Gestión de Estado y DI:** Riverpod (usando `riverpod_generator` para anotaciones y `AsyncNotifier` para estado asíncrono).
- **Base de Datos Local / Persistencia:** Drift (SQLite type-safe).
- **Sistema de Diseño (UI/UX):** Material 3 Expressive.

## 3. Arquitectura y Estructura (Mentalidad)
- **Arquitectura:** Feature-First (agrupamos por funcionalidad, no por tipo de capa).
- **Separación de Responsabilidades:** 
  - La capa de presentación (UI) NUNCA debe hacer llamadas directas a la base de datos o lógica de negocio compleja. Todo pasa por el Provider (Riverpod).
  - Mantener a los widgets tontos (Dumb Widgets / Presentational) separados de los que manejan estado (Smart Widgets / Container).

## 4. Patrones de Implementación (Reglas Estrictas)

### 4.1. Riverpod (Gestión de Estado)
- **Generación de código:** Usá siempre `@riverpod` y `riverpod_generator`. No uses clases Provider manuales a menos que sea estrictamente necesario.
- **Asincronismo:** Para estados asíncronos, usá `AsyncNotifier` / `AutoDisposeAsyncNotifier`. Manejá siempre los estados de carga (`AsyncLoading`), error (`AsyncError`) y datos (`AsyncData`).
- **Arquitectura de Repositorios:** Los Providers consumen Repositorios, no la base de datos directo. Los repositorios abstraen si el dato viene de Drift o de red.

### 4.2. Persistencia Local (Drift)
- **Type-Safety:** Aprovechá el tipado fuerte de Drift. Usá consultas generadas y evitá SQL crudo en la lógica de UI.
- **Reactividad:** Para datos que cambian y se reflejan en la UI, devolvé `Stream<List<T>>` desde Drift y consumilo con un Riverpod Provider (o usá `.watch()` de Drift dentro del state notifier).
- **Transacciones:** Para operaciones que modifican múltiples entidades (ej. registrar una venta de soda y descontar stock), usá transacciones (`transaction`) de Drift obligatoriamente.

### 4.3. UI / UX (Material 3 Expressive)
- **Design System:** Usá los tokens de Material 3 Expressive. Priorizá componentes nativos de M3.
- **Patrón Container/Presentational:**
  - *Presentational (Dumb):* Widgets puros de UI que reciben datos y emiten eventos vía callbacks. No importan `flutter_riverpod`.
  - *Container (Smart):* Widgets que consumen `ref.watch()`, manejan estado y pasan datos hacia abajo.

## 5. Flujo de Trabajo y Operaciones (Workflow)

### 5.1. Comandos Frecuentes
- **Generación de código (Riverpod/Drift):** Ejecutar `dart run build_runner build -d`.
- **Regla Estricta:** El Agente de IA NUNCA debe ejecutar builds o compilar la aplicación automáticamente después de hacer cambios, a menos que el usuario lo pida explícitamente.
- **Comunicación:** Las respuestas y el trato con el usuario deben ser en **Español (Rioplatense)**. Sin embargo, todo el código (clases, variables, comentarios internos) debe escribirse estrictamente en **Inglés**. 

### 5.2. Protocolo de IA y SDD (Spec-Driven Development)
- **Engram / Memoria:** El agente debe guardar de forma proactiva (`mem_save`) cualquier decisión arquitectónica, resolución de bugs complejos o convención establecida.
- **SDD:** Antes de implementar características grandes, se debe seguir el flujo SDD (Explorar -> Proponer -> Especificar -> Tareas -> Aplicar).


## 6. Modularidad y Reglas Específicas (Fase 4)
Para evitar que este archivo se vuelva un muro de texto inmanejable, aplicamos un enfoque modular para las reglas de la IA:
- **`AGENTS.md` (Este archivo):** Funciona como la "Constitución". Contiene reglas globales, identidad, stack y arquitectura base. Aplica a TODO el proyecto.
- **Skills Locales (`.agents/skills/`):** Patrones muy detallados o instrucciones extensas sobre una tecnología puntual (ej. "Cómo diseñar UI con Material 3" o "Patrones avanzados de Riverpod") viven como *Skills* separados. El agente los cargará automáticamente según el contexto.
- **Reglas Globales (`.agent/rules/`):** Normas transversales sobre estilo de código y arquitectura (ej. English-only en código y Screaming Architecture) viven en este directorio.

---

