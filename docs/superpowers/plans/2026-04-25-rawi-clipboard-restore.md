# Rawi Clipboard Restore Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the user's previous text clipboard after Rawi auto-pastes a transcription.

**Architecture:** Keep the feature inside `src-tauri/src/paste.rs`. Add a tiny clipboard abstraction so the restore flow can be tested without touching the real OS clipboard or simulating keyboard input.

**Tech Stack:** Rust, Tauri backend, `arboard`, existing Cargo test runner.

---

### Task 1: Clipboard Restore Flow

**Files:**
- Modify: `src-tauri/src/paste.rs`

- [ ] **Step 1: Write failing tests**

Add tests showing that the paste helper captures previous clipboard text, sets the transcription, invokes paste, and restores the previous text afterward.

- [ ] **Step 2: Run focused test**

Run: `cargo test paste::tests::restores_previous_text_after_paste`

Expected: fail because the helper does not exist yet.

- [ ] **Step 3: Implement helper**

Add a private clipboard text trait, an `arboard::Clipboard` implementation, and a helper used by `paste_text`.

- [ ] **Step 4: Run focused test**

Run: `cargo test paste::tests::restores_previous_text_after_paste`

Expected: pass.

- [ ] **Step 5: Run backend verification**

Run: `cargo test`

Expected: all backend tests pass.
