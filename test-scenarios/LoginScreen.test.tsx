/**
 * LoginScreen Tests
 * 
 * Tests for iOS login button responsiveness fix
 * Bug: br_40a8ee69-c10e-4dac-8057-f9cb38d6bd74
 */

import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { Alert } from 'react-native';
import LoginScreen from './LoginScreen.example';

// Mock Alert
jest.spyOn(Alert, 'alert');

describe('LoginScreen - iOS Touch Responsiveness', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Button Press Handling', () => {
    test('login button should respond to press event', async () => {
      const mockOnLogin = jest.fn().mockResolvedValue(undefined);
      const { getByTestId } = render(<LoginScreen onLogin={mockOnLogin} />);

      const emailInput = getByTestId('email-input');
      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      // Fill in credentials
      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.changeText(passwordInput, 'password123');

      // Press login button
      fireEvent.press(loginButton);

      // Verify onLogin was called
      await waitFor(() => {
        expect(mockOnLogin).toHaveBeenCalledWith('test@example.com', 'password123');
      });
    });

    test('login button should show loading state during login', async () => {
      const mockOnLogin = jest.fn(() => new Promise(resolve => setTimeout(resolve, 100)));
      const { getByTestId, queryByTestId } = render(<LoginScreen onLogin={mockOnLogin} />);

      const emailInput = getByTestId('email-input');
      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.changeText(passwordInput, 'password123');
      fireEvent.press(loginButton);

      // Loading indicator should appear
      await waitFor(() => {
        expect(queryByTestId('loading-indicator')).toBeTruthy();
      });

      // Wait for login to complete
      await waitFor(() => {
        expect(queryByTestId('loading-indicator')).toBeNull();
      });
    });

    test('login button should prevent double-tap', async () => {
      const mockOnLogin = jest.fn(() => new Promise(resolve => setTimeout(resolve, 100)));
      const { getByTestId } = render(<LoginScreen onLogin={mockOnLogin} />);

      const emailInput = getByTestId('email-input');
      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.changeText(passwordInput, 'password123');

      // Rapidly press button twice
      fireEvent.press(loginButton);
      fireEvent.press(loginButton);
      fireEvent.press(loginButton);

      // Wait for completion
      await waitFor(() => {
        expect(mockOnLogin).toHaveBeenCalledTimes(1); // Should only be called once
      }, { timeout: 200 });
    });

    test('login button should be disabled during loading', async () => {
      const mockOnLogin = jest.fn(() => new Promise(resolve => setTimeout(resolve, 100)));
      const { getByTestId } = render(<LoginScreen onLogin={mockOnLogin} />);

      const emailInput = getByTestId('email-input');
      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.changeText(passwordInput, 'password123');
      fireEvent.press(loginButton);

      // Button should be disabled
      await waitFor(() => {
        expect(loginButton.props.accessibilityState?.disabled).toBe(true);
      });
    });
  });

  describe('Input Validation', () => {
    test('should show alert if email is empty', () => {
      const { getByTestId } = render(<LoginScreen />);

      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(passwordInput, 'password123');
      fireEvent.press(loginButton);

      expect(Alert.alert).toHaveBeenCalledWith('Error', 'Please enter email and password');
    });

    test('should show alert if password is empty', () => {
      const { getByTestId } = render(<LoginScreen />);

      const emailInput = getByTestId('email-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.press(loginButton);

      expect(Alert.alert).toHaveBeenCalledWith('Error', 'Please enter email and password');
    });
  });

  describe('Error Handling', () => {
    test('should handle login failure gracefully', async () => {
      const mockOnLogin = jest.fn().mockRejectedValue(new Error('Invalid credentials'));
      const { getByTestId, queryByTestId } = render(<LoginScreen onLogin={mockOnLogin} />);

      const emailInput = getByTestId('email-input');
      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.changeText(passwordInput, 'wrongpassword');
      fireEvent.press(loginButton);

      // Wait for error
      await waitFor(() => {
        expect(Alert.alert).toHaveBeenCalledWith('Error', 'Login failed. Please try again.');
      });

      // Loading should be cleared
      expect(queryByTestId('loading-indicator')).toBeNull();
    });

    test('should clear loading state even if login throws', async () => {
      const mockOnLogin = jest.fn().mockRejectedValue(new Error('Network error'));
      const { getByTestId, queryByTestId } = render(<LoginScreen onLogin={mockOnLogin} />);

      const emailInput = getByTestId('email-input');
      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.changeText(passwordInput, 'password123');
      fireEvent.press(loginButton);

      // Wait for error to be handled
      await waitFor(() => {
        expect(queryByTestId('loading-indicator')).toBeNull();
      });

      // Button should be enabled again
      expect(loginButton.props.accessibilityState?.disabled).toBe(false);
    });
  });

  describe('iOS-Specific Touch Properties', () => {
    test('login button should have activeOpacity prop', () => {
      const { getByTestId } = render(<LoginScreen />);
      const loginButton = getByTestId('login-button');
      
      // TouchableOpacity should have activeOpacity
      expect(loginButton.props.activeOpacity).toBe(0.7);
    });

    test('login button should have hitSlop for better touch area', () => {
      const { getByTestId } = render(<LoginScreen />);
      const loginButton = getByTestId('login-button');
      
      // Should have hitSlop for iOS
      expect(loginButton.props.hitSlop).toEqual({
        top: 10,
        bottom: 10,
        left: 10,
        right: 10,
      });
    });

    test('forgot password button should also have iOS touch props', () => {
      const { getByTestId } = render(<LoginScreen />);
      const forgotButton = getByTestId('forgot-password-button');
      
      expect(forgotButton.props.activeOpacity).toBe(0.7);
    });
  });

  describe('Accessibility', () => {
    test('all interactive elements should have testID', () => {
      const { getByTestId } = render(<LoginScreen />);
      
      expect(getByTestId('email-input')).toBeTruthy();
      expect(getByTestId('password-input')).toBeTruthy();
      expect(getByTestId('login-button')).toBeTruthy();
      expect(getByTestId('forgot-password-button')).toBeTruthy();
    });

    test('inputs should be disabled during loading', async () => {
      const mockOnLogin = jest.fn(() => new Promise(resolve => setTimeout(resolve, 100)));
      const { getByTestId } = render(<LoginScreen onLogin={mockOnLogin} />);

      const emailInput = getByTestId('email-input');
      const passwordInput = getByTestId('password-input');
      const loginButton = getByTestId('login-button');

      fireEvent.changeText(emailInput, 'test@example.com');
      fireEvent.changeText(passwordInput, 'password123');
      fireEvent.press(loginButton);

      await waitFor(() => {
        expect(emailInput.props.editable).toBe(false);
        expect(passwordInput.props.editable).toBe(false);
      });
    });
  });
});

/**
 * Integration Tests
 * 
 * These tests should be run manually on actual iOS devices or simulators
 * to verify real touch behavior. To run these tests:
 * 1. Remove the .skip from the test name
 * 2. Run on actual iOS device/simulator
 * 3. Manually verify the described behavior
 * 4. Re-add .skip after verification
 * 
 * Alternatively, these scenarios can be tracked in a separate manual QA checklist.
 */
describe('LoginScreen - iOS Manual Integration Tests', () => {
  test.skip('MANUAL: Button should respond within 100ms on iOS', () => {
    // This test requires manual verification on iOS device
    // Steps:
    // 1. Run app on iOS simulator/device
    // 2. Navigate to login screen
    // 3. Tap login button
    // 4. Verify visual feedback appears within 100ms
    // 5. Verify button press is registered
  });

  test.skip('MANUAL: Button should work with VoiceOver enabled', () => {
    // This test requires manual verification with accessibility features
    // Steps:
    // 1. Enable VoiceOver on iOS device
    // 2. Navigate to login button
    // 3. Double-tap to activate
    // 4. Verify button press is registered
  });

  test.skip('MANUAL: Button should work during keyboard dismissal', () => {
    // This test requires manual verification
    // Steps:
    // 1. Focus on password input (keyboard shown)
    // 2. Tap login button (keyboard dismisses)
    // 3. Verify button press is registered
    // 4. Verify no touch event is lost
  });
});
