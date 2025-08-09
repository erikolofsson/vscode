# Workbench — Panels & Layout

Summary
- This document analyzes the Panel subsystem and related layout actions that control the primary panel area (bottom/right/top/left) and its behavior (position, alignment, maximization, composite bar).
- Primary sources: [`src/vs/workbench/browser/parts/panel/panelActions.ts:1`](src/vs/workbench/browser/parts/panel/panelActions.ts:1) and [`src/vs/workbench/browser/parts/panel/panelPart.ts:1`](src/vs/workbench/browser/parts/panel/panelPart.ts:1).

Goals
- Capture responsibilities, lifecycles, public APIs/events, and UI flows for the panel.
- Identify how panel actions register with menus/keybindings and how layout service methods are expected to work.
- Call out porting risks and adapter requirements for hosts implementing a subset of VS Code workbench.

Responsibilities
- Panel action registration and wiring for toggling, focusing, positioning, alignment, maximizing and moving views between panel & auxiliary bar: see [`src/vs/workbench/browser/parts/panel/panelActions.ts:1`](src/vs/workbench/browser/parts/panel/panelActions.ts:1).
- Panel part UI, composite bar options, sizing limits and styling integration with theme colors: see [`src/vs/workbench/browser/parts/panel/panelPart.ts:1`](src/vs/workbench/browser/parts/panel/panelPart.ts:1).
- Context menu augmentation for panel title actions (position, alignment, show/hide labels) and additional submenu items are provided by panel composite bar options (`panelPart.getCompositeBarOptions`).

Key Concepts & Patterns
- LayoutService-driven: layoutService exposes panel position, alignment, hidden/visible state and maximized toggles; actions call layoutService methods (e.g., setPartHidden, setPanelPosition, setPanelAlignment, toggleMaximizedPanel). See actions in [`panelActions.ts:66`](src/vs/workbench/browser/parts/panel/panelActions.ts:66) and other action handlers.
- CompositeBar integration: PanelPart extends AbstractPaneCompositePart and uses a pane composite bar to render the list of available panel view containers. Composite bar options (colors, orientation, placeholder keys, hover behavior) are configured in [`panelPart.ts:132`](src/vs/workbench/browser/parts/panel/panelPart.ts:132).
- MenuRegistry/MenuId wiring: many actions are registered with MenuRegistry and MenuId (MenubarAppearanceMenu, LayoutControlMenu, PanelTitle, PanelPositionMenu, PanelAlignmentMenu) — essential to produce UI menus and context actions. See menu registrations in [`panelActions.ts:183`](src/vs/workbench/browser/parts/panel/panelActions.ts:183).
- Context keys controlling action visibility: PanelVisibleContext, PanelPositionContext, PanelAlignmentContext, PanelMaximizedContext, IsAuxiliaryWindowContext are used to show/hide or toggle action states.

Lifecycles
- Action registration at startup: registerAction2 calls create global or menu-bound actions so commands are available early (`panelActions.ts`).
- Panel part lifecycle: PanelPart is constructed and registered as a workbench part (Parts.PANEL_PART). It receives theme updates (`updateStyles`), layout events (`layout(width,height,top,left)`) and configuration changes (e.g., `workbench.panel.showLabels`) to recompute composite bar rendering (`panelPart.ts:109`).
- Composite selection persistence: PanelPart uses storage keys to persist the active panel id across sessions (see `PanelPart.activePanelSettingsKey`).

Public APIs & Events (expected from host or runtime)
- IWorkbenchLayoutService:
  - setPartHidden(isHidden, partId)
  - isVisible(partId)
  - setPanelPosition(Position)
  - getPanelPosition()
  - setPanelAlignment(PanelAlignment)
  - getPanelAlignment()
  - toggleMaximizedPanel()
  - isPanelMaximized()
  - These are called by actions in [`panelActions.ts`](src/vs/workbench/browser/parts/panel/panelActions.ts:1).
- IPaneCompositePartService / pane composite APIs for focusing the active panel composite and retrieving active pane composite (`panelActions.ts:113-125`).
- MenuService/MenuRegistry and ContextKeyService to resolve menus and action toggles.

UI Flows & Behaviors
- Toggle Panel: "Toggle Panel Visibility" toggles hidden/visible state and is bound to Ctrl/Cmd+J by default (`panelActions.ts:30-72`).
- Focus into Panel: ensures the panel is visible and focuses the active composite (`panelActions.ts:99-126`).
- Positioning: Actions to move the panel to top/left/right/bottom call layoutService.setPanelPosition; menu entries reflect toggled state (`panelActions.ts:128-216`).
- Alignment: Panel alignment actions set alignment (left/right/center/justify); maximize action is constrained by alignment & position (`panelActions.ts:176-241`, `:276-315`).
- Maximization: Toggle maximized panel action supports maximize/restore, with precondition checks and UX notifications for unsupported combinations (`panelActions.ts:276-315`).
- Move views between Panel and Auxiliary/Side bar: MovePanelToSidePanelAction and MoveSidePanelToPanelAction move view containers between locations and ensure parts are visible afterward (`panelActions.ts:341-424`).
- Composite bar: Panel shows composite bar in the title area (icons/labels/hovers), with configurable behavior for showing labels via `workbench.panel.showLabels` setting; context menu includes panel position/align and a toggle to show labels (`panelPart.ts:132-190`).

Descriptor & Registration Patterns
- Actions use registerAction2 and MenuRegistry.appendMenuItem to integrate into menubar, layout control menus and panel title menus — a host must provide MenuService and MenuRegistry semantics.
- The panel uses AbstractPaneCompositePart conventions (persistence keys, active composite context keys) — hosts should adapt similar part lifecycle and composite service.

Porting Risks & Suggested Mitigations
1) Layout API mismatch
- Risk: Host may not provide the same layout APIs (setPanelPosition, setPanelAlignment, toggleMaximizedPanel, isPanelMaximized).
- Mitigation: Provide a layout adapter implementing these methods. Fallback behavior: if alignment is not supported, disable maximize and provide a notification to users.

2) Menu & ContextKey Engine dependency
- Risk: Panel actions rely on MenuRegistry, MenuId, and ContextKeyExpr logic for toggled states and menu composition.
- Mitigation: Implement a minimal MenuAdapter and ContextKeyAdapter to evaluate menu preconditions and produce primary/secondary actions for menus used by the panel.

3) Composite bar and pane composite integration
- Risk: AbstractPaneCompositePart and IPaneCompositePartService expect a host composite system (switching composites, persisting active ids).
- Mitigation: Implement PaneCompositeAdapter that can provide getActivePaneComposite(ViewContainerLocation.Panel) and focus composite; or provide a minimal shim that maps composite ids to host UI components.

4) Theming & CSS variables
- Risk: PanelPart uses theme tokens (PANEL_BACKGROUND, PANEL_BORDER, etc.) to style the panel container.
- Mitigation: Provide ThemeAdapter that returns color tokens or supply default CSS that approximates the expected styling.

5) Notifications and UX fallbacks
- Risk: Some actions show notifications if unsupported (e.g., maximizing with non-center alignment).
- Mitigation: Provide NotificationAdapter or map to host alert mechanism.

Adapter / Shim Suggestions
- LayoutAdapter: implement IWorkbenchLayoutService surface used by panel actions.
- MenuAdapter + ContextKeyAdapter: evaluate menu preconditions and return actions/menu structure for MenuId values.
- PaneCompositeAdapter: minimal implementation of IPaneCompositePartService to query and focus active composites.
- ThemeAdapter: provide color tokens and file icon behaviors.
- NotificationAdapter: host notification mapping for warn/error/info.

Tests & QA
- Unit:
  - togglePanel action toggles layoutService.setPartHidden with correct boolean and toggled menu state.
  - position/alignment actions call setPanelPosition/setPanelAlignment with expected enum values.
  - maximize action validates precondition and toggles state correctly; warns when unsupported.
- Integration:
  - Move view containers: assert viewDescriptorService.moveViewContainerToLocation called and destination part made visible.
  - Panel composite bar renders icons/labels respect `workbench.panel.showLabels` setting and persists active composite key.
- UX / Smoke:
  - Confirm focusPanel focuses composite when panel hidden or visible.
  - Confirm composite bar context menu contains position and align submenu entries.

Implementation Callouts (important code locations)
- Toggle/Focus panel actions: [`src/vs/workbench/browser/parts/panel/panelActions.ts:30`](src/vs/workbench/browser/parts/panel/panelActions.ts:30)
- Position & alignment action configs and menu items: [`src/vs/workbench/browser/parts/panel/panelActions.ts:160`](src/vs/workbench/browser/parts/panel/panelActions.ts:160)
- Toggle Maximize and UX checks: [`src/vs/workbench/browser/parts/panel/panelActions.ts:276`](src/vs/workbench/browser/parts/panel/panelActions.ts:276)
- Moving view containers between panel and auxiliary side bar: [`src/vs/workbench/browser/parts/panel/panelActions.ts:341`](src/vs/workbench/browser/parts/panel/panelActions.ts:341)
- PanelPart composite options and styling integration: [`src/vs/workbench/browser/parts/panel/panelPart.ts:132`](src/vs/workbench/browser/parts/panel/panelPart.ts:132)
- Panel layout sizing logic and preferred sizes: [`src/vs/workbench/browser/parts/panel/panelPart.ts:39`](src/vs/workbench/browser/parts/panel/panelPart.ts:39)

References
- Panel actions: [`src/vs/workbench/browser/parts/panel/panelActions.ts:1`](src/vs/workbench/browser/parts/panel/panelActions.ts:1)
- Panel part implementation: [`src/vs/workbench/browser/parts/panel/panelPart.ts:1`](src/vs/workbench/browser/parts/panel/panelPart.ts:1)
- Related composite APIs: search `paneCompositePart` and `paneCompositeBar` under `src/vs/workbench/browser/parts/`.

Next steps
- Add this doc to MANIFEST and update TODOs. Continue reading other layout parts (sidebar, titlebar, statusbar) in batches of ~5 files for the wider Workbench Layout doc.
