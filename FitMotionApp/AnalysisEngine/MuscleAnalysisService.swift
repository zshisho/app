import Foundation
import UIKit

/// Servicio para analizar grupos musculares y estimar su activación durante ejercicios
class MuscleAnalysisService {
    
    // MARK: - Propiedades
    
    /// Modo de entrenamiento actual
    private var trainingMode: TrainingMode = .hypertrophy
    
    /// Tipo de ejercicio actual
    private var currentExercise: ExerciseType = .squat
    
    /// Historial de poses para análisis temporal
    private var poseHistory: [BodyPose] = []
    
    /// Tamaño máximo del historial de poses
    private let maxHistorySize = 30
    
    /// Delegado para recibir resultados de análisis muscular
    weak var delegate: MuscleAnalysisDelegate?
    
    // MARK: - Configuración
    
    /// Establece el modo de entrenamiento
    /// - Parameter mode: Modo de entrenamiento (fuerza o hipertrofia)
    func setTrainingMode(_ mode: TrainingMode) {
        self.trainingMode = mode
    }
    
    /// Establece el tipo de ejercicio actual
    /// - Parameter exerciseType: Tipo de ejercicio a analizar
    func setExerciseType(_ exerciseType: ExerciseType) {
        self.currentExercise = exerciseType
        // Limpiar historial al cambiar de ejercicio
        poseHistory.removeAll()
    }
    
    // MARK: - Análisis de Poses
    
    /// Procesa una nueva pose detectada
    /// - Parameter pose: Pose corporal detectada
    func processPose(_ pose: BodyPose) {
        // Añadir pose al historial
        poseHistory.append(pose)
        
        // Mantener tamaño máximo del historial
        if poseHistory.count > maxHistorySize {
            poseHistory.removeFirst()
        }
        
        // Analizar fase del movimiento
        let movementPhase = determineMovementPhase()
        
        // Estimar activación muscular
        let muscleActivation = estimateMuscleActivation(for: pose, phase: movementPhase)
        
        // Analizar calidad del ejercicio
        let exerciseQuality = analyzeExerciseQuality(pose: pose, phase: movementPhase)
        
        // Detectar errores comunes
        let errors = detectExerciseErrors(pose: pose, phase: movementPhase)
        
        // Notificar resultados
        let analysisResult = ExerciseAnalysisResult(
            pose: pose,
            muscleActivation: muscleActivation,
            movementPhase: movementPhase,
            exerciseQuality: exerciseQuality,
            detectedErrors: errors
        )
        
        delegate?.muscleAnalysisService(self, didProduceAnalysisResult: analysisResult)
    }
    
    /// Determina la fase actual del movimiento (concéntrica, excéntrica, isométrica)
    private func determineMovementPhase() -> MovementPhase {
        guard poseHistory.count >= 3 else {
            return .unknown
        }
        
        // Obtener las últimas poses
        let currentPose = poseHistory.last!
        let previousPose = poseHistory[poseHistory.count - 2]
        
        // Analizar cambios según el tipo de ejercicio
        switch currentExercise {
        case .squat:
            return determineSquatPhase(currentPose: currentPose, previousPose: previousPose)
        case .deadlift:
            return determineDeadliftPhase(currentPose: currentPose, previousPose: previousPose)
        case .benchPress:
            return determineBenchPressPhase(currentPose: currentPose, previousPose: previousPose)
        default:
            return .unknown
        }
    }
    
    /// Determina la fase de una sentadilla
    private func determineSquatPhase(currentPose: BodyPose, previousPose: BodyPose) -> MovementPhase {
        // Obtener ángulos de rodilla
        guard let currentRightKnee = currentPose.jointAngles[.rightKnee],
              let previousRightKnee = previousPose.jointAngles[.rightKnee] else {
            return .unknown
        }
        
        // Calcular cambio en el ángulo
        let kneeAngleChange = currentRightKnee - previousRightKnee
        
        // Determinar fase basada en el cambio de ángulo
        if abs(kneeAngleChange) < 2.0 {
            return .isometric
        } else if kneeAngleChange > 0 {
            // Ángulo aumentando = subiendo = fase concéntrica
            return .concentric
        } else {
            // Ángulo disminuyendo = bajando = fase excéntrica
            return .eccentric
        }
    }
    
    /// Determina la fase de un peso muerto
    private func determineDeadliftPhase(currentPose: BodyPose, previousPose: BodyPose) -> MovementPhase {
        // Obtener ángulos de cadera
        guard let currentHip = currentPose.jointAngles[.rightHip],
              let previousHip = previousPose.jointAngles[.rightHip] else {
            return .unknown
        }
        
        // Calcular cambio en el ángulo
        let hipAngleChange = currentHip - previousHip
        
        // Determinar fase basada en el cambio de ángulo
        if abs(hipAngleChange) < 2.0 {
            return .isometric
        } else if hipAngleChange > 0 {
            // Ángulo aumentando = enderezándose = fase concéntrica
            return .concentric
        } else {
            // Ángulo disminuyendo = inclinándose = fase excéntrica
            return .eccentric
        }
    }
    
    /// Determina la fase de un press de banca
    private func determineBenchPressPhase(currentPose: BodyPose, previousPose: BodyPose) -> MovementPhase {
        // Obtener ángulos de codo
        guard let currentElbow = currentPose.jointAngles[.rightElbow],
              let previousElbow = previousPose.jointAngles[.rightElbow] else {
            return .unknown
        }
        
        // Calcular cambio en el ángulo
        let elbowAngleChange = currentElbow - previousElbow
        
        // Determinar fase basada en el cambio de ángulo
        if abs(elbowAngleChange) < 2.0 {
            return .isometric
        } else if elbowAngleChange > 0 {
            // Ángulo aumentando = extendiendo = fase concéntrica
            return .concentric
        } else {
            // Ángulo disminuyendo = flexionando = fase excéntrica
            return .eccentric
        }
    }
    
    // MARK: - Análisis Muscular
    
    /// Estima la activación de grupos musculares basada en la pose y fase del movimiento
    /// - Parameters:
    ///   - pose: Pose corporal actual
    ///   - phase: Fase del movimiento
    /// - Returns: Mapa de activación muscular por grupo muscular
    private func estimateMuscleActivation(for pose: BodyPose, phase: MovementPhase) -> [MuscleGroup: Float] {
        var muscleActivation: [MuscleGroup: Float] = [:]
        
        switch currentExercise {
        case .squat:
            muscleActivation = estimateSquatMuscleActivation(pose: pose, phase: phase)
        case .deadlift:
            muscleActivation = estimateDeadliftMuscleActivation(pose: pose, phase: phase)
        case .benchPress:
            muscleActivation = estimateBenchPressMuscleActivation(pose: pose, phase: phase)
        default:
            break
        }
        
        // Ajustar activación según modo de entrenamiento
        return adjustActivationForTrainingMode(muscleActivation: muscleActivation, phase: phase)
    }
    
    /// Estima la activación muscular para sentadilla
    private func estimateSquatMuscleActivation(pose: BodyPose, phase: MovementPhase) -> [MuscleGroup: Float] {
        var activation: [MuscleGroup: Float] = [:]
        
        // Obtener ángulos relevantes
        guard let kneeAngle = pose.jointAngles[.rightKnee],
              let hipAngle = pose.jointAngles[.rightHip] else {
            return activation
        }
        
        // Normalizar ángulos (0-1)
        let normalizedKneeAngle = min(max(kneeAngle, 0), 180) / 180
        let normalizedHipAngle = min(max(hipAngle, 0), 180) / 180
        
        // Cuádriceps (máxima activación cuando rodilla está flexionada ~90°)
        let quadActivation = 1.0 - abs(normalizedKneeAngle - 0.5) * 2
        activation[.quadriceps] = Float(quadActivation)
        
        // Glúteos (máxima activación en fase concéntrica con cadera flexionada)
        var gluteActivation = 1.0 - abs(normalizedHipAngle - 0.5) * 2
        if phase == .concentric {
            gluteActivation *= 1.2 // Mayor activación en fase concéntrica
        }
        activation[.gluteus] = Float(min(gluteActivation, 1.0))
        
        // Isquiotibiales (activación moderada en sentadilla)
        let hamstringActivation = 1.0 - abs(normalizedHipAngle - 0.4) * 1.5
        activation[.hamstrings] = Float(max(min(hamstringActivation, 1.0), 0.0))
        
        // Core (activación constante durante todo el movimiento)
        activation[.core] = 0.7
        
        return activation
    }
    
    /// Estima la activación muscular para peso muerto
    private func estimateDeadliftMuscleActivation(pose: BodyPose, phase: MovementPhase) -> [MuscleGroup: Float] {
        var activation: [MuscleGroup: Float] = [:]
        
        // Obtener ángulos relevantes
        guard let kneeAngle = pose.jointAngles[.rightKnee],
              let hipAngle = pose.jointAngles[.rightHip] else {
            return activation
        }
        
        // Normalizar ángulos (0-1)
        let normalizedKneeAngle = min(max(kneeAngle, 0), 180) / 180
        let normalizedHipAngle = min(max(hipAngle, 0), 180) / 180
        
        // Isquiotibiales (máxima activación en peso muerto)
        var hamstringActivation = 1.0 - abs(normalizedHipAngle - 0.3) * 1.2
        if phase == .eccentric {
            hamstringActivation *= 1.1 // Mayor activación en fase excéntrica
        }
        activation[.hamstrings] = Float(min(hamstringActivation, 1.0))
        
        // Glúteos (alta activación en extensión de cadera)
        var gluteActivation = 1.0 - abs(normalizedHipAngle - 0.4) * 1.5
        if phase == .concentric {
            gluteActivation *= 1.2 // Mayor activación en fase concéntrica
        }
        activation[.gluteus] = Float(min(gluteActivation, 1.0))
        
        // Espalda baja (alta activación durante todo el movimiento)
        activation[.lowerBack] = 0.9
        
        // Trapecios (activación moderada)
        activation[.trapezius] = 0.7
        
        // Core (activación alta durante todo el movimiento)
        activation[.core] = 0.8
        
        return activation
    }
    
    /// Estima la activación muscular para press de banca
    private func estimateBenchPressMuscleActivation(pose: BodyPose, phase: MovementPhase) -> [MuscleGroup: Float] {
        var activation: [MuscleGroup: Float] = [:]
        
        // Obtener ángulos relevantes
        guard let elbowAngle = pose.jointAngles[.rightElbow],
              let shoulderAngle = pose.jointAngles[.rightShoulder] else {
            return activation
        }
        
        // Normalizar ángulos (0-1)
        let normalizedElbowAngle = min(max(elbowAngle, 0), 180) / 180
        let normalizedShoulderAngle = min(max(shoulderAngle, 0), 180) / 180
        
        // Pectoral (máxima activación cuando codo está flexionado ~90°)
        var chestActivation = 1.0 - abs(normalizedElbowAngle - 0.5) * 2
        if phase == .concentric {
            chestActivation *= 1.1 // Mayor activación en fase concéntrica
        }
        activation[.chest] = Float(min(chestActivation, 1.0))
        
        // Tríceps (mayor activación en extensión)
        var tricepsActivation = normalizedElbowAngle * 1.5
        if phase == .concentric && normalizedElbowAngle > 0.7 {
            tricepsActivation *= 1.2 // Mayor activación al final de la fase concéntrica
        }
        activation[.triceps] = Float(min(tricepsActivation, 1.0))
        
        // Deltoides anterior (activación constante)
        activation[.anteriorDeltoid] = 0.8
        
        return activation
    }
    
    /// Ajusta la activación muscular según el modo de entrenamiento
    private func adjustActivationForTrainingMode(muscleActivation: [MuscleGroup: Float], phase: MovementPhase) -> [MuscleGroup: Float] {
        var adjustedActivation = muscleActivation
        
        switch trainingMode {
        case .strength:
            // En entrenamiento de fuerza, mayor activación en fase concéntrica
            if phase == .concentric {
                for (muscle, activation) in muscleActivation {
                    adjustedActivation[muscle] = min(activation * 1.2, 1.0)
                }
            }
            
        case .hypertrophy:
            // En hipertrofia, mayor activación en fase excéntrica y mayor tiempo bajo tensión
            if phase == .eccentric {
                for (muscle, activation) in muscleActivation {
                    adjustedActivation[muscle] = min(activation * 1.15, 1.0)
                }
            } else if phase == .isometric {
                for (muscle, activation) in muscleActivation {
                    adjustedActivation[muscle] = min(activation * 1.1, 1.0)
                }
            }
        }
        
        return adjustedActivation
    }
    
    // MARK: - Análisis de Calidad
    
    /// Analiza la calidad de ejecución del ejercicio
    /// - Parameters:
    ///   - pose: Pose corporal actual
    ///   - phase: Fase del movimiento
    /// - Returns: Evaluación de calidad del ejercicio
    private func analyzeExerciseQuality(pose: BodyPose, phase: MovementPhase) -> ExerciseQuality {
        var quality = ExerciseQuality()
        
        switch trainingMode {
        case .strength:
            quality = analyzeForStrength(pose: pose, phase: phase)
        case .hypertrophy:
            quality = analyzeForHypertrophy(pose: pose, phase: phase)
        }
        
        return quality
    }
    
    /// Analiza la calidad para objetivo de fuerza
    private func analyzeForStrength(pose: BodyPose, phase: MovementPhase) -> ExerciseQuality {
        var quality = ExerciseQuality()
        
        // Para fuerza, evaluar:
        // 1. Estabilidad del core
        quality.coreStability = evaluateCoreStability(pose: pose)
        
        // 2. Eficiencia de la trayectoria
        quality.trajectoryEfficiency = evaluateTrajectoryEfficiency()
        
        // 3. Velocidad en fase concéntrica
        quality.concentricVelocity = evaluateConcentricVelocity(phase: phase)
        
        // 4. Rigidez articular
        quality.jointStiffness = evaluateJointStiffness(pose: pose)
        
        return quality
    }
    
    /// Analiza la calidad para objetivo de hipertrofia
    private func analyzeForHypertrophy(pose: BodyPose, phase: MovementPhase) -> ExerciseQuality {
        var quality = ExerciseQuality()
        
        // Para hipertrofia, evaluar:
        // 1. Tiempo bajo tensión
        quality.timeUnderTension = evaluateTimeUnderTension(phase: phase)
        
        // 2. Control excéntrico
        quality.eccentricControl = evaluateEccentricControl(phase: phase)
        
        // 3. Rango de movimiento completo
        quality.rangeOfMotion = evaluateRangeOfMotion()
        
        // 4. Aislamiento muscular
        quality.muscleIsolation = evaluateMuscleIsolation(pose: pose)
        
        return quality
    }
    
    /// Evalúa la estabilidad del core
    private func evaluateCoreStability(pose: BodyPose) -> Float {
        // Evaluar estabilidad del core basado en la alineación de la columna
        guard let spineAngle = pose.jointAngles[.spine] else {
            return 0.5 // Valor por defecto si no hay datos
        }
        
        // Una columna vertical es ideal (cerca de 180 grados)
        let normalizedSpineAngle = min(max(spineAngle, 0), 180) / 180
        
        // Penalizar desviaciones de la verticalidad
        return Float(1.0 - abs(normalizedSpineAngle - 0.9) * 2)
    }
    
    /// Evalúa la eficiencia de la trayectoria
    private func evaluateTrajectoryEfficiency() -> Float {
        // Requiere análisis de múltiples frames para evaluar la trayectoria
        guard poseHistory.count >= 5 else {
            return 0.5 // Valor por defecto si no hay suficientes datos
        }
        
        // En una implementación real, se analizaría la desviación de la trayectoria ideal
        // Por ahora, devolvemos un valor simulado
        return 0.8
    }
    
    /// Evalúa la velocidad en fase concéntrica
    private func evaluateConcentricVelocity(phase: MovementPhase) -> Float {
        // Requiere análisis de múltiples frames para evaluar la velocidad
        guard poseHistory.count >= 3 && phase == .concentric else {
            return 0.5 // Valor por defecto si no hay suficientes datos o no es fase concéntrica
        }
        
        // En una implementación real, se calcularía la velocidad angular
        // Por ahora, devolvemos un valor simulado
        return 0.75
    }
    
    /// Evalúa la rigidez articular
    private func evaluateJointStiffness(pose: BodyPose) -> Float {
        // En una implementación real, se analizaría la estabilidad de las articulaciones
        // Por ahora, devolvemos un valor simulado
        return 0.7
    }
    
    /// Evalúa el tiempo bajo tensión
    private func evaluateTimeUnderTension(phase: MovementPhase) -> Float {
        // Evaluar tiempo bajo tensión basado en la duración de las fases
        if phase == .eccentric || phase == .isometric {
            // En una implementación real, se mediría la duración de estas fases
            // Por ahora, devolvemos un valor simulado
            return 0.8
        } else {
            return 0.6
        }
    }
    
    /// Evalúa el control excéntrico
    private func evaluateEccentricControl(phase: MovementPhase) -> Float {
        // Evaluar control excéntrico basado en la consistencia de la velocidad
        if phase == .eccentric && poseHistory.count >= 3 {
            // En una implementación real, se analizaría la consistencia de la velocidad
            // Por ahora, devolvemos un valor simulado
            return 0.75
        } else {
            return 0.5
        }
    }
    
    /// Evalúa el rango de movimiento
    private func evaluateRangeOfMotion() -> Float {
        // Requiere análisis de múltiples frames para evaluar el ROM
        guard poseHistory.count >= 10 else {
            return 0.5 // Valor por defecto si no hay suficientes datos
        }
        
        // En una implementación real, se analizaría el rango completo del movimiento
        // Por ahora, devolvemos un valor simulado
        return 0.7
    }
    
    /// Evalúa el aislamiento muscular
    private func evaluateMuscleIsolation(pose: BodyPose) -> Float {
        // En una implementación real, se analizaría la activación selectiva de músculos
        // Por ahora, devolvemos un valor simulado
        return 0.65
    }
    
    // MARK: - Detección de Errores
    
    /// Detecta errores comunes en la ejecución del ejercicio
    /// - Parameters:
    ///   - pose: Pose corporal actual
    ///   - phase: Fase del movimiento
    /// - Returns: Lista de errores detectados
    private func detectExerciseErrors(pose: BodyPose, phase: MovementPhase) -> [ExerciseError] {
        var errors: [ExerciseError] = []
        
        switch currentExercise {
        case .squat:
            errors = detectSquatErrors(pose: pose, phase: phase)
        case .deadlift:
            errors = detectDeadliftErrors(pose: pose, phase: phase)
        case .benchPress:
            errors = detectBenchPressErrors(pose: pose, phase: phase)
        default:
            break
        }
        
        return errors
    }
    
    /// Detecta errores en sentadilla
    private func detectSquatErrors(pose: BodyPose, phase: MovementPhase) -> [ExerciseError] {
        var errors: [ExerciseError] = []
        
        // Verificar valgo de rodilla
        if let kneeValgus = detectKneeValgus(pose: pose), kneeValgus {
            errors.append(.kneeValgus)
        }
        
        // Verificar profundidad insuficiente
        if let depth = calculateSquatDepth(pose: pose), depth < 0.7 {
            errors.append(.insufficientDepth)
        }
        
        // Verificar inclinación excesiva del torso
        if let torsoAngle = pose.jointAngles[.spine], torsoAngle < 160 {
            errors.append(.excessiveTorsoLean)
        }
        
        return errors
    }
    
    /// Detecta errores en peso muerto
    private func detectDeadliftErrors(pose: BodyPose, phase: MovementPhase) -> [ExerciseError] {
        var errors: [ExerciseError] = []
        
        // Verificar flexión lumbar
        if let lumbarFlexion = detectLumbarFlexion(pose: pose), lumbarFlexion {
            errors.append(.lumbarFlexion)
        }
        
        // Verificar posición de la barra (simulado)
        errors.append(.suboptimalBarPath)
        
        return errors
    }
    
    /// Detecta errores en press de banca
    private func detectBenchPressErrors(pose: BodyPose, phase: MovementPhase) -> [ExerciseError] {
        var errors: [ExerciseError] = []
        
        // Verificar asimetría en los brazos
        if let asymmetry = detectArmAsymmetry(pose: pose), asymmetry {
            errors.append(.asymmetricMovement)
        }
        
        // Verificar arco excesivo (simulado)
        errors.append(.excessiveArch)
        
        return errors
    }
    
    /// Detecta valgo de rodilla
    private func detectKneeValgus(pose: BodyPose) -> Bool? {
        // En una implementación real, se analizaría la alineación de cadera-rodilla-tobillo
        // Por ahora, devolvemos un valor simulado
        return false
    }
    
    /// Calcula la profundidad de la sentadilla
    private func calculateSquatDepth(pose: BodyPose) -> Float? {
        guard let kneeAngle = pose.jointAngles[.rightKnee] else {
            return nil
        }
        
        // Normalizar ángulo (0-1), donde 1 es profundidad máxima
        return Float(1.0 - (kneeAngle / 180.0))
    }
    
    /// Detecta flexión lumbar
    private func detectLumbarFlexion(pose: BodyPose) -> Bool? {
        // En una implementación real, se analizaría la curvatura de la columna
        // Por ahora, devolvemos un valor simulado
        return false
    }
    
    /// Detecta asimetría en los brazos
    private func detectArmAsymmetry(pose: BodyPose) -> Bool? {
        guard let rightElbow = pose.jointAngles[.rightElbow],
              let leftElbow = pose.jointAngles[.leftElbow] else {
            return nil
        }
        
        // Detectar asimetría si la diferencia es mayor a 10 grados
        return abs(rightElbow - leftElbow) > 10
    }
}

// MARK: - Enumeraciones y Estructuras

/// Modos de entrenamiento
enum TrainingMode {
    case strength
    case hypertrophy
}

/// Tipos de ejercicios soportados
enum ExerciseType {
    case squat
    case deadlift
    case benchPress
    case shoulderPress
    case pullUp
    case row
    case lunge
    case other
}

/// Fases del movimiento
enum MovementPhase {
    case concentric  // Fase de contracción (subida en sentadilla)
    case eccentric   // Fase de elongación (bajada en sentadilla)
    case isometric   // Fase de mantenimiento
    case unknown
}

/// Grupos musculares
enum MuscleGroup: String, CaseIterable {
    case quadriceps
    case hamstrings
    case gluteus
    case calves
    case chest
    case upperBack
    case lowerBack
    case shoulders
    case biceps
    case triceps
    case forearms
    case core
    case anteriorDeltoid
    case lateralDeltoid
    case posteriorDeltoid
    case trapezius
    
    /// Nombre del grupo muscular para visualización
    var displayName: String {
        switch self {
        case .quadriceps: return "Cuádriceps"
        case .hamstrings: return "Isquiotibiales"
        case .gluteus: return "Glúteos"
        case .calves: return "Pantorrillas"
        case .chest: return "Pecho"
        case .upperBack: return "Espalda Superior"
        case .lowerBack: return "Espalda Baja"
        case .shoulders: return "Hombros"
        case .biceps: return "Bíceps"
        case .triceps: return "Tríceps"
        case .forearms: return "Antebrazos"
        case .core: return "Core"
        case .anteriorDeltoid: return "Deltoides Anterior"
        case .lateralDeltoid: return "Deltoides Lateral"
        case .posteriorDeltoid: return "Deltoides Posterior"
        case .trapezius: return "Trapecio"
        }
    }
    
    /// Nombre del archivo de imagen para visualización
    var imageName: String {
        return "muscle_\(self.rawValue)"
    }
}

/// Tipos de errores en ejercicios
enum ExerciseError: String {
    case kneeValgus = "Valgo de Rodilla"
    case insufficientDepth = "Profundidad Insuficiente"
    case excessiveTorsoLean = "Inclinación Excesiva del Torso"
    case lumbarFlexion = "Flexión Lumbar"
    case suboptimalBarPath = "Trayectoria Subóptima de la Barra"
    case asymmetricMovement = "Movimiento Asimétrico"
    case excessiveArch = "Arco Excesivo"
    
    /// Descripción del error para feedback
    var description: String {
        switch self {
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
        case .asymmetricMovement:
            return "Mantén un movimiento simétrico en ambos lados del cuerpo."
        case .excessiveArch:
            return "Reduce el arco en la espalda baja para proteger la columna."
        }
    }
}

/// Estructura para evaluar la calidad del ejercicio
struct ExerciseQuality {
    // Métricas para entrenamiento de fuerza
    var coreStability: Float = 0.0
    var trajectoryEfficiency: Float = 0.0
    var concentricVelocity: Float = 0.0
    var jointStiffness: Float = 0.0
    
    // Métricas para entrenamiento de hipertrofia
    var timeUnderTension: Float = 0.0
    var eccentricControl: Float = 0.0
    var rangeOfMotion: Float = 0.0
    var muscleIsolation: Float = 0.0
    
    /// Calcula la puntuación global según el modo de entrenamiento
    func overallScore(for mode: TrainingMode) -> Float {
        switch mode {
        case .strength:
            return (coreStability + trajectoryEfficiency + concentricVelocity + jointStiffness) / 4.0
        case .hypertrophy:
            return (timeUnderTension + eccentricControl + rangeOfMotion + muscleIsolation) / 4.0
        }
    }
}

/// Resultado del análisis de ejercicio
struct ExerciseAnalysisResult {
    let pose: BodyPose
    let muscleActivation: [MuscleGroup: Float]
    let movementPhase: MovementPhase
    let exerciseQuality: ExerciseQuality
    let detectedErrors: [ExerciseError]
    let timestamp: TimeInterval = CACurrentMediaTime()
}

// MARK: - Protocolo Delegado

/// Protocolo para recibir resultados de análisis muscular
protocol MuscleAnalysisDelegate: AnyObject {
    /// Llamado cuando se produce un nuevo resultado de análisis
    func muscleAnalysisService(_ service: MuscleAnalysisService, didProduceAnalysisResult result: ExerciseAnalysisResult)
}
