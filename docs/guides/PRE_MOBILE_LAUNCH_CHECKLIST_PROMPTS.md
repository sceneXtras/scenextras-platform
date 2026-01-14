# Implementation Prompt: Recent Characters Widget

## Objective

Implement a Home Screen Widget for iOS and Android that displays recent characters from SceneXtras app. When users tap a character in the widget, it should open the app and navigate directly to that character's chat screen.

## Requirements

### Widget Features
- Display recent characters (last 3-6 characters user chatted with)
- Show character avatar, name, and last message preview
- Click/tap on character opens app and navigates to chat
- Auto-updates when new chats occur
- Works on both iOS and Android

### Technical Requirements
- Use React Native with Expo SDK 54
- Integrate with existing Zustand stores (`characterStore`, `messageStore`)
- Support deep linking to chat screens
- Handle widget updates from app state changes

---

## Implementation Approach

### Option A: Home Screen Widgets (Recommended)

**Package:** `react-native-widget-extension`

**Why:** Supports both iOS and Android home screen widgets, which is what we need for "recent characters" display.

**Limitation:** Widgets must be written in Swift (iOS) and Kotlin (Android), but app integration is via JavaScript.

### Option B: Live Activities Only (Alternative)

**Package:** `@heojeongbo/expo-live-activity`

**Why:** Pure React/TypeScript, but only shows on Lock Screen (iOS) or as notifications (Android), not as home screen widgets.

**Use Case:** Better for active chat sessions, not for "recent characters" browsing.

---

## Implementation Plan

### Phase 1: Setup Widget Extension

1. **Install Package**
   ```bash
   cd mobile_app_sx
   npx expo install react-native-widget-extension
   ```

2. **Configure Expo**
   ```javascript
   // app.config.js
   export default {
     expo: {
       plugins: [
         [
           'react-native-widget-extension',
           {
             frequentUpdates: true,
             widgetsFolder: 'SceneXtrasWidgets',
           },
         ],
         // ... existing plugins
       ],
     },
   };
   ```

3. **Run Prebuild**
   ```bash
   npx expo prebuild --clean
   ```

### Phase 2: Create Widget Data Sharing Service

**File:** `mobile_app_sx/services/widgetDataService.ts`

```typescript
import { Platform } from 'react-native';
import { SharedGroupPreferences } from 'react-native-shared-group-preferences';
import { useCharacterStore } from '@/store/characterStore';
import { useMessageStore } from '@/store/messageStore';

const APP_GROUP_IDENTIFIER = 'group.com.scenextras.widget';

interface CharacterWidgetData {
  id: string;
  name: string;
  avatarUrl: string;
  lastMessage: string;
  lastMessageTime: number;
}

export class WidgetDataService {
  /**
   * Get recent characters sorted by last message time
   */
  static getRecentCharacters(maxCount: number = 6): CharacterWidgetData[] {
    const messages = useMessageStore.getState().messages;
    const characters = useCharacterStore.getState().characters;

    // Get all chats with messages
    const chatsWithMessages = Object.keys(messages)
      .map(characterId => {
        const character = characters.find(c => c.id === characterId);
        const chatMessages = messages[characterId];
        
        if (!character || !chatMessages || chatMessages.length === 0) {
          return null;
        }

        const lastMessage = chatMessages[chatMessages.length - 1];
        
        return {
          id: character.id,
          name: character.name,
          avatarUrl: character.avatarUrl,
          lastMessage: lastMessage.text || '',
          lastMessageTime: lastMessage.timestamp || Date.now(),
        } as CharacterWidgetData;
      })
      .filter(Boolean) as CharacterWidgetData[];

    // Sort by last message time (most recent first)
    chatsWithMessages.sort((a, b) => b.lastMessageTime - a.lastMessageTime);

    // Return top N characters
    return chatsWithMessages.slice(0, maxCount);
  }

  /**
   * Update widget data when characters/messages change
   */
  static async updateWidgetData() {
    if (Platform.OS !== 'ios') {
      // Android uses SharedPreferences (different implementation)
      return;
    }

    try {
      const recentCharacters = this.getRecentCharacters(6);
      
      await SharedGroupPreferences.setItem(
        'recentCharacters',
        recentCharacters,
        APP_GROUP_IDENTIFIER
      );

      // Notify widget to refresh
      // This will trigger widget timeline update
      console.log('Widget data updated:', recentCharacters.length, 'characters');
    } catch (error) {
      console.error('Failed to update widget data:', error);
    }
  }

  /**
   * Handle deep link when widget is tapped
   */
  static createDeepLink(characterId: string): string {
    return `scenextras://chat/${characterId}`;
  }
}
```

### Phase 3: Create Widget Update Hook

**File:** `mobile_app_sx/hooks/useWidgetUpdates.ts`

```typescript
import { useEffect } from 'react';
import { useMessageStore } from '@/store/messageStore';
import { useCharacterStore } from '@/store/characterStore';
import { WidgetDataService } from '@/services/widgetDataService';

/**
 * Hook to automatically update widget when chat data changes
 */
export function useWidgetUpdates() {
  const messages = useMessageStore(state => state.messages);
  const characters = useCharacterStore(state => state.characters);

  useEffect(() => {
    // Update widget whenever messages or characters change
    WidgetDataService.updateWidgetData();
  }, [messages, characters]);

  return null;
}
```

### Phase 4: Integrate Widget Updates in App

**Update:** `mobile_app_sx/app/_layout.tsx`

```typescript
import { useWidgetUpdates } from '@/hooks/useWidgetUpdates';

export default function RootLayout() {
  // Update widgets when app state changes
  useWidgetUpdates();

  // ... rest of layout
}
```

### Phase 5: Handle Deep Linking

**Update:** `mobile_app_sx/app.config.js`

```javascript
export default {
  expo: {
    // ... existing config
    scheme: 'scenextras',
    // ... rest of config
  },
};
```

**Create:** `mobile_app_sx/app/[...chat].tsx` (or update existing chat routing)

```typescript
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect } from 'react';
import { useCharacterStore } from '@/store/characterStore';

export default function ChatRedirect() {
  const { characterId } = useLocalSearchParams<{ characterId: string }>();
  const router = useRouter();
  const characters = useCharacterStore(state => state.characters);

  useEffect(() => {
    if (characterId) {
      // Navigate to chat screen
      router.replace(`/(tabs)/chats/${characterId}`);
    }
  }, [characterId, router]);

  return null;
}
```

### Phase 6: Create Native Widget (iOS)

**File:** `ios/SceneXtrasWidgets/RecentCharactersWidget.swift`

```swift
import WidgetKit
import SwiftUI

struct CharacterEntry: TimelineEntry {
    let date: Date
    let characters: [CharacterData]
}

struct CharacterData: Codable {
    let id: String
    let name: String
    let avatarUrl: String
    let lastMessage: String
    let lastMessageTime: TimeInterval
}

struct RecentCharactersWidget: Widget {
    let kind: String = "RecentCharactersWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentCharactersProvider()) { entry in
            RecentCharactersView(entry: entry)
        }
        .configurationDisplayName("Recent Characters")
        .description("Quick access to your recent character chats")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RecentCharactersProvider: TimelineProvider {
    func placeholder(in context: Context) -> CharacterEntry {
        CharacterEntry(
            date: Date(),
            characters: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CharacterEntry) -> ()) {
        let entry = CharacterEntry(date: Date(), characters: loadCharacters())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CharacterEntry>) -> ()) {
        let characters = loadCharacters()
        let entry = CharacterEntry(date: Date(), characters: characters)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func loadCharacters() -> [CharacterData] {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.scenextras.widget"),
              let data = sharedDefaults.data(forKey: "recentCharacters"),
              let characters = try? JSONDecoder().decode([CharacterData].self, from: data) else {
            return []
        }
        return characters
    }
}

struct RecentCharactersView: View {
    var entry: CharacterEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Characters")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(entry.characters.prefix(3), id: \.id) { character in
                Link(destination: URL(string: "scenextras://chat/\(character.id)")!) {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: character.avatarUrl)) { image in
                            image.resizable()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(character.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(character.lastMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
    }
}
```

### Phase 7: Create Native Widget (Android)

**File:** `android/app/src/main/java/com/scenextras/widget/RecentCharactersWidget.kt`

```kotlin
package com.scenextras.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

class RecentCharactersWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_recent_characters)
        
        // Load characters from SharedPreferences
        val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
        val charactersJson = prefs.getString("recentCharacters", "[]")
        
        val characters = parseCharacters(charactersJson ?: "[]")
        
        // Update widget UI
        // (Implementation depends on your widget layout)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun parseCharacters(json: String): List<CharacterData> {
        val array = JSONArray(json)
        val characters = mutableListOf<CharacterData>()
        
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            characters.add(
                CharacterData(
                    id = obj.getString("id"),
                    name = obj.getString("name"),
                    avatarUrl = obj.getString("avatarUrl"),
                    lastMessage = obj.getString("lastMessage"),
                    lastMessageTime = obj.getLong("lastMessageTime")
                )
            )
        }
        
        return characters
    }
}

data class CharacterData(
    val id: String,
    val name: String,
    val avatarUrl: String,
    val lastMessage: String,
    val lastMessageTime: Long
)
```

### Phase 8: Android Widget Data Service

**Update:** `mobile_app_sx/services/widgetDataService.ts`

```typescript
import { Platform, NativeModules } from 'react-native';

// ... existing code ...

export class WidgetDataService {
  // ... existing methods ...

  static async updateWidgetData() {
    const recentCharacters = this.getRecentCharacters(6);

    if (Platform.OS === 'ios') {
      // iOS implementation (existing)
      await SharedGroupPreferences.setItem(
        'recentCharacters',
        recentCharacters,
        APP_GROUP_IDENTIFIER
      );
    } else if (Platform.OS === 'android') {
      // Android implementation
      const { WidgetStorage } = NativeModules;
      if (WidgetStorage) {
        await WidgetStorage.setRecentCharacters(JSON.stringify(recentCharacters));
      }
    }
  }
}
```

---

## Testing Checklist

- [ ] Install `react-native-widget-extension`
- [ ] Add Expo config plugin
- [ ] Run `expo prebuild --clean`
- [ ] Create `WidgetDataService`
- [ ] Create `useWidgetUpdates` hook
- [ ] Implement iOS widget (Swift)
- [ ] Implement Android widget (Kotlin)
- [ ] Set up deep linking
- [ ] Test widget appears on home screen
- [ ] Test widget updates when chats change
- [ ] Test tapping character opens chat
- [ ] Test on iOS device
- [ ] Test on Android device

---

## Alternative: Pure React/TypeScript Approach (Future)

If you want to wait for **Voltra** to be released, it promises:
- Pure React/TypeScript widgets (no Swift/Kotlin)
- Live Activities + Home Widgets + Dynamic Island
- Cross-platform support

For now, `react-native-widget-extension` is the best option for Home Screen Widgets.

---

## Notes

- **Widgets require native code** - This is an iOS/Android limitation
- **Data sharing** - Use App Groups (iOS) or SharedPreferences (Android)
- **Deep linking** - Required to navigate from widget to app
- **Update frequency** - Widgets update periodically, not instantly
- **Testing** - Widgets only work on physical devices, not simulators

---

**Priority:** Medium
**Estimated Time:** 2-3 days (including native widget development)
**Complexity:** Medium-High (requires native code)
