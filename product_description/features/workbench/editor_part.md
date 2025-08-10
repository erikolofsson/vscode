# Workbench — Editor Part

Summary
- The Editor Part hosts editor groups, the grid layout, and manages editor lifecycles (open, close, move, merge, restore). It is the core of multi-editor UX (tabs, groups, split, maximize/expand, centered layout).

Primary responsibilities
- Manage multiple editor groups and their grid layout, including serialization and restoration.
- Provide APIs for group operations: add/remove/move/copy/merge/split/arrange/size.
- Handle drag & drop into the editor, focused group activation, centered layout and maximize/expand behaviors.
- Emit editor/group lifecycle events for other subsystems and persist UI state.

Key source anchors (read during analysis)
- [`src/vs/workbench/browser/parts/editor/editorPart.ts`](src/vs/workbench/browser/parts/editor/editorPart.ts:86)
- Grid serialization and restore: [`SerializableGrid`](src/vs/workbench/browser/parts/editor/editorPart.ts:1211)
- Group creation & lifecycle: [`doCreateGroupView()`](src/vs/workbench/browser/parts/editor/editorPart.ts:629)
- Drop target & DnD overlay: [`createEditorDropTarget()`](src/vs/workbench/browser/parts/editor/editorPart.ts:968)

Public APIs and extension points
- Implements IEditorPart and IEditorGroupsView; used by services that need to open editors, query groups, or manipulate layout programmatically.
- Methods of interest:
  - addGroup / removeGroup / moveGroup / copyGroup / mergeGroup / mergeAllGroups
  - arrangeGroups / toggleMaximizeGroup / toggleExpandGroup / setGroupOrientation
  - applyLayout / getLayout / applyState / createEditorDropTarget
- Event hooks exposed: onDidFocus, onDidLayout, onDidChangeActiveGroup, onDidAddGroup, onDidRemoveGroup, onDidMoveGroup, onDidChangeGroupMaximized, onDidChangeEditorPartOptions.

UI flows and lifecycles
- Creation
  - EditorPart creates a SerializableGrid and an initial EditorGroup on first render (createContentArea). If saved UI state exists, it attempts to restore the previous grid and MRU state.
- Group operations
  - Groups are represented by EditorGroupView instances. Adding a group creates a new EditorGroupView and updates the grid widget. Events (onDidAddGroup) are fired and UI updated (notifyGroupIndexChange).
- Active group handling
  - Tracks activeGroup and maintains mostRecentActiveGroups for MRU ordering. Activating a group moves the host window to front unless preserveWindowOrder is set.
- Restore & state
  - UI state (serialized grid + active group + MRU) is persisted and restored via workspace/profile mementos. Restore includes fallback and error handling on corrupt state.

Data model & serialization
- IEditorPartUIState contains:
  - serializedGrid: output of SerializableGrid.serialize()
  - activeGroup: GroupIdentifier
  - mostRecentActiveGroups: GroupIdentifier[]
- SerializableGrid captures nested branch nodes and view nodes; editor group models (ISerializedEditorGroupModel) are embedded to restore open editors and per-editor metadata.

Drag & drop and DnD brokering
- EditorPart registers an EditorDropTarget and integrates CompositeDragAndDropObserver to show overlay feedback, set dropEffect, and open parts on proximity (timeout-based open when dragging near edges).
- Handles both editor-internal drops and external composite/view drops — when a composite or view is dropped, it delegates to ViewDescriptorService to move containers/views and opens the target composite.

Layout, centered view & constraints
- Uses CenteredViewLayout to support centered editor UIs and toggling (centerLayout / isLayoutCentered).
- Grid supports arrangements (EVEN, MAXIMIZE, EXPAND) and view sizing strategies (Sizing.Distribute / Split / Auto).
- Boundary sash information is kept and re-used across grid widget reinstantiations.

Theming tokens and styles
- Uses theme tokens for borders/backgrounds: `EDITOR_GROUP_BORDER`, `EDITOR_PANE_BACKGROUND`. EditorPart passes theme-derived styles into grid and centered layout so separators and backgrounds match the current theme.

Events and telemetry hooks
- Fires many granular events useful for plugins/tests: focus, layout changes, active group changes, group index/label/lock events, group maximized toggle.
- Command execution and other user actions routed via services that may emit telemetry elsewhere.

Persistence keys
- Editor UI state: `editorpart.state` (workspace memento)
- Centered view state: `editorpart.centeredview` (profile memento)

Tests to add / verify
- Unit tests
  - Serialization round-trip for complex nested grid layouts and per-group editor models.
  - MRU list maintenance and active group restoration correctness.
  - applyState / applyEmptyState behavior and atomicity (events paused/resumed in correct order).
- Integration / UI tests
  - Drag & drop overlay behavior and auto-open-on-proximity timeouts.
  - Group add/remove/move/merge UI flows and focus restoration.
  - Centered layout toggle and maximize/expand behaviors across orientations.

Porting notes and risks
- Grid serialization fidelity is crucial — the serialized structure is nested and must be reproduced with exact semantics to allow state restore across versions.
- EditorGroupView behavior includes many semantics (sticky editors, pinned state, per-editor indices) that are encoded into serialized models — careful mapping required during port.
- The EditorPart depends on many platform services: InstantiationService, ThemeService, ConfigurationService, StorageService, HostService, ContextKeyService. Provide adapter contracts or a lightweight host implementation to satisfy these.
- Drag & drop behavior mixes timing and DOM overlays; ensure the port replicates CompositeDragAndDropObserver and overlay semantics (timeout thresholds, proximity heuristics).

Adapter recommendations (doc-only)
- EditorGrid adapter
  - Provide nested branch nodes, view add/remove/move APIs, serialize/deserialize, layout APIs (maximize/expand/distribute), and boundary sash support.
- EditorGroupView adapter
  - Encapsulate editors list, open/close/pinning, sticky editors semantics, focus handling, and events for active editor changes.
- HostService adapter
  - Provide moveTop(window) semantics used when activating groups to bring window to front (used for multi-window scenarios).

Quick references
- EditorPart class: [`src/vs/workbench/browser/parts/editor/editorPart.ts`](src/vs/workbench/browser/parts/editor/editorPart.ts:86)
- Grid widget & serialization: [`SerializableGrid`](src/vs/workbench/browser/parts/editor/editorPart.ts:1211)
- Drop handling: [`createEditorDropTarget()`](src/vs/workbench/browser/parts/editor/editorPart.ts:968)

Next recommended docs
- Detailed "Grid serialization and EditorGroup model" doc with examples of serialized JSON and migration notes.
- Cross-link with "Views & Viewlets" and "Panels & Layout" docs to show how editors interact with composites and panels.

Status
- Drafted based on reading [`src/vs/workbench/browser/parts/editor/editorPart.ts`](src/vs/workbench/browser/parts/editor/editorPart.ts:1) and its serialized grid logic.
