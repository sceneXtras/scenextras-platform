/**
 * LoginScreen - Fixed iOS Touch Issue
 * 
 * This file demonstrates the proper implementation of the login button
 * with fixes for iOS touch responsiveness issues
 * 
 * Bug: br_40a8ee69-c10e-4dac-8057-f9cb38d6bd74
 * Platform: iOS
 * Severity: Critical
 */

import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
  StyleSheet,
  Platform,
  Alert,
} from 'react-native';

interface LoginScreenProps {
  onLogin?: (email: string, password: string) => Promise<void>;
}

const LoginScreen: React.FC<LoginScreenProps> = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  /**
   * FIX #1: Memoized handler with proper loading state management
   * - Prevents double-tap
   * - Ensures loading state is always cleared
   */
  const handleLogin = useCallback(async () => {
    // Prevent double-tap
    if (isLoading) {
      console.log('[LoginScreen] Already loading, ignoring tap');
      return;
    }

    // Validate inputs
    if (!email || !password) {
      Alert.alert('Error', 'Please enter email and password');
      return;
    }

    setIsLoading(true);
    try {
      if (onLogin) {
        await onLogin(email, password);
      } else {
        // Default auth logic
        await new Promise(resolve => setTimeout(resolve, 1000));
        Alert.alert('Success', 'Login successful');
      }
    } catch (error) {
      console.error('[LoginScreen] Login failed:', error);
      Alert.alert('Error', 'Login failed. Please try again.');
    } finally {
      // Always clear loading state
      setIsLoading(false);
    }
  }, [email, password, isLoading, onLogin]);

  return (
    <View style={styles.container} pointerEvents="box-none">
      <View style={styles.formContainer}>
        <Text style={styles.title}>SceneXtras Login</Text>

        <TextInput
          style={styles.input}
          placeholder="Email"
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          editable={!isLoading}
          testID="email-input"
        />

        <TextInput
          style={styles.input}
          placeholder="Password"
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          editable={!isLoading}
          testID="password-input"
        />

        {/**
         * FIX #2: Properly configured TouchableOpacity
         * - activeOpacity for iOS visual feedback
         * - hitSlop for larger touch area (iOS best practice)
         * - Loading indicator inside button (not overlapping)
         * - Disabled state properly managed
         */}
        <TouchableOpacity
          style={[
            styles.loginButton,
            isLoading && styles.loginButtonDisabled,
          ]}
          onPress={handleLogin}
          disabled={isLoading}
          activeOpacity={0.7}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          testID="login-button"
        >
          {isLoading ? (
            <ActivityIndicator 
              color="#ffffff" 
              size="small"
              testID="loading-indicator"
            />
          ) : (
            <Text style={styles.loginButtonText}>Login</Text>
          )}
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.forgotPasswordButton}
          onPress={() => Alert.alert('Info', 'Password reset not implemented')}
          disabled={isLoading}
          activeOpacity={0.7}
          testID="forgot-password-button"
        >
          <Text style={styles.forgotPasswordText}>Forgot Password?</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  formContainer: {
    width: '90%',
    maxWidth: 400,
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 24,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
      },
      android: {
        elevation: 4,
      },
    }),
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 24,
    textAlign: 'center',
  },
  input: {
    height: 48,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 16,
    fontSize: 16,
    marginBottom: 16,
    backgroundColor: '#fafafa',
  },
  loginButton: {
    height: 48,
    backgroundColor: '#007AFF',
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
    /**
     * FIX #3: Ensure button has proper touchable styling
     * - No position: absolute that might block touches
     * - Proper z-index if needed
     */
  },
  loginButtonDisabled: {
    backgroundColor: '#ccc',
    opacity: 0.7,
  },
  loginButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  forgotPasswordButton: {
    marginTop: 16,
    padding: 8,
    alignItems: 'center',
  },
  forgotPasswordText: {
    color: '#007AFF',
    fontSize: 14,
  },
});

export default LoginScreen;

/**
 * TESTING NOTES:
 * 
 * iOS-Specific Tests:
 * 1. Test on iOS simulator with different iOS versions (14+)
 * 2. Test on real iOS device (different screen sizes)
 * 3. Verify touch feedback is immediate (< 100ms)
 * 4. Verify no touch event conflicts with keyboard
 * 5. Test with VoiceOver enabled (accessibility)
 * 
 * Edge Cases:
 * - Rapid tapping (double-tap prevention)
 * - Tap while keyboard is dismissing
 * - Tap during app state transition
 * - Tap with loading state stuck (should be prevented by finally block)
 */
