# Chat — Text-edit & Diff flows

Purpose
- Summarize the text-edit and diff preview architecture used by Chat: how preview models are created from workspace snapshots, how diffs are rendered via pooled diff editors, how SHA1 verification is performed before applying edits, and porting considerations.

Responsibilities
- Create original and modified models for a text-edit suggestion without mutating workspace files.
- Compute and persist original model SHA1 to enable safe apply checks.
- Replay prior edits from the session into the modified model so the diff reflects cumulative changes.
- Render a diff preview (inline or side-by-side) using pooled diff widgets and expose apply/discard controls.
- Apply edits atomically to workspace files with verification and user confirmation on mismatch.

Related source files
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)

Overview
- Text-edit suggestions are surfaced as "textEditGroup" response parts.
- When rendering a preview, the system must present a diff between the original workspace file and a "modified" model that includes suggested edits (and any previously applied or suggested edits in the session).
- To avoid mutating workspace state prematurely, the modified model is created from a snapshot of the original model and is kept isolated under a synthetic URI (scheme: `vscodeChatCodeBlock`).
- The preview uses pooled diff widgets (DiffEditorPool / CodeCompareBlockPart) to render the comparison. Applying changes will update the real workspace model after safety checks.

CodeCompareModelService — createModel (implementation notes)
- Steps performed by createModel:
  - Acquire a reference to the original model: `textModelService.createModelReference(chatTextEdit.uri)`.
  - Create a modified model using a text buffer factory from the original snapshot:
    - createModel(createTextBufferFactoryFromSnapshot(originalSnapshot), { languageId, onDidChange: Event.None }, URI.from({ scheme: Schemas.vscodeChatCodeBlock, path, query: generateUuid() }), false)
    - Then createModelReference for that synthetic URI to get the modified resolved model.
  - Compute originalSha1:
    - If chatTextEdit.state?.sha1 exists, reuse it.
    - Otherwise use DefaultModelSHA1Computer to compute SHA1 from the original model and store it in chatTextEdit.state.
  - Replay prior edits from earlier requests in the session against the modified model:
    - Iterate session requests up to the current response and collect textEditGroup edits.
    - Convert edits to edit operations (TextEdit.asEditOperation) and call modifiedModel.pushEditOperations(null, edits, () => null).
  - Return an IReference containing { originalSha1, original: originalModel, modified: modifiedModel } with a RefCountedDisposable that disposes the underlying model references.
  - The service self-acquires the reference briefly (d.acquire) and schedules a release after a short timeout (e.g., 5000ms) so streaming scenarios reuse models.

Important implementation snippets & semantics
- The modified model uses a synthetic URI whose scheme is [`Schemas.vscodeChatCodeBlock`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1) with a generated UUID query to avoid collisions.
- Prior edits are gathered by walking the chatModel.getRequests() and collecting edits for groups targeting the same uri until reaching the current response; these are replayed into the modified model so the diff is accurate.
- References are managed via RefCountedDisposable to avoid leaking model refs; the service uses a short self-acquire to cache models during streaming.

DiffEditorPool behavior
- DiffEditorPool is a ResourcePool that constructs CodeCompareBlockPart instances on demand.
- get() returns an IDisposableReference-like object:
  - { object: CodeCompareBlockPart, isStale: () => boolean, dispose: () => void }
  - dispose() calls codeBlock.reset(), marks the reference stale, and releases the part back to the pool.
- ChatTextEditContentPart obtains a diff reference via diffEditorPool.get(), then calls comparePart.object.render(data, width, token) where data.diffData is an async promise resolving to { original, modified, originalSha1 }.

DefaultChatTextEditor & apply flow (high-level)
- Before applying edits, the editor verifies the original SHA1 computed earlier against the current workspace model:
  - If SHA1 matches, edits can be applied automatically (via model.pushEditOperations or equivalent).
  - If SHA1 mismatches (workspace changed since diff creation), prompt the user with a confirmation dialog explaining the mismatch and showing the diff; provide options to refresh, force apply, or cancel.
- Applying edits:
  - Convert TextEdit groups into ISingleEditOperation arrays or compute single-edit operations from diff results.
  - Perform model.pushEditOperations(null, edits, () => null) on the target workspace model(s) or use editor service commands to apply edits atomically.
  - Update chatTextEdit.state.applied (or set applied flag) to prevent reapplication and to keep session history consistent.

Streaming semantics & snapshots
- Modified models are created from snapshots so live workspace changes are not reflected unless re-resolved intentionally.
- The CodeCompareModelService uses a short-lived caching window (RefCountedDisposable + timeout) to reuse models during streaming updates and avoid frequent reallocation.
- This strategy avoids mutating the real file until user confirms apply, and preserves a stable diff preview even when the session streams incremental suggestions.

UI wiring
- ChatTextEditContentPart:
  - If rendererOptions.renderTextEditsAsSummary returns true, the part may render a compact summary instead of a full diff.
  - Otherwise it acquires a comparePart from DiffEditorPool, registers comparePart.object.onDidChangeContentHeight to fire its own onDidChangeHeight, and calls comparePart.object.render(...) with the diffData promise.
- The diff block UI shows controls for applying edits, opening the diff in a full editor, and possibly viewing per-edit metadata.

Porting checklist (text-edit / diff)
- [ ] Provide text model snapshot capability and a way to instantiate a new, isolated "modified" model from a snapshot with a synthetic URI.
- [ ] Implement SHA1 computation for text models and store per-chatTextEdit state for sha1/applied counters.
- [ ] Implement ResourcePool / DiffEditorPool with acquire/release semantics and IDisposableReference-like contracts (object, isStale, dispose).
- [ ] Provide a diff UI capable of rendering side-by-side or inline diffs and exposing the underlying edit operations.
- [ ] Implement a safe apply flow:
  - Verify original SHA1 matches current file content.
  - If mismatch, surface a clear confirmation dialog showing the diff and options.
  - Apply edits atomically and update chat state to mark applied edits.
- [ ] Provide APIs to pushEditOperations or equivalent atomic apply across multiple files.
- [ ] Implement logic to gather and replay prior edits from the session into the modified model for accurate diffs.
- [ ] Add telemetry and defensive logging around model creation, diff compute, and apply operations.

Testing checklist
- Unit tests:
  - CodeCompareModelService.createModel: validates original & modified creation, SHA1 computation, replay of prior edits, and proper disposal.
  - DiffEditorPool.acquire/release semantics and isStale behavior under concurrent use.
  - Converting TextEdit groups into edit operations (TextEdit.asEditOperation) and expected pushEditOperations calls.
- Integration tests:
  - Streaming text-edit suggestions: modified model accumulates edits and UI diff updates; height updates propagate to the list properly.
  - Apply flow: applying edits updates workspace files as expected and updates chat state (applied flags); verify behavior when multiple edits target the same file.
  - SHA1 mismatch flow: simulate workspace change between preview and apply, assert confirmation modal shown and branch behaviors (force apply vs cancel vs refresh).
- Performance tests:
  - Pool reuse under many concurrent diffs; latency to render diffs for large files; time-to-apply edits for large multi-hunk changes.

Security & safety considerations
- Never mutate workspace files without explicit user confirmation when the original SHA1 differs.
- Present clear, localized explanations when conflicts are detected (e.g., "The file changed since this suggestion was generated").
- Respect file permissions and workspace protections (read-only files, git locks) and surface informative errors instead of crashing.

Implementation risks & mitigations
- Race conditions between streaming updates and user actions (apply/open):
  - Mitigation: serialize apply operations per target file and use isStale guards on pooled references.
- Memory leaks from long-lived model references:
  - Mitigation: use RefCountedDisposable with timeouts and ensure pool release paths always dispose models.
- Large diffs causing UI jank:
  - Mitigation: throttle diff computation, show skeletons, and limit pool sizing to avoid overcommit.

Cross-links
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1`](src/vs/workbench/contrib/chat/browser/chatContentParts/chatTextEditContentPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1`](src/vs/workbench/contrib/chat/browser/codeBlockPart.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatEditor.ts:1`](src/vs/workbench/contrib/chat/browser/chatEditor.ts:1)
- [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`](src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1)

End of document
