# Attachments, Markdown, Text-Edit, Progress & Tool I/O (synthesis)

Summary:
- This document synthesizes responsibilities, UI flows, lifecycle patterns and porting considerations found across the following implementation files:
  - [`ChatAttachmentsContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)
  - [`ChatMarkdownContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
  - [`ChatTextEditContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
  - [`ChatProgressContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
  - [`ChatCollapsibleInputOutputContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:66)

Responsibilities:
- Render attached request variables (files, images, snippets, tool outputs) and provide context menus / copy/save actions via [`ChatAttachmentsContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:19).
- Render markdown responses with rich features: codeblock pooling, KaTeX/math support, inline anchors and decorations via [`ChatMarkdownContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:66).
- Render text-edit/diff responses as either summaries or interactive diff editors; create ephemeral original/modified models and compute original SHA1 via [`ChatTextEditContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:44).
- Render progress and working state messages that may hide when subsequent content arrives via [`ChatProgressContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:22).
- Render collapsible tool input/output widgets with save/export actions and grouped resource attachments via [`ChatCollapsibleInputOutputContentPart`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:66).

Key call-sites & event flows:
- Attachment widgets are instantiated per variable and wired with a context-menu handler that forwards a `MenuId.ChatToolOutputResourceContext` invocation (see [`ChatCollapsibleInputOutputContentPart` context menu wiring](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:223)).
- Code blocks use a pooled editor: see [`EditorPool.get()` resource wrapper](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:356) returning an [`IDisposableReference`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:55).
- Text-edit diffs rely on [`CodeCompareModelService.createModel()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184) to produce original/modified models, compute original SHA1, and apply prior edits before returning a short-lived ref (self-acquire + timeout).
- Progress parts call `alert()` for SR when a spinner is shown and otherwise hide when later content appears; logic in [`shouldShowSpinner()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:79).

Important injected services (for porting)
- Instantiation/DI: [`IInstantiationService`] used extensively for widget creation across all parts (e.g., [`chatAttachmentsContentPart.ts:31`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:31)).
- Markdown & models: [`MarkdownRenderer`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:86), [`ITextModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:92), [`IModelService`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:180).
- File & workspace services: [`IFileService`, `IFileDialogService`, `IWorkspaceContextService`] used by save/export flow in [`SaveResourcesAction`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:301).
- Context menus / toolbar: [`IContextMenuService`, MenuId` usage`] across pill widgets and resource toolbars (`chatMarkdown`, `CollapsedCodeBlock`, `ChatCollapsibleInputOutputContentPart`).

Core patterns & semantics to preserve when porting
- Resource pooling with explicit isStale/reset semantics:
  - Pattern: acquire from [`ResourcePool()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:352), wrap with { object, isStale: () => stale, dispose: () => { reset(); stale = true; release(obj) } } as in [`EditorPool.get()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:356).
- Ephemeral model creation and SHA1 computation for diffs:
  - [`CodeCompareModelService.createModel()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184) creates a transient modified model from original snapshot, computes originalSha1 (DefaultModelSHA1Computer), applies prior edits, then self-acquires the RefCountedDisposable briefly (setTimeout release).
- Progressive/streaming rendering decisions:
  - [`ChatMarkdownContentPart.hasSameContent()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:311) uses "last codeblock is streaming" heuristics to allow incremental replaces instead of hiding progress.
- Accessibility signals for progress:
  - SR alert when spinner is shown — [`ChatProgressContentPart` uses alert()](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:49).

UI behaviors & visuals
- Code block pills (collapsed code blocks) are interactive keyboard-accessible elements that open editors/diffs and show insertion/deletion summaries with aria labels: see [`CollapsedCodeBlock.render()` and context menu wiring](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:377).
- Attachments show different widgets per variable kind (image, file, paste, notebook output, toolset) and mark partial/omitted states with 'warning' CSS and ARIA descriptions: see [`ChatAttachmentsContentPart.initAttachedContext()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:42).
- Collapsible IO widgets present an input (code) and multiple output parts (grouped resources or code) with a toolbar (MenuWorkbenchToolBar) and a `Save As...` action (`SaveResourcesAction`) that performs copy/read-write via the platform file service.

Porting risks and mitigations
- Webview and renderer contract not present here, but similar rendering widgets rely on host-provided MarkdownRenderer and model services. Ensure host provides:
  - A Markdown renderer with sanitizer + KaTeX support and async extension load hooks (see MarkedKatexSupport usage in [`chatMarkdownContentPart.ts:112`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:112)).
- Pool reuse races: the isStale wrapper and reset() must be preserved to avoid reuse-after-dispose races; tests should exercise concurrent streaming updates.
- File API differences: the `SaveResourcesAction` assumes fileService.copy/readFile/writeFile semantics and dialogs; adapt to host file API or provide an adapter that can stream binary blob writes (MCP note: "MCP doesn't support streaming data" in code).
- Model SHA1 computation: the port must supply a SHA1 computation API or implement DefaultModelSHA1Computer equivalent; otherwise diff verification and edit replay logic will break.

Test cases & QA targets (high priority)
- ResourcePool lifecycle: acquire → use → dispose → ensure object.reset() and pool.release() were called; verify isStale flips true and object reclaimed for next get.
- CodeCompareModelService: createModel returns originalSha1 matching snapshot; modified model receives applied edits; short-lived self-acquire prevents premature disposal during streaming.
- Progress hiding rule: a progress message followed by a non-progress message should cause the spinner/message to be hidden — exercise ChatProgressContentPart.shouldShowSpinner() behavior.
- Attachment context menu: right-click an attachment should open `MenuId.ChatToolOutputResourceContext` with correct context (parts array) and SaveResourcesAction should copy files and show notification/reveal.
- Collapsible IO layout: toggling expansion should update DOM height and fire height change events that the renderer listens to.

Implementation notes & suggested adapter surface
- Provide a pooled-editor adapter implementing:
  - create code-editor instances with layout()/reset()/focus()/onDidChangeContentHeight() hooks matching [`CodeBlockPart` expectations](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:296).
- Provide a diff-model helper equivalent to [`CodeCompareModelService.createModel()`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184) that:
  - creates transient modified model from original snapshot,
  - computes original SHA1,
  - applies prior edits in request order,
  - returns a disposable reference object that can be self-acquired briefly.
- Provide file dialog and file service wrappers that support copy/read/write and optionally streaming for large binary resources (see `SaveResourcesAction`).

Cross-file anchors (for review)
- Attachments: [`chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)
- Markdown & codeblocks: [`chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- Text-edit & diff model: [`chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- Progress & SR: [`chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)
- Collapsible IO & Save action: [`chatToolInputOutputContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatToolInputOutputContentPart.ts:1)

Next steps
- Add this doc to MANIFEST and OVERVIEW cross-links.
- Run the QA pass tasks: cross-link exact source-file ranges in each feature doc and consolidate porting checklist entries into product_description/PORTING_CHECKLIST.md.
- Continue automated loop: pick the next prioritized batch of chat files and synthesize a focused doc.

End of synthesis.
