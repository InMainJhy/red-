# Harmony Homepage Visual Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the Harmony homepage visual quality without changing its information architecture or business behavior.

**Architecture:** Keep the work scoped to the existing homepage style tokens and `Index.ets` builder methods. Reuse the current layout and click flows, but replace the visual treatment of the background and homepage cards with a colder, more cohesive poster-like system.

**Tech Stack:** HarmonyOS ArkTS, homepage builders in `harmony/entry/src/main/ets/pages/Index.ets`, shared color tokens in `harmony/entry/src/main/ets/common/styles/Colors.ets`.

---

### Task 1: Refresh Shared Color Language

**Files:**
- Modify: `harmony/entry/src/main/ets/common/styles/Colors.ets`

- [ ] Adjust the base background, card, text accent, border, and glow tokens toward a colder blue-gray palette while keeping contrast safe for the existing homepage.
- [ ] Keep the token names stable so no homepage logic changes are required.
- [ ] Verify the updated tokens still make semantic sense for success, warning, error, and text hierarchy.

### Task 2: Rebuild Homepage Background

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`

- [ ] Replace the current homepage background blobs with fewer, larger, lower-contrast atmospheric layers.
- [ ] Reduce mint and candy-like color bias, favoring foggy blue-gray, cold white, and pale silver-blue.
- [ ] Preserve full-screen coverage and current layout safety.

### Task 3: Redesign Large Homepage Function Cards

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`

- [ ] Rework `buildHomeFeatureCard` into a cleaner poster-collage treatment while preserving the existing 2x2 feature grid and navigation.
- [ ] Add layered backplates, cropped accent blocks, quieter mascot usage, and stronger typography hierarchy.
- [ ] Normalize card colors so the four cards feel like one family instead of four unrelated gradients.

### Task 4: Harmonize Secondary Homepage Cards

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`

- [ ] Tune the meeting hero, prep cards, quick actions, and history empty state so they match the new card system more closely.
- [ ] Reduce oversaturated highlights and soften glass effects where needed.
- [ ] Keep interactions, touch feedback, and routes unchanged.

### Task 5: Verify the Visual Refresh

**Files:**
- Modify: `harmony/entry/src/main/ets/common/styles/Colors.ets`
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`

- [ ] Run the most practical available verification command for the Harmony workspace and report exact results.
- [ ] Perform a targeted text scan to confirm the homepage still references the same routes and builders.
- [ ] Review the final diff to ensure the change stays visual-only and homepage-scoped.
