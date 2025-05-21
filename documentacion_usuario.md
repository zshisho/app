# Documentación de FitMotion - Aplicación iOS para Análisis de Vectores de Movimiento en Ejercicios

## Índice

1. [Introducción](#introducción)
2. [Requisitos del Sistema](#requisitos-del-sistema)
3. [Estructura del Proyecto](#estructura-del-proyecto)
4. [Arquitectura](#arquitectura)
5. [Componentes Principales](#componentes-principales)
6. [Flujo de Datos](#flujo-de-datos)
7. [Guía de Instalación](#guía-de-instalación)
8. [Guía de Uso](#guía-de-uso)
9. [Personalización](#personalización)
10. [Solución de Problemas](#solución-de-problemas)
11. [Extensión y Mejoras](#extensión-y-mejoras)
12. [Referencias](#referencias)

## Introducción

FitMotion es una aplicación iOS diseñada para analizar vectores de movimiento en ejercicios de musculación en tiempo real, utilizando la cámara del dispositivo. La aplicación identifica grupos musculares involucrados y cuantifica su nivel de activación, diferenciando entre objetivos de fuerza e hipertrofia.

### Características Principales

- Detección de pose humana en tiempo real mediante Vision y ARKit
- Análisis biomecánico de ejercicios de musculación
- Clasificación y cuantificación de activación muscular
- Detección de errores comunes en la ejecución
- Feedback visual inmediato
- Modos específicos para entrenamiento de fuerza e hipertrofia
- Visualización de activación muscular con código de colores

## Requisitos del Sistema

### Hardware
- iPhone XR/XS o superior (recomendado iPhone 12 o superior)
- Chip A12 Bionic o superior
- 2GB RAM mínimo (recomendado 4GB o más)
- 100MB de espacio de almacenamiento disponible

### Software
- iOS 15.0 o superior
- Xcode 13.0 o superior para desarrollo
- Swift 5.5 o superior

### Dependencias
- Vision Framework (incluido en iOS)
- ARKit (incluido en iOS)
- AVFoundation (incluido en iOS)
- SwiftUI (incluido en iOS)
- Combine (incluido en iOS)

## Estructura del Proyecto

```
FitMotionApp/
├── Models/                  # Modelos de datos
│   ├── BodyPose.swift       # Modelo de pose corporal
│   └── ...
├── Views/                   # Vistas de la interfaz de usuario
│   ├── ExerciseAnalysisView.swift  # Vista principal de análisis
│   └── ...
├── ViewModels/              # ViewModels (MVVM)
│   ├── ExerciseAnalysisViewModel.swift  # ViewModel principal
│   └── ...
├── Services/                # Servicios de la aplicación
│   ├── PoseDetectionService.swift  # Servicio de detección de pose
│   └── ...
├── AnalysisEngine/          # Motor de análisis
│   ├── MuscleAnalysisService.swift  # Servicio de análisis muscular
│   └── ...
├── Resources/               # Recursos (imágenes, etc.)
│   ├── Assets.xcassets      # Catálogo de activos
│   └── ...
└── App/                     # Punto de entrada de la aplicación
    └── FitMotionApp.swift   # Archivo principal de la app
```

## Arquitectura

FitMotion sigue una arquitectura MVVM (Model-View-ViewModel) con capas adicionales para el procesamiento de visión y análisis biomecánico:

1. **Capa de Presentación (UI)**
   - Vistas SwiftUI
   - ViewModels

2. **Capa de Dominio**
   - Modelos
   - Servicios

3. **Capa de Análisis de Movimiento**
   - Motor de Análisis
   - Clasificador de Grupos Musculares
   - Detector de Poses
   - Analizador de Vectores

4. **Capa de Datos**
   - Repositorios
   - Persistencia

5. **Frameworks Nativos**
   - Vision
   - ARKit
   - AVFoundation

## Componentes Principales

### BodyPose

Modelo que representa una pose corporal detectada, incluyendo:
- Puntos clave (keypoints) del cuerpo
- Ángulos articulares
- Vectores entre puntos clave
- Niveles de confianza de detección

```swift
struct BodyPose {
    var keypoints: [JointType: CGPoint]
    var jointAngles: [JointAngleType: Float]
    var confidences: [JointType: Float]
    var vectors: [VectorType: CGVector]
    var timestamp: TimeInterval
    
    // Inicializadores y métodos
}
```

### PoseDetectionService

Servicio responsable de la captura de video y detección de poses:
- Configuración de la sesión de captura
- Procesamiento de frames de video
- Detección de pose mediante Vision
- Notificación de poses detectadas

```swift
class PoseDetectionService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Propiedades y métodos para captura y detección
    
    func startCapture()
    func stopCapture()
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer
}
```

### MuscleAnalysisService

Servicio para analizar grupos musculares y estimar su activación:
- Procesamiento de poses detectadas
- Determinación de fases del movimiento
- Estimación de activación muscular
- Análisis de calidad del ejercicio
- Detección de errores

```swift
class MuscleAnalysisService {
    // Propiedades y métodos para análisis muscular
    
    func processPose(_ pose: BodyPose)
    func setTrainingMode(_ mode: TrainingMode)
    func setExerciseType(_ exerciseType: ExerciseType)
}
```

### ExerciseAnalysisViewModel

ViewModel que coordina la detección de pose y el análisis muscular:
- Gestión del estado de la aplicación
- Coordinación entre servicios
- Exposición de datos para la UI
- Manejo de acciones del usuario

```swift
class ExerciseAnalysisViewModel: ObservableObject {
    // Propiedades publicadas para la UI
    
    func startCapture()
    func stopCapture()
    func toggleTrainingMode()
    func toggleMuscleActivation()
    func cycleExerciseType()
}
```

### ExerciseAnalysisView

Vista principal que muestra la cámara y los resultados del análisis:
- Previsualización de cámara
- Visualización de pose detectada
- Visualización de activación muscular
- Panel de información y controles
- Feedback sobre errores detectados

```swift
struct ExerciseAnalysisView: View {
    @ObservedObject var viewModel: ExerciseAnalysisViewModel
    
    var body: some View {
        // Implementación de la interfaz de usuario
    }
}
```

## Flujo de Datos

1. **Captura de Video**
   - `PoseDetectionService` captura frames de video mediante AVFoundation

2. **Detección de Pose**
   - Los frames se procesan con Vision para detectar poses humanas
   - Se extraen puntos clave y se crea un objeto `BodyPose`

3. **Análisis de Pose**
   - `MuscleAnalysisService` recibe la pose detectada
   - Analiza ángulos articulares y vectores de movimiento
   - Determina la fase del movimiento (concéntrica, excéntrica, isométrica)

4. **Clasificación Muscular**
   - Se estima la activación de diferentes grupos musculares
   - Se ajusta según el tipo de ejercicio y modo de entrenamiento

5. **Análisis de Calidad**
   - Se evalúa la calidad de la ejecución
   - Se detectan posibles errores o riesgos

6. **Actualización de UI**
   - `ExerciseAnalysisViewModel` recibe los resultados del análisis
   - Actualiza las propiedades publicadas
   - La UI se actualiza automáticamente mediante SwiftUI

## Guía de Instalación

### Requisitos Previos
- Xcode 13.0 o superior
- Cuenta de desarrollador de Apple (para probar en dispositivo físico)

### Pasos de Instalación

1. **Clonar el Repositorio**
   ```bash
   git clone https://github.com/tuusuario/FitMotion.git
   cd FitMotion
   ```

2. **Abrir el Proyecto en Xcode**
   ```bash
   open FitMotion.xcodeproj
   ```

3. **Configurar Equipo de Desarrollo**
   - En Xcode, selecciona el proyecto FitMotion
   - En la pestaña "Signing & Capabilities", selecciona tu equipo de desarrollo

4. **Compilar y Ejecutar**
   - Selecciona un dispositivo iOS compatible como destino
   - Presiona el botón de ejecutar (▶️) o usa Cmd+R

5. **Permisos de Cámara**
   - La primera vez que ejecutes la aplicación, deberás conceder permisos de cámara
   - Estos permisos son esenciales para el funcionamiento de la aplicación

## Guía de Uso

### Configuración Inicial

1. **Posicionamiento del Dispositivo**
   - Coloca el dispositivo a 2-3 metros de distancia
   - Asegúrate de que todo tu cuerpo sea visible en la pantalla
   - Usa un soporte o trípode para estabilidad

2. **Selección de Ejercicio**
   - Al iniciar la aplicación, se configura automáticamente para sentadillas
   - Usa el botón de ciclo (↻) para cambiar entre ejercicios disponibles

3. **Selección de Modo de Entrenamiento**
   - Elige entre modo Fuerza o Hipertrofia según tu objetivo
   - El modo afecta los parámetros de análisis y feedback

### Realización de Ejercicios

1. **Posición Inicial**
   - Colócate en la posición inicial del ejercicio seleccionado
   - Espera a que la aplicación detecte tu pose (indicado por el esqueleto superpuesto)

2. **Ejecución del Ejercicio**
   - Realiza el ejercicio a velocidad controlada
   - Observa el feedback en tiempo real

3. **Interpretación del Feedback**
   - **Esqueleto**: Muestra la pose detectada
   - **Mapa Muscular**: Visualiza la activación muscular con código de colores
   - **Fase de Movimiento**: Indica la fase actual (concéntrica, excéntrica, isométrica)
   - **Calidad**: Porcentaje que indica la calidad global de la ejecución
   - **Correcciones**: Alertas sobre posibles errores o mejoras

### Controles Principales

- **Botón de Modo**: Alterna entre modos Fuerza y Hipertrofia
- **Botón de Visualización**: Activa/desactiva la visualización de activación muscular
- **Botón de Ejercicio**: Cambia al siguiente tipo de ejercicio

## Personalización

### Añadir Nuevos Ejercicios

1. **Definir el Tipo de Ejercicio**
   ```swift
   // En ExerciseType.swift o archivo similar
   enum ExerciseType {
       case squat
       case deadlift
       // Añadir nuevo ejercicio
       case newExercise
   }
   ```

2. **Implementar Análisis para el Nuevo Ejercicio**
   ```swift
   // En MuscleAnalysisService.swift
   private func determineNewExercisePhase(currentPose: BodyPose, previousPose: BodyPose) -> MovementPhase {
       // Implementación específica para el nuevo ejercicio
   }
   
   private func estimateNewExerciseMuscleActivation(pose: BodyPose, phase: MovementPhase) -> [MuscleGroup: Float] {
       // Implementación específica para el nuevo ejercicio
   }
   ```

3. **Actualizar el Método de Procesamiento Principal**
   ```swift
   // En MuscleAnalysisService.swift, actualizar los métodos switch
   switch currentExercise {
       case .squat: // ...
       case .deadlift: // ...
       case .newExercise:
           return determineNewExercisePhase(currentPose: currentPose, previousPose: previousPose)
   }
   ```

### Integrar Modelos de ML Personalizados

1. **Entrenar y Exportar Modelo**
   - Entrena un modelo de Core ML para tu caso específico
   - Exporta el modelo en formato .mlmodel

2. **Añadir el Modelo al Proyecto**
   - Arrastra el archivo .mlmodel a tu proyecto en Xcode
   - Asegúrate de que está incluido en el target de la aplicación

3. **Actualizar PoseDetectionService**
   ```swift
   // En PoseDetectionService.swift
   private func setupVision() {
       do {
           let modelURL = Bundle.main.url(forResource: "TuModeloPersonalizado", withExtension: "mlmodelc")!
           let model = try MLModel(contentsOf: modelURL)
           visionModel = try VNCoreMLModel(for: model)
           poseRequest = VNCoreMLRequest(model: visionModel!, completionHandler: handlePoseDetection)
           // ...
       } catch {
           print("Error al configurar Vision: \(error)")
       }
   }
   ```

### Ajustar Parámetros de Análisis

Los parámetros de análisis se pueden ajustar para mejorar la precisión según las necesidades específicas:

1. **Umbrales de Detección de Errores**
   ```swift
   // En MuscleAnalysisService.swift
   private func detectSquatErrors(pose: BodyPose, phase: MovementPhase) -> [ExerciseError] {
       // Ajustar umbrales según necesidad
       if let depth = calculateSquatDepth(pose: pose), depth < 0.8 { // Cambiar 0.7 a 0.8 para mayor exigencia
           errors.append(.insufficientDepth)
       }
   }
   ```

2. **Factores de Activación Muscular**
   ```swift
   // En MuscleAnalysisService.swift
   private func estimateSquatMuscleActivation(pose: BodyPose, phase: MovementPhase) -> [MuscleGroup: Float] {
       // Ajustar factores de activación
       if phase == .concentric {
           gluteActivation *= 1.3 // Cambiar 1.2 a 1.3 para mayor énfasis
       }
   }
   ```

## Solución de Problemas

### Problemas Comunes y Soluciones

1. **Detección de Pose Inestable**
   - **Síntoma**: El esqueleto superpuesto parpadea o desaparece frecuentemente
   - **Solución**: Mejorar la iluminación, evitar contraluces, asegurar que todo el cuerpo es visible

2. **Rendimiento Lento**
   - **Síntoma**: La aplicación se ejecuta con lag o se calienta el dispositivo
   - **Solución**: Cerrar aplicaciones en segundo plano, usar un dispositivo más reciente, reducir la resolución de procesamiento

3. **Clasificación Incorrecta de Ejercicios**
   - **Síntoma**: La aplicación no reconoce correctamente el ejercicio realizado
   - **Solución**: Asegurarse de seleccionar manualmente el ejercicio correcto, realizar movimientos más definidos

4. **Falsos Positivos en Errores**
   - **Síntoma**: La aplicación muestra errores aunque la ejecución sea correcta
   - **Solución**: Ajustar los umbrales de detección de errores en el código

### Logs y Depuración

La aplicación incluye un sistema de logging para facilitar la depuración:

```swift
// Activar logs detallados
UserDefaults.standard.set(true, forKey: "FitMotion_DetailedLogging")

// Ver logs en la consola de Xcode
// Filtrar por "FitMotion" para encontrar logs relevantes
```

## Extensión y Mejoras

### Áreas de Mejora Potencial

1. **Modelos de ML Mejorados**
   - Entrenar modelos específicos para diferentes tipos de ejercicios
   - Incorporar datos de EMG real para mejorar la estimación de activación muscular

2. **Análisis Longitudinal**
   - Implementar seguimiento de progreso a lo largo del tiempo
   - Análisis de tendencias y mejoras en la técnica

3. **Personalización por Usuario**
   - Calibración específica según proporciones corporales
   - Ajuste de parámetros según nivel de experiencia

4. **Integración con Wearables**
   - Combinar datos de cámara con sensores de wearables
   - Incorporar datos de frecuencia cardíaca y otros biomarcadores

### Contribuciones

Si deseas contribuir al proyecto:

1. Haz fork del repositorio
2. Crea una rama para tu característica (`git checkout -b feature/amazing-feature`)
3. Realiza tus cambios y haz commit (`git commit -m 'Add some amazing feature'`)
4. Push a la rama (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## Referencias

### Documentación Oficial
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [ARKit](https://developer.apple.com/documentation/arkit)
- [Core ML](https://developer.apple.com/documentation/coreml)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)

### Recursos de Biomecánica
- Delavier, F. (2010). Strength Training Anatomy. Human Kinetics.
- Schoenfeld, B. J. (2016). Science and Development of Muscle Hypertrophy. Human Kinetics.
- Contreras, B. (2019). Glute Lab: The Art and Science of Strength and Physique Training. Victory Belt Publishing.

### Artículos Técnicos
- Cao, Z., Hidalgo, G., Simon, T., Wei, S. E., & Sheikh, Y. (2021). OpenPose: Realtime Multi-Person 2D Pose Estimation Using Part Affinity Fields. IEEE Transactions on Pattern Analysis and Machine Intelligence.
- Schoenfeld, B. J., Contreras, B., Willardson, J. M., Fontana, F., & Tiryaki-Sonmez, G. (2014). Muscle activation during low- versus high-load resistance training in well-trained men. European Journal of Applied Physiology, 114(12), 2491-2497.

---

© 2025 FitMotion. Todos los derechos reservados.
