# Scenario Profile Picture Generation Fix

## Problem

Scenario profile picture generation was creating images of rooms/environments instead of character portraits. 

### Root Cause

The scenario image endpoint (`/api/story/scenario/generate-image`) was using the `/imagine` command type, which applies the `get_in_character_image_prompt()` transformation. This transformation is designed for **first-person POV scenes/environments**, not character portraits.

When the prompt "Cinematic portrait of {character_name}" went through this transformation, it was converted into a scene description, resulting in images of rooms rather than character portraits.

### Example from Logs

```
Enhanced prompt: 
Transform this visualization request for Maris Daggerwind's universe (Captain Hook   The Cursed Tides).
Create a first person cinematic image that feels authentic to the character's world, style, and perspective.
...
Transform this visualization request: Cinematic portrait of Maris Daggerwind from Captain Hook   The Cursed Tides in this scenario: ...
```

The transformation system tried to convert "Cinematic portrait of X" into a first-person POV scene, which is incorrect for character portraits.

## Solution

Created a dedicated prompt transformation for character portraits:

### 1. New Function: `get_character_portrait_prompt()`

**Location:** `sceneXtras/api/chat/image_generation.py` (line 653)

This function is specifically designed for generating character portrait images:
- Focuses on the character as the primary subject
- Includes accurate physical descriptions (hair color, eyes, features)
- Uses portrait photography techniques (shallow depth of field, portrait lenses)
- Keeps background contextual but blurred
- Emphasizes facial features and expression

**Key differences from `/imagine` transformation:**
- `/imagine` → First-person POV scenes (rooms, corridors, environments)
- `/portrait` → Character-focused portraits (face, upper body, personality)

### 2. New Command Type: `/portrait`

**Location:** `sceneXtras/api/chat/image_generation.py` (line 1063)

Added handling for the `/portrait` command type in the `generate_image()` function:

```python
elif command_type == "/portrait":
    enhanced_prompt = get_character_portrait_prompt(chat_input, prompt)
```

### 3. Updated Scenario Image Endpoint

**Location:** `sceneXtras/api/router/story_router.py` (line 4096)

Changed the scenario image generation endpoint to use `/portrait` instead of `/imagine`:

```python
result = await generate_image(
    prompt=prompt,
    current_user=current_user,
    chat_input=chat_input_for_image,
    command_type="/portrait",  # Use /portrait for character images, not /imagine
)
```

## Technical Details

### Portrait Prompt Template Features

The new `get_character_portrait_prompt()` includes:

1. **Character-focused composition**: Character is the primary subject
2. **Physical accuracy**: Hair color, eye color, distinctive features from source material
3. **Portrait photography specs**: 
   - Portrait lens (50mm, 85mm, 70mm)
   - Shallow depth of field (f/1.8, f/2.0, f/2.8)
   - Professional portrait lighting
4. **Context integration**: Scenario text becomes background context
5. **Expression capture**: Emphasizes personality through facial expression
6. **Costume authenticity**: Includes character-appropriate outfits/armor
7. **Quality modifiers**: 4K, HDR, professional portrait

### Examples from Template

**Hermione Granger Example:**
- Subject: Young witch with bushy brown hair, intelligent eyes, Gryffindor robes
- Context: Hogwarts library with magical tomes in blurred background
- Style: Magical realism portrait, warm golden lighting, 85mm f/2.8

**Tony Stark Example:**
- Subject: Charismatic inventor with goatee, arc reactor glowing
- Context: High-tech workshop with holographic displays in background
- Style: Modern superhero cinematic, dramatic blue/orange lighting, 50mm f/1.8

**Daenerys Targaryen Example:**
- Subject: Mother of Dragons with platinum blonde braids, violet eyes, Targaryen armor
- Context: Dragon visible behind shoulder breathing smoke
- Style: Epic fantasy portrait, dragon fire lighting, 70mm f/2.0

## Testing Recommendations

1. **Test with various characters**: Ensure portraits generate correctly across different universes
2. **Test with scenario text**: Verify scenario descriptions become background context, not the focus
3. **Check quota handling**: Confirm quota decrements work correctly
4. **Verify fallback**: Ensure fallback image URL works if generation fails

## Command Types Reference

Now available for image generation:

- `/imagine` - First-person POV scenes (rooms, corridors, environments)
- `/explore` - Environmental exploration (surroundings, atmosphere)
- `/meet` - Character interaction scenes (meeting another character)
- `/go` - Location transitions (arriving at new places)
- `/portrait` - **NEW** Character portrait images (face, upper body, personality)

## Files Modified

1. **chat/image_generation.py**
   - Added `get_character_portrait_prompt()` function (line 653)
   - Added `/portrait` command handling in `generate_image()` (line 1063)

2. **router/story_router.py**
   - Changed `command_type` from `/imagine` to `/portrait` (line 4096)

## Impact

- ✅ Scenario profile pictures will now generate character portraits instead of rooms
- ✅ Portrait transformation optimized for character-focused composition
- ✅ No changes to existing `/imagine`, `/explore`, `/meet`, `/go` commands
- ✅ Backward compatible - only affects scenario image generation endpoint
- ✅ Same quota system applies

## Future Enhancements

Potential improvements:
1. Add portrait style options (cinematic, comic book, realistic, artistic)
2. Support specific pose requests (action pose, sitting, standing)
3. Add emotion/expression parameters (determined, sad, joyful, fierce)
4. Character expression matching to scenario mood
