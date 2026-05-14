# Harmony Motion System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a unified “lightly dynamic” motion system to the Harmony app, covering page-to-page transitions, staged page entrance, card press feedback, and list stagger across the homepage, persona browsing, creation, meeting, and summary flows.

**Architecture:** Reuse the existing animation token files in `common/styles` and the per-page `@State` animation patterns already present in `Index`, `ExplorePersonas`, `MeetingChatPage`, and `SummaryListPage`. Extend shared motion helpers first, then wire the same transition contract into the first-round core pages so navigation and section reveal use the same timing, offsets, and press feedback.

**Tech Stack:** HarmonyOS ArkTS, existing `Animation.ets` and `Effects.ets` tokens, page-local `animateTo` state transitions, router params, and the current `DynamicGlassBackground` / card-based UI components.

---

### Task 1: Extend Shared Motion Tokens and Helpers

**Files:**
- Modify: `harmony/entry/src/main/ets/common/styles/Animation.ets`
- Modify: `harmony/entry/src/main/ets/common/styles/index.ets`

- [ ] **Step 1: Add shared motion constants and route-friendly direction types**

Insert shared constants near the existing stagger helpers so every page reads from the same source:

```ts
export type MotionDirection = 'forward' | 'backward' | 'up'

export const PAGE_MOTION_X_FORWARD: number = 34
export const PAGE_MOTION_X_BACKWARD: number = -28
export const PAGE_MOTION_Y_UP: number = 22
export const PAGE_SECTION_HERO_Y: number = 24
export const PAGE_SECTION_CARD_Y: number = 18
export const PAGE_SECTION_LIST_Y: number = 14
export const CARD_PRESS_DOWN_VP: number = 2
```

- [ ] **Step 2: Add reusable helpers for page start positions and section delay**

Add functions that convert a direction or section type into offsets and delays:

```ts
export function getPageMotionStartX(direction: MotionDirection): number {
  if (direction === 'backward') {
    return PAGE_MOTION_X_BACKWARD
  }
  if (direction === 'forward') {
    return PAGE_MOTION_X_FORWARD
  }
  return 0
}

export function getPageMotionStartY(direction: MotionDirection): number {
  return direction === 'up' ? PAGE_MOTION_Y_UP : 0
}

export function getSectionRevealOffset(section: 'hero' | 'card' | 'list'): number {
  if (section === 'hero') {
    return PAGE_SECTION_HERO_Y
  }
  if (section === 'card') {
    return PAGE_SECTION_CARD_Y
  }
  return PAGE_SECTION_LIST_Y
}

export function getSectionRevealDelay(index: number, baseDelay: number = PAGE_SECTION_STAGGER_MS): number {
  return index * baseDelay
}
```

- [ ] **Step 3: Re-export the new helpers from the styles index**

Update the shared export surface so pages can import one source:

```ts
export {
  AnimationDuration,
  AnimationCurve,
  AnimationPresets,
  AnimationPreset,
  HoverEffects,
  PressEffects,
  HoverEffect,
  PressEffect,
  MotionDirection,
  PAGE_SECTION_STAGGER_MS,
  CARD_PRESS_DOWN_VP,
  getStaggerDelay,
  getSectionRevealDelay,
  getSectionRevealOffset,
  getPageMotionStartX,
  getPageMotionStartY,
  getAppearAnimation,
  getDisappearAnimation,
  getScaleInAnimation,
  ShimmerAnimation
} from './Animation'
```

- [ ] **Step 4: Verify the helper names are exported exactly once**

Run: `rg -n "MotionDirection|CARD_PRESS_DOWN_VP|getPageMotionStartX|getSectionRevealDelay" harmony/entry/src/main/ets/common/styles`

Expected: The new symbols appear in `Animation.ets` and are re-exported from `index.ets` without duplicate definitions.

### Task 2: Unify Core Navigation Transitions

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/ExplorePersonas.ets`
- Modify: `harmony/entry/src/main/ets/pages/CreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/AIDialogueCreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingParticipantPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`

- [ ] **Step 1: Pass a transition direction through homepage navigation**

Update the core `router.pushUrl` calls in `Index.ets` so first-round destination pages receive a `motionDirection` param:

```ts
await this.router().pushUrl({
  url: 'pages/ExplorePersonas',
  params: {
    motionDirection: 'forward'
  }
})
```

Apply the same parameter to the homepage routes that open:

- `pages/CreateRole`
- `pages/AIDialogueCreateRole`
- `pages/MeetingParticipantPage`
- `pages/MeetingChatPage`
- `pages/SummaryListPage`

- [ ] **Step 2: Standardize destination page enter animation state**

For each first-round page, add or align a pair of page-level states:

```ts
@State private pageSlideX: number = 34
@State private pageSlideOpacity: number = 0
```

And in `aboutToAppear()` initialize them from route params:

```ts
const params = router.getParams() as RouteParams
const motionDirection = (params.motionDirection as MotionDirection) ?? 'forward'
this.pageSlideX = getPageMotionStartX(motionDirection)
this.pageSlideOpacity = 0

setTimeout(() => {
  animateTo({
    duration: AnimationDuration.page,
    curve: AnimationCurve.emphasized
  }, () => {
    this.pageSlideX = 0
    this.pageSlideOpacity = 1
  })
}, 10)
```

- [ ] **Step 3: Apply the page container transform to every first-round page root**

Wrap each page’s top-level content container with the same transform contract:

```ts
.opacity(this.pageSlideOpacity)
.translate({ x: this.pageSlideX, y: 0 })
.animation({
  duration: AnimationDuration.page,
  curve: AnimationCurve.emphasized
})
```

- [ ] **Step 4: Wire summary detail navigation to use the same contract**

Update `SummaryListPage.navigateToDetail` to pass a forward transition:

```ts
router.pushUrl({
  url: 'pages/SummaryDetailPage',
  params: {
    arenaRunId: card.runId,
    motionDirection: 'forward'
  }
})
```

- [ ] **Step 5: Verify the route param is used across the first-round pages**

Run: `rg -n "motionDirection|pageSlideX|pageSlideOpacity" harmony/entry/src/main/ets/pages/{Index,ExplorePersonas,CreateRole,AIDialogueCreateRole,MeetingParticipantPage,MeetingChatPage,SummaryListPage,SummaryDetailPage}.ets`

Expected: `Index.ets` passes `motionDirection`, and every first-round destination page reads it and animates its root container.

### Task 3: Add Shared Section Reveal and Card Feedback to Homepage and Persona Browsing

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/ExplorePersonas.ets`

- [ ] **Step 1: Replace homepage one-off entrance timings with grouped section reveal**

In `Index.ets`, add explicit state for section entrance:

```ts
@State private prepSectionOpacity: number = 0
@State private prepSectionY: number = PAGE_SECTION_CARD_Y
@State private actionsSectionOpacity: number = 0
@State private actionsSectionY: number = PAGE_SECTION_LIST_Y
@State private recordsSectionOpacity: number = 0
@State private recordsSectionY: number = PAGE_SECTION_LIST_Y
```

Then create a staged entry method:

```ts
private animateHomeSections(): void {
  setTimeout(() => {
    animateTo({ duration: AnimationDuration.slow, curve: AnimationCurve.smooth }, () => {
      this.prepSectionOpacity = 1
      this.prepSectionY = 0
    })
  }, getSectionRevealDelay(1))

  setTimeout(() => {
    animateTo({ duration: AnimationDuration.slow, curve: AnimationCurve.smooth }, () => {
      this.actionsSectionOpacity = 1
      this.actionsSectionY = 0
    })
  }, getSectionRevealDelay(2))

  setTimeout(() => {
    animateTo({ duration: AnimationDuration.slow, curve: AnimationCurve.smooth }, () => {
      this.recordsSectionOpacity = 1
      this.recordsSectionY = 0
    })
  }, getSectionRevealDelay(3))
}
```

- [ ] **Step 2: Apply grouped reveal transforms to homepage section builders**

Apply the section state to the containers for “准备”, “扩展”, and “最近纪要”:

```ts
.opacity(this.prepSectionOpacity)
.translate({ x: 0, y: this.prepSectionY })
```

Use the matching `actionsSection*` and `recordsSection*` states on the other two blocks.

- [ ] **Step 3: Strengthen homepage card press feedback with shared down offset**

Update the primary meeting card, workbench cards, and latest summary card so the pressed state also shifts down:

```ts
.scale({
  x: this.pressedMeetingCardTag === tag ? 0.97 : 1,
  y: this.pressedMeetingCardTag === tag ? 0.97 : 1
})
.translate({ x: 0, y: this.pressedMeetingCardTag === tag ? CARD_PRESS_DOWN_VP : 0 })
```

- [ ] **Step 4: Apply the same reveal rhythm to `ExplorePersonas`**

Align the hero, search area, category bar, and results list with the shared section offsets:

```ts
this.heroTranslateY = getSectionRevealOffset('hero')
this.searchPanelTranslateY = getSectionRevealOffset('card')
this.categoryBarTranslateY = getSectionRevealOffset('card')
this.resultsTranslateY = getSectionRevealOffset('list')
```

Keep the current search result card stagger, but replace hard-coded offsets with shared helper values.

- [ ] **Step 5: Verify homepage and persona browsing use the new motion helpers**

Run: `rg -n "getSectionRevealOffset|CARD_PRESS_DOWN_VP|prepSectionOpacity|actionsSectionOpacity|recordsSectionOpacity" harmony/entry/src/main/ets/pages/Index.ets harmony/entry/src/main/ets/pages/ExplorePersonas.ets`

Expected: Both files reference the shared helper names instead of duplicated literal offsets.

### Task 4: Apply Motion System to Creation and Meeting Pages

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/CreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/AIDialogueCreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingParticipantPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`

- [ ] **Step 1: Split creation page content into staged reveal groups**

For both creation pages, add section-level states such as:

```ts
@State private headerOpacity: number = 0
@State private headerY: number = PAGE_SECTION_HERO_Y
@State private formOpacity: number = 0
@State private formY: number = PAGE_SECTION_CARD_Y
@State private ctaOpacity: number = 0
@State private ctaY: number = PAGE_SECTION_LIST_Y
```

Animate them sequentially in `aboutToAppear()` and apply each pair to the matching content block.

- [ ] **Step 2: Add selection feedback and staged list reveal to `MeetingParticipantPage`**

Keep the existing selection logic, but normalize the movement and press rhythm:

```ts
.scale({
  x: this.isAgentSelected(agent.id) ? 1.02 : (this.pressedAgentId === agent.id ? 0.97 : 1),
  y: this.isAgentSelected(agent.id) ? 1.02 : (this.pressedAgentId === agent.id ? 0.97 : 1)
})
.translate({ x: 0, y: this.pressedAgentId === agent.id ? CARD_PRESS_DOWN_VP : 0 })
```

Also ensure the summary strip, selected-persona groups, and save CTA each reveal in separate timed groups.

- [ ] **Step 3: Upgrade `MeetingChatPage` from root slide only to grouped reveal**

Add section states for:

- meeting header
- message area shell
- composer area

Use the shared reveal offsets:

```ts
@State private headerOpacity: number = 0
@State private headerY: number = PAGE_SECTION_HERO_Y
@State private conversationOpacity: number = 0
@State private conversationY: number = PAGE_SECTION_CARD_Y
@State private composerOpacity: number = 0
@State private composerY: number = PAGE_SECTION_LIST_Y
```

Animate them in order after the page slide-in, then keep the existing bubble-by-bubble message animation for stream updates.

- [ ] **Step 4: Verify the creation and meeting pages now have grouped section state**

Run: `rg -n "headerOpacity|formOpacity|ctaOpacity|conversationOpacity|composerOpacity|CARD_PRESS_DOWN_VP" harmony/entry/src/main/ets/pages/{CreateRole,AIDialogueCreateRole,MeetingParticipantPage,MeetingChatPage}.ets`

Expected: The creation and meeting files contain section-level reveal states and shared press offset usage.

### Task 5: Apply Motion System to Summary Pages and Finish Verification

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`
- Read: `docs/superpowers/specs/2026-05-12-harmony-motion-system-design.md`

- [ ] **Step 1: Replace single body reveal in `SummaryListPage` with grouped entry**

Add separate states for:

- header hero
- summary list body
- empty/error state block

Use the shared offsets instead of the current single `bodyOpacity/bodyTranslateY` timing:

```ts
@State private heroOpacity: number = 0
@State private heroY: number = PAGE_SECTION_HERO_Y
@State private listOpacity: number = 0
@State private listY: number = PAGE_SECTION_LIST_Y
```

- [ ] **Step 2: Bring `SummaryDetailPage` onto the same page transition contract**

Keep its existing internal motion, but add the `motionDirection` page slide root states and align section offsets with the shared helpers for:

- hero
- toolbar
- content body

- [ ] **Step 3: Run static diff and identifier checks**

Run: `git diff --check`

Expected: No whitespace or merge-marker problems in any modified ArkTS files.

Run: `rg -n "motionDirection|getPageMotionStartX|getSectionRevealOffset|CARD_PRESS_DOWN_VP" harmony/entry/src/main/ets/pages harmony/entry/src/main/ets/common/styles`

Expected: Shared motion helpers are referenced by the first-round pages and the common styles layer.

- [ ] **Step 4: Perform Harmony build verification in DevEco Studio**

Run in DevEco Studio: `Build > Make Module 'entry'`

Expected: ArkTS compilation succeeds for the modified pages. If a failure remains, record the exact file and line number before any follow-up fix.

- [ ] **Step 5: Final visual review against the motion spec**

Confirm these outcomes manually in the Harmony preview:

1. Homepage modules no longer appear all at once; they establish focus in sequence.
2. Homepage routes into browse, create, meeting, and summary pages use the same horizontal page transition.
3. Persona chips, cards, and meeting cards share the same press/down response.
4. Creation and meeting pages feel alive without distracting from reading or input.
5. Summary list and detail pages feel part of the same motion system instead of a separate visual style.
