Activity Bar — Test proposal

Purpose
Define unit and integration test skeletons that validate Activity Bar behaviors: lifecycle, keyboard navigation, badges, drag & drop visuals, persistence of pinned placeholders, and menu integration.

References
- Activity Bar implementation: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:42)
- Pane composite base: [`src/vs/workbench/browser/parts/paneCompositeBar.ts:1`](src/vs/workbench/browser/parts/paneCompositeBar.ts:1)
- Titlebar menubar integration: [`src/vs/workbench/browser/parts/titlebar/menubarControl.ts:404`](src/vs/workbench/browser/parts/titlebar/menubarControl.ts:404)
- Adapter guide (for mocks): [`product_description/features/workbench/adapter_guides.md:1`](product_description/features/workbench/adapter_guides.md:1)

Test environment
- Unit runner: Jest + jsdom
- Integration runner: Playwright (headful) for keyboard & drag interactions
- Required test doubles (documented in adapter_guides):
  - CompositeBar mock (see CompositeBarAdapter spec)
  - LayoutAdapter mock (in-memory)
  - MenuAdapter mock (SimpleInMemoryMenu)
  - ContextKeyAdapter mock (InMemoryContextKeyAdapter)

Test cases (skeletons)

1) Composite creation lifecycle (unit)
- Setup:
  - Mock IInstantiationService to return a spyable PaneCompositeBar mock.
  - Instantiate ActivitybarPart with the mock paneCompositePart and dependencies.
- Steps:
  - Assert compositeBar is not created initially.
  - Call show(); assert create() called on mock composite.
  - Call hide(); assert dispose/clear called and DOM content cleared.
- Assertions:
  - create called once on show, clear/dispose called on hide.
- References: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:146`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:146)

2) Theme color propagation (unit)
- Setup:
  - Provide a fake IColorTheme that returns specific hex colors for tokens used in ActivityBar.
  - Create compositeBar options via ActivitybarPart.createCompositeBar.
- Steps:
  - Call options.colors(theme) and inspect returned mapping.
- Assertions:
  - Colors for activeForegroundColor, badgeBackground, dragAndDropBorder match expectations.
- References: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:88`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:88)

3) Keyboard navigation (integration)
- Setup:
  - Render activity bar DOM with compact menu present and composite container.
- Steps:
  - Focus the menubar; send Down/Right key; assert focus moves into the activity icons.
  - From activity icons, send Up/Left key; assert focus returns to menubar.
- Assertions:
  - Focus transitions match described behavior.
- References: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:293`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:293)

4) Context menu composition (unit)
- Setup:
  - Mock IMenuService to return menu actions for MenuId.ActivityBarPositionMenu.
- Steps:
  - Call getActivityBarContextMenuActions() and collect actions.
- Assertions:
  - Includes SubmenuAction 'Activity Bar Position' and ToggleSidebarPosition action; includes ToggleSidebarVisibility when part === SIDEBAR.
- References: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:369`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:369)

5) Drag & drop visuals (integration)
- Setup:
  - Real DOM compositeBar (or faithful DOM shim); provide theme color for ACTIVITY_BAR_DRAG_AND_DROP_BORDER.
- Steps:
  - Simulate dragenter/dragover events over an activity icon.
- Assertions:
  - Composite bar shows drag overlay/border with color matching theme token.
- References: color mapping: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:88`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:88)

6) Persistence of pinned viewlets (integration)
- Setup:
  - Use LayoutAdapter mock and Storage mock for profile persistence.
- Steps:
  - Pin/unpin view containers and simulate restart (recreate ActivitybarPart).
- Assertions:
  - Previously pinned order restored from storage keys: `workbench.activity.pinnedViewlets2`.
- References: storage keys: [`src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:46`](src/vs/workbench/browser/parts/activitybar/activitybarPart.ts:46)

Test scaffolding notes
- Keep tests small and focused; isolate external services with mocks.
- For integration tests that rely on browser behavior (drag, keyboard), run under Playwright with a minimal HTML host that mounts the relevant DOM nodes and wires basic mock services.

Deliverables
- Jest unit test files:
  - product_description/test-proposals/activitybar.unit.test.js (skeleton with mocks)
- Playwright integration test:
  - product_description/test-proposals/activitybar.integration.spec.js (skeleton)
- Mock adapters documentation:
  - product_description/test-proposals/mocks/README.md (reference to adapter guide)

Next actions
- Create the test skeleton files above if you want me to populate them.
- Otherwise I will continue documenting remaining Workbench parts (status bar, dialogs, notifications) per plan.
