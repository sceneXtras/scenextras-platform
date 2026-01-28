# iOS Touch Responsiveness - Quick Reference

## Common iOS Button Issues & Fixes

### Issue 1: Button Not Responding to Taps
**Symptoms:** Button doesn't respond, no visual feedback  
**Fix:**
```tsx
<TouchableOpacity
  activeOpacity={0.7}  // Add this!
  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}  // And this!
  onPress={handlePress}
>
```

### Issue 2: Parent View Blocking Touches
**Symptoms:** Taps go through to background  
**Fix:**
```tsx
// Change from:
<View style={{ zIndex: 1 }}>

// To:
<View pointerEvents="box-none" style={{ zIndex: 1 }}>
```

### Issue 3: Loading State Blocks Button
**Symptoms:** Button becomes permanently unresponsive  
**Fix:**
```tsx
// Don't overlay loading indicator:
{isLoading && <ActivityIndicator style={{ position: 'absolute' }} />}  // ❌ BAD

// Put it inside the button:
{isLoading ? <ActivityIndicator /> : <Text>Login</Text>}  // ✅ GOOD
```

### Issue 4: Double-Tap Not Prevented
**Symptoms:** Login fires multiple times  
**Fix:**
```tsx
const handleLogin = useCallback(async () => {
  if (isLoading) return;  // Prevent double-tap (guard check is sufficient)
  
  setIsLoading(true);
  try {
    await login();
  } finally {
    setIsLoading(false);  // Always use finally!
  }
}, [/* isLoading NOT in deps - guard check handles double-tap */]);
```

### Issue 5: Button Disabled But Looks Enabled
**Symptoms:** Button looks clickable but doesn't work  
**Fix:**
```tsx
<TouchableOpacity
  disabled={isLoading}  // Disable while loading
  style={[
    styles.button,
    isLoading && styles.buttonDisabled  // Visual feedback
  ]}
>
```

## iOS-Specific TouchableOpacity Props

| Prop | Purpose | Recommended Value |
|------|---------|-------------------|
| `activeOpacity` | Visual feedback on touch | `0.7` |
| `hitSlop` | Increase touch area | `{{ top: 10, bottom: 10, left: 10, right: 10 }}` |
| `disabled` | Prevent touches | Tie to loading state |
| `delayPressIn` | Delay before active state | `0` (default) for instant feedback |
| `delayPressOut` | Delay before inactive state | `100` (default) |

## Pointer Events Values

| Value | Behavior | Use Case |
|-------|----------|----------|
| `auto` | View and children receive touches | Default, most common |
| `none` | View and children ignore touches | ❌ Avoid on containers |
| `box-none` | View ignores, children receive | ✅ Good for wrappers |
| `box-only` | View receives, children ignore | Rare use case |

## Best Practices Checklist

- [ ] All buttons have `activeOpacity` (iOS)
- [ ] Important buttons have `hitSlop` (iOS)
- [ ] Loading indicators are inside buttons, not overlapping
- [ ] Handlers are memoized with `useCallback`
- [ ] Double-tap prevention implemented
- [ ] Loading state has proper cleanup (`finally` block)
- [ ] Parent views use `pointerEvents="box-none"` when needed
- [ ] Disabled state has visual feedback
- [ ] Test on iOS simulator AND real device
- [ ] Test with different iOS versions

## Testing Commands

```bash
# iOS Simulator
./run.sh --ios
# or
npx expo start --ios

# Real iOS Device
npx expo run:ios --device

# Run Tests
bun run test
# or
npm test

# Type Check
bun run typecheck
```

## Debug Checklist

If button still not working:

1. **Check parent views:**
   ```bash
   # Search for pointerEvents="none"
   grep -r 'pointerEvents.*none' .
   ```

2. **Verify handler is bound:**
   ```tsx
   onPress={() => console.log('Button pressed!')}
   ```

3. **Check for overlapping views:**
   - Set background colors to debug z-index
   - Check for position: absolute elements

4. **Verify not disabled:**
   ```tsx
   console.log('Button disabled?', isLoading);
   ```

5. **Test with simple button:**
   ```tsx
   <TouchableOpacity onPress={() => alert('Works!')}>
     <Text>Test</Text>
   </TouchableOpacity>
   ```

## Common Mistakes

### ❌ DON'T:
```tsx
// Overlapping spinner blocks touches
<TouchableOpacity onPress={handlePress}>
  <Text>Login</Text>
</TouchableOpacity>
{loading && <Spinner style={{ position: 'absolute' }} />}

// Parent blocks all touches
<View pointerEvents="none">
  <Button />
</View>

// No double-tap prevention
const handlePress = async () => {
  setLoading(true);
  await api.call();
  setLoading(false);  // No finally block!
};
```

### ✅ DO:
```tsx
// Spinner inside button
<TouchableOpacity 
  onPress={handlePress}
  disabled={loading}
  activeOpacity={0.7}
  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
>
  {loading ? <Spinner /> : <Text>Login</Text>}
</TouchableOpacity>

// Parent allows child touches
<View pointerEvents="box-none">
  <Button />
</View>

// Proper async handling
const handlePress = useCallback(async () => {
  if (loading) return;
  setLoading(true);
  try {
    await api.call();
  } finally {
    setLoading(false);
  }
}, []); // Note: loading NOT in deps - guard check is sufficient
```

## Performance Tips

- Memoize handlers: `useCallback(() => {}, [deps])`
- Memoize components: `React.memo(Component)`
- Avoid inline functions: `onPress={() => handle()}` → `onPress={handle}`
- Use `InteractionManager` for heavy operations after touch

## Resources

- [React Native Touch Handling](https://reactnative.dev/docs/handling-touches)
- [TouchableOpacity API](https://reactnative.dev/docs/touchableopacity)
- [Debugging Guide](https://reactnative.dev/docs/debugging)
