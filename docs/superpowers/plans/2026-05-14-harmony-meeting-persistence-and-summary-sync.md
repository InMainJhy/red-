# Harmony Meeting Persistence And Summary Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist Harmony meeting state across app restarts, auto-sync completed meetings into the summary list, separate history-meeting and summary responsibilities, and remove the round-count setting from the meeting parameter flow.

**Architecture:** Keep the changes scoped to the existing Harmony front-end flow. Upgrade `MeetingSessionStore` from a static in-memory bridge to a lightweight persisted session store, wire `MeetingChatPage` completion into `SummaryService`, keep homepage history driven by arena history, and move the summary list to the dedicated summary data source.

**Tech Stack:** HarmonyOS ArkTS, `@ohos.data.preferences`, `Index.ets`, `MeetingChatPage.ets`, `SummaryListPage.ets`, `SummaryDetailPage.ets`, `MeetingSessionStore.ets`, `SummaryService.ets`.

---

### Task 1: Persist Meeting Session State

**Files:**
- Modify: `harmony/entry/src/main/ets/utils/MeetingSessionStore.ets`
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingProfilePickerPage.ets`

- [ ] Replace the current static-only `MeetingSessionStore` state with a persisted store backed by local Preferences while keeping the existing API shape as stable as possible for callers.
- [ ] Persist `profileId`, `profileIds`, `selectedAgentIds`, `topic`, `reasoningEffort`, and the latest continue-meeting context needed to reopen the session after a cold start.
- [ ] Add explicit initialization and hydration points so homepage, profile picker, and meeting page can restore the stored state on first load instead of behaving like a fresh install.
- [ ] Keep a safe fallback path where persistence failure only logs and falls back to in-memory state.

### Task 2: Remove Round Count From The Harmony Meeting Flow

**Files:**
- Modify: `harmony/entry/src/main/ets/utils/MeetingSessionStore.ets`
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
- Modify: `harmony/entry/src/main/ets/common/Models.ets` if route typing cleanup is needed

- [ ] Delete the stored `roundCount` field and its getters/setters from `MeetingSessionStore`.
- [ ] Remove round-count UI, defaults, save behavior, and route parameter passing from the homepage parameter panel.
- [ ] Remove round-count parsing and request passing from `MeetingChatPage` so the backend default turn count is used.
- [ ] Keep only `reasoningEffort` as the remaining user-facing meeting parameter.

### Task 3: Auto-Sync Completed Meetings Into Summary Storage

**Files:**
- Modify: `harmony/entry/src/main/ets/service/SummaryService.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`

- [ ] Make `SummaryService` safe to initialize from non-summary pages so meeting completion can save records on the first run.
- [ ] Add an idempotent “upsert by `arenaRunId`” path so the same meeting completion cannot create duplicate summaries.
- [ ] In `MeetingChatPage`, when a streamed or fallback meeting finishes successfully, convert the result into a summary record and save it automatically through `SummaryService`.
- [ ] Show a meeting-complete toast/status message that tells the user the result has already been synced to the summary page, while keeping them on the meeting screen.

### Task 4: Separate Homepage History From Summary List Responsibilities

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`

- [ ] Keep homepage history sourced from `PersonaApi.getArenaHistory(...)`, with record tap behavior continuing the selected meeting instead of opening its summary.
- [ ] Change `SummaryListPage` to load from `SummaryService.getSummaryList(...)` so the page shows synced summaries rather than raw arena history.
- [ ] Preserve `SummaryDetailPage` compatibility for both `summaryId` and legacy `arenaRunId` entry paths, but ensure the primary list navigation flows through summary records.
- [ ] Review empty/error states so the UI language clearly distinguishes “历史会议” from “纪要”.

### Task 5: Verification And Regression Check

**Files:**
- Modify: `harmony/entry/src/main/ets/utils/MeetingSessionStore.ets`
- Modify: `harmony/entry/src/main/ets/service/SummaryService.ets`
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`

- [ ] Run the most practical available verification command for the Harmony workspace and report the exact outcome.
- [ ] Do a targeted code scan for `roundCount` usage and remove or explain any remaining references.
- [ ] Verify the meeting completion path still supports continuing a historical meeting after saving the summary.
- [ ] Review the final diff to confirm the behavioral split is correct: homepage history continues meetings, summary page shows synced summaries, and meeting page no longer acts as the main summary result surface.
