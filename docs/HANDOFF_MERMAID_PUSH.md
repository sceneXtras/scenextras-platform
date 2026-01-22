# Handoff: Push Mermaid Fixes to GitHub

## Status
Mermaid syntax is **FIXED** in all local files. Need to commit/push to make visible on GitHub.

## What Was Fixed
1. `[*]` → `End([End])` - stateDiagram syntax in flowcharts
2. `A --> B: label` → `A -->|label| B` - edge label syntax

## Files Fixed
- golang_auth_gateway/flows/BUSINESS_FLOWS.md ✅
- golang_search_engine/flows/BUSINESS_FLOWS.md ✅
- frontend_webapp/flows/BUSINESS_FLOWS.md ✅
- mobile_app_sx/flows/BUSINESS_FLOWS.md ✅
- sceneXtras/api/flows/BUSINESS_FLOWS.md ✅
- website-backoffice/flows/BUSINESS_FLOWS.md (no changes needed)
- automations/flows/BUSINESS_FLOWS.md (no changes needed)

## Remaining: Push to GitHub

### Structure
- **Monorepo**: `sceneXtras/scenextras-platform`
- **Submodules**: Individual service repos under `sceneXtras/` org

### Steps to Complete

For each submodule with changes:
```bash
cd golang_search_engine
git add flows/BUSINESS_FLOWS.md
git commit -m "docs: Fix Mermaid diagram syntax for GitHub rendering"
git push origin main
cd ..

cd frontend_webapp
git add flows/BUSINESS_FLOWS.md
git commit -m "docs: Fix Mermaid diagram syntax for GitHub rendering"
git push origin main
cd ..

cd mobile_app_sx
git add flows/BUSINESS_FLOWS.md
git commit -m "docs: Fix Mermaid diagram syntax for GitHub rendering"
git push origin main
cd ..

cd sceneXtras
git add api/flows/BUSINESS_FLOWS.md
git commit -m "docs: Fix Mermaid diagram syntax for GitHub rendering"
git push origin main
cd ..
```

Then update monorepo:
```bash
cd /Users/securiter/Workspace/scenextras_complex
git add golang_auth_gateway golang_search_engine frontend_webapp mobile_app_sx sceneXtras
git commit -m "chore: Update submodules with Mermaid syntax fixes"
git push origin main
```

## Verification
After push, check: `https://github.com/sceneXtras/scenextras-platform/blob/main/golang_auth_gateway/flows/BUSINESS_FLOWS.md`
