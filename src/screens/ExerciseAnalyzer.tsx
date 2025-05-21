import React, { useState, useEffect, useRef } from 'react';
import { StyleSheet, View, Text, Dimensions } from 'react-native';
import { Camera } from 'expo-camera';
import * as tf from '@tensorflow/tfjs';
import * as posenet from '@tensorflow-models/posenet';
import { cameraWithTensors } from '@tensorflow/tfjs-react-native';

const TensorCamera = cameraWithTensors(Camera);

const { width, height } = Dimensions.get('window');

export default function ExerciseAnalyzer() {
  const [hasPermission, setHasPermission] = useState(null);
  const [model, setModel] = useState<posenet.PoseNet | null>(null);
  const [pose, setPose] = useState(null);
  const [exerciseState, setExerciseState] = useState({
    type: 'unknown',
    phase: 'preparing',
    muscleActivation: {},
    quality: 0,
    errors: [],
  });

  useEffect(() => {
    (async () => {
      const { status } = await Camera.requestCameraPermissionsAsync();
      setHasPermission(status === 'granted');
      
      await tf.ready();
      const loadedModel = await posenet.load({
        architecture: 'MobileNetV1',
        outputStride: 16,
        multiplier: 0.75,
        quantBytes: 2,
      });
      setModel(loadedModel);
    })();
  }, []);

  const handleCameraStream = (images: IterableIterator<tf.Tensor3D>) => {
    const loop = async () => {
      if (!model) return;

      try {
        const nextImageTensor = images.next().value;
        if (nextImageTensor) {
          const pose = await model.estimateSinglePose(nextImageTensor);
          setPose(pose);
          analyzeExercise(pose);
          tf.dispose(nextImageTensor);
        }
      } catch (error) {
        console.error('Error analyzing frame:', error);
      }
      requestAnimationFrame(loop);
    };
    loop();
  };

  const analyzeExercise = (pose) => {
    if (!pose || !pose.keypoints) return;

    // Identificar ejercicio basado en postura
    const exerciseType = identifyExercise(pose);
    
    // Analizar fase del movimiento
    const phase = analyzePhase(pose);
    
    // Calcular activación muscular
    const muscleActivation = calculateMuscleActivation(pose, exerciseType);
    
    // Evaluar calidad del ejercicio
    const { quality, errors } = evaluateQuality(pose, exerciseType);

    setExerciseState({
      type: exerciseType,
      phase,
      muscleActivation,
      quality,
      errors,
    });
  };

  const identifyExercise = (pose) => {
    // Implementación básica - expandir según necesidades
    return 'squat'; // Por ahora retornamos squat como ejemplo
  };

  const analyzePhase = (pose) => {
    // Análisis simple de fase - expandir según necesidades
    return 'eccentric';
  };

  const calculateMuscleActivation = (pose, exerciseType) => {
    // Cálculo básico - expandir según necesidades
    return {
      quadriceps: 0.8,
      hamstrings: 0.6,
      glutes: 0.7,
    };
  };

  const evaluateQuality = (pose, exerciseType) => {
    // Evaluación básica - expandir según necesidades
    return {
      quality: 0.85,
      errors: ['Knees caving in slightly'],
    };
  };

  if (hasPermission === null) {
    return <View />;
  }
  if (hasPermission === false) {
    return <Text>No access to camera</Text>;
  }

  return (
    <View style={styles.container}>
      <TensorCamera
        style={styles.camera}
        type={Camera.Constants.Type.back}
        cameraTextureHeight={height}
        cameraTextureWidth={width}
        resizeHeight={200}
        resizeWidth={152}
        resizeDepth={3}
        onReady={handleCameraStream}
        autorender={true}
      />
      
      <View style={styles.overlay}>
        <Text style={styles.exerciseText}>
          Exercise: {exerciseState.type}
        </Text>
        <Text style={styles.phaseText}>
          Phase: {exerciseState.phase}
        </Text>
        <Text style={styles.qualityText}>
          Quality: {Math.round(exerciseState.quality * 100)}%
        </Text>
        {exerciseState.errors.map((error, index) => (
          <Text key={index} style={styles.errorText}>{error}</Text>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  camera: {
    flex: 1,
  },
  overlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: 'rgba(0,0,0,0.7)',
    padding: 20,
  },
  exerciseText: {
    color: 'white',
    fontSize: 18,
    marginBottom: 5,
  },
  phaseText: {
    color: 'white',
    fontSize: 16,
    marginBottom: 5,
  },
  qualityText: {
    color: 'white',
    fontSize: 16,
    marginBottom: 5,
  },
  errorText: {
    color: '#ff6b6b',
    fontSize: 14,
    marginBottom: 3,
  },
});