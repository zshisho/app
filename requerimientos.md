# Requerimientos Funcionales para Aplicación iOS de Análisis de Movimiento

## Objetivo Principal
Desarrollar una aplicación iOS que utilice la cámara para analizar vectores de movimiento en ejercicios de musculación, identificar grupos musculares involucrados y cuantificar su nivel de activación durante la ejecución del ejercicio.

## Requerimientos Funcionales Clave

### 1. Captura y Análisis de Video
- Acceso y utilización de la cámara del dispositivo iOS
- Procesamiento de video en tiempo real
- Detección de pose humana y puntos clave del cuerpo
- Tracking de movimiento continuo durante la ejecución del ejercicio

### 2. Identificación de Ejercicios
- Reconocimiento automático del tipo de ejercicio que se está realizando
- Soporte para ejercicios fundamentales (sentadilla, peso muerto, press de banca, etc.)
- Capacidad de añadir nuevos ejercicios o patrones de movimiento

### 3. Análisis Biomecánico
- Cálculo de ángulos articulares en tiempo real
- Análisis de vectores de movimiento y trayectorias
- Detección de desviaciones respecto a patrones ideales
- Evaluación de velocidad y aceleración en diferentes fases del movimiento

### 4. Identificación de Grupos Musculares
- Mapeo de grupos musculares involucrados en cada ejercicio
- Clasificación de músculos primarios, secundarios y estabilizadores
- Visualización del mapa muscular con código de colores según nivel de activación

### 5. Cuantificación de Actividad Muscular
- Estimación del nivel de activación de cada grupo muscular
- Cálculo de tiempo bajo tensión para cada músculo
- Análisis diferenciado para objetivos de fuerza vs. hipertrofia
- Métricas de intensidad relativa para cada grupo muscular

### 6. Feedback en Tiempo Real
- Indicaciones visuales sobre la correcta ejecución
- Alertas sobre posibles errores o riesgos
- Sugerencias de corrección durante el ejercicio
- Información sobre grupos musculares activos en cada fase

### 7. Análisis Post-Ejercicio
- Resumen detallado de la ejecución
- Estadísticas de activación muscular
- Comparación con ejecuciones anteriores
- Recomendaciones para mejorar la técnica

### 8. Personalización
- Calibración según características físicas del usuario
- Ajuste de parámetros según nivel de experiencia
- Configuración de objetivos (fuerza o hipertrofia)
- Preferencias de feedback y visualización

## Requerimientos Técnicos

### Frameworks y Tecnologías
- **Vision Framework**: Para detección de pose humana y análisis de movimiento
- **ARKit**: Para tracking espacial y visualización aumentada
- **Core ML**: Para modelos de machine learning de clasificación de ejercicios
- **Metal/Core Image**: Para procesamiento eficiente de imágenes
- **Swift y SwiftUI/UIKit**: Para desarrollo de la interfaz y lógica de la aplicación

### Requisitos de Hardware
- Compatibilidad con iPhone XR/XS o superior
- Utilización óptima en dispositivos con chip A14 o superior
- Soporte para cámara frontal y trasera
- Optimización para diferentes condiciones de iluminación

### Consideraciones de Rendimiento
- Procesamiento en tiempo real (mínimo 30 FPS)
- Optimización para consumo de batería
- Gestión eficiente de memoria
- Funcionamiento sin conexión a internet

## Limitaciones y Consideraciones
- La precisión del análisis muscular se basará en modelos biomecánicos, no en mediciones directas de EMG
- La app requerirá condiciones adecuadas de iluminación y espacio
- El usuario deberá posicionar correctamente el dispositivo para capturar el ejercicio completo
- Se necesitará una fase de calibración inicial para optimizar resultados

## Métricas de Éxito
- Precisión en la identificación de grupos musculares > 90%
- Estimación de activación muscular con margen de error < 15%
- Tiempo de respuesta para feedback < 100ms
- Estabilidad de la aplicación durante sesiones de hasta 60 minutos
