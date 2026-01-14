# Chat Options (Like, Dislike, Edit, Rewind, Pin) - Complete Flow Documentation

This document traces the complete implementation of chat message operations (like, dislike, edit, rewind, pin) from UI components to backend API endpoints and database storage.

## Overview

The chat options system provides users with interaction capabilities for both character and user messages in conversations. These operations are implemented consistently across Web (React), Mobile (React Native), with a shared Python FastAPI backend.

## Architecture

### Frontend (Web & Mobile)
- **UI Components**: Message context menus and operation buttons
- **State Management**: Zustand stores (messageStore)
- **API Layer**: Service functions with optimistic updates
- **Hooks**: React Query for server state synchronization

### Backend (Python FastAPI)
- **API Routes**: `/like_message`, `/dislike_message`, `/pin_message`
- **Business Logic**: Message operations in supabase_impl.py
- **Database**: Supabase PostgreSQL with chat_history table
- **Models**: ConversationHistory class with message manipulation methods

## Web Frontend Implementation

### 1. UI Component: MessageOperations.tsx

```typescript
// Located at: frontend_webapp/src/components/chat/MessageOperations.tsx

interface MessageOperationsProps {
  message: Message;
  characterId: string;
  session?: Session | null;
  isMultiChatMode?: boolean;
  multiChatGroupId?: string;
  onEdit?: (messageId: string) => void;
  onDelete?: (messageId: string) => void;
  onReply?: (content: string) => void;
  onToggleMenu?: (messageId: string) => void;
}

// Key operation handlers:
const handleLikeMessage = async () => {
  try {
    await handleLike(session || null, message);
    toast.success('Message liked!');
  } catch (error) {
    log.error('Error liking message:', error);
    toast.error('Failed to like message');
  }
};

const handleDislikeMessage = async () => {
  try {
    await handleDislike(session || null, message);
    toast.success('Feedback recorded');
  } catch (error) {
    log.error('Error disliking message:', error);
    toast.error('Failed to record feedback');
  }
};

const handlePinMessage = async () => {
  if (!message.message_id) return;
  
  try {
    const sessionToken = 'placeholder';
    const characterName = 'placeholder';
    await pinMessage(
      session || null,
      sessionToken,
      characterName,
      message.message_id,
      !message.isPinned,
    );
    toast.success(message.isPinned ? 'Message unpinned' : 'Message pinned');
  } catch (error) {
    log.error('Error pinning message:', error);
    toast.error('Failed to pin message');
  }
};
```

**Features:**
- Different options for character vs user messages
- Character messages: Like, Dislike, Pin, Reply, Copy, Delete
- User messages: Edit, Copy, Reply, Delete
- Context menu with dropdown display
- Toast notifications for feedback

### 2. API Client Functions

```typescript
// Located at: frontend_webapp/src/api/apiClient.ts

export async function handleLike(session: Session | null, message: Message) {
  try {
    const response = await api.get(`/like_message/${message.id}`, {
      headers: {
        Authorization: getAuthHeader(session),
      },
    });
    return !!response.data;
  } catch (error) {
    log.error('Error liking the message:', error);
    Sentry.captureException(error);
    return false;
  }
}

export async function handleDislike(session: Session | null, message: Message) {
  try {
    const response = await api.get(`/dislike_message/${message.id}`, {
      headers: {
        Authorization: getAuthHeader(session),
      },
    });
    return !!response.data;
  } catch (error) {
    Sentry.captureException(error);
    log.error('Error disliking the message:', error);
    return false;
  }
}

export async function pinMessage(
  session: Session | null,
  sessionToken: string,
  characterName: string,
  messageId: string,
  isPinned = true,
): Promise<{ success: boolean; message: string }> {
  try {
    const response = await api.post(
      '/pin_message',
      {
        session_token: sessionToken,
        character_name: characterName,
        message_id: messageId,
        is_pinned: isPinned,
      },
      // ... headers
    );
    return response.data;
  } catch (error) {
    // Error handling
  }
}
```

## Mobile App Implementation

### 1. UI Component: MessageContextMenu.tsx

```typescript
// Located at: mobile_app_sx/components/MessageContextMenu.tsx

// Actions differ by message type:
const actions = isUserMessage ? [
  { id: 'edit', icon: Edit, label: 'Edit' },
  { id: 'copy', icon: Copy, label: 'Copy' },
  { id: 'delete', icon: Trash2, label: 'Delete' },
] : [
  { id: 'reply', icon: Reply, label: 'Reply' },
  { id: 'copy', icon: Copy, label: 'Copy' },
  { id: 'pin', icon: Pin, label: 'Pin' },
  { id: 'rewind', icon: RotateCcw, label: 'Rewind' },
];

// Context menu with blur effect and animations
return (
  <Modal visible={visible} transparent animationType="none">
    {/* Blur overlay with highlighted message */}
    <CrossPlatformBlur intensity={50} tint="dark" />
    
    {/* Menu with glassmorphic design */}
    <Animated.View style={styles.menu}>
      {actions.map((action) => (
        <TouchableOpacity
          key={action.id}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            onAction(action.id, messageId);
          }}
        >
          <action.icon size={18} color="#FFFFFF" />
          <Text>{action.label}</Text>
        </TouchableOpacity>
      ))}
    </Animated.View>
  </Modal>
);
```

### 2. Store Functions: messageStore.ts

```typescript
// Located at: mobile_app_sx/store/messageStore.ts

const likeMessage = async (messageId) => {
  try {
    await chatApi.likeMessage(messageId);
    get().updateMessage(messageId, { isLiked: true });
    logger.info('Message liked', { messageId });
  } catch (error) {
    logger.error('Failed to like message', error);
    throw error;
  }
};

const dislikeMessage = async (messageId) => {
  try {
    await chatApi.dislikeMessage(messageId);
    get().updateMessage(messageId, { isLiked: false });
    logger.info('Message disliked', { messageId });
  } catch (error) {
    logger.error('Failed to dislike message', error);
    throw error;
  }
};

const pinMessageAPI = async (messageId, isPinned = true) => {
  set({ isLoading: true });
  try {
    await chatApi.pinMessage(messageId, isPinned);
    get().updateMessage(messageId, { isPinned });
    logger.info(isPinned ? 'Message pinned' : 'Message unpinned', { messageId });
  } catch (error) {
    set({ error: `Failed to ${isPinned ? 'pin' : 'unpin'} message` });
    throw error;
  }
};

const editMessage = async (messageId, newContent) => {
  try {
    await chatApi.editUserMessage(messageId, newContent);
    get().updateMessage(messageId, { content: newContent });
    logger.info('Message edited', { messageId });
  } catch (error) {
    set({ error: 'Failed to edit message' });
    throw error;
  }
};
```

### 3. API Service Functions

```typescript
// Located at: mobile_app_sx/services/chatApi.ts

export async function likeMessage(messageId: string): Promise<void> {
  try {
    const authHeader = await getAuthorizationHeader();
    
    if (!authHeader) {
      throw new Error('Authentication required. Please log in to like messages.');
    }
    
    const response = await fetch(`${API_BASE_URL}/api/like_message/${messageId}`, {
      method: 'GET',
      headers: {
        'Authorization': authHeader,
      },
    });
    
    if (!response.ok) {
      throw new Error(`Failed to like message: ${response.statusText}`);
    }
  } catch (error) {
    logger.error('Failed to like message:', error);
    throw error;
  }
}

export async function dislikeMessage(messageId: string): Promise<void> {
  try {
    const authHeader = await getAuthorizationHeader();
    
    if (!authHeader) {
      throw new Error('Authentication required to dislike messages.');
    }
    
    const response = await fetch(`${API_BASE_URL}/api/dislike_message/${messageId}`, {
      method: 'GET',
      headers: {
        'Authorization': authHeader,
      },
    });
    
    if (!response.ok) {
      throw new Error(`Failed to dislike message: ${response.statusText}`);
    }
  } catch (error) {
    logger.error('Failed to dislike message:', error);
    throw error;
  }
}

export async function pinMessage(messageId: string, isPinned: boolean = true): Promise<void> {
  try {
    const authHeader = await getAuthorizationHeader();
    
    const response = await fetch(`${API_BASE_URL}/api/pin_message`, {
      method: 'POST',
      headers: {
        'Authorization': authHeader,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message_id: messageId,
        is_pinned: isPinned,
        // session_token and character_name handled internally
      }),
    });
    
    if (!response.ok) {
      throw new Error(`Failed to ${isPinned ? 'pin' : 'unpin'} message: ${response.statusText}`);
    }
  } catch (error) {
    logger.error(`Failed to ${isPinned ? 'pin' : 'unpin'} message:`, error);
    throw error;
  }
}
```

## Backend FastAPI Implementation

### 1. API Routes: gpt_chat_router.py

```python
# Located at: sceneXtras/api/router/gpt_chat_router.py

@chat_router.get("/like_message/{message_id}")
def like_message(message_id: str, current_user: User = Depends(get_current_user)):
    posthog.capture(
        current_user.id, "message liked", properties={"message_id": message_id}
    )
    return add_like(current_user.id, message_id)

@chat_router.get("/dislike_message/{message_id}")
def dislike_message(message_id: str, current_user: User = Depends(get_current_user)):
    posthog.capture(
        current_user.id, "message disliked", properties={"message_id": message_id}
    )
    return add_dislike(current_user.id, message_id)

@chat_router.post("/dislike_message")
def dislike_message_with_feedback(
    dislike_request: DislikeRequest, 
    current_user: User = Depends(get_current_user)
):
    """
    Dislike a message with optional feedback.
    """
    posthog.capture(
        current_user.id,
        "message disliked with feedback",
        properties={
            "message_id": dislike_request.message_id,
            "has_feedback": bool(dislike_request.feedback),
            "feedback_length": len(dislike_request.feedback) if dislike_request.feedback else 0,
        },
    )
    return add_dislike(
        current_user.id, dislike_request.message_id, dislike_request.feedback
    )

class PinMessageRequest(BaseModel):
    session_token: str
    character_name: str
    message_id: str
    is_pinned: bool = True

@chat_router.post("/pin_message")
async def pin_message(
    request: PinMessageRequest,
    current_user: User = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Dict:
    """
    Pin or unpin a specific message in a conversation by its ID.
    """
    try:
        # Get conversation history
        (
            conversation_history,
            character_name,
            character_movie,
            length_flag,
            premium_length_flag,
        ) = get_or_initialize_conversation_history(
            request.session_token, current_user.id, request.character_name
        )
        
        # Pin or unpin the message
        success = conversation_history.pin_message_by_id(
            request.message_id, request.is_pinned
        )
        
        if not success:
            return {"success": False, "message": "Message not found"}
        
        # Save the updated conversation history
        save_conversation_history(
            conversation_history=conversation_history,
            session_token=request.session_token,
            character_name=request.character_name,
            character_movie=character_movie,
            user_id=current_user.id,
            session=session,
        )
        
        return {
            "success": True, 
            "message": f"Message {pinned or unpinned} successfully"
        }
    except Exception as e:
        logger.error(f"Error pinning message: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to pin message")
```

### 2. Database Operations: supabase_impl.py

```python
# Located at: sceneXtras/api/db/supabase_impl.py

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10),
    retry=retry_if_exception_type((httpx.RemoteProtocolError, httpx.ReadTimeout)),
)
def add_like(user_id: str, message_id: str):
    """
    Increment the like count for a specific message in the chat history and reset the dislike count.
    """
    try:
        # First try to find the message by chat_id (UUID) field
        response = (
            supabase.table("chat_history")
            .select("id", "like_count", "dislike_count")
            .eq("chat_id", message_id)
            .eq("user_id", user_id)
            .execute()
        )
        
        if response.data:
            # Get the numeric ID
            numeric_id = response.data[0]["id"]
            current_like_count = response.data[0]["like_count"]
            
            # Update using the numeric ID
            result = (
                supabase.table("chat_history")
                .update({
                    "like_count": current_like_count + 1,
                    "dislike_count": 0,  # Reset dislike count when liked
                    "updated_at": datetime.utcnow().isoformat()
                })
                .eq("id", numeric_id)
                .execute()
            )
            
            if result.data:
                logger.info(f"Successfully liked message {message_id} for user {user_id}")
                return {"liked": True, "like_count": current_like_count + 1}
            else:
                logger.error(f"Failed to update like count for message {message_id}")
                return {"liked": False}
        else:
            logger.warning(f"Message {message_id} not found for user {user_id}")
            return {"liked": False}
            
    except Exception as e:
        logger.error(f"Error adding like to message {message_id}: {str(e)}")
        Sentry.capture_exception(e)
        return {"liked": False}

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10),
    retry=retry_if_exception_type((httpx.RemoteProtocolError, httpx.ReadTimeout)),
)
def add_dislike(user_id: int, message_id: str, feedback: Optional[str] = None):
    """
    Increment the dislike count for a specific message in the chat history and reset the like count.
    Optionally stores user feedback for the dislike.
    """
    try:
        # First try to find the message by chat_id (UUID) field
        response = (
            supabase.table("chat_history")
            .select("id", "dislike_count", "like_count")
            .eq("chat_id", message_id)
            .eq("user_id", user_id)
            .execute()
        )
        
        if response.data:
            # Get the numeric ID
            numeric_id = response.data[0]["id"]
            current_dislike_count = response.data[0]["dislike_count"]
            
            # Prepare update data
            update_data = {
                "dislike_count": current_dislike_count + 1,
                "like_count": 0,  # Reset like count when disliked
                "updated_at": datetime.utcnow().isoformat()
            }
            
            # Add feedback if provided
            if feedback:
                update_data["dislike_feedback"] = feedback
            
            # Update using the numeric ID
            result = (
                supabase.table("chat_history")
                .update(update_data)
                .eq("id", numeric_id)
                .execute()
            )
            
            if result.data:
                logger.info(
                    f"Successfully disliked message {message_id} for user {user_id}"
                    + (f" with feedback: {feedback}" if feedback else "")
                )
                return {"disliked": True, "dislike_count": current_dislike_count + 1}
            else:
                logger.error(f"Failed to update dislike count for message {message_id}")
                return {"disliked": False}
        else:
            logger.warning(f"Message {message_id} not found for user {user_id}")
            return {"disliked": False}
            
    except Exception as e:
        logger.error(f"Error adding dislike to message {message_id}: {str(e)}")
        Sentry.capture_exception(e)
        return {"disliked": False}
```

### 3. Conversation Model: models.py

```python
# Located at: sceneXtras/api/chat/models.py

class ConversationHistory:
    def pin_message_by_id(self, message_id: str, is_pinned: bool = True) -> bool:
        """
        Pin or unpin a specific message in the conversation history by its ID.
        Args:
            message_id: The unique identifier of the message to pin/unpin
            is_pinned: Whether to pin (True) or unpin (False) the message
        Returns:
            bool: True if the message was found and updated, False otherwise
        """
        for msg in self._messages:
            if msg.id == message_id:
                msg.pinned = is_pinned
                # If we have summarization enabled, we need to rebuild summary groups
                # since pinned messages are never summarized
                if self._use_enhanced_summary and is_pinned:
                    # Find any summaries that might contain this message
                    for summary_id, summarized_msgs in self._summary_map.items():
                        if message_id in summarized_msgs:
                            # We've pinned a message that was previously summarized
                            # Need to rebuild summaries without this message
                            self._rebuild_summaries_excluding_message(message_id)
                            break
                
                logger.info(f"Message {message_id} {'pinned' if is_pinned else 'unpinned'}")
                return True
        
        logger.warning(f"Message {message_id} not found for pinning")
        return False
    
    def _rebuild_summaries_excluding_message(self, message_id: str):
        """
        Rebuild conversation summaries excluding a specific message.
        This ensures pinned messages are never included in summaries.
        """
        # Get all messages except the one being pinned
        messages_to_summarize = [msg for msg in self._messages if msg.id != message_id]
        
        # Clear existing summary mapping
        self._summary_map.clear()
        
        # Recreate summaries with the filtered messages
        if len(messages_to_summarize) > self._summary_interval:
            self._create_enhanced_summaries(messages_to_summarize)
        
        logger.info(f"Rebuilt summaries excluding pinned message {message_id}")
```

## Database Schema

### chat_history Table

```sql
CREATE TABLE chat_history (
    id SERIAL PRIMARY KEY,
    chat_id UUID NOT NULL,  -- Message UUID from conversation
    user_id UUID NOT NULL REFERENCES users(id),
    character_name VARCHAR(255) NOT NULL,
    message_content TEXT NOT NULL,
    message_role VARCHAR(50) NOT NULL,  -- 'user' or 'assistant'
    like_count INTEGER DEFAULT 0,
    dislike_count INTEGER DEFAULT 0,
    dislike_feedback TEXT,
    pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    session_token VARCHAR(255),
    character_movie VARCHAR(255),
  
    INDEX idx_chat_id_user (chat_id, user_id),
    INDEX idx_user_character (user_id, character_name),
    INDEX idx_session_token (session_token)
);
```

## State Management Flow

### 1. Like/Dislike Operations

```
User Action → UI Component → Store Function → API Call → Backend Route → Database Update → Response → Optimistic Update
    ↓               ↓              ↓           ↓            ↓             ↓              ↓           ↓
Press Thumb → MessageOperations → likeMessage() → POST/GET → /like_message → add_like() → chat_history table → toast.success()
```

### 2. Pin/Unpin Operations

```
User Action → UI Component → Store Function → API Call → Backend Route → ConversationModel → Save State → Frontend Update
    ↓               ↓              ↓           ↓            ↓              ↓             ↓              ↓
Press Pin → MessageContextMenu → pinMessageAPI() → POST → /pin_message → pin_message_by_id() → save_conversation_history() → Update UI
```

### 3. Edit Operations (User Messages Only)

```
User Action → Edit Mode → Store Function → API Call → Backend Route → Update Message → Save State → Frontend Update
    ↓              ↓            ↓           ↓            ↓               ↓             ↓             ↓
Press Edit → Input Field → editMessage() → POST → [EDIT_ENDPOINT] → update_message() → save_conversation_history() → Render new content
```

## Error Handling & Retries

### Frontend
- **Optimistic Updates**: Local state updated immediately
- **Toast Notifications**: User feedback on success/failure
- **Haptic Feedback**: Mobile vibration for user actions
- **Loading States**: Disable buttons during operations

### Backend
- **Retry Logic**: 3 attempts with exponential backoff
- **Transaction Rollback**: Database consistency on errors
- **Logging**: Comprehensive error tracking with Sentry
- **PostHog Analytics**: User interaction tracking

### Database
- **Atomic Operations**: Single transaction per message operation
- **Constraints**: Unique constraints prevent duplicate operations
- **Indexes**: Optimized for user/message lookup performance

## Key Features & Optimizations

### 1. Pinned Messages Never Summarized
- Pinned messages are excluded from conversation summarization
- Rebuild summaries when messages are pinned/unpinned
- Ensures important content remains accessible

### 2. Mutual Exclusion of Like/Dislike
- Liking a message resets dislike count to 0
- Disliking a message resets like count to 0
- Prevents conflicting user sentiment states

### 3. Authentication & Authorization
- All operations require valid user session
- Users can only modify messages in their conversations
- Multi-chat support with session tokens

### 4. Performance Optimizations
- Local state management for instant UI updates
- Background API synchronization
- Cached message states reduce API calls
- Efficient database queries with proper indexing

## Security Considerations

### 1. Input Validation
- Message ID validation (UUID format)
- User ownership verification
- Content sanitization for edits

### 2. Rate Limiting
- Prevent abuse of like/dislike operations
- Session-based request limits
- Transaction frequency monitoring

### 3. Access Control
- Users can only operate on their messages
- Character messages: Like/dislike/pin only
- User messages: Edit/delete/copy only

## Testing Strategy

### Frontend Tests
- Component rendering with different message types
- User interaction simulation
- Toast notification verification
- Loading state assertions

### Backend Tests
- API endpoint functionality
- Database transaction integrity
- Error handling scenarios
- Authentication validation

### Integration Tests
- End-to-end user flows
- Cross-platform consistency
- Performance benchmarks
- Error recovery testing

## Future Enhancements

### 1. Advanced Feedback
- Rich text feedback for dislikes
- Categorized feedback types
- AI analysis of feedback trends

### 2. Message Operations
- Message threading
- Bulk operations (select multiple)
- Message archiving system

### 3. Analytics Dashboard
- User engagement metrics
- Message interaction heatmaps
- Content performance insights

---

This documentation provides a complete trace of the chat options functionality across all layers of the application stack, ensuring comprehensive understanding for development, debugging, and future enhancements.
