# Roleplay Scenario System - Logical Flows Documentation

## Initial Component Opening Flow

### When User Opens Story Creator
1. **Component Mounts** → `StoryCreatorWizard.tsx`
2. **Store initializes** with `currentStep: -1` (mode selection)
3. **UI renders** mode selector screen
4. **Progress bar** shows 0/6 steps

## Step-by-Step User Options

### Step -1: Mode Selection
**User sees:** Two cards
- **One-Shot**: "Create complete story with one prompt"
- **Co-Pilot**: "Step-by-step guided creation"

**User actions:**
- Click One-Shot → Shows text input, auto-generates story
- Click Co-Pilot → Advances to Step 0

### Step 0: Universe Type (Co-Pilot only)
**User sees:** 5 options
- Movie, Series, Anime, Cartoon, Original

**User action:** Click option → Auto-advance to Step 1

### Step 1: Title & Genres
**User sees:**
- Text input for title (min 2 chars)
- Genre pills (Action, Comedy, Drama, etc.)

**User actions:**
- Type title → Real-time validation
- Click genres → Toggle selection
- "Continue" button disabled until valid

### Step 2: Characters
**User sees:**
- Character input field
- Suggestion chips based on title
- "Generate with AI" button
- Character list with edit/delete

**User actions:**
- Type name → Add character
- Click suggestions → Quick add
- Generate AI → Creates character with backstory
- Edit character → Opens modal with details

### Step 3: Story Spark
**User sees:**
- Large text area (optional)
- Story element suggestions (emotional core, dynamics, etc.)

**User actions:**
- Type custom prompt OR
- Click suggested elements → Auto-populate

### Step 4: Creation & Review
**User sees:**
- Loading animation during generation
- Story preview with cover, characters, scenes
- "Start Chat" or "Save Story" buttons

## State Changes Flow

### One-Shot Mode
```
User enters prompt → 
API: generateCompleteScenario() → 
Store updates with ALL data at once → 
Jump to Step 4 (review)
```

### Co-Pilot Mode
```
Step 0→1: Store universeType
Step 1→2: API createMovie() → Store movie data
Step 2→3: API generateStoryElements() → Store story elements  
Step 3→4: Generate all assets → Store complete story
```

## API Call Timing

### One-Shot: Single Call
- `generateCompleteScenario()` → Returns everything

### Co-Pilot: Sequential Calls
1. After title/genres: `createMovie()`
2. After characters: `generateStoryElements()`
3. In review step: `generateMovieCoverImage()`, `generateCharacterProfileImages()`, `generateMovieSceneImages()`

## Navigation Logic

### Forward Navigation
- **Continue button** → Validates current step → Calls API if needed → Advances
- **Auto-advance** on some steps (universe selection)

### Back Navigation
- **Back button** → Goes to previous step
- **Data preserved** - no loss of user input
- **API calls not repeated** - generation flags prevent duplicates

## Error Handling

### API Failures
- **Graceful degradation** - continues with partial data
- **User can still proceed** - not blocked by failures
- **Retry mechanisms** - for image generation

### Validation Errors
- **Real-time feedback** - inline error messages
- **Button disabled** - until requirements met
- **Character limits** - enforced with counters

## Loading States

### Multiple Concurrent States
- `isLoading` - One-shot generation
- `isUniverseGenerating` - Movie creation
- `isSubmitting` - Final story save
- `isCoverLoading` - Cover image generation

### Loading UI
- **Progress bar** - shows step completion
- **LoadingStoryPage** - animated steps during generation
- **Skeleton loaders** - for individual components

## Exit Flows

### User Can Exit By:
1. **Back button** from first step → Returns to previous page
2. **Close/X button** → Same as back
3. **Browser back** → Navigation handled by React Router

### Cleanup on Exit
- **Cancel active API requests**
- **Reset generation flags**
- **Clear timers**

## Key Decision Points

### Mode Selection (Step -1)
- One-Shot = Fast, less control
- Co-Pilot = More control, step-by-step

### Character Management (Step 2)
- Manual input = Full control
- AI generation = Automated details
- Suggestions = Quick start

### Story Prompt (Step 3)
- Custom prompt = User's idea
- Suggested elements = AI-curated options

## Component Files and Locations

### Core Components
- `StoryCreatorWizard.tsx` - Main wizard container
- `StoryModeSelector.tsx` - Mode selection step
- `UniverseSelectorStep.tsx` - Universe type selection
- `TitleInputStep.tsx` - Title and genre input
- `CharacterInputStep.tsx` - Character management
- `StoryCreationStep.tsx` - Final creation and review

### Supporting Components
- `StoryExportViewer.tsx` - Story preview and export
- `LoadingStoryPage.tsx` - Loading animation
- `CreateStoryButton.tsx` - Floating action button

### State Management
- `useStoryWizardStore.ts` - Zustand store for wizard state
- `storyApi.ts` - API service calls

### Data Models
```typescript
interface StoryCreatorData {
  universeType: 'Movie' | 'Series' | 'Anime' | 'Cartoon';
  title: string;
  characters: CharacterDetail[];
  storyPrompt: string;
  universe: string;
  selectedGenres: string[];
  mode: 'one-shot' | 'co-pilot';
  storyElements?: StoryElementsResponse;
  movie?: MovieResponse;
}
```

## API Endpoints

### Core Generation
- `generateCompleteScenario()` - One-shot complete generation
- `createMovie()` - Create movie/universe data
- `createCharacter()` - Generate character with AI
- `generateStoryElements()` - Create story elements
- `generateMultiCharacterConversation()` - Create dialogues

### Asset Generation
- `generateMovieCoverImage()` - Story cover art
- `generateMovieSceneImages()` - Scene illustrations
- `generateCharacterProfileImages()` - Character portraits

### Database Operations
- `saveMovieToDatabase()` - Persist stories
- `saveCharacterToDatabase()` - Save characters
- `saveStoryElementToDatabase()` - Store story elements

## Character System

### Character Roles
- Main Character
- Supporting Character
- Antagonist
- Ally
- Love Interest
- Comic Relief

### Character Features
- Smart suggestions based on title
- AI-powered generation with backstories
- Role assignment
- Profile image generation
- Edit capabilities via modal

## Navigation Routes

### Key Routes
- `/create-story` - Story creation wizard
- `/story-export` - Story viewer and export
- `/scenester` - Chat interface for interacting with stories

### Entry Points
- Floating action button (`CreateStoryButton.tsx`)
- Bottom navigation in main app

## Technical Implementation Details

### State Management Pattern
- Centralized Zustand store
- Generation flags prevent duplicate API calls
- Progressive enhancement approach
- Graceful error handling

### Performance Optimizations
- Lazy loading of components
- Code splitting for wizard steps
- Request deduplication
- Asset generation caching

### User Experience Features
- Smooth animations with Framer Motion
- Progress indicators
- Real-time validation
- Loading states with feedback
- Responsive design for mobile

This flow provides flexibility for different user preferences while maintaining data integrity and preventing duplicate operations.