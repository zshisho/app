import Foundation
import Vision
import AVFoundation
import UIKit

/// Servicio responsable de la captura de video y detección de poses
class PoseDetectionService: NSObject {
    
    // MARK: - Propiedades
    
    /// Sesión de captura de AVFoundation
    private let captureSession = AVCaptureSession()
    
    /// Capa de previsualización para mostrar el video de la cámara
    private let previewLayer = AVCaptureVideoPreviewLayer()
    
    /// Cola de procesamiento para análisis de video
    private let videoProcessingQueue = DispatchQueue(label: "com.fitmotion.videoProcessing", qos: .userInteractive)
    
    /// Request de Vision para detección de pose
    private var poseRequest: VNCoreMLRequest?
    
    /// Request de Vision para detección de pose 3D (si está disponible)
    private var pose3DRequest: VNDetectHumanBodyPose3DRequest?
    
    /// Modelo de Vision para detección de pose
    private var visionModel: VNCoreMLModel?
    
    /// Delegado para recibir resultados de detección
    weak var delegate: PoseDetectionDelegate?
    
    /// Indica si el servicio está actualmente capturando
    private(set) var isRunning = false
    
    /// Contador de frames para optimización de rendimiento
    private var frameCount = 0
    
    /// Intervalo de procesamiento (procesar cada N frames)
    private let processingInterval = 2
    
    /// Última pose detectada
    private var lastPose: BodyPose?
    
    // MARK: - Inicialización
    
    override init() {
        super.init()
        setupVision()
    }
    
    // MARK: - Configuración
    
    /// Configura el framework Vision y carga los modelos
    private func setupVision() {
        // Configurar request de pose 2D
        pose3DRequest = VNDetectHumanBodyPose3DRequest(completionHandler: handlePose3DDetection)
        
        // Intentar cargar modelo de Core ML para pose estimation
        do {
            // En una implementación real, cargaríamos un modelo específico para análisis de ejercicios
            // Por ahora, usamos el detector de pose integrado de Vision
            
            // Ejemplo de carga de modelo personalizado:
            // let modelURL = Bundle.main.url(forResource: "ExerciseAnalysisModel", withExtension: "mlmodelc")!
            // let model = try MLModel(contentsOf: modelURL)
            // visionModel = try VNCoreMLModel(for: model)
            // poseRequest = VNCoreMLRequest(model: visionModel!, completionHandler: handlePoseDetection)
            // poseRequest?.imageCropAndScaleOption = .scaleFill
            
            print("Vision configurado correctamente")
        } catch {
            print("Error al configurar Vision: \(error)")
        }
    }
    
    /// Configura la sesión de captura de video
    func setupCaptureSession() -> Bool {
        captureSession.beginConfiguration()
        
        // Configurar calidad de video
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Configurar entrada de video
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("No se pudo configurar la entrada de video")
            captureSession.commitConfiguration()
            return false
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("No se pudo añadir la entrada de video a la sesión")
            captureSession.commitConfiguration()
            return false
        }
        
        // Configurar salida de video
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoProcessingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("No se pudo añadir la salida de video a la sesión")
            captureSession.commitConfiguration()
            return false
        }
        
        // Configurar orientación de la conexión de video
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = false
            }
        }
        
        captureSession.commitConfiguration()
        
        // Configurar capa de previsualización
        previewLayer.session = captureSession
        previewLayer.videoGravity = .resizeAspectFill
        
        return true
    }
    
    // MARK: - Control de Captura
    
    /// Inicia la captura de video y detección de poses
    func startCapture() {
        if !captureSession.isRunning {
            videoProcessingQueue.async { [weak self] in
                self?.captureSession.startRunning()
                DispatchQueue.main.async {
                    self?.isRunning = true
                    self?.delegate?.poseDetectionServiceDidStartCapture()
                }
            }
        }
    }
    
    /// Detiene la captura de video
    func stopCapture() {
        if captureSession.isRunning {
            captureSession.stopRunning()
            isRunning = false
            delegate?.poseDetectionServiceDidStopCapture()
        }
    }
    
    /// Obtiene la capa de previsualización para mostrar en la UI
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        return previewLayer
    }
    
    // MARK: - Procesamiento de Poses
    
    /// Maneja los resultados de detección de pose 3D
    private func handlePose3DDetection(request: VNRequest, error: Error?) {
        guard error == nil else {
            print("Error en detección de pose 3D: \(error!)")
            return
        }
        
        guard let observations = request.results as? [VNHumanBodyPose3DObservation],
              let observation = observations.first else {
            return
        }
        
        let timestamp = CACurrentMediaTime()
        let pose = BodyPose(from: observation, timestamp: timestamp)
        
        DispatchQueue.main.async { [weak self] in
            self?.lastPose = pose
            self?.delegate?.poseDetectionService(self!, didDetectPose: pose)
        }
    }
    
    /// Maneja los resultados de detección de pose 2D
    private func handlePoseDetection(request: VNRequest, error: Error?) {
        guard error == nil else {
            print("Error en detección de pose: \(error!)")
            return
        }
        
        guard let observations = request.results as? [VNHumanBodyPoseObservation],
              let observation = observations.first else {
            return
        }
        
        let timestamp = CACurrentMediaTime()
        let pose = BodyPose(from: observation, timestamp: timestamp)
        
        DispatchQueue.main.async { [weak self] in
            self?.lastPose = pose
            self?.delegate?.poseDetectionService(self!, didDetectPose: pose)
        }
    }
    
    /// Procesa un frame de video para detección de pose
    private func processVideoFrame(_ pixelBuffer: CVPixelBuffer) {
        // Optimización: procesar solo cada N frames
        frameCount = (frameCount + 1) % processingInterval
        if frameCount != 0 {
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            // Intentar primero con detección 3D si está disponible
            if let pose3DRequest = pose3DRequest {
                try imageRequestHandler.perform([pose3DRequest])
            } 
            // Si no hay detección 3D o falla, usar detección 2D
            else if let poseRequest = poseRequest {
                try imageRequestHandler.perform([poseRequest])
            }
            // Si no hay requests configurados, usar el detector de pose integrado
            else {
                let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
                    guard error == nil else {
                        print("Error en detección de pose integrada: \(error!)")
                        return
                    }
                    
                    guard let observations = request.results as? [VNHumanBodyPoseObservation],
                          let observation = observations.first else {
                        return
                    }
                    
                    let timestamp = CACurrentMediaTime()
                    let pose = BodyPose(from: observation, timestamp: timestamp)
                    
                    DispatchQueue.main.async {
                        self?.lastPose = pose
                        self?.delegate?.poseDetectionService(self!, didDetectPose: pose)
                    }
                }
                
                try imageRequestHandler.perform([request])
            }
        } catch {
            print("Error al procesar frame: \(error)")
        }
    }
}

// MARK: - Extensión para AVCaptureVideoDataOutputSampleBufferDelegate

extension PoseDetectionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        processVideoFrame(pixelBuffer)
    }
}

// MARK: - Protocolo Delegado

/// Protocolo para recibir resultados de detección de pose
protocol PoseDetectionDelegate: AnyObject {
    /// Llamado cuando se detecta una nueva pose
    func poseDetectionService(_ service: PoseDetectionService, didDetectPose pose: BodyPose)
    
    /// Llamado cuando el servicio inicia la captura
    func poseDetectionServiceDidStartCapture()
    
    /// Llamado cuando el servicio detiene la captura
    func poseDetectionServiceDidStopCapture()
}
