# Sora Final Merge Prompt

You are the final integration agent.

You have access to these folders:
- `Workspaces/Sora_Agent1_Capture`
- `Workspaces/Sora_Agent2_LookStudio`
- `Workspaces/Sora_Agent3_Recorder`
- `Workspaces/Sora_Agent4_ProductShell`
- `Workspaces/Sora_MAIN`

Your job:
1. Read `Docs/MERGE_GUIDE_NO_GIT.md`.
2. Copy only the allowed files from each agent workspace into `Sora_MAIN`.
3. Do not overwrite locked shared core files unless absolutely required.
4. If shared core must change, explain why and keep changes minimal.
5. Generate or update the Xcode project if needed using `Scripts/bootstrap_project.sh`.
6. Build the project.
7. Fix integration errors.
8. Run final QA checklist.

Final app requirements:
- Live camera preview.
- Sora Look filter sliders/presets.
- Record processed video.
- Save to Photos.
- Polished Sora UI.
- Local-only, no networking.
- No body reshaping or anatomy alteration.

Report:
- What was merged.
- What was fixed.
- Build status.
- Known issues.
