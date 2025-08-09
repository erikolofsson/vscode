# Chat — Pull Requests, Quota, Tasks, To‑Do & Tool I/O (batch)

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatPullRequestContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatPullRequestContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatQuotaExceededPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatQuotaExceededPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTaskContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTaskContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTodoListWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTodoListWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1)

Responsibilities
- PR card UI + opener link rendering: [`ChatPullRequestContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatPullRequestContentPart.ts:20)
- Quota/entitlement error UI and CTA flows: [`ChatQuotaExceededPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatQuotaExceededPart.ts:38)
- Task/progress rendering (collapsible lists vs progress messages): [`ChatTaskContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTaskContentPart.ts:17)
- Session-scoped To‑Do widget (expand/collapse, per-session data): [`ChatTodoListWidget`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTodoListWidget.ts:12)
- Collapsible tool I/O (input/output parts), attachments rendering and Save/Export flow: [`ChatCollapsibleInputOutputContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:66)

Injected services & dependencies
- Opener for PR links: [`IOpenerService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatPullRequestContentPart.ts:28)
- Entitlement / command / telemetry for quota actions: [`IChatEntitlementService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatQuotaExceededPart.ts:51)
- Collapsible list pool & editor pool for tasks and code blocks: [`CollapsibleListPool`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTaskContentPart.ts:25), [`EditorPool`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:42)
- File system + dialogs + progress + notification for Save As flow: see [`chatToolInputOutputContentPart.ts:301`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:301)
- Attachments plumbing (attachment model + widgets): [`ChatAttachmentsContentPart` used inside I/O part](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:216)

UI flows & interactions
- PR card: clicking the link opens the PR in external/editor via openerService (`chatPullRequestContentPart.ts:43`).
- Quota: clicking upgrade/manage runs a command and then reveals retry UI; retry triggers widget.rerunLastRequest() and shows wait warning (`chatQuotaExceededPart.ts:116`).
- Tasks: when task.progress exists render a collapsible list; otherwise render a ChatProgressContentPart spinner/message (`chatTaskContentPart.ts:32`).
- To‑Do widget: session-bound; updateSessionId(sessionId) toggles visibility and re-renders list (`chatTodoListWidget.ts:73`).
- Tool I/O: creates collapsible input/output, renders codeblocks via pooled editors, groups binary data into attachments, and exposes Save As / Save Folder behavior (`chatToolInputOutputContentPart.ts:160`, `...:216`, `...:301`).

Lifecycle & patterns
- All UI parts implement Disposable and register disposables via this._register; many parts emit onDidChangeHeight for layout.
- Pools (EditorPool, CollapsibleListPool) are used to reuse expensive UI widgets and must be reset before release (see editor reference handling in `chatToolInputOutputContentPart.ts:262`).
- Long-running background work and file operations use progressService and CancellationToken-style patterns (render cancellation in tool output parts; save uses progressService `withProgress` at `chatToolInputOutputContentPart.ts:326`).

Porting considerations & risks
- File I/O & dialogs: `fileService.copy`, `fileService.readFile` / `writeFile` and `IFileDialogService` used for Save As; target must provide equivalent or shim to avoid blocking memory. See `chatToolInputOutputContentPart.ts:311` and `...:318`.
- Entitlement & command wiring: quota component invokes command ids and telemetry — maintain or map `workbench.action.chat.upgradePlan` / `workbench.action.chat.manageOverages` and telemetry calls (`chatQuotaExceededPart.ts:121`).
- Attachment binary handling & MIME detection: code uses `getAttachableImageExtension` to decide image widgets vs file widgets; ensure same MIME heuristics (`chatToolInputOutputContentPart.ts:33`).
- Large resource handling: Save multiple resources flows must be robust (streaming copy vs in-memory buffers) to avoid high memory use (`chatToolInputOutputContentPart.ts:313`).
- Accessibility: To‑Do widget uses aria-expanded and keyboard handlers; preserve aria semantics (`chatTodoListWidget.ts:39`).

Suggested tests
- PR card: unit test openerService.open invoked with PR URI (`chatPullRequestContentPart.ts:46`).
- Quota flow: mock entitlement state and assert command/telemetry invoked and retry/wait UI becomes visible (`chatQuotaExceededPart.ts:116`).
- To‑Do widget: session id update shows/hides list and toggleExpanded updates aria and height (`chatTodoListWidget.ts:73`).
- SaveResourcesAction: simulate `IFileDialogService` and `IFileService` to assert copy/write occurs and progress reported (`chatToolInputOutputContentPart.ts:301`).

Next automated actions
1. Write this doc into the feature docset (this file).
2. Update TODO to mark this batch completed.
3. Continue to the next prioritized batch of up to 5 chat files (I will proceed immediately).
