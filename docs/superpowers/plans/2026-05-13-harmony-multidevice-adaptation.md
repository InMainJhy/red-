# Harmony Multi-Device Adaptation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable Harmony breakpoint/layout layer and apply it to the main user flow so phone, foldable, and tablet layouts behave intentionally instead of stretching the mobile UI.

**Architecture:** Introduce a shared breakpoint observer plus pure responsive layout metrics, then wire those metrics into the Harmony home, meeting prep, meeting chat, and summary detail pages. Keep first-pass adaptation focused on container width, page gutters, and single-column versus split-column composition.

**Tech Stack:** ArkTS, HarmonyOS ArkUI, Hypium unit tests

---

### Task 1: Build reusable responsive primitives

**Files:**
- Create: `harmony/entry/src/main/ets/common/BreakpointSystem.ets`
- Create: `harmony/entry/src/main/ets/common/ResponsiveLayout.ets`
- Modify: `harmony/entry/src/test/LocalUnit.test.ets`
- Modify: `harmony/entry/src/test/List.test.ets`

- [ ] Add pure breakpoint-to-layout mapping with test coverage for `xs/sm/md/lg/xl`.
- [ ] Add a shared mediaquery breakpoint observer for live page updates.
- [ ] Keep layout metrics small and page-oriented: max width, gutters, section gap, card padding, split layout flags.

### Task 2: Adapt the main home and meeting prep pages

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingParticipantPage.ets`

- [ ] Subscribe both pages to shared breakpoint updates.
- [ ] Replace fixed outer paddings with responsive gutters.
- [ ] Constrain main content width on larger devices.
- [ ] Convert key sections from a single stacked column to split layout where appropriate.

### Task 3: Adapt the meeting chat and summary detail pages

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`

- [ ] Apply responsive gutters and max-width containers.
- [ ] Keep chat readable on wide screens by preventing line lengths from stretching too far.
- [ ] Use split layout for summary actions/body on medium-large screens.

### Task 4: Add resource adaptation scaffolding and verify

**Files:**
- Create: `harmony/entry/src/main/resources/phone/element/float.json`
- Create: `harmony/entry/src/main/resources/tablet/element/float.json`

- [ ] Add baseline phone/tablet float resources so the project is ready for more resource-driven adaptation.
- [ ] Run the available local verification commands and note any environment blockers.
