Widget, Input, List Renderer, Editor & ViewPane — Responsibilities & Port Notes

Summary:
- Consolidated synthesis of the chat UI orchestration: widget composition, input lifecycles, list renderer (progressive rendering & pooling), editor integration and view-pane/session restore.

Source files (primary):
- [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatViewPane.ts:1`](src/vs/workbench/contrib/chat/browser/chatViewPane.ts:1)

Responsibilities (high level):
- Orchestration / host (widget)
  - Instantiate input(s), list + renderer, editor pools and codeblock/model collections; coordinate submit/accept flow, editing flow, layout and telemetry. See [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1).
- Input lifecycle & UI
  - Persistent input model pinning, history, attachments, implicit context, model selection and mode switching. See [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1).
- List rendering & progressive streaming
  - Virtual tree with dynamic heights, progressive markdown slicing, content-part diffing, and resource pooling for embedded editors/diffs. See [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1).
- Editor integration & pane
  - Editor-pane wrapper preserves memento, restores sessions, and creates a ChatWidget scoped by view id. See [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1).
- View-pane & session restore
  - Side-bar view logic that migrates/restores persisted sessions, decides when to show welcome view, and wires session memento. See [`src/vs/workbench/contrib/chat/browser/chatViewPane.ts:1`](src/vs/workbench/contrib/chat/browser/chatViewPane.ts:1).

Key invariants & patterns:
- Input transient URI & model pinning
  - Input uses a transient URI and pins model references to avoid premature disposal (see [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1242`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1242)).
- Generation lock (ref-counted)
  - Input exposes startGenerating() that returns a disposable which decrements a refcount and resolves a Deferred promise when all consumers complete.
- Progressive rendering heuristics
  - Renderer slices markdown by words, driven by a WindowIntervalTimer and element.renderData (lastRenderTime + renderedWordCount); rate computed by getProgressiveRenderRate. See [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:247`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:247).
- ResourcePool + IDisposableReference
  - EditorPool / DiffEditorPool wrap a ResourcePool and return an IDisposableReference { object, isStale(), dispose() } — reset() must be called before release. Example: [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:352`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:352).
- Per-row scoped contexts & toolbars
  - Rows create scoped IContextKeyService instances and MenuWorkbenchToolBar instances so per-row tool/menu items get correct scoped context (see [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:362`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:362)).
- Checkpoint & editing model
  - The widget manages checkpoints and toggles editing vs inline editing flows; editing state affects layout/where the input DOM is placed and whether to show overlays.

Important call-sites & flows:
- Editor open -> reveal chat & focus codeblock
  - Handler in [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:426`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:426) locates codeblock editor by custom-scheme URI and reveals the associated chat row.
- Submit flow
  - _acceptInput collects input + attachments, cancels outstanding requests and calls chatService.sendRequest (see [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1746`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1746)).
- Progressive render loop
  - Word-slicing via getNWords, element.renderData maintenance, and WindowIntervalTimer driven updates (see [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:608`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:608)).
- Diff/model creation & SHA1 checks
  - CodeCompareModelService creates original + modified models (transient scheme), computes SHA1 and replays edits; self-acquire with delayed release to encourage reuse during streaming ([`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:184)).

Injected services & platform features required:
- Text model resolver service with createModelReference(pin) semantics and transient URI provider.
  - Example reference: [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1242`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1242)
- Editor & DiffEditor APIs supporting setModel/getModel, layout, content-height events.
  - See codeblock embedding: [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:296`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:296)
- Virtual tree implementation supporting dynamic heights and reveal/refilter.
  - See WorkbenchObjectTree usage: [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1041`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1041)
- Menu/toolbar/contextkey overlays and per-template scoping (createScoped).
  - Toolbar usage: [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:370`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:370)
- Webview + extension activation surface for output renderers (intrinsicContentSize observable).
  - See: [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:114`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:114)

Porting risks & required adapters (prioritized):
- ModelReference adapter
  - Must provide createModelReference(uri) returning a ref-counted object with object.textEditorModel and uri; required for pinning input models and modified snapshots.
- Editor & DiffEditor
  - Need embedding surface or graceful fallback (collapsed-pills) if full-featured editors/diffs aren't available.
- ResourcePool semantics
  - Implement ResourcePool + IDisposableReference to preserve reuse/reset/isStale patterns.
- ContextKey & Menu toolbars
  - Per-row createScoped context and MenuWorkbenchToolBar behaviors must be ported or shimmable.
- Progressive rendering
  - Timing-dependent heuristics (words/s) need config knobs and tests to avoid UX regressions in different environments.
- Session persistence & memento
  - ChatEditor/ChatViewPane rely on mementos and session migration paths; ports must map these semantics into persistent storage.

Tests to add / run:
- Model pinning lifetime tests: createModelReference + transient model snapshot creation and disposal.
- ResourcePool lifecycle tests: acquire/reset/release and reuse under streaming.
- Progressive streaming tests: simulate streaming markdown and assert slice-by-slice rendering and height updates.
- Editor open -> reveal tests: open custom-scheme codeblock URI triggers reveal, focus & selection.
- Session restore & migration tests: ChatViewPane memento-based restore and transferred session handling.

Concrete porting checklist (next steps):
1) Implement TextModelReference API and transient codeblock content provider (Schemas.vscodeChatCodeBlock).
2) Implement ResourcePool and IDisposableReference wrappers + unit tests.
3) Provide an editor embedding or a shim for code + diff editors with layout & content-height events.
4) Implement Workbench-like tree with dynamic heights/reveal/refilter APIs or adapt an existing virtual list with those features.
5) Implement menu/toolbar/context-key overlays and per-row scoped context.
6) Implement session persistence (Memento) and transfer/migration semantics used by ChatViewPane.
7) Implement progressive-render configuration knobs and accessibility alert behaviors.

Notes & implementation hints:
- Keep codeblock editors pooled and ensure codeBlock.reset() is called before releasing to pool; see [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:357`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:357).
- Pin input model early with textModelResolverService.createModelReference(this.inputUri) so the model is not GC'd (see [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1242`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1242)).
- Webview renderers should expose intrinsicContentSize observable so parent can autorun and update height (see [`src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:114`](src/vs/workbench/contrib/chat/browser/chatOutputItemRenderer.ts:114)).
- Implement getNWords-based slicing and element.renderData maintenance to reproduce progressive streaming behavior (see [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:972`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:972)).

Cross-links (quick):
- Orchestration / submit flow: [`src/vs/workbench/contrib/chat/browser/chatWidget.ts:1650`](src/vs/workbench/contrib/chat/browser/chatWidget.ts:1650)
- Input lifecycle & UI: [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1002`](src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1002)
- List renderer & progressive rendering: [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:856`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:856)
- Editor pane & memento: [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:153`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:153)
- ViewPane restore & transfer: [`src/vs/workbench/contrib/chat/browser/chatViewPane.ts:167`](src/vs/workbench/contrib/chat/browser/chatViewPane.ts:167)

Last updated: 2025-08-09T07:28:34Z
