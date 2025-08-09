# Chat — Codeblocks & Editor Pooling

Purpose
- Explain the architecture and lifecycle for code blocks rendered inside chat messages, the pooled editor strategy, collapsed pill behavior for edit-type blocks, and porting considerations.

Responsibilities
- Host embedded code blocks (read-only and editable) inside chat list items.
- Manage codeblock text models and codemapper URIs that map codeblocks to workspace/editable contexts.
- Provide "open in editor" behavior that reveals a pooled or full editor with preserved selection/uri metadata.
- Ensure pooled editors are reused safely across DOM containers and streaming updates.
- Coordinate with diff/edit preview flows for text-edit suggestions.

Related source files
- [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1)

Key concepts
- EditorPool / DiffEditorPool: ResourcePool pattern that returns IDisposableReference-like objects that expose { object, isStale, dispose }.
- CodeBlockModelCollection: holds metadata and promises for codeblock models and codemapperUri mapping.
- Collapsed pills: lightweight placeholders for edit-type codeblocks where the heavy editor is only created on demand.
- vscodeChatCodeBlock URIs: a special synthetic URI scheme used to resolve/open pooled editors and to support "open in editor" flows.

EditorPool behavior
- Acquire returns a reference with a live editor part instance and a dispose method.
- Dispose resets the editor part and releases it back to the pool; references expose isStale to detect late callbacks.
- Pools ensure pooled editors can be attached to different DOM containers via reset/reattach semantics.
- Pools should be sized to balance memory usage and allocation cost; a warm small pool reduces jank.

Codeblock rendering lifecycle
- The Markdown renderer detects fenced code blocks and the content-part sync hook (codeBlockRendererSync) yields codeblock descriptors.
- If a codeblock has a codemapperUri indicating an edit-type block, the renderer may render a collapsed pill instead of allocating an embedded editor.
- When the user expands the codeblock (or an action requests open-in-editor), the renderer acquires a CodeBlockPart from the EditorPool and creates/attaches models.
- For streaming responses, model text may be updated incrementally; pooled editors must accept model updates and trigger height recalculation.

CodemapperUri semantics
- A codemapperUri identifies a codeblock that maps to an editable resource or an edit-origin. It typically implies:
  - the codeblock is a candidate for producing text edits against a workspace file, or
  - the codeblock should be represented with a stable URI so it can be opened/referenced.
- Lifecycle: codemapperUri and associated models are created by codeblock model collection when the response containing the codeblock is processed, and should be released when the response is removed or session is disposed.

Open-in-editor flow
- The chat widget or list renderer maps vscodeChatCodeBlock URIs to pooled editors and/or full editor panes.
- When "Open in Editor" is invoked:
  - If an embedded pooled editor instance exists for that URI, reveal and focus it.
  - Otherwise, create a modelRef (or request a full editor open) for the codeblock's model and reveal a proper editor pane with selection/reveal info.
- Selection and reveal coordinates stored in the codeblock metadata must be honored.

Diff editors & edit previews
- DiffEditorPool supplies diff widgets for text-edit group previews (inline or side-by-side).
- CodeCompareModelService constructs original and modified models (using snapshots), computes original SHA1, and returns references for diff editors.
- DefaultChatTextEditor applies edits by verifying the original SHA1 and either pushing edits to the model or replaying diffs from a diff editor; mismatches prompt a confirmation dialog.

Porting checklist (codeblocks)
- [ ] Implement a ResourcePool-like abstraction with acquire/release and IDisposableReference semantics.
- [ ] Provide a lightweight embeddable editor surface compatible with pooling (attach/detach/reset).
- [ ] Implement a synthetic URI scheme (like `vscodeChatCodeBlock`) to reveal pooled editors from external actions.
- [ ] Implement CodeBlockModelCollection equivalent to map codeblock id → URI/model promises and manage model lifetimes.
- [ ] Preserve collapsed-pill behavior for edit-type codeblocks to avoid allocating heavy editors until user expands.
- [ ] Ensure streaming updates to pooled models are performant and synchronized with list height updates.
- [ ] Implement SHA1-based original model verification and user confirmation flow for applying edits.

Performance & memory notes
- Pool sizing: measure the worst-case number of concurrent visible editors and set pool size accordingly.
- Release strategy: aggressively reset editors when not visible but keep a small warm pool to reduce reallocation.
- Model lifecycle: prefer using snapshots for modified views to avoid mutating original workspace models and to provide safe apply/preview flows.

Accessibility
- Collapsed pills must be keyboard-focusable and announce they are expandable and whether they map to an editable resource.
- Embedded editors must expose aria labels describing language and a concise description for screen readers.
- Diff previews should expose accessible summaries and controls for applying/discarding edits.

Testing checklist
- Unit:
  - Pool acquire/release under concurrent requests and verify reset semantics.
  - Fence parsing helpers (e.g., `codeblockHasClosingBackticks`) and edge cases.
  - Collapsed-pill rendering does not allocate editors until expanded.
- Integration:
  - Streaming codeblock updates update the pooled model and reflect in UI with correct height changes.
  - Open-in-editor reveals pooled editor with correct selection and language.
  - Applying edits with original SHA1 mismatch prompts confirmation and applies or aborts correctly.
- Performance:
  - Memory profiling when many codeblocks are present in history; validate pool reuse reduces memory and allocation spikes.

Risks & mitigation
- Risk: pooled editors attached to stale DOM nodes cause visual corruption — mitigation: ensure `reset()` fully clears editor state and rebinds DOM when reattached.
- Risk: streaming updates concurrent with editor acquisition produce race conditions — mitigation: serialize model updates and batch height recalculations; use isStale checks on disposed references.
- Risk: losing language-service quality in pooled lightweight editors — mitigation: provide fallback rendering and on-demand richer language services when expanded.

Cross-links
- Editor integration: [`product_description/features/chat/editor_integration.md:1`](product_description/features/chat/editor_integration.md:1)
- Rendering: [`product_description/features/chat/rendering.md:1`](product_description/features/chat/rendering.md:1)
- Text-edit/diff flows: [`product_description/features/chat/textedit_diff.md:1`](product_description/features/chat/textedit_diff.md:1)

End of document
