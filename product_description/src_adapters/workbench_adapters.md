# Workbench — Adapter Contracts (host-facing)

Purpose

This document defines minimal adapter contracts required by the Workbench parts to run inside an external host. The goal is documentation-only: specify method names, events and expected semantics so a host implementer can provide thin shims.

Scope

- Sidebar / Panel / Composites & Activity Bar
- Views & View containers
- Notifications & Statusbar
- Storage and Authentication helpers
- DnD helper

Conventions

- Each adapter is described with responsibilities, required methods/events and short notes.
- Any "language construct" below (method names) is shown as a clickable reference to this file, per repository documentation conventions.

Adapters

1) PaneCompositePartServiceAdapter

Responsibilities:
- Surface open/get/pinned/visible APIs for composites in different locations (sidebar/panel/auxiliary).

Required API:
- [`PaneCompositePartServiceAdapter.openPaneComposite()`](product_description/src_adapters/workbench_adapters.md:1) — (id?: string, location: string, focus?: boolean) => Promise<void | { id: string }>
- [`PaneCompositePartServiceAdapter.getActivePaneComposite()`](product_description/src_adapters/workbench_adapters.md:1) — (location: string) => { id?: string }
- [`PaneCompositePartServiceAdapter.getPaneComposites()`](product_description/src_adapters/workbench_adapters.md:1) — (location: string) => Array<{ id: string; title: string; icon?: string }>
- [`PaneCompositePartServiceAdapter.getPinnedPaneCompositeIds()`](product_description/src_adapters/workbench_adapters.md:1) — (location: string) => string[]
- [`PaneCompositePartServiceAdapter.onDidPaneCompositeOpen`](product_description/src_adapters/workbench_adapters.md:1) — Event<{ id: string; location: string }>
- [`PaneCompositePartServiceAdapter.onDidPaneCompositeClose`](product_description/src_adapters/workbench_adapters.md:1) — Event<{ id: string; location: string }>

Notes:
- Semantics should match [`src/vs/workbench/browser/parts/paneCompositePartService.ts:1`].

2) ViewDescriptorAdapter

Responsibilities:
- Provide descriptors for view containers and individual views; support moving views between containers and querying movement permissions.

Required API:
- [`ViewDescriptorAdapter.getViewContainerById()`](product_description/src_adapters/workbench_adapters.md:1) — (id: string) => { id: string; title: string }
- [`ViewDescriptorAdapter.getViewDescriptorById()`](product_description/src_adapters/workbench_adapters.md:1) — (id: string) => { id: string; name: string; canMoveView?: boolean; weight?: number }
- [`ViewDescriptorAdapter.getViewContainerModel()`](product_description/src_adapters/workbench_adapters.md:1) — (containerId: string) => { visibleViewDescriptors: any[]; allViewDescriptors: any[]; move(viewId: string, toViewId: string): void; setVisible(viewId: string, visible: boolean): void }
- [`ViewDescriptorAdapter.moveViewsToContainer()`](product_description/src_adapters/workbench_adapters.md:1) — (views: Array<{ id: string }>, destinationContainerId: string, visibility?: string, source?: string) => void
- [`ViewDescriptorAdapter.getViewContainerLocation()`](product_description/src_adapters/workbench_adapters.md:1) — (containerId: string) => 'sidebar' | 'panel' | 'auxiliary'

Notes:
- Mirrors behaviors used in [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`].

3) StorageAdapter

Responsibilities:
- Provide get/set for scoped keys (profile, workspace, machine) with typed helpers.

Required API:
- [`StorageAdapter.get()`](product_description/src_adapters/workbench_adapters.md:1) — (key: string, scope: 'profile'|'workspace'|'global') => string | number | boolean | undefined
- [`StorageAdapter.getNumber()`](product_description/src_adapters/workbench_adapters.md:1) — (key: string, scope) => number | undefined
- [`StorageAdapter.getBoolean()`](product_description/src_adapters/workbench_adapters.md:1) — (key: string, scope) => boolean
- [`StorageAdapter.store()`](product_description/src_adapters/workbench_adapters.md:1) — (key: string, value: any, scope: 'profile'|'workspace'|'global') => void
- [`StorageAdapter.onDidChangeValue`](product_description/src_adapters/workbench_adapters.md:1) — Event fired when a stored key changes

Notes:
- Keys used by workbench include `workbench.activity.showAccounts`, `${containerId}.numberOfVisibleViews`, and layout keys. See [`src/vs/workbench/browser/parts/sidebar/sidebarPart.ts:1`] and others.

4) NotificationsModelAdapter

Responsibilities:
- Surface notification creation, update, close and events for center/toasts and list filtering.

Required API:
- [`NotificationsModelAdapter.addNotification()`](product_description/src_adapters/workbench_adapters.md:1) — (n: { message: string; severity?: string; actions?: any[]; source?: string; progress?: boolean }) => { id: string }
- [`NotificationsModelAdapter.closeNotification()`](product_description/src_adapters/workbench_adapters.md:1) — (id: string) => void
- [`NotificationsModelAdapter.onDidAddNotification`](product_description/src_adapters/workbench_adapters.md:1) — Event<{ id: string }>
- [`NotificationsModelAdapter.onDidRemoveNotification`](product_description/src_adapters/workbench_adapters.md:1) — Event<{ id: string }>
- [`NotificationsModelAdapter.getNotifications()`](product_description/src_adapters/workbench_adapters.md:1) — () => Array<any>

Notes:
- Preserve spam protection and purge timeouts behavior described in [`src/vs/workbench/browser/parts/notifications/notificationsToasts.ts:1`] and [`src/vs/workbench/browser/parts/notifications/notificationsCenter.ts:1`].

5) StatusbarAdapter

Responsibilities:
- Add/update/remove status bar entries and support priorities/alignments.

Required API:
- [`StatusbarAdapter.addEntry()`](product_description/src_adapters/workbench_adapters.md:1) — (id: string, entry: { text?: string; ariaLabel?: string; alignment?: 'left'|'right'; priority?: number }) => { dispose(): void; update(entryPartial): void }
- [`StatusbarAdapter.setHidden()`](product_description/src_adapters/workbench_adapters.md:1) — (hidden: boolean) => void
- [`StatusbarAdapter.onDidClickEntry`](product_description/src_adapters/workbench_adapters.md:1) — Event<{ id: string }>

Notes:
- Follow semantics of [`src/vs/workbench/browser/parts/statusbar/statusbarPart.ts:1`].

6) ActivityAdapter

Responsibilities:
- Provide activity counts, badge info and on-change events for composites.

Required API:
- [`ActivityAdapter.getActivity()`](product_description/src_adapters/workbench_adapters.md:1) — (itemId: string) => Array<{ count?: number; priority?: number; class?: string }>
- [`ActivityAdapter.onDidChangeActivity`](product_description/src_adapters/workbench_adapters.md:1) — Event<{ id: string }>

Notes:
- Integrates with GlobalCompositeBar and CompositeBar actions. See [`src/vs/workbench/browser/parts/globalCompositeBar.ts:1`] and [`src/vs/workbench/browser/parts/compositeBar.ts:1`].

7) AuthenticationAdapter / AccountsAdapter

Responsibilities:
- Enumerate accounts, sessions, sign-out flow and session change events.

Required API:
- [`AccountsAdapter.getAccounts()`](product_description/src_adapters/workbench_adapters.md:1) — () => Array<{ providerId: string; label: string; canSignOut: boolean }>
- [`AccountsAdapter.onDidChangeSessions`](product_description/src_adapters/workbench_adapters.md:1) — Event<{ providerId: string; added?: any[]; removed?: any[]; changed?: any[] }>
- [`AccountsAdapter.signOut()`](product_description/src_adapters/workbench_adapters.md:1) — (providerId: string, accountLabel: string) => Promise<void>
- [`AccountsAdapter.getEmbeddedSessionInfo()`](product_description/src_adapters/workbench_adapters.md:1) — () => Promise<{ id: string; canSignOut?: boolean } | undefined>

Notes:
- Behavior matches expectations in [`src/vs/workbench/browser/parts/globalCompositeBar.ts:1`].

8) DnDAdapter (helpers)

Responsibilities:
- Toggle dropEffect, provide drag payloads for 'view' and 'composite', and allow registration for draggable/target elements.

Required API:
- [`DnDAdapter.registerDraggable()`](product_description/src_adapters/workbench_adapters.md:1) — (element: HTMLElement, getData: () => any) => IDisposable
- [`DnDAdapter.registerTarget()`](product_description/src_adapters/workbench_adapters.md:1) — (element: HTMLElement, callbacks: { onDragEnter?, onDragOver?, onDragLeave?, onDrop? }) => IDisposable
- [`DnDAdapter.toggleDropEffect()`](product_description/src_adapters/workbench_adapters.md:1) — (dataTransfer: DataTransfer, effect: 'move'|'copy', enable: boolean) => void

Notes:
- See [`src/vs/workbench/browser/parts/views/viewPaneContainer.ts:1`] and [`src/vs/workbench/browser/parts/compositeBar.ts:1`] for behavior.

Minimal stubs & errors

- Adapters can throw when unimplemented, but host should provide graceful fallbacks for non-critical services (e.g., ActivityAdapter missing => no badges).
- Prefer evented patterns (onDidChangeX) to polling.

Security & privacy notes

- Authentication and profile adapters must not expose secrets; only surface display metadata and provide sign-out operations delegated to host.
- Storage adapters should respect scope: PROFILE vs WORKSPACE vs MACHINE.

Next steps

- Create individual adapter README files with example TypeScript shim implementations under `product_description/src_adapters/` (this document will be used as the canonical contract).
- Draft unit/integration tests that mock these adapters.

Cross references

- Composite & Activity bar doc: [`product_description/features/workbench/composites_and_activitybar.md:1`]
- Sidebar/Panel/Views doc: [`product_description/features/workbench/sidebar_panel_and_views.md:1`]
- Notifications doc: [`product_description/features/workbench/notifications.md:1`]

End of adapter contracts.
