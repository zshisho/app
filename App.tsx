import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import ExerciseAnalyzer from './src/screens/ExerciseAnalyzer';
import Home from './src/screens/Home';

const Stack = createStackNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen 
          name="Home" 
          component={Home}
          options={{ title: 'FitMotion Analyzer' }}
        />
        <Stack.Screen 
          name="Analyzer" 
          component={ExerciseAnalyzer}
          options={{ title: 'Exercise Analysis' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}