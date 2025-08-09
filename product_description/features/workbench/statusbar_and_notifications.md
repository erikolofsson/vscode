# Workbench — Status Bar and Notifications

Summary
- The status bar presents short, actionable pieces of information and micro-controls at the bottom of the workbench. Notifications are surfaced via the notifications UI (center / toasts / actions) and integrate with the status bar (badges, beaks).
- This document synthesizes the status bar implementation, view-model and persistence, theming tokens, keyboard interactions, and the notifications actions surface discovered in the source tree.

Primary responsibilities
- Host an extensible registry of status entries that can be added/updated/removed by services and extensions.
- Provide left/right alignment, priority and relative placement semantics for entries.
- Handle visibility preferences, compact grouping, hover/tooltips and entry-level commands.
- Expose focus and keyboard navigation for accessibility and keyboard users.
- Coordinate notifications-related actions (clear, expand, hide, do-not-disturb) and wire them to commands.

Key source anchors (read during analysis)
- Status bar implementation and part: [`StatusbarPart()`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:119)
- Status bar view-model and persistence: [`StatusbarViewModel()`](src/vs/workbench/browser/parts/statusbar/statusbarModel.ts:23)
- Individual status entry renderer / interactions: [`StatusbarEntryItem()`](src/vs/workbench/browser/parts/statusbar/statusbarItem.ts:30)
- Status bar actions and keybindings: [`statusbarActions.ts`](src/vs/workbench/browser/parts/statusbar/statusbarActions.ts:1)
- Notifications actions surface (actions wired to commands): [`notificationsActions.ts`](src/vs/workbench/browser/parts/notifications/notificationsActions.ts:1)

Public APIs and extension points
- IStatusbarService — global service to add and update entries. Consumers call addEntry(entry, id, alignment, priorityOrLocation) to create an entry; returns an accessor to update/dispose the entry. See: [`StatusbarService()`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:755)
- Scoped status bar containers — hosts can create auxiliary statusbar parts for isolated containers: [`createAuxiliaryStatusbarPart()`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:779)
- Entry contract: `IStatusbarEntry` (shape referenced/used across parts) — supplies text, tooltip, command, colors, and progressive / beak hints. See usage in: [`StatusbarEntryItem()`](src/vs/workbench/browser/parts/statusbar/statusbarItem.ts:30)

UI flows and lifecycles
- Registration
  - Callers register entries via `IStatusbarService.addEntry(...)`. If the part is not yet created, entries are queued as pending and materialized when the statusbar part is created (pendingEntries flow in [`statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:232)).
- Rendering
  - View model (`StatusbarViewModel`) holds an ordered list of entries and is responsible for sorting by numeric priority or placing entries relative to other entries (relative priority). See [`statusbarModel.ts`](src/vs/workbench/browser/parts/statusbar/statusbarModel.ts:256).
  - UI containers: left `.left-items.items-container` and right `.right-items.items-container` (flex layout, right side reversed) — entries are appended according to alignment and computed order. See creation in [`statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:412).
- Entry updates
  - Each registered entry is represented by a `StatusbarEntryItem` instance which manages label, optional progress codicon, hover, command wiring, background/foreground color listeners, and beak display. See [`statusbarItem.ts`](src/vs/workbench/browser/parts/statusbar/statusbarItem.ts:30).
- Compact grouping
  - Entries can be marked `compact` (location-based placement) causing CSS classes (`compact-left` / `compact-right`) to draw them closer and install group hover highlighting. See compact handling in [`statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:502).
- Keyboard & focus
  - Status bar focus and navigation are exposed via commands/keybindings (Left/Right/Up/Down/Home/End/Escape). Commands are registered in [`statusbarActions.ts`](src/vs/workbench/browser/parts/statusbar/statusbarActions.ts:63).

Persistence and user preferences
- Hidden entries are persisted in the profile storage key: `workbench.statusbar.hidden` (see `StatusbarViewModel.HIDDEN_ENTRIES_KEY`) and synchronized using the storage service. See: [`statusbarModel.ts`](src/vs/workbench/browser/parts/statusbar/statusbarModel.ts:25).
- Entry overrides: runtime code and scoped services can call `overrideEntry(id, override)` to temporarily change appearance for a specific entry (see [`statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:210)).

Theming tokens and style concerns
- The status bar uses theme tokens to compute background/foreground/border and focus outlines:
  - Examples: `STATUS_BAR_BACKGROUND`, `STATUS_BAR_FOREGROUND`, `STATUS_BAR_ITEM_HOVER_BACKGROUND`, `STATUS_BAR_ITEM_COMPACT_HOVER_BACKGROUND`, `STATUS_BAR_BORDER`, `STATUS_BAR_FOCUS_BORDER`. See references in [`statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:16) and dynamic stylesheet setup in [`statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:660).
- Entry-level colors can be ThemeColor or literal values; the renderer subscribes to theme changes to update live. See color handling in [`statusbarItem.ts`](src/vs/workbench/browser/parts/statusbar/statusbarItem.ts:246).

Notifications — what was found
- The repository contains a notifications actions surface file: [`notificationsActions.ts`](src/vs/workbench/browser/parts/notifications/notificationsActions.ts:1) which defines
  - Clear / Clear All actions, Expand/Collapse, Hide Notifications Center, Do Not Disturb toggles and copy message action.
  - These actions invoke commands such as `CLEAR_NOTIFICATION`, `CLEAR_ALL_NOTIFICATIONS`, and `TOGGLE_DO_NOT_DISTURB_MODE` defined elsewhere (`notificationsCommands.js`).
- Note: the main UI parts for notifications (part/model) were not present at the expected paths in this checkout when reading. The actions file exists but the expected `notificationsPart.ts` / `notificationsModel.ts` were not found during the scan. Next step should be to locate the notifications part code (it may be in a different folder or under `contrib/notifications`).

Tests and verification checklist (recommended)
- Unit tests
  - StatusbarViewModel ordering and sorting: priorities (number vs relative), compact grouping, markFirstLastVisibleEntry semantics.
  - Persistence: hidden entries persisted/restored using `workbench.statusbar.hidden`.
  - StatusbarEntryItem behavior: tooltip equality, command execution path and error handling (telemetry + notification on error), background/foreground ThemeColor updates.
- Integration / UI tests
  - Keyboard navigation (Left/Right/Home/End/Escape) focusing first/last and cycling entries.
  - Compact grouping hover behavior (group hover highlight).
  - Context menu on statusbar shows per-entry toggle actions and Manage/Hide actions (see context menu creation in [`statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:574)).
- Notifications tests
  - Action wiring: Clear / Clear All / Expand / Collapse / Do Not Disturb command execution and expected model state changes.
  - Notifications center visibility and interactions with status bar beaks (if present).

Porting notes and risks
- Heavy DI and service reliance
  - Status bar relies on platform services (InstantiationService, ThemeService, StorageService, ContextKeyService, ContextMenuService) — host must provide DI adapters or lightweight equivalents.
- Tooltip and hover integration
  - Hover setup uses the platform hover service and provides managed hover with actions. Porting must include a hover delegate that supports action buttons and focus/sticky behavior.
- Priority/relative placement logic
  - Sorting has nuanced rules (primary/secondary priorities and relative-location insertion). Port implementers should retain stable sort semantics and tests to validate ordering.
- Theming subtleties
  - The status bar uses dynamic style sheets and theme tokens for focus outlines and beak border color. Hosts must expose theme tokens and a way to compute opaque backgrounds (for correct beak/border drawing).
- Missing notifications part
  - The notifications actions are present but the core notifications part/model were not found at the expected path in this repository snapshot. Porting the notifications UI will require locating those sources or re-implementing the notifications center, toasts, and command handlers.

Adapter recommendations (documentation-only)
- Provide a minimal StatusbarAdapter that implements:
  - addEntry / update / dispose lifecycle and exposes a DOM container for left/right placement.
  - Storage adapter to persist hidden entries.
  - Theme adapter to resolve theme tokens and subscribe to theme changes (for ThemeColor support).
  - Hover adapter to render managed hover content and support action buttons.
- Provide a NotificationsAdapter that:
  - Exposes commands for CLEAR_NOTIFICATION, CLEAR_ALL_NOTIFICATIONS, EXPAND/COLLAPSE, HIDE_NOTIFICATIONS_CENTER and DO_NOT_DISTURB toggles.
  - Provides a notifications model (queue + visibility + severity + source) and a center UI to present messages and actions.

Next steps (recommended)
1. Locate and read the notifications part/model implementation (the scan found `notificationsActions.ts` but not the part/model). If they exist under a different path, read them to complete this doc.
2. Add a focused "Notifications" feature doc that documents the center/toast lifecycles, queueing, severity rules, and DND behavior.
3. Create unit/integration test proposals for statusbar and notifications (map existing test files or add new ones under the tests tree).
4. Add a product_description TODO and update MANIFEST.md to include this feature doc (I will update the manifest next).

Status
- Status bar: documented based on `statusbarPart.ts`, `statusbarModel.ts`, `statusbarItem.ts` and `statusbarActions.ts`.
- Notifications: actions documented (`notificationsActions.ts`) but notifications part/model not found in the scan — further reads required.

References (quick links to read files used)
- [`src/vs/workbench/browser/parts/statusbar/statusbarPart.ts`](src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:1)
- [`src/vs/workbench/browser/parts/statusbar/statusbarModel.ts`](src/vs/workbench/browser/parts/statusbar/statusbarModel.ts:1)
- [`src/vs/workbench/browser/parts/statusbar/statusbarItem.ts`](src/vs/workbench/browser/parts/statusbar/statusbarItem.ts:1)
- [`src/vs/workbench/browser/parts/statusbar/statusbarActions.ts`](src/vs/workbench/browser/parts/statusbar/statusbarActions.ts:1)
- [`src/vs/workbench/browser/parts/notifications/notificationsActions.ts`](src/vs/workbench/browser/parts/notifications/notificationsActions.ts:1)
