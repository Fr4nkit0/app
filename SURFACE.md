# Surface Brief: The Premium SaaS (Mobile Edition)

Este documento registra la dirección visual para la aplicación móvil de Marilin, adaptando el contrato de diseño "Premium SaaS" (estilo Vercel/Stripe) que utilizamos en la web para el ecosistema de Flutter. Todo agente de IA trabajando en Flutter debe seguir estrictamente este documento para la UI.

## La Dirección
**The Premium SaaS**
* **Linaje:** Aplicaciones modernas, limpias, de alto rendimiento y estética B2B.
* **Tesis:** Elegancia lograda a través de sombras sutiles, bordes redondeados, tipografía nítida y ausencia de componentes pesados o sombras duras.

## Reglas Principales para Flutter (Material 3)

### 1. Viewport & Layout (Fondos y Tarjetas)
Una interfaz limpia que se sienta flotante y respirable.
* **Fondo de Pantalla (Scaffold):** Usar un gris muy sutil como fondo general (`backgroundColor: const Color(0xFFF8FAFC)` - equivalente a Slate 50).
* **Cards & Panels:** El contenido debe ir sobre contenedores blancos flotantes (`Colors.white`).
* **Elevación:** NO usar el `Card` clásico de Material con elevaciones oscuras. Usar `Container` con `elevation: 0`, un borde súper delicado (`Border.all(color: Colors.grey.shade200)`) y un `BoxShadow` extremadamente difuminado y sutil (ej. blur radius alto, opacidad de 0.04).

### 2. Materiales & Tipografía
* **Radios y Bordes:** Usar esquinas redondeadas grandes para contenedores (`BorderRadius.circular(16)` a `24`) y redondeo medio para botones e inputs (`BorderRadius.circular(10)` a `12`).
* **Tipografía:** Usar colores de alto contraste para el texto primario (ej. `Color(0xFF0F172A)` - Slate 900) y grises suaves para textos secundarios (`Colors.grey.shade500`).

### 3. Paleta de Colores
Una paleta prístina, profesional y vibrante:
* **Backgrounds:** Slate 50 (`#f8fafc`) para los Scaffold, White (`#ffffff`) para las tarjetas flotantes.
* **Acciones Primarias (Botones Activos):** El usuario prefirió un **Azul Brillante y Limpio** (equivalente al `blue-600` de Tailwind, ej. `Color(0xFF2563EB)`) para las acciones principales. **EVITAR** tonos industriales oscuros o casi negros para los botones principales.
* **Acciones Secundarias:** Botones blancos con texto oscuro y borde gris suave (`OutlinedButton` con estilo específico).
* **Badges y Chips:** Pequeñas píldoras suaves sin bordes duros, usando fondos con baja opacidad (ej. azul muy clarito con texto azul fuerte para "Activo").

### 4. Inputs y Formularios
* Usar `OutlineInputBorder` con colores grises muy claros (`Colors.grey.shade200`).
* Cuando el input está enfocado, el borde debe ser del azul primario, logrando un efecto limpio.
* Evitar fondos grises oscuros adentro de las barras de búsqueda.

## Riesgos a Evitar en Flutter
* **Material Clásico:** Es fácil caer en el aspecto estándar de "Android 2018" si se usan los componentes por defecto sin ajustar el tema. Se debe sobreescribir el `ThemeData` para imponer `elevation: 0`, colores planos y redondeos grandes.
* **Oscuridad:** El usuario detesta el look oscuro/industrial. Todo debe sentirse luminoso y espacioso.

---
*Contrato estético registrado para asegurar consistencia absoluta entre la Web y la App.*
