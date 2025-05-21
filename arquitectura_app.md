# Arquitectura de la Aplicación iOS para Análisis de Vectores de Movimiento

## Visión General

La aplicación "FitMotion" está diseñada para analizar vectores de movimiento en ejercicios de musculación en tiempo real, identificar grupos musculares involucrados y cuantificar su nivel de activación. La arquitectura sigue un patrón MVVM (Model-View-ViewModel) con capas adicionales para el procesamiento de visión y análisis biomecánico.

## Diagrama de Arquitectura

```
+-----------------------------------------------+
|                CAPA DE PRESENTACIÓN           |
|  +----------------+  +--------------------+   |
|  | Vistas (SwiftUI)|  | ViewModels        |   |
|  +----------------+  +--------------------+   |
+-----------------------------------------------+
                      |
+-----------------------------------------------+
|                CAPA DE DOMINIO                |
|  +----------------+  +--------------------+   |
|  | Modelos        |  | Servicios          |   |
|  +----------------+  +--------------------+   |
+-----------------------------------------------+
                      |
+-----------------------------------------------+
|           CAPA DE ANÁLISIS DE MOVIMIENTO      |
|  +----------------+  +--------------------+   |
|  | Motor de       |  | Clasificador de    |   |
|  | Análisis       |  | Grupos Musculares  |   |
|  +----------------+  +--------------------+   |
|  +----------------+  +--------------------+   |
|  | Detector de    |  | Analizador de      |   |
|  | Poses          |  | Vectores           |   |
|  +----------------+  +--------------------+   |
+-----------------------------------------------+
                      |
+-----------------------------------------------+
|                CAPA DE DATOS                  |
|  +----------------+  +--------------------+   |
|  | Repositorios   |  | Persistencia       |   |
|  +----------------+  +--------------------+   |
+-----------------------------------------------+
                      |
+-----------------------------------------------+
|             FRAMEWORKS NATIVOS                |
|  +----------------+  +--------------------+   |
|  | Vision         |  | ARKit              |   |
|  +----------------+  +--------------------+   |
|  +----------------+  +--------------------+   |
|  | Core ML        |  | AVFoundation       |   |
|  +----------------+  +--------------------+   |
+-----------------------------------------------+
```

## Componentes Principales

### 1. Capa de Presentación

#### Vistas (SwiftUI)
- **CameraView**: Visualización de la cámara en tiempo real con superposición de análisis
- **ExerciseAnalysisView**: Pantalla principal de análisis de ejercicios
- **MuscleActivationView**: Visualización de activación muscular
- **SettingsView**: Configuración de la aplicación
- **ExerciseHistoryView**: Historial de ejercicios analizados

#### ViewModels
- **ExerciseAnalysisViewModel**: Gestiona el estado y la lógica de la pantalla de análisis
- **MuscleActivationViewModel**: Gestiona los datos de activación muscular
- **SettingsViewModel**: Gestiona la configuración de la aplicación
- **ExerciseHistoryViewModel**: Gestiona el historial de ejercicios

### 2. Capa de Dominio

#### Modelos
- **Exercise**: Modelo de ejercicio con tipo, configuración y métricas
- **BodyPose**: Modelo de pose corporal con puntos clave y ángulos
- **MuscleGroup**: Modelo de grupo muscular con nivel de activación
- **AnalysisResult**: Resultado del análisis de un ejercicio
- **UserProfile**: Perfil del usuario con configuraciones personalizadas

#### Servicios
- **ExerciseService**: Gestión de ejercicios y análisis
- **UserService**: Gestión de perfiles de usuario
- **AnalyticsService**: Recopilación de métricas y análisis

### 3. Capa de Análisis de Movimiento

#### Motor de Análisis
- **PoseAnalysisEngine**: Motor principal de análisis de poses
- **JointAngleCalculator**: Cálculo de ángulos entre articulaciones
- **MovementVectorAnalyzer**: Análisis de vectores de movimiento
- **ExerciseClassifier**: Clasificación del tipo de ejercicio

#### Clasificador de Grupos Musculares
- **MuscleActivationEstimator**: Estimación de activación muscular
- **MuscleGroupMapper**: Mapeo de grupos musculares según ejercicio y pose
- **StrengthHypertrophyAnalyzer**: Análisis diferenciado para fuerza vs hipertrofia

#### Detector de Poses
- **PoseDetector**: Integración con Vision para detección de poses
- **PoseTracker**: Seguimiento de poses a lo largo del tiempo
- **PoseProcessor**: Procesamiento y filtrado de poses detectadas

#### Analizador de Vectores
- **VectorCalculator**: Cálculo de vectores entre puntos clave
- **TrajectoryAnalyzer**: Análisis de trayectorias de movimiento
- **VelocityAccelerationCalculator**: Cálculo de velocidad y aceleración

### 4. Capa de Datos

#### Repositorios
- **ExerciseRepository**: Acceso a datos de ejercicios
- **UserRepository**: Acceso a datos de usuario
- **AnalysisResultRepository**: Acceso a resultados de análisis

#### Persistencia
- **LocalStorage**: Almacenamiento local de datos
- **ModelStorage**: Gestión de modelos de Core ML
- **SettingsStorage**: Almacenamiento de configuraciones

### 5. Frameworks Nativos

- **Vision**: Detección de poses y análisis de imágenes
- **ARKit**: Tracking espacial y visualización aumentada
- **Core ML**: Modelos de machine learning para clasificación
- **AVFoundation**: Captura y procesamiento de video

## Flujo de la Aplicación

### 1. Inicialización
1. Carga de modelos de Core ML
2. Configuración de la sesión de cámara
3. Inicialización de servicios y repositorios
4. Carga de perfil de usuario y configuraciones

### 2. Captura y Análisis
1. Captura de frames de video en tiempo real
2. Detección de pose humana mediante Vision
3. Tracking de puntos clave del cuerpo
4. Cálculo de ángulos articulares y vectores de movimiento
5. Clasificación del tipo de ejercicio
6. Estimación de activación muscular
7. Análisis de calidad de ejecución

### 3. Visualización y Feedback
1. Superposición de puntos clave y conexiones en la vista de cámara
2. Visualización de grupos musculares activos con código de colores
3. Indicadores de calidad de ejecución
4. Alertas sobre posibles errores o riesgos
5. Métricas en tiempo real (repeticiones, tiempo bajo tensión, etc.)

### 4. Análisis Post-Ejercicio
1. Generación de resumen de la sesión
2. Almacenamiento de resultados
3. Visualización de estadísticas y progreso
4. Recomendaciones personalizadas

## Integración con Vision y ARKit

### Vision Framework
```swift
// Configuración del request de Vision para detección de pose 3D
func configurePoseDetection() {
    guard let modelURL = Bundle.main.url(forResource: "PoseEstimationModel", withExtension: "mlmodelc") else {
        fatalError("No se pudo encontrar el modelo de Core ML")
    }
    
    do {
        let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        poseRequest = VNCoreMLRequest(model: visionModel, completionHandler: handlePoseDetection)
        poseRequest.imageCropAndScaleOption = .scaleFill
    } catch {
        fatalError("Error al cargar el modelo de Vision: \(error)")
    }
}

// Procesamiento de frames de video
func processVideoFrame(_ pixelBuffer: CVPixelBuffer) {
    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
    
    do {
        try imageRequestHandler.perform([poseRequest])
    } catch {
        print("Error al procesar el frame: \(error)")
    }
}

// Manejo de resultados de detección de pose
func handlePoseDetection(request: VNRequest, error: Error?) {
    guard let observations = request.results as? [VNHumanBodyPose3DObservation] else { return }
    
    guard let observation = observations.first else { return }
    
    // Extraer puntos clave 3D
    let recognizedPoints = try? observation.recognizedPoints(.all)
    
    // Procesar puntos clave
    processPosePoints(recognizedPoints)
}
```

### ARKit Integration
```swift
// Configuración de ARKit
func configureARSession() {
    let configuration = ARBodyTrackingConfiguration()
    arSession.run(configuration)
    arSession.delegate = self
}

// Delegado de ARSession
func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let bodyAnchor = anchors.compactMap({ $0 as? ARBodyAnchor }).first else { return }
    
    // Obtener esqueleto 3D
    let skeleton = bodyAnchor.skeleton
    
    // Procesar joints del esqueleto
    processSkeletonJoints(skeleton)
}
```

## Análisis de Grupos Musculares

```swift
// Estimación de activación muscular basada en ángulos articulares
func estimateMuscleActivation(for exercise: Exercise, with pose: BodyPose) -> [MuscleGroup: Float] {
    var muscleActivation: [MuscleGroup: Float] = [:]
    
    switch exercise.type {
    case .squat:
        // Análisis para sentadilla
        let kneeAngle = pose.jointAngles[.knee] ?? 0
        let hipAngle = pose.jointAngles[.hip] ?? 0
        
        // Cuádriceps
        muscleActivation[.quadriceps] = calculateQuadricepsActivation(kneeAngle: kneeAngle)
        
        // Glúteos
        muscleActivation[.gluteus] = calculateGluteusActivation(hipAngle: hipAngle, kneeAngle: kneeAngle)
        
        // Isquiotibiales
        muscleActivation[.hamstrings] = calculateHamstringsActivation(hipAngle: hipAngle)
        
    case .deadlift:
        // Análisis para peso muerto
        // ...
        
    case .benchPress:
        // Análisis para press de banca
        // ...
        
    default:
        break
    }
    
    return muscleActivation
}

// Cálculo de activación de cuádriceps basado en ángulo de rodilla
func calculateQuadricepsActivation(kneeAngle: Float) -> Float {
    // El cuádriceps se activa más cuando la rodilla está flexionada
    // Máxima activación alrededor de 90 grados
    let normalizedAngle = min(max(kneeAngle, 0), 180) / 180
    
    // Función de activación basada en investigación biomecánica
    // Mayor activación entre 60-120 grados (normalizado: 0.33-0.67)
    if normalizedAngle >= 0.33 && normalizedAngle <= 0.67 {
        return 1.0 - abs(normalizedAngle - 0.5) * 3
    } else {
        return max(0, 1.0 - abs(normalizedAngle - 0.5) * 2)
    }
}
```

## Visualización de Activación Muscular

```swift
// Visualización de activación muscular con código de colores
func muscleActivationOverlay(for muscleActivation: [MuscleGroup: Float]) -> some View {
    ZStack {
        // Silueta del cuerpo
        Image("body_silhouette")
            .resizable()
            .aspectRatio(contentMode: .fit)
        
        // Superposición de grupos musculares
        ForEach(MuscleGroup.allCases, id: \.self) { muscleGroup in
            if let activation = muscleActivation[muscleGroup] {
                MuscleGroupView(
                    muscleGroup: muscleGroup,
                    activation: activation
                )
            }
        }
    }
}

// Vista de grupo muscular con nivel de activación
struct MuscleGroupView: View {
    let muscleGroup: MuscleGroup
    let activation: Float
    
    var body: some View {
        Image(muscleGroup.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .opacity(Double(activation))
            .foregroundColor(activationColor)
    }
    
    // Color basado en nivel de activación
    var activationColor: Color {
        switch activation {
        case 0.0..<0.3:
            return .blue
        case 0.3..<0.6:
            return .green
        case 0.6..<0.8:
            return .yellow
        default:
            return .red
        }
    }
}
```

## Análisis Diferenciado: Fuerza vs Hipertrofia

```swift
// Análisis diferenciado según objetivo
func analyzeExerciseQuality(pose: BodyPose, exercise: Exercise, goal: TrainingGoal) -> ExerciseQuality {
    switch goal {
    case .strength:
        return analyzeForStrength(pose: pose, exercise: exercise)
    case .hypertrophy:
        return analyzeForHypertrophy(pose: pose, exercise: exercise)
    }
}

// Análisis para objetivo de fuerza
func analyzeForStrength(pose: BodyPose, exercise: Exercise) -> ExerciseQuality {
    var quality = ExerciseQuality()
    
    // Para fuerza, evaluar:
    // 1. Estabilidad del core
    quality.coreStability = evaluateCoreStability(pose: pose)
    
    // 2. Eficiencia de la trayectoria (línea recta)
    quality.trajectoryEfficiency = evaluateTrajectoryEfficiency(pose: pose, exercise: exercise)
    
    // 3. Velocidad en fase concéntrica
    quality.concentricVelocity = evaluateConcentricVelocity(pose: pose)
    
    // 4. Rigidez articular
    quality.jointStiffness = evaluateJointStiffness(pose: pose)
    
    return quality
}

// Análisis para objetivo de hipertrofia
func analyzeForHypertrophy(pose: BodyPose, exercise: Exercise) -> ExerciseQuality {
    var quality = ExerciseQuality()
    
    // Para hipertrofia, evaluar:
    // 1. Tiempo bajo tensión
    quality.timeUnderTension = evaluateTimeUnderTension(pose: pose)
    
    // 2. Control excéntrico
    quality.eccentricControl = evaluateEccentricControl(pose: pose)
    
    // 3. Rango de movimiento completo
    quality.rangeOfMotion = evaluateRangeOfMotion(pose: pose, exercise: exercise)
    
    // 4. Aislamiento muscular
    quality.muscleIsolation = evaluateMuscleIsolation(pose: pose, exercise: exercise)
    
    return quality
}
```

## Consideraciones de Rendimiento

```swift
// Optimización de rendimiento para procesamiento en tiempo real
class PerformanceOptimizer {
    private var frameCount = 0
    private let processingInterval = 3 // Procesar cada N frames
    
    // Determinar si procesar el frame actual
    func shouldProcessFrame() -> Bool {
        frameCount = (frameCount + 1) % processingInterval
        return frameCount == 0
    }
    
    // Ajustar resolución de procesamiento según dispositivo
    func optimalProcessingResolution(for device: UIDevice) -> CGSize {
        let devicePerformance = getDevicePerformanceLevel()
        
        switch devicePerformance {
        case .high:
            return CGSize(width: 640, height: 480)
        case .medium:
            return CGSize(width: 480, height: 360)
        case .low:
            return CGSize(width: 320, height: 240)
        }
    }
    
    // Determinar nivel de rendimiento del dispositivo
    private func getDevicePerformanceLevel() -> DevicePerformanceLevel {
        let deviceModel = UIDevice.current.model
        let processorCount = ProcessInfo.processInfo.processorCount
        
        if deviceModel.contains("iPhone") && processorCount >= 6 {
            return .high
        } else if processorCount >= 4 {
            return .medium
        } else {
            return .low
        }
    }
    
    enum DevicePerformanceLevel {
        case high, medium, low
    }
}
```

## Gestión de Errores y Feedback

```swift
// Sistema de detección y feedback de errores
class ExerciseErrorDetector {
    // Detectar errores comunes en la ejecución
    func detectErrors(pose: BodyPose, exercise: Exercise) -> [ExerciseError] {
        var errors: [ExerciseError] = []
        
        switch exercise.type {
        case .squat:
            // Verificar valgo de rodilla
            if let kneeValgus = detectKneeValgus(pose: pose), kneeValgus {
                errors.append(.kneeValgus)
            }
            
            // Verificar profundidad insuficiente
            if let depth = calculateSquatDepth(pose: pose), depth < exercise.parameters.minimumDepth {
                errors.append(.insufficientDepth)
            }
            
            // Verificar inclinación excesiva del torso
            if let torsoAngle = calculateTorsoAngle(pose: pose), torsoAngle > exercise.parameters.maximumTorsoAngle {
                errors.append(.excessiveTorsoLean)
            }
            
        case .deadlift:
            // Verificar flexión lumbar
            if let lumbarFlexion = detectLumbarFlexion(pose: pose), lumbarFlexion {
                errors.append(.lumbarFlexion)
            }
            
            // Verificar posición de la barra
            if let barPath = calculateBarPath(pose: pose), !isBarPathOptimal(barPath) {
                errors.append(.suboptimalBarPath)
            }
            
        // Otros ejercicios...
            
        default:
            break
        }
        
        return errors
    }
    
    // Generar feedback basado en errores detectados
    func generateFeedback(for errors: [ExerciseError]) -> [String] {
        return errors.map { error in
            switch error {
            case .kneeValgus:
                return "Mantén las rodillas alineadas con los pies, evitando que se colapsen hacia adentro."
            case .insufficientDepth:
                return "Intenta descender más profundo para maximizar la activación muscular."
            case .excessiveTorsoLean:
                return "Mantén el torso más erguido para proteger la columna lumbar."
            case .lumbarFlexion:
                return "Mantén la columna neutral, evitando la flexión lumbar."
            case .suboptimalBarPath:
                return "Mantén la barra cerca del cuerpo durante todo el movimiento."
            // Otros errores...
            }
        }
    }
}

// Tipos de errores en ejercicios
enum ExerciseError {
    case kneeValgus
    case insufficientDepth
    case excessiveTorsoLean
    case lumbarFlexion
    case suboptimalBarPath
    // Otros errores...
}
```

## Conclusión

Esta arquitectura proporciona una base sólida para el desarrollo de la aplicación iOS de análisis de vectores de movimiento en ejercicios de musculación. La estructura modular permite la separación de responsabilidades y facilita la extensión y mantenimiento del código. La integración con Vision y ARKit permite un análisis preciso en tiempo real, mientras que el enfoque en la clasificación muscular y la diferenciación entre objetivos de fuerza e hipertrofia proporciona un valor añadido significativo para los usuarios.
