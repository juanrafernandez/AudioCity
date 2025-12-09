# AudioCity Design System v2.0

## Filosofía de Diseño

AudioCity sigue una estética **limpia, moderna y funcional** inspirada en apps como Transit. El objetivo es crear una experiencia que sea:

- **Inmediata**: La información crítica es visible al instante
- **Confiable**: El diseño transmite profesionalismo y seguridad
- **Accesible**: Contrastes adecuados, tamaños táctiles correctos
- **Deleitosa**: Animaciones sutiles que hacen la app agradable de usar

### Principios de UX

1. **Información densa pero legible** - Como Transit, mostramos muchos datos sin abrumar
2. **Jerarquía visual clara** - Los elementos más importantes destacan
3. **Feedback constante** - El usuario siempre sabe qué está pasando
4. **Gestos naturales** - Pull-to-dismiss, swipe actions, haptic feedback

---

## Paleta de Colores

### Colores de Marca

| Token | Hex | Uso | Psicología |
|-------|-----|-----|------------|
| `primary` | `#FF5757` | CTAs, elementos destacados | Energía, aventura, emoción |
| `primaryDark` | `#E04545` | Estados pressed | Profundidad, acción |
| `primaryLight` | `#FFE5E5` | Fondos sutiles | Suavidad, contexto |
| `primarySurface` | `#FFF5F5` | Fondos de cards | Calidez sutil |

### Colores Secundarios

| Token | Hex | Uso |
|-------|-----|-----|
| `secondary` | `#00BFA6` | Información secundaria, alternativas |
| `gold` | `#FFB800` | Puntos, recompensas, premium |
| `info` | `#2196F3` | Información, navegación |

### Colores Semánticos

| Token | Hex | Uso |
|-------|-----|-----|
| `success` | `#4CAF50` | Completado, activo, correcto |
| `warning` | `#FF9800` | Atención, pendiente |
| `error` | `#D32F2F` | Error (diferente a primary) |

### Neutros

| Token | Light Mode | Dark Mode |
|-------|------------|-----------|
| `background` | `#FAFAFA` | `#121212` |
| `surface` | `#FFFFFF` | `#1E1E1E` |
| `textPrimary` | `#1A1A1A` | `#F5F5F5` |
| `textSecondary` | `#6B6B6B` | `#B0B0B0` |
| `textTertiary` | `#9E9E9E` | `#757575` |
| `border` | `#E5E5E5` | `#3D3D3D` |

### Colores de Nivel (Gamificación)

| Nivel | Color | Hex |
|-------|-------|-----|
| Explorador | Gris | `#9E9E9E` |
| Viajero | Azul | `#2196F3` |
| Guía Local | Verde | `#4CAF50` |
| Experto | Púrpura | `#9C27B0` |
| Maestro | Coral | `#FF5757` |

---

## Tipografía

Usamos **SF Pro** (fuente del sistema iOS) con variaciones:

### Escala Tipográfica

| Token | Tamaño | Peso | Uso |
|-------|--------|------|-----|
| `displayLarge` | 40pt | Bold Rounded | Splash, héroes |
| `displayMedium` | 32pt | Bold Rounded | Títulos principales |
| `displaySmall` | 28pt | Semibold Rounded | Subtítulos destacados |
| `headlineLarge` | 24pt | Bold | Título de pantalla |
| `headlineMedium` | 20pt | Semibold | Título de sección |
| `headlineSmall` | 18pt | Semibold | Subtítulos |
| `titleLarge` | 18pt | Semibold | Nombre de ruta |
| `titleMedium` | 16pt | Semibold | Título de elemento |
| `titleSmall` | 14pt | Semibold | Título pequeño |
| `bodyLarge` | 16pt | Regular | Descripciones |
| `bodyMedium` | 14pt | Regular | Texto estándar |
| `bodySmall` | 13pt | Regular | Texto secundario |
| `labelLarge` | 16pt | Medium | Botones grandes |
| `labelMedium` | 14pt | Medium | Botones, tabs |
| `labelSmall` | 12pt | Medium | Badges, chips |
| `caption` | 12pt | Regular | Metadatos |
| `captionSmall` | 11pt | Regular | Texto muy pequeño |

### Números

| Token | Tamaño | Uso |
|-------|--------|-----|
| `numberLarge` | 32pt Mono Bold | ETA, puntos totales |
| `numberMedium` | 20pt Mono Semibold | Tiempos, distancias |
| `numberSmall` | 14pt Mono Medium | Badges numéricos |

---

## Espaciado

Sistema basado en **múltiplos de 4** para ritmo visual:

| Token | Valor | Uso |
|-------|-------|-----|
| `xxs` | 2pt | Micro ajustes |
| `xs` | 4pt | Entre elementos relacionados |
| `sm` | 8pt | Espaciado pequeño |
| `md` | 12pt | Espaciado medio-pequeño |
| `base` | 16pt | Espaciado base |
| `lg` | 20pt | Espaciado medio-grande |
| `xl` | 24pt | Espaciado grande |
| `xxl` | 32pt | Entre secciones |
| `xxxl` | 40pt | Separaciones mayores |
| `mega` | 48pt | Márgenes de pantalla |

### Tokens de Layout

| Token | Valor |
|-------|-------|
| `containerPadding` | 16pt |
| `cardPadding` | 16pt |
| `sectionSpacing` | 24pt |

---

## Radios de Esquina

| Token | Valor | Uso |
|-------|-------|-----|
| `xs` | 4pt | Inputs pequeños |
| `sm` | 8pt | Chips, tags |
| `md` | 12pt | Cards pequeñas |
| `lg` | 16pt | Cards principales |
| `xl` | 20pt | Modales |
| `xxl` | 24pt | Sheets |
| `full` | 9999pt | Circular (avatares) |

---

## Sombras

| Token | Blur | Y Offset | Opacidad | Uso |
|-------|------|----------|----------|-----|
| `sm` | 4pt | 2pt | 4% | Cards en reposo |
| `md` | 8pt | 4pt | 8% | Cards hover |
| `lg` | 16pt | 8pt | 12% | Elementos flotantes |
| `xl` | 24pt | 12pt | 16% | Modales |

---

## Animaciones

### Duraciones

| Token | Valor | Uso |
|-------|-------|-----|
| `fast` | 100ms | Feedback inmediato |
| `normal` | 200ms | Transiciones estándar |
| `slow` | 300ms | Transiciones complejas |
| `slower` | 400ms | Animaciones de entrada |

### Curvas

- **Spring** (response: 0.3, damping: 0.7) - Interacciones
- **Bouncy** (response: 0.4, damping: 0.6) - Celebraciones
- **EaseOut** - Entradas
- **EaseInOut** - Transiciones

---

## Componentes

### Botones

```
ACButton("Texto", icon: "play.fill", style: .primary, size: .medium)
```

| Estilo | Fondo | Texto | Uso |
|--------|-------|-------|-----|
| `primary` | Coral | Blanco | Acción principal |
| `secondary` | Transparente + borde | Coral | Acción secundaria |
| `tertiary` | Transparente | Coral | Acción terciaria |
| `ghost` | Transparente | Gris | Cancelar, cerrar |
| `destructive` | Rojo | Blanco | Eliminar |

| Tamaño | Altura | Uso |
|--------|--------|-----|
| `small` | 32pt | Acciones compactas |
| `medium` | 44pt | Estándar (mínimo táctil iOS) |
| `large` | 52pt | CTAs destacados |

### Cards

- **ACRouteCard**: Card horizontal completa con imagen, título, metadatos
- **ACCompactRouteCard**: Card vertical para carruseles (180px ancho)
- **ACETACard**: Datos numéricos estilo Transit (tiempo/distancia)
- **ACInfoCard**: Información con icono y descripción

### Inputs

- **ACTextField**: Campo de texto con icono y validación
- **ACSearchField**: Búsqueda con bordes redondeados
- **ACTextArea**: Área de texto multi-línea
- **ACChip**: Selección de filtros
- **ACToggle**: Switch con descripción
- **ACStepper**: Contador numérico

### Navegación

- **ACSectionHeader**: Cabecera de sección con acción "Ver todo"
- **ACSegmentedControl**: Control segmentado
- **ACProgressBar**: Barra de progreso
- **ACStepIndicator**: Indicador de pasos (wizard)
- **ACTabBar**: Tab bar personalizada

### Feedback

- **ACEmptyState**: Estado vacío con ilustración
- **ACLoadingState**: Indicador de carga
- **ACErrorState**: Estado de error con retry
- **ACToast**: Notificación temporal
- **ACAlertBanner**: Banner de alerta persistente
- **ACSkeleton**: Placeholder de carga

### Mapa

- **ACMapPin**: Pin personalizado con estados
- **ACMapInfoCard**: Card flotante de información
- **ACNowPlayingCard**: Controles de reproducción
- **ACRoutePathIndicator**: Progreso visual de paradas

---

## Accesibilidad

### Contraste

- Texto primario sobre fondo: **≥ 7:1** (AAA)
- Texto secundario sobre fondo: **≥ 4.5:1** (AA)
- Elementos interactivos: **≥ 3:1**

### Tamaños Táctiles

- Mínimo: **44x44pt** (estándar iOS)
- Recomendado: **48x48pt** para acciones principales

### VoiceOver

- Todos los componentes tienen `accessibilityLabel` descriptivos
- Los estados (seleccionado, deshabilitado) se anuncian
- Los controles de reproducción son accesibles

---

## Dark Mode

El sistema soporta modo oscuro automático:

- Los colores semánticos se adaptan automáticamente
- El coral primario se ajusta a `#FF6B6B` para mejor legibilidad
- Las superficies usan tonos elevados para profundidad
- Las sombras se reducen (menos visibles en oscuro)

---

## Implementación en SwiftUI

### Uso de Colores

```swift
Text("Título")
    .foregroundColor(ACColors.textPrimary)
    .background(ACColors.surface)
```

### Uso de Tipografía

```swift
Text("Título de Sección")
    .font(ACTypography.headlineMedium)
```

### Uso de Espaciado

```swift
VStack(spacing: ACSpacing.md) {
    // contenido
}
.padding(ACSpacing.containerPadding)
```

### Uso de Componentes

```swift
ACButton("Comenzar Ruta", icon: "play.fill", style: .primary) {
    // acción
}

ACRouteCard(
    title: "Barrio de las Letras",
    subtitle: "Madrid, Centro",
    duration: "45 min",
    distance: "2.3 km",
    stopsCount: 8,
    onTap: { },
    onFavorite: { }
)
```

---

## Próximos Pasos

1. [ ] Migrar vistas existentes al nuevo design system
2. [ ] Añadir soporte completo de Dark Mode
3. [ ] Implementar animaciones de transición entre pantallas
4. [ ] Crear variantes de componentes para iPad
5. [ ] Documentar patrones de interacción específicos
