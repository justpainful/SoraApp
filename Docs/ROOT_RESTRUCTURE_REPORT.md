# Root Restructure Report

This report details the reorganization of the Sora repository to support root-level builds and GitHub Actions workflows.

## Files Moved to Root

The production-ready Sora application has been moved from `Workspaces/Sora_MAIN` to the repository root:
* **Source Code**: `Workspaces/Sora_MAIN/Sora/` -> [Sora/](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/Sora)
* **Scripts**: `Workspaces/Sora_MAIN/Scripts/bootstrap_project.sh` and `build_ipa.sh` -> [Scripts/](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/Scripts)
* **GitHub Actions Workflow**: `Workspaces/Sora_MAIN/.github/workflows/ios-ipa.yml` -> [.github/workflows/ios-ipa.yml](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/.github/workflows/ios-ipa.yml)
* **XcodeGen Spec**: `Workspaces/Sora_MAIN/project.yml` -> [project.yml](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/project.yml)
* **Documentation**:
  * `Workspaces/Sora_MAIN/README_BUILD_IPA.md` -> [README_BUILD_IPA.md](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/README_BUILD_IPA.md)
  * `Workspaces/Sora_MAIN/Docs/FINAL_QA_AUDIT.md` -> [Docs/FINAL_QA_AUDIT.md](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/Docs/FINAL_QA_AUDIT.md)
  * `Workspaces/Sora_MAIN/Docs/FIX_PASS_FINAL_REPORT.md` -> [Docs/FIX_PASS_FINAL_REPORT.md](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/Docs/FIX_PASS_FINAL_REPORT.md)

## Files Left Archived in Workspaces

The following workspaces and files are left under `Workspaces/` as historical archives of individual agent implementations:
* `Workspaces/Sora_Agent1_Capture/`
* `Workspaces/Sora_Agent2_LookStudio/`
* `Workspaces/Sora_Agent3_Recorder/`
* `Workspaces/Sora_Agent4_ProductShell/`
* `Workspaces/Sora_BASE/`
* In `Workspaces/Sora_MAIN/`, only the metadata directories/files (`Prompts/`, `.gitignore`, `README_AR.md`) were kept for archive completeness. All build-related configurations and workflows were cleaned up to prevent build confusion.

## Quality Mode Audit

* **Exposed UI**: None. The `QualityModeButton` view is not placed or referenced in the active user interface (`CameraView.swift`, `ControlsOverlay.swift`, or `SettingsSheet.swift`).
* **Settings Text**: The Settings screen displays a placeholder text explicitly stating:
  > *"Current build uses stable 1080p30. Quality mode is coming in v0.2."*
* **Compliance**: Complies fully with the rule requiring Quality Mode to be hidden or clearly disabled as v0.2.

## Workflow & Build Status

* **Workflow Location**: [.github/workflows/ios-ipa.yml](file:///c:/Users/kuroi/Downloads/Sora_Agent_Starter/Sora_Agent_Starter/.github/workflows/ios-ipa.yml)
* **Execution Path**: The workflow is configured to check out the repository root, run `bash ./Scripts/bootstrap_project.sh` to generate the project, and then run `bash ./Scripts/build_ipa.sh`.
* **Build Modes**:
  * **With Signing Secrets**: If GitHub repository secrets are set (`APPLE_CERTIFICATE_BASE64`, `P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `KEYCHAIN_PASSWORD`, `DEVELOPMENT_TEAM`, `BUNDLE_IDENTIFIER`, `EXPORT_METHOD`), the workflow will build a Release archive and export a signed `.ipa` file.
  * **Without Secrets (Verification Mode)**: If any signing secrets are missing, the workflow falls back to a verification-only simulator build (exit code 0) to verify compilation and project structure correctness.

## Remaining Issues

* None. The project is fully configured for root-level local and CI/CD builds.
