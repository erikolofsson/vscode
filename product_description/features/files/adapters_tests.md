# Adapter test proposals — Files contribution

Purpose
- Provide unit and integration test proposals to validate adapter implementations and important porting assumptions for the Files contribution.
- These tests target correctness of streaming I/O, undo/atomicity semantics, watcher resiliency, working-copy lifecycle (save/backup/revert), and editor-resolver flows.
- Reference docs:
  - Design & API sketches: [`product_description/features/files/adapters.md:1`](product_description/features/files/adapters.md:1)
  - Adapter shim implementations: [`src/adapters/bulkEditAdapter.ts:1`](src/adapters/bulkEditAdapter.ts:1), [`src/adapters/fileWatcherAdapter.ts:1`](src/adapters/fileWatcherAdapter.ts:1), [`src/adapters/workingCopyAdapter.ts:1`](src/adapters/workingCopyAdapter.ts:1), [`src/adapters/uploadAdapter.ts:1`](src/adapters/uploadAdapter.ts:1), [`src/adapters/fileSystemAccessAdapter.ts:1`](src/adapters/fileSystemAccessAdapter.ts:1), [`src/adapters/modelReferenceAdapter.ts:1`](src/adapters/modelReferenceAdapter.ts:1), [`src/adapters/editorResolverAdapter.ts:1`](src/adapters/editorResolverAdapter.ts:1)

Test matrix (high level)
1) BulkEditAdapter tests
   - Unit: apply() basic success
     - Arrange: small list of edits (create/update/delete) against an in-memory host or mock FS.
     - Assert: apply() returns success=true and no failed[]; target resources exist with expected contents.
   - Unit: partial failure handling
     - Arrange: simulate a failure on one edit (e.g., permission error).
     - Assert: apply() returns success=false, failed[] contains the failing edit; other edits were applied or rolled back depending on host capability. Verify documented host behavior.
   - Integration: undo semantics
     - Arrange: host exposes undoToken from apply().
     - Action: call revert(undoToken).
     - Assert: resources revert to pre-edit state (or revert() returns false if unsupported but documented).
   - Performance: large-batch latency
     - Test applying many small edits vs fewer large-file edits; assert host doesn't block event-loop for unreasonable time.

2) FileWatcherAdapter tests
   - Unit: event emission
     - Simulate file changes via adapter helpers (e.g., `simulateChange`) and assert onDidChange listeners receive correct FileChangesEvent shaped payloads.
   - Resilience: error handling and backoff
     - Simulate onDidError conditions and assert host callers observe error event and that watch() can be disposed and restarted cleanly.
   - Integration: pause/resume behavior
     - If adapter provides pause/resume (or host implements by disposing/creating watcher), assert that a paused watcher doesn't emit changes and a resumed watcher emits events for subsequent changes.
   - Scalability: many rapid changes
     - Emit large number of change events and verify adapter/client debounce behavior and that no events are lost (or are coalesced as documented).

3) WorkingCopyAdapter tests
   - Unit: save/dirty lifecycle
     - Mark resource dirty, assert isDirty() true, call save(), assert isDirty() false and onDidChangeDirty fired.
   - Backup: backup() contract
     - Call backup() and assert returned URI (if any) is well-formed and onDidBackup event fired with matching resources.
   - Revert: revert() restores state
     - After modifications, call revert() and assert model content returns to previous saved/backup state.
   - Hot-exit scenario
     - Simulate shutdown sequence: query isDirty(), call backup() for all dirty, ensure all backups succeed or are properly reported.

4) UploadAdapter tests
   - Streaming: large file write
     - Provide an AsyncIterable<Uint8Array> that yields many chunks; call write(); assert target contents match the concatenation and onProgress callbacks (if provided) receive increasing loaded values.
   - File.stream() fallback
     - For environments with File.stream(), exercise writeFileObject(); in environments without, exercise arrayBuffer fallback and assert correctness.
   - Concurrency limits
     - Create concurrent uploads to same/adjacent resources and assert host behavior: serializes, rejects, or merges as documented.

5) FileSystemAccessAdapter tests
   - Write stream correctness
     - createWriteStream(uri) -> write chunks -> close(); assert final file contents match written bytes and that close() flushes output.
   - Pick file/folder
     - If pickFile/pickFolder implemented, test expected returned URIs and save flow from consumers.
   - Web API fallbacks
     - Simulate absence of File System Access APIs and assert adapter provides expected fallbacks (blob download, host dialog).

6) ModelReferenceAdapter tests
   - Acquire / reference lifetime
     - Acquire model reference twice for same resource and assert returned references expose the same underlying model (or defined host semantics such as copy-on-write).
   - Content change events
     - Simulate external change and assert onDidChangeContent fires with correct resource and that consumers update accordingly.
   - Disposal safety
     - Dispose a reference and assert subsequent operations behave as documented (either error or re-acquire creates fresh model).

7) EditorResolverAdapter tests
   - Editor enumeration
     - getEditorsFor(resource) returns a sorted list by priority and only supports matching descriptors.
   - Open by id
     - open(resource, editorId) triggers the expected adapter behavior (fire event or call into host open path).
   - Registering new editors
     - registerEditor (or dynamic editor registration) causes getEditorsFor to include the new descriptor and not break existing consumers.

Suggested test harness & patterns
- Use a lightweight test runner (Jest or Mocha + ts-node) for fast iteration in a host repo:
  - Tests should import the shims in `src/adapters/*.ts` for the baseline contract.
  - Keep adapter example implementations (InMemory*) local to tests to avoid coupling to real FS.
- For streaming tests, provide helper AsyncIterable producers that yield deterministic chunks and optionally delay between yields to simulate network or slow streams.
- Use property-based inputs for bulk-edit (randomized small edits) to exercise edge-cases like name collisions, cross-directory moves, and metadata preservation.

Mocking & dependency injection
- Each adapter test should accept a small mock host that exposes the minimal host primitives (e.g., an in-memory path map, a simulated dialog result).
- Prefer deterministic, synchronous mocks for unit tests; use heavier integration tests for host-specific behavior.

Acceptance criteria
- Each adapter must have at least:
  - 5 unit tests covering happy-path and primary failure modes
  - 2 integration tests for streaming and undo semantics (or documented host-limited behavior)
- Tests must run in CI quickly (< 30 seconds total for adapters unit tests ideally) by using in-memory mocks and not touching platform-native dialogs.

Next steps for implementers
1. Create `test/adapters/` and add test harness and runner config.
2. Implement unit tests using the InMemory* shims already present under `src/adapters/` as seed implementations:
   - [`src/adapters/bulkEditAdapter.ts:1`](src/adapters/bulkEditAdapter.ts:1)
   - [`src/adapters/fileWatcherAdapter.ts:1`](src/adapters/fileWatcherAdapter.ts:1)
   - [`src/adapters/workingCopyAdapter.ts:1`](src/adapters/workingCopyAdapter.ts:1)
   - [`src/adapters/uploadAdapter.ts:1`](src/adapters/uploadAdapter.ts:1)
   - [`src/adapters/fileSystemAccessAdapter.ts:1`](src/adapters/fileSystemAccessAdapter.ts:1)
   - [`src/adapters/modelReferenceAdapter.ts:1`](src/adapters/modelReferenceAdapter.ts:1)
   - [`src/adapters/editorResolverAdapter.ts:1`](src/adapters/editorResolverAdapter.ts:1)
3. Add CI job to run adapter tests on push and PRs.

Document created: [`product_description/features/files/adapters_tests.md:1`](product_description/features/files/adapters_tests.md:1)
