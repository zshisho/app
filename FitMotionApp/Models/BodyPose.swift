import Foundation
import Vision
import UIKit

/// Modelo que representa una pose corporal con puntos clave y ángulos articulares
struct BodyPose {
    /// Puntos clave del cuerpo en coordenadas normalizadas (0-1)
    var keypoints: [JointType: CGPoint] = [:]
    
    /// Ángulos entre articulaciones en grados
    var jointAngles: [JointAngleType: Float] = [:]
    
    /// Confianza de detección para cada punto clave
    var confidences: [JointType: Float] = [:]
    
    /// Vectores entre puntos clave
    var vectors: [VectorType: CGVector] = [:]
    
    /// Timestamp de la detección
    var timestamp: TimeInterval
    
    /// Inicializador desde observación de Vision
    init(from observation: VNHumanBodyPoseObservation, timestamp: TimeInterval) {
        self.timestamp = timestamp
        
        // Extraer puntos clave reconocidos
        if let recognizedPoints = try? observation.recognizedPoints(.all) {
            // Convertir puntos de Vision a nuestro modelo
            for (jointName, point) in recognizedPoints {
                if let jointType = JointType(visionJoint: jointName) {
                    // Convertir a coordenadas normalizadas (0-1)
                    let normalizedPoint = CGPoint(x: CGFloat(point.location.x), y: CGFloat(point.location.y))
                    keypoints[jointType] = normalizedPoint
                    confidences[jointType] = point.confidence
                }
            }
        }
        
        // Calcular ángulos articulares
        calculateJointAngles()
        
        // Calcular vectores entre puntos clave
        calculateVectors()
    }
    
    /// Inicializador desde observación 3D de Vision (si está disponible)
    init(from observation: VNHumanBodyPose3DObservation, timestamp: TimeInterval) {
        self.timestamp = timestamp
        
        // Extraer puntos clave 3D reconocidos
        if let recognizedPoints = try? observation.recognizedPoints3D(.all) {
            // Proyectar puntos 3D a 2D para nuestro modelo
            for (jointName, point) in recognizedPoints {
                if let jointType = JointType(visionJoint3D: jointName) {
                    // Proyectar punto 3D a 2D y normalizar (0-1)
                    // Nota: En una implementación real, se usaría una matriz de proyección adecuada
                    let normalizedPoint = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
                    keypoints[jointType] = normalizedPoint
                    confidences[jointType] = point.confidence
                }
            }
        }
        
        // Calcular ángulos articulares
        calculateJointAngles()
        
        // Calcular vectores entre puntos clave
        calculateVectors()
    }
    
    /// Calcula los ángulos entre articulaciones
    private mutating func calculateJointAngles() {
        // Calcular ángulo de rodilla derecha
        if let hip = keypoints[.rightHip], 
           let knee = keypoints[.rightKnee], 
           let ankle = keypoints[.rightAnkle] {
            jointAngles[.rightKnee] = calculateAngle(p1: hip, p2: knee, p3: ankle)
        }
        
        // Calcular ángulo de rodilla izquierda
        if let hip = keypoints[.leftHip], 
           let knee = keypoints[.leftKnee], 
           let ankle = keypoints[.leftAnkle] {
            jointAngles[.leftKnee] = calculateAngle(p1: hip, p2: knee, p3: ankle)
        }
        
        // Calcular ángulo de cadera derecha
        if let shoulder = keypoints[.rightShoulder], 
           let hip = keypoints[.rightHip], 
           let knee = keypoints[.rightKnee] {
            jointAngles[.rightHip] = calculateAngle(p1: shoulder, p2: hip, p3: knee)
        }
        
        // Calcular ángulo de cadera izquierda
        if let shoulder = keypoints[.leftShoulder], 
           let hip = keypoints[.leftHip], 
           let knee = keypoints[.leftKnee] {
            jointAngles[.leftHip] = calculateAngle(p1: shoulder, p2: hip, p3: knee)
        }
        
        // Calcular ángulo de codo derecho
        if let shoulder = keypoints[.rightShoulder], 
           let elbow = keypoints[.rightElbow], 
           let wrist = keypoints[.rightWrist] {
            jointAngles[.rightElbow] = calculateAngle(p1: shoulder, p2: elbow, p3: wrist)
        }
        
        // Calcular ángulo de codo izquierdo
        if let shoulder = keypoints[.leftShoulder], 
           let elbow = keypoints[.leftElbow], 
           let wrist = keypoints[.leftWrist] {
            jointAngles[.leftElbow] = calculateAngle(p1: shoulder, p2: elbow, p3: wrist)
        }
        
        // Calcular ángulo de hombro derecho
        if let hip = keypoints[.rightHip], 
           let shoulder = keypoints[.rightShoulder], 
           let elbow = keypoints[.rightElbow] {
            jointAngles[.rightShoulder] = calculateAngle(p1: hip, p2: shoulder, p3: elbow)
        }
        
        // Calcular ángulo de hombro izquierdo
        if let hip = keypoints[.leftHip], 
           let shoulder = keypoints[.leftShoulder], 
           let elbow = keypoints[.leftElbow] {
            jointAngles[.leftShoulder] = calculateAngle(p1: hip, p2: shoulder, p3: elbow)
        }
        
        // Calcular ángulo del torso (columna)
        if let neck = keypoints[.neck], 
           let midHip = getMidpoint(p1: keypoints[.rightHip], p2: keypoints[.leftHip]) {
            let topSpine = CGPoint(x: neck.x, y: neck.y + 0.1) // Punto virtual arriba del cuello
            jointAngles[.spine] = calculateAngle(p1: topSpine, p2: neck, p3: midHip)
        }
    }
    
    /// Calcula los vectores entre puntos clave
    private mutating func calculateVectors() {
        // Vector de columna
        if let neck = keypoints[.neck],
           let midHip = getMidpoint(p1: keypoints[.rightHip], p2: keypoints[.leftHip]) {
            vectors[.spine] = CGVector(dx: midHip.x - neck.x, dy: midHip.y - neck.y)
        }
        
        // Vector de muslo derecho
        if let hip = keypoints[.rightHip],
           let knee = keypoints[.rightKnee] {
            vectors[.rightThigh] = CGVector(dx: knee.x - hip.x, dy: knee.y - hip.y)
        }
        
        // Vector de muslo izquierdo
        if let hip = keypoints[.leftHip],
           let knee = keypoints[.leftKnee] {
            vectors[.leftThigh] = CGVector(dx: knee.x - hip.x, dy: knee.y - hip.y)
        }
        
        // Vector de pierna derecha
        if let knee = keypoints[.rightKnee],
           let ankle = keypoints[.rightAnkle] {
            vectors[.rightLeg] = CGVector(dx: ankle.x - knee.x, dy: ankle.y - knee.y)
        }
        
        // Vector de pierna izquierda
        if let knee = keypoints[.leftKnee],
           let ankle = keypoints[.leftAnkle] {
            vectors[.leftLeg] = CGVector(dx: ankle.x - knee.x, dy: ankle.y - knee.y)
        }
        
        // Vector de brazo superior derecho
        if let shoulder = keypoints[.rightShoulder],
           let elbow = keypoints[.rightElbow] {
            vectors[.rightUpperArm] = CGVector(dx: elbow.x - shoulder.x, dy: elbow.y - shoulder.y)
        }
        
        // Vector de brazo superior izquierdo
        if let shoulder = keypoints[.leftShoulder],
           let elbow = keypoints[.leftElbow] {
            vectors[.leftUpperArm] = CGVector(dx: elbow.x - shoulder.x, dy: elbow.y - shoulder.y)
        }
        
        // Vector de antebrazo derecho
        if let elbow = keypoints[.rightElbow],
           let wrist = keypoints[.rightWrist] {
            vectors[.rightForearm] = CGVector(dx: wrist.x - elbow.x, dy: wrist.y - elbow.y)
        }
        
        // Vector de antebrazo izquierdo
        if let elbow = keypoints[.leftElbow],
           let wrist = keypoints[.leftWrist] {
            vectors[.leftForearm] = CGVector(dx: wrist.x - elbow.x, dy: wrist.y - elbow.y)
        }
    }
    
    /// Calcula el ángulo entre tres puntos en grados
    private func calculateAngle(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Float {
        let vector1 = CGVector(dx: p1.x - p2.x, dy: p1.y - p2.y)
        let vector2 = CGVector(dx: p3.x - p2.x, dy: p3.y - p2.y)
        
        let dot = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let det = vector1.dx * vector2.dy - vector1.dy * vector2.dx
        
        let angle = atan2(det, dot)
        
        // Convertir a grados y asegurar valor positivo (0-180)
        let degrees = abs(angle * 180 / .pi)
        return Float(degrees)
    }
    
    /// Obtiene el punto medio entre dos puntos
    private func getMidpoint(p1: CGPoint?, p2: CGPoint?) -> CGPoint? {
        guard let p1 = p1, let p2 = p2 else { return nil }
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
}

/// Tipos de articulaciones del cuerpo
enum JointType: String, CaseIterable {
    case nose
    case neck
    case rightShoulder
    case rightElbow
    case rightWrist
    case leftShoulder
    case leftElbow
    case leftWrist
    case rightHip
    case rightKnee
    case rightAnkle
    case leftHip
    case leftKnee
    case leftAnkle
    
    /// Convierte un joint de Vision a nuestro tipo
    init?(visionJoint: VNHumanBodyPoseObservation.JointName) {
        switch visionJoint {
        case .nose: self = .nose
        case .neck: self = .neck
        case .rightShoulder: self = .rightShoulder
        case .rightElbow: self = .rightElbow
        case .rightWrist: self = .rightWrist
        case .leftShoulder: self = .leftShoulder
        case .leftElbow: self = .leftElbow
        case .leftWrist: self = .leftWrist
        case .rightHip: self = .rightHip
        case .rightKnee: self = .rightKnee
        case .rightAnkle: self = .rightAnkle
        case .leftHip: self = .leftHip
        case .leftKnee: self = .leftKnee
        case .leftAnkle: self = .leftAnkle
        default: return nil
        }
    }
    
    /// Convierte un joint 3D de Vision a nuestro tipo
    init?(visionJoint3D: VNHumanBodyPose3DObservation.JointName) {
        // Mapeo similar al anterior, adaptado para joints 3D
        // En una implementación real, se mapearían todos los joints 3D disponibles
        return nil
    }
}

/// Tipos de ángulos articulares
enum JointAngleType: String, CaseIterable {
    case rightKnee
    case leftKnee
    case rightHip
    case leftHip
    case rightElbow
    case leftElbow
    case rightShoulder
    case leftShoulder
    case spine
}

/// Tipos de vectores entre puntos clave
enum VectorType: String, CaseIterable {
    case spine
    case rightThigh
    case leftThigh
    case rightLeg
    case leftLeg
    case rightUpperArm
    case leftUpperArm
    case rightForearm
    case leftForearm
}
