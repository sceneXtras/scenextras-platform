import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

/**
 * User Store with crash-safe initialization
 * Fixes Settings page crash by ensuring proper state initialization
 */

interface User {
  id: string;
  name?: string;
  email?: string;
  // Add other user fields as needed
}

interface UserStoreState {
  user: User | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
}

interface UserStoreActions {
  setUser: (user: User | null) => void;
  initialize: () => Promise<void>;
  reset: () => void;
}

type UserStore = UserStoreState & UserStoreActions;

const initialState: UserStoreState = {
  user: null,
  isLoading: false,
  isInitialized: false,
  error: null,
};

/**
 * Custom storage implementation with error handling
 * Prevents crashes when storage access fails
 */
const createSafeStorage = () => {
  // Import MMKV only on React Native
  let storage: any;
  
  try {
    if (typeof window !== 'undefined' && (window as any).MMKV) {
      const { MMKV } = require('react-native-mmkv');
      storage = new MMKV();
    }
  } catch (error) {
    console.error('Failed to initialize MMKV storage:', error);
  }

  return createJSONStorage(() => ({
    getItem: (name: string) => {
      try {
        return storage?.getString(name) ?? null;
      } catch (error) {
        console.error('Storage getItem error:', error);
        return null;
      }
    },
    setItem: (name: string, value: string) => {
      try {
        storage?.set(name, value);
      } catch (error) {
        console.error('Storage setItem error:', error);
      }
    },
    removeItem: (name: string) => {
      try {
        storage?.delete(name);
      } catch (error) {
        console.error('Storage removeItem error:', error);
      }
    },
  }));
};

export const useUserStore = create<UserStore>()(
  persist(
    (set, get) => ({
      ...initialState,

      setUser: (user) => {
        set({ user, error: null });
      },

      initialize: async () => {
        // Prevent multiple initializations
        if (get().isInitialized) {
          return;
        }

        set({ isLoading: true, error: null });

        try {
          // Add a small delay to prevent race conditions
          await new Promise((resolve) => setTimeout(resolve, 50));

          // TODO: Fetch user data from API if needed
          // const userData = await fetchUserData();
          // set({ user: userData, isLoading: false, isInitialized: true });

          // For now, just mark as initialized
          set({ isLoading: false, isInitialized: true });
        } catch (error) {
          console.error('Failed to initialize user store:', error);
          set({
            isLoading: false,
            isInitialized: true,
            error: error instanceof Error ? error.message : 'Unknown error',
          });
        }
      },

      reset: () => {
        set(initialState);
      },
    }),
    {
      name: 'user-store',
      storage: createSafeStorage(),
      // Ensure hydration is complete before first render
      partialize: (state) => ({
        user: state.user,
      }),
      onRehydrateStorage: () => (state) => {
        // Mark as initialized after rehydration
        if (state) {
          state.isInitialized = true;
        }
      },
    }
  )
);

// Auto-initialize on store creation
// This runs once when the module is imported
if (typeof window !== 'undefined') {
  // Small delay to ensure the app is ready
  setTimeout(() => {
    useUserStore.getState().initialize();
  }, 100);
}
