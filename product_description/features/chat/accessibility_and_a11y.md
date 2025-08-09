# Chat — Accessibility & A11y

Purpose
- Ensure the chat UI is fully accessible to keyboard users and screen readers, including progressive streaming responses, attachments, embedded code blocks, and interactive followups.

Responsibilities
- Provide ARIA semantics and live-region updates for progressive/streaming responses.
- Ensure keyboard navigation for the virtualized list, attachments, toolbars, and embedded editors.
- Make hover/tooltips accessible (aria-describedby / managed hovers) and provide fallback text for assistive tech.
- Announce errors, quota messages and important state changes in a consistent, non-spammy way.

Key implementation files
- [`src/vs/workbench/contrib/chat/browser/chatAccessibilityProvider.ts:1`]
- [`src/vs/workbench/contrib/chat/browser/chatListRenderer.ts:1`]
- [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`]
- [`src/vs/workbench/contrib/chat/browser/chatContentParts/chatMarkdownContentPart.ts:1`]
- [`src/vs/workbench/contrib/chat/browser/chatInputPart.ts:1`]

UI patterns & specifics to preserve when porting
- List semantics:
  - The chat history acts as a list of items (requests/responses). Use appropriate role/list/listitem semantics and ensure focus moves predictably between items.
  - Virtualized lists must preserve accessibility: only the active/focused item should be focusable; offscreen items should not trap focus.
- Progressive/streaming responses:
  - Use aria-live regions (polite or assertive as appropriate) to announce "response starting", incremental progress (summarized), and "response complete".
  - Avoid announcing every incremental word. Instead, announce when streaming starts, optionally a coarse "updating" status, and a final announcement when complete.
  - The codebase uses small alerts (see usages of alert()) and a ChatAccessibilityService to surface these semantics — preserve equivalent in the target runtime.
- Embedded editors & code blocks:
  - Code regions should have accessible names (e.g., "Code block — JavaScript") and expose role="textbox" or equivalent.
  - Provide keyboard shortcuts / actions for "Copy code", "Open in editor", and ensure those actions are discoverable via the keyboard and screen reader.
- Attachments & chips:
  - Each attachment chip must include an aria-label describing the attachment (file name, line-range for file fragments, or image description).
  - Deletion/clear buttons must be keyboard reachable and announce the resulting state (removed).
- Hovers and tooltips:
  - Managed hovers should provide accessible fallbacks; use aria-describedby or an offscreen element with the same text for screen readers.
  - When hover content contains interactive controls, ensure trapFocus behavior is implemented or an accessible alternative is provided.

Implementation & porting notes
- Platform accessibility primitives:
  - Use the target platform's native accessibility APIs (aria-* in web, NSAccessibility on macOS, UIAccessibility on iOS, etc.) to implement live regions and role semantics.
- Virtualization:
  - Ensure the virtualization implementation exposes the visible DOM nodes to assistive tech correctly and that keyboard focus does not jump to recycled nodes unexpectedly.
- Announcements:
  - Implement a small accessibility service to centralize live-region announcements (rate-limit announcements, provide start/stop messages).
- Hints:
  - Provide concise ARIA labels rather than long verbatim content for announcements; use more detailed content only on explicit focus.
  - Where the original uses visual cues (icons, color), ensure equivalent textual hints exist (aria-label, visually hidden text).

Testing & validation
- Automated accessibility tests (e.g., Axe, Pa11y) focused on:
  - ARIA roles and attributes for list and listitems.
  - Presence of aria-live region(s) for streaming content.
  - Keyboard focusability and tab order for attachments, toolbars, and content parts.
- Manual screen-reader walkthroughs:
  - Compose → Send → Progressive stream → Final content sequence (NVDA/VoiceOver/JAWS).
  - Open attachment preview and clear attachment via keyboard.
  - Open codeblock actions: Copy, Open in Editor, Apply Edit.
  - Error/quota flows and confirmation dialogues (ensure announcements occur).
- User testing:
  - Include users with assistive technology to validate timing and verbosity choices for progressive rendering announcements.

Accessibility checklist (for porting)
- [ ] Implement aria-live regions for progressive updates and final content announcements.
- [ ] Ensure each chat list item is reachable via keyboard and has an accessible name.
- [ ] Ensure all interactive elements (attachments, toolbar buttons, followups) have aria-labels and keyboard handlers.
- [ ] Provide accessible names and roles for embedded code blocks and editors and expose copy/select actions.
- [ ] Provide accessible fallbacks for hover/tooltips (aria-describedby or offscreen text).
- [ ] Add automated a11y tests and manual test scripts.

Cross-links
- Chat overview: [`product_description/features/chat/overview.md:1`]
- Renderer & markdown: [`src/vs/workbench/contrib/chat/browser/chatMarkdownRenderer.ts:1`]
- Widget & input: [`product_description/features/chat/widget.md:1`], [`product_description/features/chat/input.md:1`]
