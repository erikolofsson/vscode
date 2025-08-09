# Chat — Attachments, Markdown Rendering, Text-Edit/Diff, Multi-Diff & Progress

Summary of batch read (files)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1)

Responsibilities
- Attachments rendering and hover/context menu handling; maps variable entries to specialized widgets (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`)).
- Markdown rendering, streaming code block handling, KaTeX support, sanitizer config, pooled editors & codeblock lifecycle (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`)).
- Text-edit / diff rendering via pooled diff editors and model-replay createModel pipeline (original SHA1 compute, edit replay, transient ref-counting): (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`)).
- Multi-diff UI and MultiDiffEditorInput creation for many-file diffs (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`)).
- Progress / working progress parts: spinner logic, SR alerts, and hide-when-following-content semantics (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`)).

Injected services & dependencies
- Attachment widgets depend on ResourceLabels, hoverDelegateFactory and many widget classes (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`)).
- MarkdownRenderer, MarkedKatexSupport, ITextModelService, CodeBlockModelCollection, EditorPool (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`)).
- ITextModelService / IModelService, DefaultModelSHA1Computer and IChatService used in CodeCompareModelService for createModel (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`)).
- MultiDiffEditorInput / MultiDiffEditorItem + editorGroupsService for opening multi-file diffs (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`)).
- IChatMarkdownAnchorService and renderFileWidgets used by progress parts to render inline anchors and file widgets (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`)).

UI flows & interactions
- Attachments: iterate variables, choose specific widget (image, file, paste, notebook output, SCM history, toolset), wire context menu handler and ARIA labeling for omitted/partial attachments (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`)).
- Markdown: render markdown (with sanitizer), stream code blocks progressively, hide empty/incomplete codeblocks, use EditorPool to render full editors and expose codeblock metadata for other parts to reference (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`)).
- Text edits: create original model ref, clone snapshot to ephemeral modified model, compute originalSha1, replay earlier edits from chatModel.getRequests(), and return a ref-counted disposable that self-acquires briefly to favor reuse during streaming (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`)).
- Multi-diff: expandable header, list up to MAX_ITEMS_SHOWN, "view all" constructs MultiDiffEditorInput and opens it in the editor group (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`)).
- Progress: spinner decision logic (show only when response is streaming), alert() for screen readers when spinner shown, hide progress messages when concrete content follows (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatProgressContentPart.ts:1`)).

Patterns & lifecycle
- ResourcePool wrapper returning IDisposableReference with isStale() and dispose() that resets object and releases to pool (EditorPool, DiffEditorPool) — preserve exact semantics to avoid reuse races (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`) and [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`)).
- Streaming-aware hasSameContent implementations to allow incremental rendering without full rebuilds (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`)).
- CodeCompareModelService.createModel pattern: originalRef = createModelReference(uri); modified created from snapshot via createTextBufferFactoryFromSnapshot + modelService.createModel(ephemeralUri); compute SHA1 or reuse cached; replay edits; return ref-counted disposable and self-acquire temporarily (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`)).

Porting considerations & risks
- Editor/model APIs: must provide createModelReference, createModel, createTextBufferFactoryFromSnapshot semantics and a SHA1 computer or equivalent. This is a high technical-risk area (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`)).
- Pool semantics: host must implement isStale/reset behavior on pooled widgets; otherwise add additional guards/tests to catch use-after-dispose (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`)).
- Multi-diff editor: VS Code-specific MultiDiffEditorInput may not exist; provide host multi-diff viewer or open diffs sequentially (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMultiDiffContentPart.ts:1`)).
- Attachments & labels: ResourceLabels and file-icon theming integration require host services or lightweight adapters; hover delegates needed for instant hovers (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatAttachmentsContentPart.ts:1`)).
- Math/KaTeX: async MarkedKatexSupport loading and sanitizer config must be supported or math disabled gracefully (`[`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`)).
- Accessibility: progress uses alert(); collapsibles update ARIA labels — preserve these behaviors.

Suggested tests
- Pool lifecycle test: acquire → use → dispose → confirm isStale returns true and reset called before reuse.
- CodeCompareModelService.createModel test: stub textModelService.createModelReference and modelService.createModel to verify originalSha1, replayed edits, and timed self-acquire release.
- Markdown streaming test: render partial codeblock then complete it; confirm incremental rendering (hasSameContent) and eventual layout change.
- Multi-diff open test: assert MultiDiffEditorInput constructed with correct MultiDiffEditorItem list and editorGroupsService.openEditor called.
- Attachments mapping test: for each IChatRequestVariableEntry kind, assert correct widget type constructed and contextmenu handler invoked.

Next automated actions
1. Write this synthesized note into product_description/features/chat/ (this file)
2. Update TODO to mark this batch completed
3. Continue with next prioritized batch of chatContentParts (I will list remaining files and pick the next ~5)

Implementation notes for engineers
- Ensure createModelReference returns an object with textEditorModel and createSnapshot so createTextBufferFactoryFromSnapshot usage works.
- Stub generateUuid and ephemeral URI creation in tests for deterministic keys.
- Provide a webview-style renderer adapter that exposes onDidChangeHeight and onDidWheel hooks if reproducing ChatToolOutputSubPart semantics.
- Preserve observable/autorun semantics or map to an equivalent reactive library and update autorun usage accordingly.

End of file.
