import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import * as Sentry from '@sentry/react-native';

interface Props {
  children: React.ReactNode;
  fallback?: React.ComponentType<FallbackProps>;
  onReset?: () => void;
}

interface FallbackProps {
  error: Error;
  resetError: () => void;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

/**
 * Error Boundary component for Settings screen
 * Catches unhandled errors and prevents white screen crashes
 */
export class SettingsErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  static getDerivedStateFromError(error: Error): State {
    return {
      hasError: true,
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log error to Sentry
    Sentry.captureException(error, {
      contexts: {
        react: {
          componentStack: errorInfo.componentStack,
        },
      },
      tags: {
        screen: 'Settings',
        errorBoundary: 'SettingsErrorBoundary',
      },
    });

    console.error('Settings screen error:', error, errorInfo);
  }

  resetError = () => {
    this.setState({
      hasError: false,
      error: null,
    });
    this.props.onReset?.();
  };

  render() {
    if (this.state.hasError && this.state.error) {
      const FallbackComponent = this.props.fallback || DefaultFallback;
      return (
        <FallbackComponent
          error={this.state.error}
          resetError={this.resetError}
        />
      );
    }

    return this.props.children;
  }
}

/**
 * Default fallback UI when error occurs
 */
function DefaultFallback({ error, resetError }: FallbackProps) {
  const errorMessage = error?.message || 'An unknown error occurred';
  
  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Something went wrong</Text>
        <Text style={styles.message}>
          We encountered an error loading your settings. Please try again.
        </Text>
        {__DEV__ && (
          <Text style={styles.errorDetails}>
            {errorMessage}
          </Text>
        )}
        <TouchableOpacity
          style={styles.button}
          onPress={resetError}
          activeOpacity={0.7}
        >
          <Text style={styles.buttonText}>Try Again</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 20,
  },
  content: {
    alignItems: 'center',
    maxWidth: 300,
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 12,
    color: '#000',
  },
  message: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 20,
    color: '#666',
    lineHeight: 22,
  },
  errorDetails: {
    fontSize: 12,
    color: '#999',
    marginBottom: 20,
    textAlign: 'center',
  },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});
