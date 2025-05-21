import Foundation
import Combine
import AVFoundation

/// ViewModel para la vista de análisis de ejercicios
class ExerciseAnalysisViewModel: ObservableObject {
    // MARK: - Propiedades publicadas
    
    /// Pose corporal actual detectada
    @Published var currentPose: BodyPose?
    
    /// Activación muscular actual
    @Published var muscleActivation: [MuscleGroup: Float] = [:]
    
    /// Fase actual del movimiento
    @Published var currentMovementPhase: MovementPhase = .unknown
    
    /// Calidad global del ejercicio (0-1)
    @Published var exerciseQuality: Float = 0.0
    
    /// Errores detectados en la ejecución
    @Published var detectedErrors: [ExerciseError] = []
    
    /// Modo de entrenamiento actual
    @Published var trainingMode: TrainingMode = .hypertrophy
    
    /// Tipo de ejercicio actual
    @Published var currentExerciseType: ExerciseType = .squat
    
    /// Indica si se debe mostrar la visualización de activación muscular
    @Published var showMuscleActivation: Bool = false
    
    // MARK: - Servicios
    
    /// Servicio de detección de pose
    private let poseDetectionService = PoseDetectionService()
    
    /// Servicio de análisis muscular
    private let muscleAnalysisService = MuscleAnalysisService()
    
    /// Capa de previsualización de la cámara
    var previewLayer: AVCaptureVideoPreviewLayer {
        return poseDetectionService.getPreviewLayer()
    }
    
    // MARK: - Inicialización
    
    init() {
        setupServices()
    }
    
    // MARK: - Configuración
    
    /// Configura los servicios y sus delegados
    private func setupServices() {
        // Configurar delegados
        poseDetectionService.delegate = self
        muscleAnalysisService.delegate = self
        
        // Configurar sesión de captura
        let setupSuccess = poseDetectionService.setupCaptureSession()
        if !setupSuccess {
            print("Error al configurar la sesión de captura")
        }
        
        // Configurar análisis muscular
        muscleAnalysisService.setTrainingMode(trainingMode)
        muscleAnalysisService.setExerciseType(currentExerciseType)
    }
    
    // MARK: - Control de Captura
    
    /// Inicia la captura de video y análisis
    func startCapture() {
        poseDetectionService.startCapture()
    }
    
    /// Detiene la captura de video y análisis
    func stopCapture() {
        poseDetectionService.stopCapture()
    }
    
    // MARK: - Acciones de Usuario
    
    /// Alterna entre modos de entrenamiento
    func toggleTrainingMode() {
        trainingMode = trainingMode == .strength ? .hypertrophy : .strength
        muscleAnalysisService.setTrainingMode(trainingMode)
    }
    
    /// Alterna la visualización de activación muscular
    func toggleMuscleActivation() {
        showMuscleActivation.toggle()
    }
    
    /// Cambia al siguiente tipo de ejercicio
    func cycleExerciseType() {
        let exerciseTypes: [ExerciseType] = [.squat, .deadlift, .benchPress, .shoulderPress]
        
        if let currentIndex = exerciseTypes.firstIndex(of: currentExerciseType) {
            let nextIndex = (currentIndex + 1) % exerciseTypes.count
            currentExerciseType = exerciseTypes[nextIndex]
        } else {
            currentExerciseType = .squat
        }
        
        muscleAnalysisService.setExerciseType(currentExerciseType)
    }
}

// MARK: - Extensión para PoseDetectionDelegate

extension ExerciseAnalysisViewModel: PoseDetectionDelegate {
    func poseDetectionService(_ service: PoseDetectionService, didDetectPose pose: BodyPose) {
        // Actualizar pose actual
        currentPose = pose
        
        // Enviar pose al servicio de análisis muscular
        muscleAnalysisService.processPose(pose)
    }
    
    func poseDetectionServiceDidStartCapture() {
        print("Captura iniciada")
    }
    
    func poseDetectionServiceDidStopCapture() {
        print("Captura detenida")
    }
}

// MARK: - Extensión para MuscleAnalysisDelegate

extension ExerciseAnalysisViewModel: MuscleAnalysisDelegate {
    func muscleAnalysisService(_ service: MuscleAnalysisService, didProduceAnalysisResult result: ExerciseAnalysisResult) {
        // Actualizar estado con resultados del análisis
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.muscleActivation = result.muscleActivation
            self.currentMovementPhase = result.movementPhase
            self.exerciseQuality = result.exerciseQuality.overallScore(for: self.trainingMode)
            self.detectedErrors = result.detectedErrors
        }
    }
}
