# VachaVox macOS UI Redesign Report

## Executive summary

VachaVox already has several strong foundations. The product scope is appropriately narrow for a menu bar utility, the current settings taxonomy is close to the real user jobs, the app already exposes the right core concepts — model readiness, output mode, hotkey mode, permissions, and local-first privacy — and the current UI uses mostly native macOS controls instead of importing web-dashboard patterns. The attached Markdown also shows a sensible split between fast-path surfaces such as the menu bar popover and slower configuration surfaces such as Settings. That is exactly the right product shape for a local dictation tool on macOS. citeturn21view0turn22view0turn11search1

The biggest problems are not “visual style” problems; they are hierarchy, state, and grammar problems. The current Settings panes are very sparse on some screens and overly dense on others, so the app feels both under-designed and over-specified at the same time. Status language is repeated and slightly inconsistent across tabs. The Home tab behaves like a dashboard, but the menu bar popover is supposed to be the real command center. The Models page makes users parse too many equally weighted actions. The Permissions screen doesn’t explain that Accessibility is output-mode dependent. Privacy/About collapses trust, legal, and app metadata into one block of text. The menu bar icon appears too app-icon-like at tiny size, which reduces legibility and misses the affordance of a quiet native menu extra. These are all high-impact usability issues because they affect the user’s first question on every launch: “Can I dictate right now, and if not, what do I need to fix?” citeturn7search0turn12search0turn22view0turn13search18turn11search1

The redesign direction should therefore be straightforward: keep VachaVox quiet, native, and local-first; make the menu bar popover the operational center; turn Settings into a conventional grouped-form settings window; rename the current Home tab into a General or Status page that acts as a setup checklist instead of a mini-dashboard; unify the app’s state model and vocabulary; and simplify model management so every model row has one obvious primary action and a small set of secondary actions. This is a refinement-heavy redesign, not a rebrand and not a ground-up reinvention. It should look more like a polished macOS utility than a “designed” app. citeturn22view0turn21view0turn13search13turn23search2

## macOS best-practice research

### Menu bar behavior and transient surfaces

The official guidance for menu bar utilities is clear: a menu bar extra is a persistent control in the menu bar, available even when the app is not frontmost, and it should provide easy access to utility functionality. SwiftUI’s `MenuBarExtra` also supports either a pulled-down menu or a chromeless anchored window, while popovers are defined as transient views that appear above other content when people click an interactive area. For VachaVox, that means the menu bar surface should do one job extremely well: immediately communicate readiness and provide the shortest possible path to start or stop dictation. It should not become a second settings window. The screens and flows affected are the menu bar icon, popover idle/ready/recording/transcribing/error states, and the footer actions that open Settings or quit. The likely files are `Sources/ChapadChapad/MenuBar/StatusItemController.swift` and `Sources/ChapadChapad/UI/PopoverView.swift`. Codex should verify the change by testing that the popover answers three questions within one glance: current state, primary next action, and any blocking issue. citeturn21view0turn12search0turn24search0turn24search1

The practical implication is that VachaVox’s popover should be a compact operational panel, not a mini control panel with duplicated configuration. The top region should show state and the primary action; the middle region should show only the few settings that matter during use, such as current model, output mode, and hotkey; and the bottom region should expose Settings, Pause, and Quit. If the current design already contains transcript history, level meter, readiness rows, and action buttons, those should be reorganized into this hierarchy rather than expanded. Verification should include opening the popover in all major states and checking that the user never needs to read more than one card to know what to do next. citeturn21view0turn12search0turn23search2

### Settings structure, sidebars, and grouped forms

Apple’s current macOS settings conventions strongly favor split-view navigation and grouped forms. The WWDC22 SwiftUI guidance is especially relevant: the new System Settings app uses `NavigationSplitView`, and grouped form style was designed specifically for settings interfaces that contain many controls, aligning labels and values consistently while adapting control appearance to context. Apple’s sidebar guidance also describes the sidebar as a broad, flat view of an information hierarchy. For VachaVox, that means the Settings window should look and behave like a settings window, not like a dashboard canvas with isolated cards floating in a wide empty area. The screens affected are every Settings tab. The likely file is `Sources/ChapadChapad/UI/SettingsView.swift`. Codex should verify the redesign by checking that label/value alignment is consistent across tabs, section headers read clearly in VoiceOver, and the window still feels natural when resized narrower or wider. citeturn22view0turn7search1turn18search9turn24search10

This has one especially important consequence for the current Home tab: it should not remain a dashboard. VachaVox does not need a dashboard because the app’s primary operational surface is the menu bar popover. However, it does benefit from a first pane that answers setup and readiness questions. So the best practice applied directly to VachaVox is to keep the first sidebar item, rename it from **Home** to **General** or **Status**, and make it a setup checklist plus current-state summary. Verification should confirm that the first pane becomes more useful when something is broken and quieter when everything is working. citeturn22view0turn21view0turn7search1

### Controls and action grammar

Apple’s control guidance is a good fit for VachaVox’s existing control set. Segmented controls are for choosing among a small set of mutually exclusive options. Pop-up buttons display the current selection or a default choice. Toggles are for on/off states. Sliders are for continuous ranges. Buttons can contain a symbol, text label, or both, and system buttons bring built-in states, adaptation, and accessibility. On current macOS, the platform is also moving toward better icon use in menus, clearer control prominence, and stronger visual differentiation between primary and destructive actions. For VachaVox, this means: keep Output mode as a segmented control; keep Performance as a pop-up button; keep Punctuation as a toggle; relabel and clarify the silence slider; reduce the number of peer buttons on model cards; and move rarely used actions behind a trailing menu. The affected screens are Models, Dictation, Hotkeys, the delete confirmation flow, and popover footer menus. The files are primarily `SettingsView.swift`, with supporting logic in `AppSettings.swift`, `ModelCatalog.swift`, and `DictationCoordinator.swift`. Verification should include keyboard-only use, hover states, and confirming that every section has one obvious primary action instead of many equivalent buttons. citeturn7search2turn10search0turn10search1turn10search2turn10search3turn13search2turn20view2turn24search3

Destructive actions deserve a separate callout. Apple’s alerts guidance says alerts contain a title, optional informative text, and a small number of buttons. The feedback guidance says to warn people when they initiate an unexpected and irreversible action that can cause data loss, but not to over-warn for ordinary actions. New AppKit guidance also recommends using color as a helpful hint for destructive actions without overpowering nearby controls. Applied to VachaVox, model deletion should remain confirmed, but the dialog should focus on the model name and the consequence, not the full path; the path should be secondary. If deleting the currently selected model changes readiness or forces a fallback model, the alert must say so. The affected screen is the delete confirmation sheet or alert, likely in `SettingsView.swift` with support from `DictationCoordinator.swift` and `ModelCatalog.swift`. Verification should ensure the default keyboard action is the safe path, the destructive action is explicit, and VoiceOver announces exactly which model will be deleted. citeturn13search0turn13search18turn20view0

### Writing, privacy messaging, and accessibility

Apple’s writing guidance is unusually relevant here. The HIG recommends simple, plain language, and Apple’s writing and help guidance emphasize removing filler, avoiding repetition, and leading with the why. For VachaVox, nearly every tab currently repeats “Model ready” as a subtitle; that repetition adds little value. Status text should instead be contextual and specific, such as “Ready to dictate,” “No model installed,” or “Paste mode needs Accessibility access.” Help text should stay short, and if a control needs a paragraph of explanation, the interface likely needs simplification. The affected surfaces are every pane, but especially General, Dictation, Hotkeys, Permissions, and Privacy. The likely file is `SettingsView.swift`, plus string sources embedded across `PopoverView.swift` and overlay/preview controllers. Verification should include a copy review pass: no pane title should be followed by a redundant subtitle, and every helper string should explain either purpose or consequence. citeturn11search2turn5view1turn23search2turn19search0

On privacy, Apple’s guidance says transparency about required data and resources is critical, and Apple’s privacy sessions emphasize that trust increases when people understand what data is accessed, why, and how much control they have. For VachaVox, this translates directly into UI language: the app should plainly say that transcription runs locally on the Mac, audio is recorded only during dictation, transcripts aren’t stored as app history, and output is delivered only through the user-selected mode such as Copy, Paste, or Preview. The Permissions page should also explain why access is needed in contextual language, and the microphone purpose string should be concise and benefit-led. The affected surfaces are Permissions, Privacy, first-run blockers in the popover, and app-level permission prompts. Likely files include `SettingsView.swift`, `PermissionsService.swift`, `SystemSettingsOpener.swift`, and any Info.plist purpose strings. Verification should include denial flows, re-open flows, and a copy audit of all permission-related text. citeturn11search1turn5view4turn5view7

Accessibility guidance is equally direct. Apple’s VoiceOver evaluation criteria require that people can complete common tasks using only VoiceOver, that all controls have concise and accurate labels, and that labels make sense out of context. WWDC25 macOS accessibility guidance adds that related elements should be grouped into containers for faster navigation, ordering should be refined if needed, default focus can be suggested when a scene appears, and keyboard shortcuts are a significant accessibility feature, not just a power-user feature. Apple also explicitly says that apps should not rely on color alone to communicate information, and sufficient contrast matters for text and iconography. For VachaVox, this means the model cards, permission rows, popover state region, and shortcut recorder all need intentional accessibility structure and non-color status cues such as symbols, row titles, and spoken values. The affected surfaces are every major surface, especially the model list, popover, keyboard shortcut recorder, and alerts. Likely files are `SettingsView.swift`, `PopoverView.swift`, `RecordingOverlayWindowController.swift`, `PreviewWindowController.swift`, and `StatusItemController.swift`. Verification must include VoiceOver traversal, Full Keyboard Access, Differentiate Without Color, and contrast checks in both appearances. citeturn5view0turn8view0turn8view1turn8view2turn15search0turn15search1turn15search2turn15search11

## Current UI audit

This audit is based on the attached Markdown inventory as the canonical context package and the attached screenshots as visual evidence. The menu bar popover, live overlay, preview window, and some error states were not captured; observations about those uncaptured surfaces are therefore structural recommendations based on the inventory and file mapping, not pixel-level critique.

### App icon and menu bar icon

The full app icon works reasonably well as a bundle icon. It is distinct, symmetrical, and dark enough to sit comfortably beside other productivity apps. The problem is the translation into the menu bar, where the current status item reads as a miniature app icon tile rather than a native status glyph. In the screenshot, it appears as a tiny dark rounded square with the VachaVox mark inside. At menu bar scale, the symbol details are too fine, the filled tile feels visually heavier than neighboring extras, and the icon does not yet communicate different app states.

What is clear is that VachaVox already has a strong brand mark. What is confusing is that the menu bar glyph is carrying branding when it should be carrying status. The accessibility risk is low recognition at small size, especially in dark mode or low contrast situations. The fix is to author a dedicated template-style menu bar symbol set that uses the VachaVox mark only if it survives at 16–18 px, otherwise fall back to a native SF Symbol metaphor such as waveform or mic for stateful variants. `StatusItemController.swift` and the `MenuBarIcon` asset are the primary touchpoints.

### Settings Home

The current Home screen communicates that the app is operational. The main card says local dictation is ready, lists the selected model, and exposes Start Dictation, Load Model, and Refresh Models. A second card summarizes engine, output, hotkey, and model status.

Visually, the strengths are simplicity and a small number of concepts. The problems are hierarchy and purpose. The pane title is large, but the usable content occupies only a small portion of a wide window. “Model ready” repeats the same status language used elsewhere. The three buttons have equal weight even though they are not equally important. Start Dictation feels out of place in Settings because the menu bar popover should be the fast path. Load Model and Refresh Models feel too operational for a “home” page. The summary rows are readable, but the values are pushed so far right that they feel detached from their labels. The accessibility risk is mostly navigational inefficiency rather than control ambiguity.

The key improvement is to stop treating this page as a dashboard. It should become a setup and status page with a health summary, a checklist when blocked, and only one optional test action rather than three equal operational controls.

### Settings Models

The Models tab is the strongest current pane because it captures the right domain concepts: selected model, downloaded models, and available downloads. The selected model summary is understandable, and the per-model cards already contain the right ingredients: identity, metadata, local path, status badge, and actions.

The problems are density and action overload. A single model row can show Select, Load, Delete, Reveal, and Open Source as peer actions. That makes users stop and parse the difference between “Select” and “Load,” which should not be a design problem they have to solve. The selected summary repeats information that already exists in the selected card. The full filesystem path is promoted too strongly; it is useful for troubleshooting but not for primary scanning. The status badges also need a more consistent grammar between Ready, Installed, Missing, Downloading, and Selected. Accessibility risks include a long VoiceOver traversal per card and repeated identical button labels like Delete or Reveal if the model name is not incorporated into accessibility labels.

The right improvement is to make each row have one obvious primary action. In practice, that means merging Select and Load into a single **Use Model** action and moving Reveal, Open Source, and Delete into a trailing secondary-actions menu.

### Settings Dictation

The Dictation pane communicates the right settings categories: output mode, punctuation, silence sensitivity, and performance. The segmented control for Copy / Paste / Preview is a good native choice.

The issues are explanatory clarity and control labeling. The selected output mode has no inline explanation of what happens in that mode. The silence slider lacks semantic end labels, so the user has to infer whether moving right means “more sensitive” or “wait longer.” Performance uses a pop-up, which is appropriate, but there is no consequence text such as “uses more memory” or “favors speed.” The pane is also visually underfilled; there is too much blank space for a screen that should teach consequences. Accessibility risks are moderate because the slider’s meaning may be unclear when read out of context unless its label and value text are improved.

The improvement is to reframe the page as a grouped settings form with short consequence text under each choice, especially for Paste and the speech-end slider.

### Settings Hotkeys and custom recorder

The Hotkeys pane is spare and legible. Mode is shown in a segmented control and preset selection is shown in a pop-up. The custom recorder screenshot also shows that the existing recorder field can fit comfortably in the layout.

The problem is that the pane currently reveals implementation rather than behavior. The note about Fn being handled by a low-level flags monitor is developer-facing, not user-facing. It explains internal implementation instead of the user result. The preset switch to “Custom shortcut” is functional, but the UI does not make shortcut inheritance or replacement especially clear, and there is no visible conflict or reserved-key handling in the screenshot. Accessibility risks include the recorder’s state change not being clearly announced and the meaning of the clear button being ambiguous without a better label.

The improvement is to make the page teach the behavior in plain language: when dictation starts, when it stops, what the current shortcut is, and what happens if the shortcut is unavailable.

### Settings Permissions

The Permissions pane is understandable at a glance. Microphone and Accessibility statuses are readable, and the page offers buttons to open the relevant System Settings panes.

The biggest issue is contextual meaning. Accessibility is not equally required for every output mode, but the UI does not say that. In VachaVox, Accessibility matters primarily for Paste output; for Copy and Preview it should be informational, not blocking. The page also mixes Start at login into the permissions surface, which is semantically awkward. Start at login is an app-lifecycle preference, not a privacy permission. The current Granted / Trusted labels are also not visually differentiated from ordinary values. Accessibility risks include insufficient semantic richness when those values are read aloud and non-color cues are absent.

The improvement is to turn each permission into a structured row with a title, status badge, explanation, and remediation button, and to move Start at login out of this pane.

### Settings Privacy/About and delete confirmation

The current Privacy/About pane is sparse, not wrong. Its strongest sentence is also its first: the local-processing promise is clear and valuable. But the rest of the pane quickly mixes trust messaging, project lineage, and dependency listing without structure. That makes the pane feel temporary rather than productized.

The improvement is to separate privacy, storage, app metadata, and diagnostics into sections. Privacy should remain prominent because it is core to VachaVox’s value proposition, but version/build and dependency acknowledgments should not sit at the same visual level as the privacy promise.

The delete confirmation dialog does the essential thing correctly by interrupting a potentially destructive action. The problem is emphasis. The wrapped local path dominates the small alert, while the higher-value information — which model, what gets removed, and whether the current selection changes — is not expressed as clearly as it could be. The destructive button text is better than a generic Delete label, but the dialog still needs tighter structure and clearer consequence language.

### Uncaptured popover, overlay, preview, and error flows

The Markdown inventory says the popover currently includes an app header, level meter, primary Start/Stop button, readiness rows, transcript card, Paused toggle, Settings, and Quit actions. Structurally, that is close to the right ingredient list. The likely risk is that too many of those elements compete at once in a transient panel that should behave more like a command palette than a mini dashboard.

The recording overlay is currently a floating NSPanel near the caret or mouse, and the preview flow is an editable window with a `TextEditor`, Cancel, and Copy. Those are the right technical shapes. The redesign opportunity is therefore not to invent new windows, but to make them feel more like system utility surfaces: smaller, calmer, more semantically obvious, and more consistent with the rest of the app’s status vocabulary.

## Proposed information architecture

The current IA is close, but the first pane is carrying the wrong role and one settings item is in the wrong place.

The recommended decision is: **keep the first pane, but rename and repurpose it**. The current Home pane should become **General** or **Status** and function as a setup checklist plus readiness page, not as a dashboard and not as a second place to operate the app. That recommendation is driven by two Apple patterns: menu bar utilities keep operational work in the menu bar surface, while settings windows work best when they use a streamlined hierarchy and grouped forms for configuration-heavy content. citeturn21view0turn22view0turn7search1

### Before

- Home
- Models
- Dictation
- Hotkeys
- Permissions
- Privacy/About

### After

- General  
  Readiness summary, setup checklist, app-level preferences such as Start at login, current defaults summary, optional test action.

- Models  
  Current model, installed models, available downloads, download progress, failure states.

- Dictation  
  Output mode, punctuation, speech-end behavior, performance mode, contextual notes that depend on output mode.

- Hotkeys  
  Trigger mode, preset/custom shortcut, conflict handling, behavior summary.

- Permissions  
  Microphone access, Accessibility access, contextual requirement text, remediation buttons.

- Privacy  
  Local-first promise, local storage details, version/build, open-source attributions, copy diagnostics action.

In addition, the app should expose **About VachaVox…** as a standard app/menu command even if the same information is mirrored inside the Privacy pane. This keeps the settings sidebar focused while still preserving a trusted place for version information and acknowledgments. SwiftUI’s Settings scene is also explicitly intended to represent in-app preferences on macOS, which supports the general separation between settings content and other top-level utility windows. citeturn18search9turn18search1

The most important grouping change is moving **Start at login** out of Permissions and into General. The most important contextual change is that **Accessibility access should be presented as required for Paste mode**, not as a universal blocker.

## Proposed UI by surface

### Menu bar icon states

**Layout and visual treatment.** Replace the current tile-like icon with a monochrome template-style icon family optimized for menu bar scale. Keep the brand mark only if it remains recognizably legible at menu bar size; otherwise prefer a symbol-led approach. The icon should never be a mini app tile with a filled rounded-square backdrop.

**State mapping.**
- Ready idle: quiet base glyph.
- Paused: base glyph with slash variant.
- Recording: base glyph changes shape, not just color; use pulse only if subtle.
- Transcribing: animated waveform or progress-like variation, again with shape or motion, not color alone.
- Blocking issue: badge or alternate symbol such as a warning mark.
- Error: exclamationmark-based variant.

**Behavior.** Keep the set small. One icon family with a few discrete state variants is better than many decorative icons. If you animate recording or transcribing, honor Reduced Motion by falling back to a static variant. Use accessibility labels on the status item itself such as “VachaVox, ready,” “VachaVox, recording,” or “VachaVox, paused.” The likely files are `StatusItemController.swift` and the menu bar image assets. Verification: side-by-side visual check in light and dark menu bars, plus VoiceOver on the status item. citeturn24search1turn24search9turn15search2turn15search11

### Menu bar popover states

**Layout.** Use a fixed-width anchored utility panel around 320–360 pt wide. The structure should be:
- top status header,
- single prominent primary action area,
- compact summary rows,
- optional contextual card,
- footer actions.

Do not let the popover become vertically long in the ready state. This surface is transient and should preserve a popover feel. citeturn12search0turn21view0

**Ready idle state.**  
Top row: app name or icon plus status badge “Ready to dictate.”  
Primary region: full-width button **Start Dictation**.  
Summary rows: **Model**, **Output**, **Shortcut** using compact `LabeledContent`-style rows.  
Footer: **Paused** toggle, **Settings…**, **Quit**.  
Microcopy should be calm and plain; no repeated “model ready” subtitle.

**Paused state.**  
Top badge becomes “Paused.”  
Primary button becomes **Resume Dictation**.  
Helper text: “Hotkeys and menu bar start are disabled while paused.”  
The Paused toggle should be in the footer and reflected immediately in the icon state.

**Recording state.**  
Top badge becomes “Listening.”  
Center shows a compact live level meter and an elapsed timer or prompt.  
Primary button becomes **Stop Dictation**.  
If push-to-talk is active, show the exact behavior: “Release the shortcut to stop.” If toggle mode is active, say “Press the shortcut again to stop.”

**Transcribing state.**  
Top badge becomes “Transcribing locally.”  
Show indeterminate progress if exact timing is unknown; Apple explicitly distinguishes indeterminate and determinate loading indicators. Disable conflicting actions rather than hiding everything. If cancel is technically possible, expose **Cancel** as a secondary action; otherwise avoid implying user control that does not exist. citeturn11search0

**Missing model state.**  
Top badge becomes “No model installed.”  
Primary button becomes **Open Models**.  
Helper text: “Install a local model to dictate on this Mac.”  
Show currently selected output and shortcut only if useful.

**Permission error state.**  
There should be contextual variants:
- **Microphone access required** when mic is denied.
- **Paste mode needs Accessibility access** when output mode is Paste and Accessibility is not trusted.
Primary button becomes **Open Permissions**.  
Secondary text should explain the consequence, not the implementation.

**Last transcript state.**  
Below the ready summary, optionally show a compact card titled **Last transcript** containing the newest transcript from the current session only. Include **Copy Again** and **Preview** actions, and optionally **Clear**. Because the app does not store transcript history, make the scope explicit: “In this session.” This respects the privacy promise while still giving people a useful recovery surface.

**Files and verification.** The main view file is `PopoverView.swift`, with state sourced from `DictationCoordinator.swift`, `AppSettings.swift`, and `StatusItemController.swift`. Verification should cover state screenshots, keyboard-only use, VoiceOver reading order, and contextual permission logic when switching output modes.

### Recording and transcribing overlay

**Layout.** Keep the overlay a lightweight floating HUD or utility panel close to the caret or pointer, but not obscuring the insertion point. It should visually read as status, not as a tool palette. Prefer a simple rounded panel with one status icon, one headline, one secondary line, and an optional meter.

**Listening state.**  
Headline: **Listening**.  
Secondary line: either **Release to stop** or **Press again to stop**, depending on hotkey mode.  
Include the level meter, but keep it subordinate to the state text.  
Avoid decorative motion; the live meter is enough.

**Transcribing state.**  
Headline: **Transcribing locally**.  
Secondary line: model name if useful, for example “Using Parakeet TDT 0.6B v3.”  
Use an indeterminate spinner or subtle progress treatment.

**Interaction behavior.** If the overlay is non-interactive, it should not steal focus from the target app. If you support Escape to cancel, make that explicit. The overlay should announce state changes for accessibility, but it does not need deep focus navigation if it is purely informative. Use reduced transparency and reduced motion accommodations in system accessibility modes. The likely files are `RecordingOverlayWindowController.swift` and `DictationCoordinator.swift`. Verification: overlay placement, focus retention in target app, reduced motion, and appearance in both dark and light mode. citeturn13search13turn15search11turn15search1

### Preview Dictation window

**Layout.** The preview should feel like a native single-purpose utility window, not a document editor. Use a standard titled macOS window with a plain title such as **Preview Dictation**. The content should be a single text editor region with a small explanatory line above it and a predictable action row below it.

**Hierarchy.**  
Top helper: “Edit text before copying.”  
Main content: `TextEditor` with standard body font and comfortable insets.  
Bottom actions: **Cancel** and **Copy**.  
Make **Copy** the default button and map it to Return or Command-Return. Make Escape cancel.

**Behavior.** Preserve the current no-history posture. Open the window with the latest transcript text, allow edits, and then copy the edited text on confirmation. If future behavior adds a paste variant, do not overload this window yet; keep it single-purpose for now. The likely files are `PreviewWindowController.swift` and `DictationCoordinator.swift`. Verification should include default button behavior, focus landing in the text editor, selection/copy workflow, and state cleanup when the window closes. citeturn21view0turn8view2

### Settings Home reworked as General

**Recommended naming.** Rename **Home** to **General**. If you strongly prefer an operational name, **Status** is acceptable, but **General** is more native to macOS settings conventions.

**Layout.** Rebuild the screen as a grouped form with three sections:
- **Readiness**
- **Defaults**
- **App behavior**

**Readiness section.**  
A top summary row or card says either **Ready to dictate** or **Needs setup**.  
Checklist rows:
- Model
- Microphone
- Accessibility, but only flagged as required if output is Paste
- Output mode
- Shortcut

Each row should include the current state and, when needed, a small remediation button that deep-links to the appropriate pane or system settings.

**Defaults section.**  
Read-only summary rows for current output, current model, and current shortcut.  
Optional secondary action: **Test Dictation**. This should be a secondary action, not the dominant button.

**App behavior section.**  
Move **Start at login** here.  
If paused is a persistent app-level setting, place **Pause dictation** here too, or keep pause only in the popover and show the current paused state as read-only here.

**Behavior.** This page should be most useful on first run and almost silent once setup is done. `SettingsView.swift`, `AppSettings.swift`, and `DictationCoordinator.swift` are the main files. Verification: with no model installed, the pane becomes a proper checklist; with everything configured, it collapses into a calm status summary. citeturn22view0turn21view0

### Settings Models

**Layout.** Use three sections:
- **Current model**
- **Installed models**
- **Available models**

**Current model.**  
Show the active model name, engine, readiness, and lightweight metadata such as language scope and expected memory need. Do not lead with the filesystem path. If the path is important, expose it as a secondary disclosure or through a Reveal action.

**Installed models.**  
Each row should show:
- icon,
- model name,
- secondary metadata,
- status badge,
- one primary action,
- trailing menu for secondary actions.

Primary action grammar:
- **In Use** if active,
- **Use Model** if installed but not active,
- **Resume Download** if partially downloaded,
- **Retry** if failed.

Secondary actions in a trailing menu:
- Reveal in Finder
- Open Source
- Delete

This is the most important simplification in the whole redesign. **Select** and **Load** should not exist as separate primary actions in the redesigned UI. If the system truly has to “load” after selection, that should happen behind a single user-facing **Use Model** command.

**Available models.**  
Each row should show metadata and one primary **Download** action. Progress should appear inline in the row instead of sending the user elsewhere. Empty and failure states should be explicit.

**Behavior.** If the current model is deleted, immediately show what fallback happens. If there is no fallback, surface a clear readiness change. Likely files: `SettingsView.swift`, `ModelCatalog.swift`, `ModelDownloadService.swift`, and `DictationCoordinator.swift`. Verification: one installed model, many installed models, zero models, download in progress, failed download, delete current model, and delete non-current model.

### Settings Dictation

**Layout.** Use a grouped form with sections for:
- **Output**
- **Formatting**
- **Speech end**
- **Performance**

**Output.**  
Keep the segmented control for **Copy**, **Paste**, **Preview**.  
Below it, show one sentence that changes with selection:
- Copy: “Copy the transcript to the clipboard.”
- Paste: “Paste into the focused app after transcription.”
- Preview: “Open an editable preview before copying.”

If Accessibility is missing and Paste is selected, show an inline note right here too, not only on the Permissions pane.

**Formatting.**  
Toggle label: **Add punctuation automatically**.

**Speech end.**  
Rename **Silence sensitivity** to **Stop after silence** or **End dictation after silence**.  
Use endpoint labels: **Wait longer** on the left and **Stop sooner** on the right.  
If you can present a neutral default marker, do so; current macOS design guidance explicitly supports a neutral slider anchor in newer systems. citeturn20view1

**Performance.**  
Keep a pop-up button, but use user-facing option names such as **Accuracy**, **Balanced**, **Speed** if those match behavior. Add a short helper line like “Higher accuracy may use more memory.”

**Files and verification.** `SettingsView.swift`, `AppSettings.swift`, and `DictationCoordinator.swift`. Verify that the dictation pane alone is enough for a new user to understand the practical difference between output modes.

### Settings Hotkeys

**Layout.** Use sections for:
- **Trigger mode**
- **Shortcut**
- **Behavior summary**

**Trigger mode.**  
Keep the segmented control. Use either **Push to talk** / **Toggle**, or slightly more explicit text such as **Hold to dictate** / **Press to toggle** if space permits.

**Shortcut.**  
Use a pop-up for presets and reveal the custom recorder only when the custom option is selected.  
Always show the current effective shortcut as a value, even when the user is on a preset.

**Behavior summary.**  
Provide plain-language summary text generated from the current state, for example:
- “Hold Command-Shift-D while speaking.”
- “Press Command-Shift-D once to start and again to stop.”

Replace the current low-level Fn implementation note with user-facing guidance. If there is a system limitation or reserved shortcut conflict, show that only when relevant.

**Recorder behavior.**  
When entering custom mode, either preserve the current shortcut visibly or clearly ask for a new one.  
Clear button accessibility label should include the context, for example “Clear shortcut.”  
If the chosen shortcut is reserved or conflicts with another app command you know about, show an inline warning row.

**Files and verification.** `SettingsView.swift`, `HotKeyService.swift`, and `AppSettings.swift`. Verify recorder focus, “recording” announcement, Escape to cancel, Delete to clear, and conflict presentation.

### Settings Permissions

**Layout.** Use one row per permission with:
- symbol,
- title,
- status badge,
- explanation,
- action button.

**Rows.**
- **Microphone** — “Required to record speech for dictation.”
- **Accessibility** — “Required only for Paste output mode.”
- Optional **Check again** or automatic refresh on pane appear / app activation.

**App behavior setting.** Move **Start at login** out of this pane.

**Behavior.**  
If microphone is denied, this pane becomes part of the readiness flow.  
If Accessibility is denied while output is Copy or Preview, present it as available-but-not-required, not as a hard failure.  
This one change will make the app feel much smarter and less alarmist.

**Files and verification.** `SettingsView.swift`, `PermissionsService.swift`, `SystemSettingsOpener.swift`, and `AppSettings.swift`. Verify all combinations:
- mic granted / denied,
- accessibility trusted / not trusted,
- output Copy / Paste / Preview.

### Settings Privacy and About

**Layout.** Keep the pane, but split it into four sections:
- **Your data**
- **Local storage**
- **About**
- **Diagnostics**

**Your data.**  
Three high-confidence statements with symbols:
- Audio is recorded only during dictation.
- Transcription runs on this Mac.
- VachaVox does not keep transcript history.

**Local storage.**  
Explain where downloaded models are stored and expose **Reveal Models Folder** if useful.

**About.**  
Show version, build, selected engine framework, and license / acknowledgments entry points.

**Diagnostics.**  
Add **Copy diagnostics** to copy app version, selected model, output mode, permission states, and readiness state. This is valuable for support and future issue reporting without requiring a separate debug window.

**Behavior.** Keep the local-first promise prominent but not repetitive across the whole app. The likely file is `SettingsView.swift`, with data coming from `AppSettings.swift`, `DictationCoordinator.swift`, and potentially `Bundle` metadata. Verification: privacy copy is readable at a glance; diagnostics output excludes transcript content.

### Delete confirmation dialog

**Layout and language.**  
Title: **Delete local model?**  
Message: “Whisper Small will be removed from this Mac.”  
Secondary consequence line, only if relevant: “VachaVox will switch to Parakeet TDT 0.6B v3,” or “Dictation will be unavailable until another model is installed.”

If you must show the path, move it to a secondary line, footnote style, or a disclosure region. Do not let it dominate the alert.

**Buttons.**  
Primary safe action: **Cancel**.  
Destructive action: **Delete Whisper Small**.  
Never use a generic Delete label. Apple’s accessibility guidance explicitly says destructive labels should make sense out of context. citeturn5view0

**Files and verification.** `SettingsView.swift`, `DictationCoordinator.swift`, and `ModelCatalog.swift`. Verify keyboard default behavior, VoiceOver label clarity, path wrapping, and selected-model fallback language.

## Design system and accessibility

### Design system recommendations

VachaVox should use the system more aggressively, not less. Typography should rely on standard macOS text styles so the app inherits platform tuning and remains readable. Use one large pane title style for the current Settings section, a semibold section header style, body text for primary values, footnote for helper text and metadata, and caption only for very secondary details such as paths or build strings. Apple’s typography guidance emphasizes legibility and hierarchy, and SF Symbols are designed to align visually with the San Francisco font. citeturn9search1turn9search3

Use a simple spacing system: 4, 8, 12, 16, 24. In practice, 16 should be the standard internal card padding, 12 should separate label-and-control groups inside a section, and 24 should separate major sections. The current Settings panes often feel too empty because spacing is being spent on blank canvas rather than on section rhythm. Grouped forms solve much of this automatically, which is another reason to prefer them for General, Dictation, Hotkeys, Permissions, and Privacy. citeturn22view0

Corner radius should stay modest and continuous. For grouped panels or cards, use something around 10–12 pt equivalent; for smaller chips and badges, 6–8 pt. Do not build a capsule-heavy interface unless you are intentionally matching a floating HUD or top-level glass control cluster. Apple’s latest AppKit design guidance explicitly distinguishes rounded rectangles for smaller controls and capsules for larger/floating contexts. That means VachaVox should keep pill styling mostly for segmented controls, badges, and perhaps the overlay, not for every card in settings. citeturn20view3

Color should be semantic rather than brand-led. Use system text colors, system fill/material backgrounds, accent color for the primary action, green for ready/success, orange for warning or setup-needed, red for destructive/error, but never rely on color alone. Apple’s color guidance emphasizes system colors that adapt to appearance and accessibility settings, and the accessibility guidance explicitly calls out contrast and differentiating without color alone. For VachaVox, every badge should combine color with icon and text, for example **Ready** with a checkmark, **Needs access** with a lock or hand icon, **Missing** with a tray/exclamation metaphor. citeturn9search0turn15search1turn15search0turn15search11

Recommended symbols:
- General / Status: `circle.badge.checkmark` or `dot.radiowaves.left.and.right`
- Models: `square.stack.3d.up`
- Dictation: `mic`
- Hotkeys: `keyboard`
- Permissions: `hand.raised`
- Privacy: `lock.shield`
- Ready badge: `checkmark.circle.fill`
- Warning badge: `exclamationmark.triangle.fill`
- Missing model: `square.stack.3d.down.right.slash`
- Last transcript: `text.quote`
- Pause: `pause.circle`
- Recording: `waveform`
- Transcribing: `ellipsis.circle` or subtle progress metaphor

These should be used conservatively and consistently. Apple explicitly recommends familiar icons for menu items and other interface iconography, and current AppKit guidance also highlights improved icon scanning in menus. citeturn24search3turn20view2turn24search9

Button hierarchy should be strict:
- one primary tinted action per surface or section,
- secondary plain or bordered actions for nearby alternatives,
- destructive actions either in a trailing menu or clearly separated.  
On newer macOS the platform also supports different tint prominence levels, which is a useful mental model even if you do not directly adopt the newest APIs. In VachaVox, **Start Dictation**, **Use Model**, **Download**, **Copy**, and **Resume** are candidates for primary actions. **Reveal**, **Open Source**, and **Delete** are not. citeturn20view0turn20view2

For panel composition, prefer grouped forms where possible and use custom cards only where the data truly exceeds the form grammar, especially on the Models page and perhaps in the popover. Use material/translucency sparingly. Apple’s latest design guidance is very clear that glass or floating material belongs to top-level controls and navigation, not to every content panel. For VachaVox, that means the overlay can use a HUD-like material and the popover can inherit system window styling, but the Settings window should remain mostly opaque, light-weight, and conventional. citeturn13search13turn20view2

Empty, error, and loading states need reusable components. VachaVox should standardize three compact state blocks:
- **Empty state**: title, one-line explanation, one primary action.
- **Error state**: title, short consequence, retry/remediation button.
- **Loading state**: status text plus the right progress indicator type, determinate if possible and indeterminate if not.  
This should be used on Models, the popover, and the overlay/transcribing state. citeturn11search0turn13search18

### Accessibility and keyboard behavior checklist

VoiceOver labels must be concise, accurate, and meaningful out of context. That means generic repeated labels like “Delete,” “Reveal,” or “Settings” are not enough when they appear in lists or repeated contexts. Use labels such as “Delete Whisper Small,” “Reveal Parakeet model in Finder,” and “Open VachaVox settings.” Text fields and recorder fields need a label in addition to their current value. citeturn5view0

Group related content into accessibility containers. The current model cards are ideal candidates: each card should be a container with a coherent read order — model name, metadata, status, then actions. Apple’s macOS accessibility guidance explicitly recommends grouping related elements into containers, avoiding excessive nesting, and using sort priorities to improve reading order. In VachaVox, the status badge and primary action should be announced before low-priority metadata like local paths. citeturn8view0turn8view3

Keyboard navigation should be explicit and testable. In Settings, the expected order is sidebar, pane title, first unresolved blocker or first control, then top-to-bottom through each section. In the popover, focus order should be header status, primary action, summary rows, optional transcript card actions, footer controls. In the preview window, default focus should land in the text editor or on the primary action depending on whether the transcript is meant to be edited immediately; Apple’s recent accessibility guidance also supports suggesting default accessibility focus for newly presented scenes. citeturn8view2turn8view1

Shortcut recorder behavior needs its own accessibility pass. When the recorder enters capture mode, announce it. Let Escape cancel recording. Let Delete clear the current shortcut. Expose the clear button with a descriptive label. If a shortcut is invalid or reserved, show an inline spoken warning. Keyboard shortcuts are not merely convenience features; Apple explicitly calls them out as important for accessibility, especially for people who do not use a mouse. citeturn8view1

Do not rely on color alone for status. Every badge and state row should combine text, iconography, and position, not just green vs red. Apple’s official evaluation criteria say common tasks should not rely on color as the only way to convey information, and SwiftUI/AppKit also expose an environment for differentiating without color. In VachaVox, “Ready” should not just be green; it should be checkmarked and labeled. “Needs access” should not just be orange; it should use warning iconography and explanatory text. citeturn15search0turn15search2turn15search11

Contrast needs deliberate checking in light and dark appearance. The current screenshots are generally gentle, but some low-contrast grey-on-grey regions and badges could become indistinct under increased contrast settings or in dark mode. Use semantic colors and test with increased contrast and reduced transparency. Apple’s accessibility guidance explicitly calls out sufficient contrast between foreground text or icons and their background. citeturn15search1turn15search4

Finally, make every common task completable using only VoiceOver and the keyboard:
- open popover,
- understand readiness,
- start and stop dictation,
- install or select a model,
- change output mode,
- set a shortcut,
- open the right permission pane,
- confirm or cancel model deletion,
- edit and copy from Preview.  
This is the accessibility bar VachaVox should target. citeturn5view0turn8view3

## Implementation guidance and prioritized backlog

### Implementation guidance for Codex

The lowest-risk approach is to **keep the existing AppKit lifecycle and window/controller structure** while redesigning the SwiftUI content first. Do not block the redesign on a migration to SwiftUI `Settings` scene or `MenuBarExtra`. Those are reasonable future cleanups, but the UI quality issues can be solved inside the current structure.

A good phased architecture starts with a shared presentation layer:

**Create a single UI-facing state grammar.**  
In `Sources/ChapadChapad/App/DictationCoordinator.swift` and `Sources/ChapadChapad/Settings/AppSettings.swift`, define presentation enums or computed structs for:
- readiness,
- dictation phase,
- model row state,
- permission state,
- output requirement state.

Example conceptual enums:
- `ReadinessState`: ready, paused, needsModel, needsMicrophone, needsAccessibilityForPaste, loadingModel, transcribing, error
- `ModelPresentationState`: inUse, installed, downloading(progress), missing, failed
- `PermissionPresentationState`: granted, needed, notNeeded, denied

This is the highest-leverage implementation step because almost every UI problem in the screenshots is really a state-model problem first.

**Extract reusable SwiftUI components inside `SettingsView.swift` or sibling files.**  
Recommended boundaries:
- `StatusSummarySection`
- `ReadinessChecklistRow`
- `LabeledStatusRow`
- `ModelCardView` or `ModelRowView`
- `PermissionRowView`
- `OutputModeDescriptionView`
- `ShortcutBehaviorSummaryView`
- `LastTranscriptCardView`
- `PopoverPrimaryActionView`
- `StatusBadgeView`

Keep these thin and presentation-only; do not let them talk directly to services.

**Keep services authoritative.**  
`DictationCoordinator.swift`, `ModelCatalog.swift`, and any download/permission services should remain the source of truth. The UI should consume derived view models or computed state only.

**Use file-level responsibility deliberately.**
- `SettingsView.swift`: sidebar structure, grouped forms, card/list composition, delete alert text.
- `PopoverView.swift`: compact stateful operational surface.
- `RecordingOverlayWindowController.swift`: visual overlay shell plus lightweight SwiftUI host.
- `PreviewWindowController.swift`: utility editing window and primary/secondary actions.
- `StatusItemController.swift`: icon state mapping, accessibility label, highlight/animation coordination.
- `AppSettings.swift`: user defaults, output mode, hotkey mode, paused state, launch at login.
- `DictationCoordinator.swift`: readiness logic, phase transitions, fallback behavior after model delete.
- `ModelCatalog.swift`: model metadata and row actions, possibly row badges and selection semantics.

**Verification strategy.**
Use a combination of:
- light/dark manual screenshots,
- keyboard-only walkthroughs,
- VoiceOver walkthroughs,
- unit tests for readiness derivation,
- integration tests for output-mode-dependent permission logic,
- snapshot or screenshot tests for major popover and settings states if you already have that infrastructure.

A concrete verification matrix should include:
- zero models installed,
- one ready model,
- selected model deleted,
- microphone denied,
- accessibility denied while output = Paste,
- accessibility denied while output = Copy,
- paused,
- recording,
- transcribing,
- preview output flow,
- custom shortcut recorder active.

### Prioritized backlog

#### P0

**Unify readiness, status vocabulary, and state derivation**  
**Rationale.** Current UI issues are mostly caused by duplicated or vague state expressions.  
**Affected surfaces / files.** Popover, General, Models, Permissions, overlay, icon states; `DictationCoordinator.swift`, `AppSettings.swift`, `StatusItemController.swift`, `PopoverView.swift`, `SettingsView.swift`.  
**Acceptance criteria.** The entire app uses one shared vocabulary: Ready to dictate, Paused, Listening, Transcribing locally, No model installed, Microphone access required, Paste mode needs Accessibility access, Error. No pane uses redundant “Model ready” subtitles.  
**Visual / behavior notes.** This is a prerequisite for nearly every other change.

**Replace Home with a General status/setup page**  
**Rationale.** The current Home page duplicates operations instead of clarifying readiness.  
**Affected surfaces / files.** Settings first pane; `SettingsView.swift`, `AppSettings.swift`, `DictationCoordinator.swift`.  
**Acceptance criteria.** First pane is renamed General or Status, shows readiness and checklist rows, moves Start at login out of Permissions, and no longer presents Load/Refresh/Start as equal first-class actions.  
**Visual / behavior notes.** Keep one optional Test Dictation secondary action.

**Redesign menu bar popover into a compact operational panel**  
**Rationale.** The menu bar surface should be the fast path and primary command center.  
**Affected surfaces / files.** Popover and status item; `PopoverView.swift`, `StatusItemController.swift`, `DictationCoordinator.swift`.  
**Acceptance criteria.** Ready, paused, recording, transcribing, missing-model, and permission-error states all render distinct layouts with one primary action and contextual helper text.  
**Visual / behavior notes.** Popover height stays compact in ready state and does not feel like a settings window.

**Introduce dedicated menu bar icon state family**  
**Rationale.** The current tiny app-icon-like status glyph is too heavy and not stateful enough.  
**Affected surfaces / files.** Menu bar icon asset and controller; `StatusItemController.swift`, menu bar resources.  
**Acceptance criteria.** The menu bar item shows distinct but restrained icon states for idle, paused, recording, transcribing, and blocking issue; each has an accessibility label.  
**Visual / behavior notes.** No filled square app tile in the menu bar.

**Simplify model row actions and merge Select + Load into Use Model**  
**Rationale.** The current model action set is dense and semantically confusing.  
**Affected surfaces / files.** Models page; `SettingsView.swift`, `ModelCatalog.swift`, `DictationCoordinator.swift`, `ModelDownloadService.swift`.  
**Acceptance criteria.** Installed model rows expose one primary action and a secondary trailing menu. There is no separate Select and Load peer-button pair in the UI.  
**Visual / behavior notes.** Surface current model, installed models, and available downloads as distinct sections.

**Make permission logic contextual to output mode**  
**Rationale.** Accessibility should not look like a universal blocker when only Paste needs it.  
**Affected surfaces / files.** General, Dictation, Permissions, popover; `PermissionsService.swift`, `AppSettings.swift`, `DictationCoordinator.swift`, `SettingsView.swift`, `PopoverView.swift`.  
**Acceptance criteria.** Accessibility denied + Copy mode does not block readiness; Accessibility denied + Paste mode does block readiness and shows contextual remediation text.  
**Visual / behavior notes.** This is a usability and trust improvement, not merely a copy change.

**Accessibility baseline pass across all common tasks**  
**Rationale.** Menu bar utilities and settings forms are only truly native when keyboard and VoiceOver flows work.  
**Affected surfaces / files.** All major UI files.  
**Acceptance criteria.** VoiceOver can complete common tasks; focus order is predictable; buttons and repeated actions have context-rich labels; status does not rely on color alone.  
**Visual / behavior notes.** Test with Differentiate Without Color, Increased Contrast, Reduce Motion, and Full Keyboard Access.

#### P1

**Rebuild Dictation settings as a grouped form with consequence text**  
**Rationale.** Output modes and silence behavior are currently under-explained.  
**Affected surfaces / files.** `SettingsView.swift`, `AppSettings.swift`.  
**Acceptance criteria.** Output mode has inline explanation, silence slider has semantic end labels, performance has consequence text, and the pane uses grouped-form spacing/alignment.  
**Visual / behavior notes.** Keep native controls.

**Rebuild Hotkeys pane with behavior summary and recorder clarity**  
**Rationale.** The current pane exposes implementation notes rather than behavior.  
**Affected surfaces / files.** `SettingsView.swift`, `HotKeyService.swift`, `AppSettings.swift`.  
**Acceptance criteria.** Mode and shortcut are clear, custom recorder has explicit state and clear button label, reserved/conflicting shortcuts show warnings, and the pane displays a plain-language behavior summary.  
**Visual / behavior notes.** Remove or hide the low-level Fn implementation note unless necessary.

**Move Start at login to General and redesign Permissions as structured rows**  
**Rationale.** Permissions and app behavior are currently mixed.  
**Affected surfaces / files.** `SettingsView.swift`, `PermissionsService.swift`, `SystemSettingsOpener.swift`, `AppSettings.swift`.  
**Acceptance criteria.** Permissions page contains only permission-related items with badges and remediation actions. Start at login moves to General.  
**Visual / behavior notes.** Accessibility row must explicitly mention Paste.

**Rewrite Privacy/About into Privacy + About + Diagnostics sections**  
**Rationale.** The current page underuses an important trust surface.  
**Affected surfaces / files.** `SettingsView.swift`, `AppSettings.swift`, bundle/version access.  
**Acceptance criteria.** The page clearly states the local-first guarantee, shows version/build, provides licenses/acknowledgments entry points, and offers Copy diagnostics without including transcript content.  
**Visual / behavior notes.** Keep this quiet and utilitarian.

**Redesign delete confirmation copy and consequence handling**  
**Rationale.** The current alert overemphasizes path text and underexplains consequences.  
**Affected surfaces / files.** `SettingsView.swift`, `DictationCoordinator.swift`, `ModelCatalog.swift`.  
**Acceptance criteria.** Alert focuses on model name and consequence, defaults to safe action, and includes fallback-state language if deleting the selected model changes readiness.  
**Visual / behavior notes.** Path is secondary, not dominant.

**Polish the recording/transcribing overlay and preview window**  
**Rationale.** These are core dictation feedback surfaces but currently unspecified visually.  
**Affected surfaces / files.** `RecordingOverlayWindowController.swift`, `PreviewWindowController.swift`, `DictationCoordinator.swift`.  
**Acceptance criteria.** Overlay communicates Listening vs Transcribing clearly, does not steal focus unnecessarily, and honors reduced motion. Preview window behaves like a native utility window with default and cancel keyboard actions.  
**Visual / behavior notes.** Keep them sparse and system-like.

#### P2

**Add standard About VachaVox surface and command plumbing**  
**Rationale.** About is a native macOS expectation even if mirrored in settings.  
**Affected surfaces / files.** App/menu command wiring, possibly AppKit app delegate surface.  
**Acceptance criteria.** About VachaVox is available through a standard app-level command and matches version/build information in the Privacy pane.  
**Visual / behavior notes.** Use standard panel where practical.

**Add last-transcript card in the popover**  
**Rationale.** It improves recovery and review without turning the app into a history manager.  
**Affected surfaces / files.** `PopoverView.swift`, `DictationCoordinator.swift`.  
**Acceptance criteria.** After a successful session, the popover can show the last transcript for the current app session, with Copy Again and Preview actions.  
**Visual / behavior notes.** Clearly scoped to “this session.”

**Introduce reusable status badges and state components**  
**Rationale.** Status consistency is one of the biggest polish opportunities.  
**Affected surfaces / files.** Shared SwiftUI components used by Settings and Popover.  
**Acceptance criteria.** Ready / Installed / Missing / Downloading / Needs access / Error all use one component family with text + symbol + semantic colors.  
**Visual / behavior notes.** This helps light/dark mode, accessibility, and visual consistency.

**Evaluate future scene modernization after UI stabilization**  
**Rationale.** A later migration to SwiftUI scene types may simplify host code, but it is not necessary to deliver the redesign.  
**Affected surfaces / files.** Status item / settings / preview host scaffolding.  
**Acceptance criteria.** Deferred until after UI redesign ships. If attempted later, it should not regress keyboard behavior, accessibility, or popover reliability.  
**Visual / behavior notes.** Do not couple this to the current redesign milestone.

### Open questions and limitations

The attached package did not include screenshots for the menu bar popover, overlay, preview window, permission-denied state, missing-model state, or last-transcript surface. Recommendations for those surfaces are therefore grounded in the Markdown inventory and file mapping rather than direct visual critique.

The package also does not expose the current actual Swift source, so file-level implementation notes are high-confidence architectural recommendations, not line-by-line code edits.

## Codex-ready redesign brief

Redesign the VachaVox macOS UI as a native, quiet, local-first menu bar utility. Preserve the current product scope and core jobs: quick start/stop dictation, clear readiness, easy local model management, output mode selection, hotkey setup, permission remediation, and visible privacy trust. Do not turn the app into a web-style dashboard, marketing surface, or highly branded custom UI.

Goals:
- Make the menu bar popover the primary operational surface.
- Replace the current Home pane with a General or Status pane that acts as a setup checklist and readiness summary.
- Standardize status language and state handling across the menu bar icon, popover, settings, overlay, preview, and model-delete flow.
- Simplify model management by replacing separate Select and Load actions with one primary Use Model action plus secondary-row actions.
- Make Accessibility permission contextual to Paste output mode.
- Strengthen privacy messaging and add version/build/diagnostics structure.
- Improve VoiceOver, keyboard navigation, non-color status cues, and contrast behavior.

Constraints:
- Keep the design native to macOS and feasible in SwiftUI/AppKit.
- Preserve local-first/privacy-first positioning.
- Reuse system controls and grouped forms where possible.
- Avoid decorative custom chrome; use material/translucency sparingly.
- Do not require a scene-architecture migration to deliver the redesign.

Surfaces to change:
- `Sources/ChapadChapad/MenuBar/StatusItemController.swift`
- `Sources/ChapadChapad/UI/PopoverView.swift`
- `Sources/ChapadChapad/UI/SettingsView.swift`
- `Sources/ChapadChapad/UI/RecordingOverlayWindowController.swift`
- `Sources/ChapadChapad/UI/PreviewWindowController.swift`
- `Sources/ChapadChapad/Settings/AppSettings.swift`
- `Sources/ChapadChapad/App/DictationCoordinator.swift`
- `Sources/ChapadChapad/Models/ModelCatalog.swift`

Implementation phases:
- Phase A: create a unified presentation state model and shared status vocabulary.
- Phase B: redesign Settings content and sidebar IA, including General, Models, Dictation, Hotkeys, Permissions, and Privacy.
- Phase C: redesign menu bar icon states and popover states.
- Phase D: redesign overlay, preview window, and delete confirmation.
- Phase E: run accessibility, keyboard, and state-matrix verification.

Acceptance criteria:
- The app exposes clear states: Ready to dictate, Paused, Listening, Transcribing locally, No model installed, Microphone access required, Paste mode needs Accessibility access, Error.
- The popover has one obvious primary action in every state.
- The first settings pane is no longer a dashboard; it is a readiness/setup page.
- The Models page has one primary action per model row and uses trailing secondary actions.
- Accessibility permission is only treated as blocking when output mode is Paste.
- Privacy page clearly states the local-first guarantee and exposes version/build plus Copy diagnostics.
- All common tasks are completable with keyboard and VoiceOver.
- Status is never conveyed by color alone.

Verification requirements:
- Manual test matrix for: no models, one model, download in progress, delete selected model, mic denied, accessibility denied with Copy, accessibility denied with Paste, paused, recording, transcribing, preview flow, custom shortcut flow.
- VoiceOver labels and reading order verified on menu bar item, popover, settings panes, model rows, shortcut recorder, and delete alert.
- Full Keyboard Access verified on all major surfaces.
- Appearance checked in light mode, dark mode, increased contrast, differentiate without color, and reduced motion.