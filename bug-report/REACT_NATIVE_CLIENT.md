# React Native Client Integration

## Installation

No additional dependencies required. Uses built-in `fetch` API.

## TypeScript Types

```typescript
// types/bugReport.ts

export interface LogEntry {
  level: 'error' | 'warn' | 'info' | 'debug';
  message: string;
  timestamp: string;
  context?: Record<string, any>;
}

export interface DeviceInfo {
  platform: string;
  os: string;
  osVersion: string;
  appVersion: string;
  buildNumber: string;
  deviceModel?: string;
  manufacturer?: string;
}

export interface UserInfo {
  userId?: string;
  username?: string;
  email?: string;
}

export interface BugReportPayload {
  title: string;
  description: string;
  stepsToReproduce?: string;
  currentRoute: string;
  navigationHistory: string[];
  logs: LogEntry[];
  deviceInfo: DeviceInfo;
  userInfo?: UserInfo;
  timestamp: string;
  traceId?: string;
  screenshot?: {
    uri: string;
    type: string;
    name: string;
  };
}

export interface BugReportResponse {
  success: boolean;
  reportId?: string;
  error?: string;
}
```

## Bug Report Service

```typescript
// services/bugReportService.ts

import * as Application from 'expo-application';
import * as Device from 'expo-device';
import { Platform } from 'react-native';
import type { BugReportPayload, BugReportResponse, DeviceInfo } from '@/types/bugReport';

const API_URL = process.env.EXPO_PUBLIC_BUG_REPORT_API_URL || 'http://localhost:8080';

class BugReportService {
  /**
   * Get device and app information
   */
  async getDeviceInfo(): Promise<DeviceInfo> {
    return {
      platform: Platform.OS,
      os: Platform.OS === 'ios' ? 'iOS' : 'Android',
      osVersion: Platform.Version.toString(),
      appVersion: Application.nativeApplicationVersion || '1.0.0',
      buildNumber: Application.nativeBuildVersion || '1',
      deviceModel: Device.modelName || undefined,
      manufacturer: Device.manufacturer || undefined,
    };
  }

  /**
   * Submit a bug report
   */
  async submitBugReport(payload: BugReportPayload): Promise<BugReportResponse> {
    try {
      const formData = new FormData();

      // Required fields
      formData.append('title', payload.title);
      formData.append('description', payload.description);
      formData.append('currentRoute', payload.currentRoute);
      formData.append('navigationHistory', JSON.stringify(payload.navigationHistory));
      formData.append('logs', JSON.stringify(payload.logs));
      formData.append('deviceInfo', JSON.stringify(payload.deviceInfo));
      formData.append('timestamp', payload.timestamp);

      // Optional fields
      if (payload.stepsToReproduce) {
        formData.append('stepsToReproduce', payload.stepsToReproduce);
      }
      if (payload.userInfo) {
        formData.append('userInfo', JSON.stringify(payload.userInfo));
      }
      if (payload.traceId) {
        formData.append('traceId', payload.traceId);
      }

      // Screenshot
      if (payload.screenshot) {
        formData.append('screenshot', {
          uri: payload.screenshot.uri,
          type: payload.screenshot.type,
          name: payload.screenshot.name,
        } as any);
      }

      const response = await fetch(`${API_URL}/api/reports`, {
        method: 'POST',
        body: formData,
        headers: {
          // Don't set Content-Type, let fetch set it with boundary
        },
      });

      const data: BugReportResponse = await response.json();
      return data;
    } catch (error) {
      console.error('Failed to submit bug report:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  /**
   * List all bug reports
   */
  async listReports(): Promise<any> {
    try {
      const response = await fetch(`${API_URL}/api/reports`);
      return await response.json();
    } catch (error) {
      console.error('Failed to list reports:', error);
      return { success: false, error: String(error) };
    }
  }

  /**
   * Get a specific report
   */
  async getReport(reportId: string): Promise<any> {
    try {
      const response = await fetch(`${API_URL}/api/reports/${reportId}`);
      return await response.json();
    } catch (error) {
      console.error('Failed to get report:', error);
      return null;
    }
  }
}

export const bugReportService = new BugReportService();
```

## Bug Report Hook

```typescript
// hooks/useBugReport.ts

import { useState } from 'react';
import { captureRef } from 'react-native-view-shot';
import { bugReportService } from '@/services/bugReportService';
import { useNavigation } from 'expo-router';
import type { BugReportPayload } from '@/types/bugReport';

interface UseBugReportOptions {
  navigationHistory?: string[];
  logs?: any[];
  userInfo?: any;
}

export function useBugReport(options: UseBugReportOptions = {}) {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigation = useNavigation();

  /**
   * Submit a bug report with automatic screenshot
   */
  const submitBugReport = async ({
    title,
    description,
    stepsToReproduce,
    screenshotRef,
  }: {
    title: string;
    description: string;
    stepsToReproduce?: string;
    screenshotRef?: any;
  }) => {
    setIsSubmitting(true);

    try {
      // Capture screenshot if ref provided
      let screenshot;
      if (screenshotRef?.current) {
        const uri = await captureRef(screenshotRef.current, {
          format: 'png',
          quality: 0.8,
        });
        screenshot = {
          uri,
          type: 'image/png',
          name: 'screenshot.png',
        };
      }

      // Get device info
      const deviceInfo = await bugReportService.getDeviceInfo();

      // Get current route
      const currentRoute = navigation.getState().routes[navigation.getState().index]?.name || 'unknown';

      // Build payload
      const payload: BugReportPayload = {
        title,
        description,
        stepsToReproduce,
        currentRoute,
        navigationHistory: options.navigationHistory || [currentRoute],
        logs: options.logs || [],
        deviceInfo,
        userInfo: options.userInfo,
        timestamp: new Date().toISOString(),
        screenshot,
      };

      // Submit
      const result = await bugReportService.submitBugReport(payload);

      return result;
    } catch (error) {
      console.error('Failed to submit bug report:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    } finally {
      setIsSubmitting(false);
    }
  };

  return {
    submitBugReport,
    isSubmitting,
  };
}
```

## Usage Example: Bug Report Screen

```typescript
// app/bug-report.tsx

import React, { useState, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity, Alert, ScrollView } from 'react-native';
import { useBugReport } from '@/hooks/useBugReport';
import { useUserStore } from '@/store/userStore';

export default function BugReportScreen() {
  const screenshotRef = useRef(null);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [steps, setSteps] = useState('');

  const user = useUserStore((state) => state.user);
  const { submitBugReport, isSubmitting } = useBugReport({
    userInfo: user ? { userId: user.id, email: user.email } : undefined,
  });

  const handleSubmit = async () => {
    if (!title || !description) {
      Alert.alert('Error', 'Please fill in title and description');
      return;
    }

    const result = await submitBugReport({
      title,
      description,
      stepsToReproduce: steps,
      screenshotRef,
    });

    if (result.success) {
      Alert.alert('Success', `Bug report submitted: ${result.reportId}`);
      setTitle('');
      setDescription('');
      setSteps('');
    } else {
      Alert.alert('Error', result.error || 'Failed to submit bug report');
    }
  };

  return (
    <ScrollView className="flex-1 bg-white p-4" ref={screenshotRef}>
      <Text className="text-2xl font-bold mb-4">Report a Bug</Text>

      <Text className="text-sm font-semibold mb-2">Title *</Text>
      <TextInput
        className="border border-gray-300 rounded-lg p-3 mb-4"
        placeholder="Brief description of the bug"
        value={title}
        onChangeText={setTitle}
      />

      <Text className="text-sm font-semibold mb-2">Description *</Text>
      <TextInput
        className="border border-gray-300 rounded-lg p-3 mb-4 h-24"
        placeholder="What happened?"
        value={description}
        onChangeText={setDescription}
        multiline
        numberOfLines={4}
      />

      <Text className="text-sm font-semibold mb-2">Steps to Reproduce</Text>
      <TextInput
        className="border border-gray-300 rounded-lg p-3 mb-4 h-24"
        placeholder="1. Go to...\n2. Click on...\n3. See error"
        value={steps}
        onChangeText={setSteps}
        multiline
        numberOfLines={4}
      />

      <TouchableOpacity
        className={`rounded-lg p-4 ${isSubmitting ? 'bg-gray-400' : 'bg-blue-500'}`}
        onPress={handleSubmit}
        disabled={isSubmitting}
      >
        <Text className="text-white text-center font-semibold">
          {isSubmitting ? 'Submitting...' : 'Submit Bug Report'}
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
}
```

## Automatic Error Boundary Integration

```typescript
// components/ErrorBoundary.tsx

import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { bugReportService } from '@/services/bugReportService';
import type { LogEntry } from '@/types/bugReport';

interface Props {
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends React.Component<Props, State> {
  state: State = {
    hasError: false,
    error: null,
  };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  async componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);

    // Auto-submit crash report
    try {
      const deviceInfo = await bugReportService.getDeviceInfo();

      const logs: LogEntry[] = [
        {
          level: 'error',
          message: error.message,
          timestamp: new Date().toISOString(),
          context: {
            stack: error.stack,
            componentStack: errorInfo.componentStack,
          },
        },
      ];

      await bugReportService.submitBugReport({
        title: `App Crash: ${error.name}`,
        description: error.message,
        stepsToReproduce: 'App crashed unexpectedly',
        currentRoute: 'unknown',
        navigationHistory: [],
        logs,
        deviceInfo,
        timestamp: new Date().toISOString(),
        traceId: `crash_${Date.now()}`,
      });
    } catch (submitError) {
      console.error('Failed to submit crash report:', submitError);
    }
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      return (
        <View className="flex-1 justify-center items-center p-4 bg-white">
          <Text className="text-2xl font-bold mb-2">Oops!</Text>
          <Text className="text-center mb-4">Something went wrong.</Text>
          <Text className="text-sm text-gray-600 text-center mb-4">
            A crash report has been automatically sent.
          </Text>
          <TouchableOpacity
            className="bg-blue-500 rounded-lg px-6 py-3"
            onPress={this.handleReset}
          >
            <Text className="text-white font-semibold">Try Again</Text>
          </TouchableOpacity>
        </View>
      );
    }

    return this.props.children;
  }
}
```

## Environment Configuration

Add to `.env`:

```bash
EXPO_PUBLIC_BUG_REPORT_API_URL=https://bug-report.scenextras.com
```

## Testing

```bash
# Start the API locally
cd bug-report
export AZURE_STORAGE_CONNECTION_STRING="..."
go run main.go

# In React Native app
EXPO_PUBLIC_BUG_REPORT_API_URL=http://localhost:8080 yarn start
```
