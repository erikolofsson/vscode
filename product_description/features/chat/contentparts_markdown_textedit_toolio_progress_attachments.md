Content parts — Markdown, Text-Edit, Tool I/O, Progress & Attachments

Summary:
- This doc synthesizes responsibilities, call-sites, injected services, lifecycles, UI flows and porting risks for the chat content parts implemented in the VS Code origin.
- Source reference files:
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
  - [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)

Responsibilities (high level):
- Render markdown chat responses with codeblocks, math, and sanitized HTML; manage codeblock editors and collapsed codeblock pills.
- Render text-edit/diff UI for suggested edits, producing original/modified models and applying edit groups.
- Present tool input/output collapsible UI, including resource groups and save/download actions.
- Show progress and working/paused indicators, and manage accessibility alerts for SR users.
- Render attached variables (files, images, notebook outputs, paste entries) with consistent ResourceLabel and widget semantics.

Key classes & APIs:
- Markdown content part: [`ChatMarkdownContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:66), uses [`EditorPool.get()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:357) to acquire editors and returns [`IDisposableReference`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:55).
- Text-edit content part: [`ChatTextEditContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:44), uses [`DiffEditorPool.get()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:159) and [`ICodeCompareModelService.createModel()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:38).
- Collapsible Tool I/O: [`ChatCollapsibleInputOutputContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:66) — constructs [`ChatAttachmentsContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:19) for output resources.
- Progress: [`ChatProgressContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:22) and [`ChatWorkingProgressContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:83).

Injected services (summary):
- Text model services: [`ITextModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:92), [`IModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:180).
- Instantiation & menu/context: [`IInstantiationService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:93), [`IContextMenuService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:401).
- Editor & label services: [`IEditorService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:398), [`ILabelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:397).
- Chat runtime: [`IChatService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:405) used by codeblock pills and compare models.
- File/IO/notification/progress: [`IFileService`, `IFileDialogService`, `INotificationService`, `IProgressService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:301).

Pools & resource management:
- Pools implemented as [`ResourcePool`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:352) and wrapped by `EditorPool`/`DiffEditorPool` which return an `IDisposableReference` object with { object, isStale(), dispose() } semantics.
- Typical lifecycle: acquire -> render -> onDidChangeContentHeight subscription -> dispose() { reset(); _pool.release(); } pattern (see [`EditorPool.get()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:357) and [`DiffEditorPool.get()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:159)).
- Self-acquire short ref pattern for diff models (`RefCountedDisposable.acquire()` with setTimeout release) in [`CodeCompareModelService.createModel()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:240).

Progressive rendering & codeblock handling:
- Markdown renderer supports incremental/progressive streaming; codeblocks are handled specially via `codeBlockRendererSync` where editors or collapsed pills are returned.
- Codeblocks use a per-response `CodeBlockModelCollection` to map session+index -> model references and codemapper URIs; streaming updates update modelEntry via `updateSync`/`update`.
- Empty/incomplete codeblocks can be hidden (see [`codeblockHasClosingBackticks()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:372)).

Text-edit / diff flow:
- When rendering text-edit groups, [`ChatTextEditContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:44) either renders a summary or acquires a diff editor from [`DiffEditorPool`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:138).
- The [`CodeCompareModelService.createModel()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184) sequence:
  1) Acquire original via `textModelService.createModelReference(uri)`.
  2) Create a modified model snapshot under scheme `vscodeChatCodeBlock` and compute SHA1 (using `DefaultModelSHA1Computer`) when missing.
  3) Replay previous edit groups into modified model and return ref-counted pair { original, modified } with delayed release semantics.
- Port must provide reference-counted model references and model creation that supports transient URIs and snapshot-based modified models.

Tool I/O collapsible part:
- `ChatCollapsibleInputOutputContentPart` composes a titled collapsible UI with:
  - a title (`ChatQueryTitlePart`), an expand/collapse observable state, and one or more code/data parts.
  - For code parts, it consumes `EditorPool.get()` to render code editors inline.
  - For data parts (images/files), it constructs an entry list and renders an embedded `ChatAttachmentsContentPart` plus a `MenuWorkbenchToolBar` for resource actions (save/download).
- The "Save resources" action (`chat.toolOutput.save`) uses file dialog + `IFileService.copy`/`readFile`+`writeFile`, with progress reporting via `IProgressService`.

Progress parts and accessibility:
- `ChatProgressContentPart` decides whether to show a spinner or hide based on following content and response completeness (`shouldShowSpinner()` logic).
- When a spinner is shown, it calls `alert()` with progress message for screen readers.

Attachments content part details:
- `ChatAttachmentsContentPart` is purely a renderer of attachment widgets using many concrete widget implementations (image/file/paste/notebook/SCM/tool widgets) and a `ResourceLabels` instance for consistent file labels.
- Widgets are created via `IInstantiationService`, and context menus are wired via `contextMenuHandler`.
- Omitted / partial state is surfaced by adding `.warning` class and modifying aria labels.

Porting risks & required adapters:
- Model pinning & transient models:
  - The origin relies heavily on `textModelService.createModelReference(uri)`-style pinned models. Port must implement reference-counted model refs with stable `textEditorModel` and `uri` properties.
- ResourcePool & IDisposableReference semantics:
  - Pools return objects that must be `reset()` before reuse; `isStale()` guards against updates after disposal. Port must replicate pool semantics or provide equivalent lifecycle primitives.
- Editor embedding & layout:
  - Codeblock editors rely on in-DOM editor embedding, height-change events, and overflowWidget anchoring. If embedding isn't available, collapsed-pill fallback must be used.
- SHA1 & model snapshot:
  - The diff flow computes SHA1 via `DefaultModelSHA1Computer` — ports without same model internals must provide deterministic hashing of model contents.
- File IO and progress:
  - `IFileService.copy` and `IFileDialogService` assumptions (atomic copy, workspace detection) need equivalent behaviors. Batch save operations rely on `IProgressService`.
- Platform APIs used: context menus, toolbar menus, hover service, markdown renderer with sanitizer and katex. Ports must implement replacements or shims for:
  - [`MarkdownRenderer`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:126) with sanitizer config and async render callback hooks.

Tests to add / run in port:
- ResourcePool lifecycle tests: acquire/release/reset and reuse under streaming.
- Model pinning tests: createModelReference lifetimes, snapshot modified-model creation, SHA1 computation, and delayed release behavior.
- Progressive rendering tests: streaming markdown with codeblocks, ensure collapsed pill -> editor replacement occurs and heights update.
- Attachment rendering tests: each widget type (image, file, paste, notebook, SCM) and context menu wiring.
- Tool output save flow: simulate save of single file and group to a chosen folder, assert file copies and progress notifications.

Recommended porting checklist (next steps):
1. Implement TextModelReference API with createModelReference(uri) returning reference-counted object matching origin semantics.
2. Implement ResourcePool and IDisposableReference wrappers and tests.
3. Provide a MarkdownRenderer-compatible component with sanitizer, async rendering hook and math (KaTeX) support / graceful fallback.
4. Implement editor embedding surface that supports height-change events or map to collapsed-pill UX.
5. Implement FileDialog, FileService and ProgressService abstractions required by tool I/O actions.
6. Port Attachment widgets or create equivalently functioning replacements (ResourceLabels + widgets).

Cross-links (source mapping):
- Markdown + codeblocks: [`chatMarkdownContentPart.ts`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- Text-edit / diff: [`chatTextEditContentPart.ts`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- Tool I/O + save action: [`chatToolInputOutputContentPart.ts`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1)
- Progress / accessibility: [`chatProgressContentPart.ts`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
- Attachments rendering: [`chatAttachmentsContentPart.ts`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)

Authoring notes:
- When implementing the port, preserve the pattern of small resource-scoped services (editor pools, codeblock model collection) to allow easy unit testing and predictable memory use.
- Where web-APIs like Canvas or Web Crypto are used (image resizing / hashing), create fallbacks or server-side equivalents.

Last updated: 2025-08-09T07:24:21Z
