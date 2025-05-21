import SwiftUI
import AVFoundation

/// Vista principal para el análisis de ejercicios
struct ExerciseAnalysisView: View {
    @ObservedObject var viewModel: ExerciseAnalysisViewModel
    
    var body: some View {
        ZStack {
            // Capa de fondo: Vista de cámara
            CameraPreviewView(previewLayer: viewModel.previewLayer)
                .edgesIgnoringSafeArea(.all)
            
            // Capa de superposición: Visualización de pose
            PoseVisualizationView(pose: viewModel.currentPose)
            
            // Capa de superposición: Visualización de activación muscular
            if viewModel.showMuscleActivation {
                MuscleActivationView(muscleActivation: viewModel.muscleActivation)
                    .opacity(0.7)
            }
            
            // Panel de información
            VStack {
                Spacer()
                
                // Panel de información y controles
                VStack(spacing: 15) {
                    // Tipo de ejercicio y modo
                    HStack {
                        Text(viewModel.currentExerciseType.displayName)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(viewModel.trainingMode.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(viewModel.trainingMode == .strength ? Color.blue : Color.green)
                            .cornerRadius(10)
                    }
                    
                    // Fase del movimiento
                    HStack {
                        Text("Fase:")
                            .font(.subheadline)
                        
                        Text(viewModel.currentMovementPhase.displayName)
                            .font(.subheadline)
                            .foregroundColor(viewModel.currentMovementPhase.color)
                        
                        Spacer()
                        
                        // Calidad del ejercicio
                        HStack {
                            Text("Calidad:")
                                .font(.subheadline)
                            
                            Text("\(Int(viewModel.exerciseQuality * 100))%")
                                .font(.subheadline)
                                .foregroundColor(qualityColor(for: viewModel.exerciseQuality))
                        }
                    }
                    
                    // Errores detectados
                    if !viewModel.detectedErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Correcciones:")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            
                            ForEach(viewModel.detectedErrors, id: \.self) { error in
                                Text("• \(error.description)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Controles
                    HStack {
                        // Botón para cambiar modo de entrenamiento
                        Button(action: viewModel.toggleTrainingMode) {
                            Image(systemName: viewModel.trainingMode == .strength ? "dumbbell.fill" : "figure.strengthtraining.traditional")
                                .font(.title2)
                                .padding(10)
                                .background(Color.secondary.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Botón para mostrar/ocultar activación muscular
                        Button(action: viewModel.toggleMuscleActivation) {
                            Image(systemName: viewModel.showMuscleActivation ? "person.fill" : "person")
                                .font(.title2)
                                .padding(10)
                                .background(Color.secondary.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Botón para cambiar tipo de ejercicio
                        Button(action: viewModel.cycleExerciseType) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                                .padding(10)
                                .background(Color.secondary.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
                .padding()
            }
        }
        .onAppear {
            viewModel.startCapture()
        }
        .onDisappear {
            viewModel.stopCapture()
        }
    }
    
    /// Determina el color según la calidad del ejercicio
    private func qualityColor(for quality: Float) -> Color {
        switch quality {
        case 0..<0.4:
            return .red
        case 0.4..<0.7:
            return .yellow
        default:
            return .green
        }
    }
}

/// Vista para previsualización de cámara
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

/// Vista para visualización de pose
struct PoseVisualizationView: View {
    let pose: BodyPose?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dibujar solo si hay una pose válida
                if let pose = pose {
                    // Dibujar conexiones entre puntos clave
                    ForEach(connections, id: \.self) { connection in
                        if let startPoint = pose.keypoints[connection.0],
                           let endPoint = pose.keypoints[connection.1],
                           let startConfidence = pose.confidences[connection.0],
                           let endConfidence = pose.confidences[connection.1],
                           startConfidence > 0.5,
                           endConfidence > 0.5 {
                            
                            Path { path in
                                path.move(to: CGPoint(
                                    x: startPoint.x * geometry.size.width,
                                    y: startPoint.y * geometry.size.height
                                ))
                                path.addLine(to: CGPoint(
                                    x: endPoint.x * geometry.size.width,
                                    y: endPoint.y * geometry.size.height
                                ))
                            }
                            .stroke(Color.white, lineWidth: 3)
                        }
                    }
                    
                    // Dibujar puntos clave
                    ForEach(Array(JointType.allCases), id: \.self) { joint in
                        if let point = pose.keypoints[joint],
                           let confidence = pose.confidences[joint],
                           confidence > 0.5 {
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .position(
                                    x: point.x * geometry.size.width,
                                    y: point.y * geometry.size.height
                                )
                        }
                    }
                }
            }
        }
    }
    
    // Conexiones entre puntos clave para visualización
    private let connections: [(JointType, JointType)] = [
        (.nose, .neck),
        (.neck, .rightShoulder),
        (.neck, .leftShoulder),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.neck, .rightHip),
        (.neck, .leftHip),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .leftHip)
    ]
}

/// Vista para visualización de activación muscular
struct MuscleActivationView: View {
    let muscleActivation: [MuscleGroup: Float]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Silueta del cuerpo (imagen de fondo)
                Image("body_silhouette")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width * 0.8)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .opacity(0.3)
                
                // Superposición de grupos musculares
                ForEach(Array(muscleActivation.keys), id: \.self) { muscleGroup in
                    if let activation = muscleActivation[muscleGroup] {
                        MuscleGroupOverlay(
                            muscleGroup: muscleGroup,
                            activation: activation,
                            size: CGSize(
                                width: geometry.size.width * 0.8,
                                height: geometry.size.height * 0.8
                            )
                        )
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
            }
        }
    }
}

/// Superposición de grupo muscular individual
struct MuscleGroupOverlay: View {
    let muscleGroup: MuscleGroup
    let activation: Float
    let size: CGSize
    
    var body: some View {
        // En una implementación real, se usarían imágenes específicas para cada grupo muscular
        // Por ahora, simulamos con formas básicas
        muscleShape
            .fill(activationColor)
            .opacity(Double(activation))
            .frame(width: size.width, height: size.height)
    }
    
    /// Forma que representa el grupo muscular
    private var muscleShape: some Shape {
        switch muscleGroup {
        case .quadriceps:
            return AnyShape(Rectangle().path(in: CGRect(x: size.width * 0.4, y: size.height * 0.5, width: size.width * 0.2, height: size.height * 0.2)))
        case .hamstrings:
            return AnyShape(Rectangle().path(in: CGRect(x: size.width * 0.4, y: size.height * 0.6, width: size.width * 0.2, height: size.height * 0.15)))
        case .gluteus:
            return AnyShape(Circle().path(in: CGRect(x: size.width * 0.4, y: size.height * 0.4, width: size.width * 0.2, height: size.width * 0.2)))
        case .chest:
            return AnyShape(Rectangle().path(in: CGRect(x: size.width * 0.35, y: size.height * 0.2, width: size.width * 0.3, height: size.height * 0.1)))
        case .upperBack:
            return AnyShape(Rectangle().path(in: CGRect(x: size.width * 0.35, y: size.height * 0.25, width: size.width * 0.3, height: size.height * 0.1)))
        case .lowerBack:
            return AnyShape(Rectangle().path(in: CGRect(x: size.width * 0.4, y: size.height * 0.35, width: size.width * 0.2, height: size.height * 0.1)))
        case .biceps:
            return AnyShape(Rectangle().path(in: CGRect(x: size.width * 0.3, y: size.height * 0.3, width: size.width * 0.1, height: size.height * 0.1)))
        case .triceps:
            return AnyShape(Rectangle().path(in: CGRect(x: size.width * 0.6, y: size.height * 0.3, width: size.width * 0.1, height: size.height * 0.1)))
        default:
            return AnyShape(Circle().path(in: CGRect(x: size.width * 0.45, y: size.height * 0.45, width: size.width * 0.1, height: size.width * 0.1)))
        }
    }
    
    /// Color basado en nivel de activación
    private var activationColor: Color {
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

/// Estructura auxiliar para envolver cualquier Shape
struct AnyShape: Shape {
    private let path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        path(rect)
    }
}

// Extensiones para mejorar la visualización

extension ExerciseType {
    var displayName: String {
        switch self {
        case .squat: return "Sentadilla"
        case .deadlift: return "Peso Muerto"
        case .benchPress: return "Press de Banca"
        case .shoulderPress: return "Press de Hombros"
        case .pullUp: return "Dominadas"
        case .row: return "Remo"
        case .lunge: return "Estocada"
        case .other: return "Otro Ejercicio"
        }
    }
}

extension TrainingMode {
    var displayName: String {
        switch self {
        case .strength: return "Fuerza"
        case .hypertrophy: return "Hipertrofia"
        }
    }
}

extension MovementPhase {
    var displayName: String {
        switch self {
        case .concentric: return "Concéntrica"
        case .eccentric: return "Excéntrica"
        case .isometric: return "Isométrica"
        case .unknown: return "Desconocida"
        }
    }
    
    var color: Color {
        switch self {
        case .concentric: return .blue
        case .eccentric: return .orange
        case .isometric: return .yellow
        case .unknown: return .gray
        }
    }
}
