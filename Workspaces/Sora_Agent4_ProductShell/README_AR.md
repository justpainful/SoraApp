# Sora Agent Starter

هذا فولدر أساس جاهز لمشروع Sora بدون ما تحتاج تبدأ من الصفر.

## كيف تستخدمه بسرعة

1. فك الضغط.
2. أعط كل إيجنت فولدره من داخل `Workspaces/`:
   - `Sora_Agent1_Capture`
   - `Sora_Agent2_LookStudio`
   - `Sora_Agent3_Recorder`
   - `Sora_Agent4_ProductShell`
3. أعط كل إيجنت البرومبت الخاص به من `Prompts/`.
4. خليه يقرأ ملفات `Docs/` قبل ما يشتغل.
5. بعد ما يخلصون، خَلّ Agent 4 أو إيجنت دمج يدمج النتائج داخل `Sora_MAIN`.

## ملاحظة مهمة

الأساس جاهز كملفات ومشروع XcodeGen. على جهاز Mac، الإيجنت يشغل:

```bash
bash Scripts/bootstrap_project.sh
```

هذا يولد `Sora.xcodeproj` من `project.yml`.

لو الإيجنت عنده XcodeGen جاهز، بيولد المشروع مباشرة. لو ما عنده، السكربت يحاول تثبيته عبر Homebrew.

## الملفات المقفلة

لا أحد يغير هذه الملفات إلا إيجنت الدمج:

- `Sora/App/SoraTypes.swift`
- `Sora/App/AppState.swift`
- `Sora/App/SoraPipelineContract.swift`
