import React from 'react';
import { render, waitFor, act } from '@testing-library/react-native';
import SettingsScreen from '../app/(drawer)/(tabs)/settings';
import { useUserStore } from '../store/userStore';

// Mock Sentry
jest.mock('@sentry/react-native', () => ({
  captureException: jest.fn(),
}));

// Mock user store
jest.mock('../store/userStore', () => ({
  useUserStore: jest.fn(),
}));

describe('SettingsScreen - Crash Fix Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render loading state initially', () => {
    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector({
        user: null,
        isLoading: true,
        isInitialized: false,
      })
    );

    const { getByText } = render(<SettingsScreen />);
    expect(getByText('Loading settings...')).toBeTruthy();
  });

  it('should handle missing user data gracefully', async () => {
    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector({
        user: null,
        isLoading: false,
        isInitialized: true,
      })
    );

    const { getByText } = render(<SettingsScreen />);
    
    await waitFor(() => {
      expect(getByText('Unable to Load Settings')).toBeTruthy();
    });
  });

  it('should render user data when available', async () => {
    const mockUser = {
      id: '123',
      name: 'Test User',
      email: 'test@example.com',
    };

    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector({
        user: mockUser,
        isLoading: false,
        isInitialized: true,
      })
    );

    const { getByText } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(getByText('Test User')).toBeTruthy();
      expect(getByText('test@example.com')).toBeTruthy();
    });
  });

  it('should handle null user fields safely', async () => {
    const mockUser = {
      id: '123',
      name: null,
      email: undefined,
    };

    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector({
        user: mockUser,
        isLoading: false,
        isInitialized: true,
      })
    );

    const { getByText } = render(<SettingsScreen />);

    await waitFor(() => {
      expect(getByText('Not set')).toBeTruthy();
    });
  });

  it('should not crash when store is undefined', () => {
    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector(undefined)
    );

    expect(() => render(<SettingsScreen />)).not.toThrow();
  });

  it('should handle store initialization timeout', async () => {
    jest.useFakeTimers();

    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector({
        user: null,
        isLoading: true,
        isInitialized: false,
      })
    );

    const { getByText, rerender } = render(<SettingsScreen />);

    // Initially shows loading
    expect(getByText('Loading settings...')).toBeTruthy();

    // Advance timers past the 100ms timeout
    act(() => {
      jest.advanceTimersByTime(150);
    });

    // Update mock to show initialized state
    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector({
        user: { id: '123', name: 'Test' },
        isLoading: false,
        isInitialized: true,
      })
    );

    rerender(<SettingsScreen />);

    await waitFor(() => {
      expect(getByText('Test')).toBeTruthy();
    });

    jest.useRealTimers();
  });

  it('should catch and display errors gracefully', () => {
    // Mock a component that throws an error
    const ThrowError = () => {
      throw new Error('Test error');
    };

    // This would normally crash without error boundary
    const { getByText } = render(
      <SettingsScreen>
        <ThrowError />
      </SettingsScreen>
    );

    // Error boundary should catch and show fallback
    expect(getByText('Something went wrong')).toBeTruthy();
  });

  it('should allow error recovery via retry button', () => {
    // Simulate error state
    const ThrowError = () => {
      throw new Error('Test error');
    };

    const { getByText } = render(
      <SettingsScreen>
        <ThrowError />
      </SettingsScreen>
    );

    const retryButton = getByText('Try Again');
    expect(retryButton).toBeTruthy();
    
    // Verify button is pressable (would trigger onReset)
    expect(retryButton.props.onPress).toBeDefined();
  });
});

describe('SettingsScreen - Race Condition Tests', () => {
  it('should handle rapid mount/unmount cycles', async () => {
    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector({
        user: { id: '123', name: 'Test' },
        isLoading: false,
        isInitialized: true,
      })
    );

    const { unmount, rerender } = render(<SettingsScreen />);
    
    // Rapid unmount and remount
    unmount();
    rerender(<SettingsScreen />);
    unmount();
    rerender(<SettingsScreen />);

    // Should not crash
    await waitFor(() => {
      expect(true).toBe(true);
    });
  });

  it('should handle store state changes during render', async () => {
    let storeState = {
      user: null,
      isLoading: true,
      isInitialized: false,
    };

    (useUserStore as jest.Mock).mockImplementation((selector) =>
      selector(storeState)
    );

    const { getByText, rerender } = render(<SettingsScreen />);

    // Initially loading
    expect(getByText('Loading settings...')).toBeTruthy();

    // Simulate store update
    storeState = {
      user: { id: '123', name: 'Test User' },
      isLoading: false,
      isInitialized: true,
    };

    rerender(<SettingsScreen />);

    await waitFor(() => {
      expect(getByText('Test User')).toBeTruthy();
    });
  });
});
