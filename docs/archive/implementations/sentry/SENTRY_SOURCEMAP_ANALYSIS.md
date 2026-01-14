# Sentry Sourcemap Configuration Analysis & Fixes

## Date: 2025-01-XX

## Current Configuration Review

### ✅ What's Working

1. **Webpack Plugin Integration** (`craco.config.js`)
   - Sentry webpack plugin is correctly configured
   - Uploads sourcemaps during build process
   - Uses `hidden-source-map` devtool (sourcemaps not referenced in JS)
   - Automatically deletes sourcemaps after upload (via plugin)

2. **Sentry Configuration** (`sentry.config.js`, `src/index.tsx`)
   - Release versioning matches between build and runtime
   - Uses format: `sceneXtras@${REACT_APP_VERSION || '1.5.7'}`
   - Proper release tagging in Sentry.init()

3. **Build Process**
   - Sourcemaps generated correctly
   - Hidden sourcemaps (security best practice)
   - PostHog integration for session replay

### ❌ Critical Issues Found

#### Issue 1: GitHub Actions Workflow Race Condition

**Problem:** The workflow deletes sourcemaps before Sentry release creation completes.

**Current Flow:**
1. Build with sourcemaps → Sentry webpack plugin uploads them ✅
2. PostHog processing → Deletes sourcemaps ❌
3. Create Sentry Release → Tries to reference deleted sourcemaps ❌

**Impact:**
- Sentry release creation step fails or can't associate sourcemaps
- PostHog processing removes sourcemaps before Sentry can finalize release
- Manual release step becomes redundant since webpack plugin already uploaded

**Fix Required:**
- Option A: Remove manual Sentry release step (webpack plugin handles it)
- Option B: Upload sourcemaps AFTER Sentry release creation
- Option C: Keep sourcemaps until after both Sentry and PostHog complete

#### Issue 2: Version Mismatch Risk

**Problem:** Multiple places define release version with different fallbacks.

**Locations:**
- `craco.config.js`: `sceneXtras@${REACT_APP_VERSION || '1.5.7'}`
- `src/index.tsx`: `sceneXtras@${REACT_APP_VERSION || '1.5.7'}`
- GitHub Actions: `sceneXtras@${github.sha}`

**Impact:**
- If `REACT_APP_VERSION` env var not set, uses hardcoded version
- GitHub Actions uses commit SHA, but build might use different version
- Runtime Sentry.init() might use different version than uploaded sourcemaps

**Fix Required:**
- Standardize version source to GitHub SHA in CI/CD
- Ensure `REACT_APP_VERSION` is set consistently

#### Issue 3: Missing Sourcemap Upload Verification

**Problem:** No verification that sourcemaps were successfully uploaded.

**Impact:**
- Silent failures if upload fails
- No way to verify sourcemaps are associated with correct release
- Difficult to debug sourcemap issues

**Fix Required:**
- Add verification step after Sentry upload
- Check Sentry API for sourcemap association
- Fail workflow if sourcemaps missing

### 🔧 Recommended Fixes

#### Fix 1: Correct Workflow Order

The workflow should:
1. Build with sourcemaps
2. Upload to Sentry (via webpack plugin OR manual step)
3. Upload to PostHog
4. Delete sourcemaps only after both complete

#### Fix 2: Standardize Versioning

Use GitHub SHA consistently:
```yaml
env:
  REACT_APP_VERSION: ${{ github.sha }}
```

And ensure it's available to webpack plugin.

#### Fix 3: Add Verification

Add step to verify sourcemaps were uploaded:
```yaml
- name: Verify Sentry Sourcemaps
  run: |
    # Check Sentry API for sourcemap association
    # Fail if sourcemaps missing
```

## Implementation Plan

1. **Fix GitHub Actions Workflow** (Priority: HIGH)
   - Reorder steps to preserve sourcemaps
   - Remove redundant Sentry release step OR move it before PostHog deletion
   - Add verification step

2. **Standardize Versioning** (Priority: MEDIUM)
   - Ensure REACT_APP_VERSION set in all environments
   - Use GitHub SHA in CI/CD
   - Update fallback versions

3. **Add Verification** (Priority: MEDIUM)
   - Create verification script
   - Add to workflow
   - Add error handling

4. **Documentation** (Priority: LOW)
   - Document sourcemap upload process
   - Add troubleshooting guide
   - Document versioning strategy

## Current Workflow Analysis

### `deploy-with-sourcemaps.yml` Flow:

```
1. Checkout code ✅
2. Setup Node.js ✅
3. Install Dependencies ✅
4. Build with Sourcemaps ✅
   └─ Sentry webpack plugin uploads sourcemaps automatically
   └─ Sourcemaps still exist in build/ directory
5. PostHog Sourcemap Processing ❌
   └─ Uploads to PostHog
   └─ DELETES sourcemaps from build/
6. Create Sentry Release ❌
   └─ Tries to upload sourcemaps that no longer exist
   └─ OR relies on webpack plugin upload (redundant step)
```

### Recommended Flow:

```
1. Checkout code ✅
2. Setup Node.js ✅
3. Install Dependencies ✅
4. Build with Sourcemaps ✅
   └─ Sentry webpack plugin uploads sourcemaps
   └─ Sourcemaps still exist in build/
5. Create Sentry Release ✅
   └─ Associate already-uploaded sourcemaps with release
   └─ OR upload sourcemaps if webpack plugin didn't run
6. PostHog Sourcemap Processing ✅
   └─ Upload to PostHog
   └─ Delete sourcemaps AFTER Sentry release finalized
7. Verify Uploads ✅
   └─ Check Sentry API
   └─ Check PostHog API
```

## Testing Recommendations

1. **Test Sourcemap Upload**
   - Build locally with `GENERATE_SOURCEMAP=true`
   - Verify sourcemaps uploaded to Sentry
   - Check Sentry dashboard for release

2. **Test Workflow**
   - Run workflow on test branch
   - Verify all steps complete
   - Check Sentry release has sourcemaps

3. **Test Error Handling**
   - Simulate Sentry upload failure
   - Verify workflow fails appropriately
   - Check error messages

## Additional Improvements

1. **Source Map Security**
   - ✅ Using `hidden-source-map` (good)
   - ✅ Deleting sourcemaps after upload (good)
   - Consider: Adding sourcemap URLs to `.gitignore` patterns

2. **Performance**
   - Sourcemap upload happens during build (good)
   - Parallel uploads where possible
   - Cache Sentry auth token

3. **Monitoring**
   - Track sourcemap upload success rate
   - Alert on upload failures
   - Monitor Sentry release creation

