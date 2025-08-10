# Workbench — Notifications (Center, Toasts, List, Status)

Summary

The Notifications subsystem surfaces transient and persistent messages to the user via two primary UI surfaces: the Notifications Center (a modal-ish panel listing queued notifications) and Toasts (ephemeral stacked toasts). This doc synthesizes responsibilities, lifecycle, key APIs, theming, persistence, accessibility, and porting notes.

Responsibilities

- Surface notifications from the core INotificationsModel as both toasts and center entries.
- Provide a Notifications Center (expandable list) with header toolbar actions (clear, configure DND, hide).
- Provide stacked Toasts with purge/timeouts, spam protection, and stacking/layout policies.
- Provide a compact Notifications List renderer used by both center and toasts.
- Expose statusbar entry that summarizes unread / in-progress notifications and toggles the center.

Components (implementation)

- Notifications Center — [`src/vs/workbench/browser/parts/notifications/notificationsCenter.ts`](src/vs/workbench/browser/parts/notifications/notificationsCenter.ts:1)
  - Lazily created container, header + toolbar, and a NotificationsList instance.
  - Handles show/hide, layout sizing (max 450x400), title updates, and visibility context key.

- Notifications Toasts — [`src/vs/workbench/browser/parts/notifications/notificationsToasts.ts`](src/vs/workbench/browser/parts/notifications/notificationsToasts.ts:1)
  - Creates ephemeral toast containers, enforces MAX_NOTIFICATIONS (3), severity-based purge timers, spam protection (IntervalCounter), and stacking order.
  - Defers toast creation with scheduleAtNextAnimationFrame to avoid UI jank.

- Notifications List — [`src/vs/workbench/browser/parts/notifications/notificationsList.ts`](src/vs/workbench/browser/parts/notifications/notificationsList.ts:1)
  - Virtualized WorkbenchList wrapper, accessibility provider, context menu (copy message), selection/focus handling and dynamic height updates.

- Notifications Viewer / Renderer — [`src/vs/workbench/browser/parts/notifications/notificationsViewer.ts`](src/vs/workbench/browser/parts/notifications/notificationsViewer.ts:1)
  - Renders individual notification items: severity icons, message (linked text handling + opener service), primary/secondary actions, expand/collapse, progress bar.

- Notifications Status integration — [`src/vs/workbench/browser/parts/notifications/notificationsStatus.ts`](src/vs/workbench/browser/parts/notifications/notificationsStatus.ts:1)
  - Adds a Statusbar entry (bell/bell-dot icons) with tooltip summarizing unread/in-progress counts and Do Not Disturb state. Responsible for transient "status messages" shown on the left of the status bar.

Key runtime concepts & contracts

- Model: INotificationsModel (source of truth for notification items and status messages). Items are INotificationViewItem / NotificationViewItem.
- Visibility model:
  - Toasts suppressed while the Notifications Center is visible.
  - Showing the center marks items as visible in-model (notification.updateVisibility(true)) and clears the unread counter.
- Spam protection: an IntervalCounter prevents showing more than MAX_NOTIFICATIONS in a short interval.
- Purge behavior: non-sticky toasts are automatically removed after severity-specific timeouts (Info/Warning/Error).

Interactions with other services (dependencies)

- IWorkbenchLayoutService — layout changes, awareness of statusbar/titlebar visibility influence available height.
- IInstantiationService — create instances of lists, action runners, and view items.
- INotificationService — provides per-source filters and global Do Not Disturb (NotificationsFilter).
- IStatusbarService — to add the notifications status entry.
- IHostService — used to detect window focus for purge delays.
- AccessibilitySignalService — emitted when clearing notifications.
- IContextMenuService, IKeybindingService, IOpenerService, IHoverService — various UI interactions.

Theme tokens

- NOTIFICATIONS_CENTER_HEADER_FOREGROUND, NOTIFICATIONS_CENTER_HEADER_BACKGROUND, NOTIFICATIONS_CENTER_BORDER — header styling for the center (see [`src/vs/workbench/browser/parts/notifications/notificationsCenter.ts`](src/vs/workbench/browser/parts/notifications/notificationsCenter.ts:1)).
- NOTIFICATIONS_TOAST_BORDER, NOTIFICATIONS_BACKGROUND — toast list background / border (see [`src/vs/workbench/browser/parts/notifications/notificationsToasts.ts`](src/vs/workbench/browser/parts/notifications/notificationsToasts.ts:1)).
- widgetShadow used for drop shadows on both center and toasts.

Commands & Actions

- Clear / Clear All / Expand / Collapse / Hide Center / Toggle Do Not Disturb / Configure per-source (implemented in [`src/vs/workbench/browser/parts/notifications/notificationsActions.ts`](src/vs/workbench/browser/parts/notifications/notificationsActions.ts:1) and wired via NotificationActionRunner / notificationsCommands).
- Statusbar command toggles between SHOW_NOTIFICATIONS_CENTER and HIDE_NOTIFICATIONS_CENTER (see [`src/vs/workbench/browser/parts/notifications/notificationsStatus.ts`](src/vs/workbench/browser/parts/notifications/notificationsStatus.ts:1)).

Context Keys

- NotificationsCenterVisibleContext — center visibility.
- NotificationsToastsVisibleContext — toasts visibility.
- NotificationFocusedContext — focus within notifications list.

Accessibility & keyboard behavior

- NotificationsList provides ARIA roles, an accessibility provider that builds aria-labels with severity prefixes and optional accessible view hint.
- Focus management:
  - When the center/toast gains focus, list.focusFirst() is used.
  - On close, focus is restored to editorGroupService.activeGroup if the center/toast previously contained focus.
- Keyboard: toolbar actions include keybinding labels; list disables selection (only focus) to avoid strong selection behavior.

Persistence & Filters

- Filter model via INotificationService supports per-source filtering and global Do Not Disturb (NotificationsFilter.ERROR used to represent DND).
- The center reacts to filter changes (center hides when the global filter is ERROR).
- No direct on-disk persistence of notification queue is implemented here (notifications are runtime).

Rendering & sizing rules

- Center maximum dimensions: 450x400, but layout takes available workbench dimensions into account and subtracts paddings and visible toolbar/status/title bar heights.
- Toast max width 450 and height adjustments per stack, with golden-ratio based height allocation for multiple toasts.
- NotificationsList computes dynamic height per item based on message overflow and presence of actions/source rows.

Porting notes / adapter recommendations

- Required host contracts:
  - NotificationsModelAdapter: provide an in-memory model emitting onDidChangeNotification and onDidChangeStatusMessage, with items implementing INotificationViewItem behavior (expand/collapse, close, actions, progress).
  - NotificationServiceAdapter: expose filters per source and global Do Not Disturb toggling.
  - StatusbarAdapter: add/remove entries and support IStatusbarEntryAccessor.update().
  - LayoutAdapter: expose main container dimensions and visibility of Parts (title/status).
  - HostServiceAdapter: expose hasFocus and onDidChangeFocus.
  - ActionRunner / Menu wiring: support ActionBar rendering and DropdownMenuActionViewItem patterns or a thin shim.

- UI behavior to reproduce:
  - Toast spam protection and scheduleAtNextAnimationFrame deferred creation — important for performance when importing a large backlog.
  - Severity-based purge timeouts and sticky semantics.
  - Per-source configure menu with the first N sources and a "More…" overflow action.

Tests (suggested)

- Unit tests:
  - Spam protection: when many notifications are added quickly, ensure only up to limit show as toasts.
  - Purge timers: non-sticky toasts disappear after configured timeout and are restored when window regains focus.
  - Filter behavior: toggling NotificationsFilter.ERROR hides center/toasts and updates statusbar icon.
  - Focus restoration: when center/toast closes and previously had focus, editor group gets focus back.

- Integration/UI tests:
  - Center show/hide and resize behavior with different workbench sizes and with/without statusbar/titlebar.
  - Action toolbar items (Clear, Configure DND, Hide) execute expected model actions.
  - Copy message context menu copies plain text content.

Related source files

- [`src/vs/workbench/browser/parts/notifications/notificationsCenter.ts`](src/vs/workbench/browser/parts/notifications/notificationsCenter.ts:1)
- [`src/vs/workbench/browser/parts/notifications/notificationsToasts.ts`](src/vs/workbench/browser/parts/notifications/notificationsToasts.ts:1)
- [`src/vs/workbench/browser/parts/notifications/notificationsList.ts`](src/vs/workbench/browser/parts/notifications/notificationsList.ts:1)
- [`src/vs/workbench/browser/parts/notifications/notificationsViewer.ts`](src/vs/workbench/browser/parts/notifications/notificationsViewer.ts:1)
- [`src/vs/workbench/browser/parts/notifications/notificationsStatus.ts`](src/vs/workbench/browser/parts/notifications/notificationsStatus.ts:1)
- [`src/vs/workbench/browser/parts/notifications/notificationsActions.ts`](src/vs/workbench/browser/parts/notifications/notificationsActions.ts:1)
- Notifications Commands & Runners: notificationsCommands / NotificationActionRunner (search for `NotificationActionRunner`).

Implementation risks & open questions

- Model portability: host must supply a model that supports fine-grained item lifecycle (visibility, progress, expansion) and eventing similar to INotificationsModel. Implementing a faithful adapter is non-trivial.
- Performance: toast creation is deferred and spam-protected for a reason — port must preserve interval/spam protection and deferred creation to avoid animation jank.
- Missing shared components: ActionBar, WorkbenchList, DropdownMenuActionViewItem, and hover infrastructure are reused across the app — a port needs equivalent components or shims.

Next steps

1. Wire a NotificationsModelAdapter and minimal StatusbarAdapter in src/adapters/ (docs-only contract first, then shims if the user permits code).
2. Add unit tests for spam protection, purge/timeouts, and filter interaction.
3. If desired, expand the product_description/MANIFEST.md to list this Notifications doc as a dedicated feature (or update the combined Status Bar & Notifications entry).

End of document.
