# Handoff: Fix Mermaid Diagram Syntax

## Status
Business flow diagrams created for all 7 repos, but Mermaid syntax has errors preventing GitHub rendering.

## Problem
The diagrams mix `stateDiagram-v2` and `flowchart` syntax incorrectly:
- `stateDiagram-v2` doesn't support `{Decision?}` diamond nodes
- `flowchart` uses `-->|label|` not `--> Node: label`

## Files to Fix
```
golang_auth_gateway/flows/BUSINESS_FLOWS.md
golang_search_engine/flows/BUSINESS_FLOWS.md
frontend_webapp/flows/BUSINESS_FLOWS.md
mobile_app_sx/flows/BUSINESS_FLOWS.md
website-backoffice/flows/BUSINESS_FLOWS.md
automations/flows/BUSINESS_FLOWS.md
sceneXtras/api/flows/BUSINESS_FLOWS.md
```

## Fix Required
For each file, either:
1. **Use flowchart syntax** (for diagrams with decisions):
   ```mermaid
   flowchart TD
       A[Start] -->|label| B{Decision?}
       B -->|Yes| C[Action]
       B -->|No| D[Other]
   ```

2. **Use stateDiagram-v2** (for state machines without `{}`):
   ```mermaid
   stateDiagram-v2
       [*] --> State1
       State1 --> State2: transition
   ```

## After Fix
Each submodule needs separate commit:
```bash
cd <repo> && git add flows/ && git commit -m "docs: Add business flows" && git push
```

## GitHub Repo
https://github.com/sceneXtras/scenextras-platform
