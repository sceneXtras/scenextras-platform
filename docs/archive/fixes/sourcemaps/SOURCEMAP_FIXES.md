# Sourcemap Configuration Review & Fixes

## Critical Issues Found

### 1. ❌ **Duplicate Sentry Upload**
**Location:** Lines 32-76

**Problem:**
- Sentry webpack plugin uploads sourcemaps during build (line 47)
- Sentry CLI also tries to upload sourcemaps again (line 68)
- This wastes time and may cause conflicts

**Fix:** Remove duplicate Sentry CLI upload since webpack plugin already handles it

### 2. ❌ **PostHog Version Format Inconsistency**
**Location:** Line 88

**Problem:**
- Uses `github.sha` directly instead of `sceneXtras@${sha}` format
- Sentry uses `sceneXtras@${sha}` format
- Makes correlation difficult

**Fix:** Use consistent format: `sceneXtras@${REACT_APP_VERSION}`

### 3. ❌ **Silent Failures**
**Location:** Lines 85, 88

**Problem:**
- PostHog failures are hidden with `|| echo`
- Build continues even if sourcemaps fail to upload
- No way to detect failures

**Fix:** Proper error handling with exit codes

### 4. ❌ **Duplicate Cleanup Step**
**Location:** Lines 99 and 101-127

**Problem:**
- Sourcemaps deleted twice
- Redundant cleanup step

**Fix:** Remove duplicate cleanup

### 5. ❌ **Missing Validation**
**Location:** No validation step

**Problem:**
- No verification that sourcemaps were generated
- No verification that uploads succeeded

**Fix:** Add validation steps

## Fixed Workflow

See the corrected workflow below with all issues fixed.

