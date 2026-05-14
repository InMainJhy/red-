# Harmony Homepage Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the Harmony homepage into a meeting-first workspace with a stronger Hero card, clearer preparation state, lighter quick actions, and recent meeting continuity.

**Architecture:** Keep the implementation scoped to `harmony/entry/src/main/ets/pages/Index.ets`, because the existing page already owns selected profile, selected agents, topic, navigation, history records, safe area, and press states. Add focused helper methods and Builder blocks inside the page rather than introducing new cross-page contracts.

**Tech Stack:** HarmonyOS ArkTS, existing local style tokens from `Colors`, `MobileSpacing`, `BorderRadius`, and existing navigation helpers.

---

### Task 1: Add Meeting-First State Helpers

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Add helper methods near existing homepage label helpers**

Add methods that derive meeting readiness, selected profile text, selected agent count, topic preview, and primary action text from the existing state:

```ts
private meetingHeroSubtitle(): string {
  if (this.hasReadyMeetingSelection()) {
    return `${this.selectedAgents().length} 个阶段人格已就绪，适合展开一场正式讨论。`
  }
  if (this.hasSelectedProfile()) {
    return `先从 ${this.selectedProfile.displayName} 的阶段人格里挑出两位参会者。`
  }
  return '先选择一个角色，再让不同阶段的人格围绕问题展开讨论。'
}

private meetingPrimaryActionLabel(): string {
  if (this.hasReadyMeetingSelection()) {
    return '立即开始会议'
  }
  if (this.hasSelectedProfile()) {
    return '整理参会人格'
  }
  return '选择角色'
}

private meetingProfileLabel(): string {
  return this.hasSelectedProfile() ? this.selectedProfile.displayName : '待选择'
}

private meetingAgentCountLabel(): string {
  if (!this.hasSelectedProfile()) {
    return '0 / 2'
  }
  return `${this.selectedAgents().length} / 2`
}

private meetingTopicPreview(): string {
  if (this.topic.length <= 34) {
    return this.topic
  }
  return `${this.topic.slice(0, 34)}...`
}
```

- [ ] **Step 2: Add a navigation helper for the Hero primary action**

Use existing methods and state so the action succeeds or guides the user:

```ts
private async handleMeetingPrimaryAction(): Promise<void> {
  if (!this.hasSelectedProfile()) {
    await this.goExplorePersonas()
    return
  }
  await this.goMeetingParticipant()
}
```

- [ ] **Step 3: Run a static syntax check**

Run: `npm run build` from `harmony` if available.

Expected: Build reaches ArkTS compilation or fails only for pre-existing project environment issues.

### Task 2: Replace Homepage Composition

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Replace `buildHomeTab` composition**

Change the default homepage order to:

```ts
@Builder
private buildHomeTab() {
  Column({ space: 14 }) {
    this.buildWelcomeSection()
    this.buildMeetingHeroCard()
    this.buildMeetingPrepSection()
    this.buildHomeQuickActions()
    this.buildHomeHistorySection()
  }
  .width('100%')
  .alignItems(HorizontalAlign.Start)
}
```

- [ ] **Step 2: Add `buildMeetingHeroCard`**

Create a large Hero card with title, selected role summary, topic preview, and primary CTA. The CTA calls `handleMeetingPrimaryAction`.

- [ ] **Step 3: Add `buildMeetingPrepSection` and `buildMeetingPrepCard`**

Add three compact preparation cards: selected role, selected stages, current topic. Each card has a clear click path.

- [ ] **Step 4: Run a focused text scan**

Run: `rg "buildMeetingHeroCard|buildMeetingPrepSection|handleMeetingPrimaryAction" harmony/entry/src/main/ets/pages/Index.ets`

Expected: All new methods are present and referenced.

### Task 3: Tune Secondary Sections

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Rename quick action section title to secondary role**

Change the section title from `快捷入口` to `继续扩展`.

- [ ] **Step 2: Update quick actions to support the meeting-first flow**

Keep two quick actions: create role and import data. Use compact card layout already present in `buildSoftQuickAction`.

- [ ] **Step 3: Rename history section**

Change `历史会议` to `最近纪要`, and update the empty-state text to point users back to the meeting Hero.

- [ ] **Step 4: Verify the page still references existing navigation only**

Run: `rg "pages/" harmony/entry/src/main/ets/pages/Index.ets`

Expected: No new route names outside the existing Harmony pages are introduced.

### Task 4: Verify and Review

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Read: `docs/superpowers/specs/2026-05-11-harmony-homepage-layout-design.md`

- [ ] **Step 1: Run available build or lint command**

Run: `npm run build` from `harmony`.

Expected: The command succeeds, or any failure is reported with the concrete reason.

- [ ] **Step 2: Check changed files**

Run: `git diff -- harmony/entry/src/main/ets/pages/Index.ets docs/superpowers/plans/2026-05-11-harmony-homepage-layout.md`

Expected: Diff shows only homepage layout and plan changes.

- [ ] **Step 3: Final self-review against spec**

Confirm these points:

1. Hero card is the largest homepage action.
2. Role, stages, and topic are visible before secondary actions.
3. Quick actions and recent records are below the main meeting path.
4. Existing safe area, tab bar, loading, and error handling remain intact.
