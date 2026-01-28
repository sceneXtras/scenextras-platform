import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  ActivityIndicator,
  StyleSheet,
  Platform,
} from 'react-native';
import { SettingsErrorBoundary } from '../../../components/ErrorBoundary';
import { useUserStore } from '../../../store/userStore';

/**
 * Settings Screen Content Component
 * Protected against crashes with defensive checks
 */
function SettingsContent() {
  const user = useUserStore((state) => state.user);
  const isLoading = useUserStore((state) => state.isLoading);
  const isInitialized = useUserStore((state) => state.isInitialized);
  const [isReady, setIsReady] = useState(false);

  // Ensure store is initialized before rendering
  useEffect(() => {
    let isMounted = true;

    // Ensure the component waits for initial store hydration
    const checkReady = () => {
      if (isMounted && isInitialized) {
        setIsReady(true);
      }
    };

    // Check immediately and set up a brief timeout as fallback
    checkReady();
    const timer = setTimeout(checkReady, 50);

    return () => {
      isMounted = false;
      clearTimeout(timer);
    };
  }, [isInitialized]);

  // Show loading state while initializing
  if (isLoading || !isReady || !isInitialized) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#007AFF" />
        <Text style={styles.loadingText}>Loading settings...</Text>
      </View>
    );
  }

  // Handle missing user data gracefully
  if (!user) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorTitle}>Unable to Load Settings</Text>
        <Text style={styles.errorMessage}>
          Please sign in to view your settings.
        </Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.contentContainer}
    >
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Account</Text>
        
        <View style={styles.settingRow}>
          <Text style={styles.label}>Name</Text>
          <Text style={styles.value}>{user.name ?? 'Not set'}</Text>
        </View>

        <View style={styles.settingRow}>
          <Text style={styles.label}>Email</Text>
          <Text style={styles.value}>{user.email ?? 'Not set'}</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Preferences</Text>
        {/* Add more settings here */}
      </View>
    </ScrollView>
  );
}

/**
 * Main Settings Screen Component
 * Wrapped with Error Boundary to prevent white screen crashes
 */
export default function SettingsScreen() {
  return (
    <SettingsErrorBoundary
      onReset={() => {
        // Reset any local state if needed
        console.log('Settings error boundary reset');
      }}
    >
      <SettingsContent />
    </SettingsErrorBoundary>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  contentContainer: {
    padding: 16,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#666',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 20,
  },
  errorTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#000',
  },
  errorMessage: {
    fontSize: 14,
    textAlign: 'center',
    color: '#666',
  },
  section: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 16,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: {
        elevation: 2,
      },
    }),
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    color: '#000',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  label: {
    fontSize: 16,
    color: '#000',
  },
  value: {
    fontSize: 16,
    color: '#666',
  },
});
