# Harmony Motion System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Harmony 端核心页面与分享/弹层组件补齐统一的页面进入、区块错峰、卡片入场与点击反馈动效。

**Architecture:** 先扩展 `common/styles/Animation.ets` 为统一动效 token 与 helper，再按“公共组件 -> 首页与会议主流程 -> 创建角色与探索 -> 纪要与分享弹层”的顺序接入。已有成熟动画的页面不推倒重写，只对齐 token、节奏和交互反馈。

**Tech Stack:** HarmonyOS ArkTS, ArkUI `animateTo`, `animation`, `TransitionEffect`, 现有 `Animation.ets`, `Spacing.ets`, `BorderRadius.ets`

---

## File Structure

### Shared motion foundation

- Modify: `harmony/entry/src/main/ets/common/styles/Animation.ets`
  - 统一页面进场位移、section 错峰间隔、卡片与按钮点击反馈、抽屉入场 token
  - 增补适合当前项目的 helper，避免页面里散落 magic number

### Shared interactive components

- Modify: `harmony/entry/src/main/ets/components/RoleHomeActionCards.ets`
  - 首页功能卡点击反馈对齐统一 token
- Modify: `harmony/entry/src/main/ets/components/RoleCard.ets`
  - 角色类大卡片点击反馈、入场节奏对齐
- Modify: `harmony/entry/src/main/ets/components/ShareSheet.ets`
  - 底部抽屉入场与内部 section 错峰
- Modify: `harmony/entry/src/main/ets/components/RecordsTab.ets`
  - 纪要中心行动卡与列表节奏对齐

### Core pages

- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
  - 首页统一页面进入与区块错峰
- Modify: `harmony/entry/src/main/ets/pages/MeetingParticipantPage.ets`
  - 保留现有成熟动画，统一 token 和点击反馈
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
  - 页面进入、准备卡、输入区的入场与点击反馈
- Modify: `harmony/entry/src/main/ets/pages/CreateRole.ets`
  - 创建角色页根容器、表单区、主按钮动效
- Modify: `harmony/entry/src/main/ets/pages/AIDialogueCreateRole.ets`
  - AI 创建角色页的顶部、模式切换、表单/对话区域动效
- Modify: `harmony/entry/src/main/ets/pages/ExplorePersonas.ets`
  - 顶部、筛选、卡片列表统一错峰
- Modify: `harmony/entry/src/main/ets/pages/UserCenter.ets`
  - 页面进入与资料卡块级出现
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
  - 列表进入和卡片轻入场
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`
  - 顶部、内容段落、操作区动效

### Verification

- Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`
  - 验证 `CompileArkTS` 通过

### Environment note

- 当前项目根目录 `/Users/intmainjhy/Desktop/intmainjhy/idea/redmain` 不是 Git 仓库，执行阶段不安排 commit step，改为每个任务完成后做 compile checkpoint。

---

### Task 1: Extend Motion Tokens And Helpers

**Files:**
- Modify: `harmony/entry/src/main/ets/common/styles/Animation.ets`

- [ ] **Step 1: Add unified motion tokens for page enter, stagger, and press feedback**

```ts
export class MotionTokenClass {
  pageEnterOffsetX: number = 28
  pageEnterOffsetY: number = 16
  sectionEnterOffsetY: number = 16
  cardEnterOffsetY: number = 14
  sheetEnterOffsetY: number = 32
  staggerStepMs: number = 64
  pressScaleCard: number = 0.978
  pressScaleButton: number = 0.962
  pressTranslateY: number = 2
}
export const MotionTokens: MotionTokenClass = new MotionTokenClass()
```

- [ ] **Step 2: Add helper functions for shared page and section animations**

```ts
export function getPageEnterAnimation(delay: number = 0): TransitionEffect {
  return TransitionEffect.OPACITY
    .animation({ duration: AnimationDuration.page, curve: AnimationCurve.emphasized, delay })
    .combine(TransitionEffect.translate({ x: MotionTokens.pageEnterOffsetX, y: 0 }))
    .animation({ duration: AnimationDuration.page, curve: AnimationCurve.emphasized, delay })
}

export function getSectionEnterAnimation(delay: number = 0): TransitionEffect {
  return TransitionEffect.OPACITY
    .animation({ duration: AnimationDuration.normal, curve: AnimationCurve.smooth, delay })
    .combine(TransitionEffect.translate({ y: MotionTokens.sectionEnterOffsetY }))
    .animation({ duration: AnimationDuration.slow, curve: AnimationCurve.smooth, delay })
}
```

- [ ] **Step 3: Add helper values for press animation timing**

```ts
export class MotionPressClass {
  cardDuration: number = AnimationDuration.fast
  buttonDuration: number = AnimationDuration.fast
  cardScale: number = MotionTokens.pressScaleCard
  buttonScale: number = MotionTokens.pressScaleButton
  offsetY: number = MotionTokens.pressTranslateY
}
export const MotionPress: MotionPressClass = new MotionPressClass()
```

- [ ] **Step 4: Run compile checkpoint**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`  
Expected: `Finished :entry:default@CompileArkTS`

---

### Task 2: Unify Click Feedback In Shared Cards

**Files:**
- Modify: `harmony/entry/src/main/ets/components/RoleHomeActionCards.ets`
- Modify: `harmony/entry/src/main/ets/components/RoleCard.ets`

- [ ] **Step 1: Import shared motion tokens into the shared card components**

```ts
import { AnimationDuration, AnimationCurve, MotionPress } from '../common/styles/Animation'
```

- [ ] **Step 2: Replace component-local press numbers in `RoleHomeActionCards.ets` with shared values**

```ts
.scale({
  x: this.pressedLeft ? MotionPress.cardScale : 1,
  y: this.pressedLeft ? MotionPress.cardScale : 1
})
.translate({ x: 0, y: this.pressedLeft ? MotionPress.offsetY : -1 })
.animation({
  duration: MotionPress.cardDuration,
  curve: AnimationCurve.emphasized
})
```

- [ ] **Step 3: Replace component-local press numbers in `RoleCard.ets` with shared values**

```ts
.scale({
  x: this.isPressed ? MotionPress.cardScale : 1,
  y: this.isPressed ? MotionPress.cardScale : 1
})
.translate({ x: 0, y: this.isPressed ? MotionPress.offsetY : 0 })
.animation({
  duration: MotionPress.cardDuration,
  curve: AnimationCurve.emphasized
})
```

- [ ] **Step 4: Run compile checkpoint**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`  
Expected: `Finished :entry:default@CompileArkTS`

---

### Task 3: Standardize Home And Meeting Flow Motion

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingParticipantPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
- Modify: `harmony/entry/src/main/ets/components/RecordsTab.ets`

- [ ] **Step 1: Add page-level slide-in state to `Index.ets` if missing**

```ts
@State pageSlideX: number = MotionTokens.pageEnterOffsetX
@State pageOpacity: number = 0.92

aboutToAppear(): void {
  setTimeout(() => {
    animateTo({
      duration: AnimationDuration.page,
      curve: AnimationCurve.emphasized
    }, () => {
      this.pageSlideX = 0
      this.pageOpacity = 1
    })
  }, 10)
}
```

- [ ] **Step 2: Apply root page animation to `Index.ets` and keep existing visual layout untouched**

```ts
.translate({ x: this.pageSlideX })
.opacity(this.pageOpacity)
.animation({
  duration: AnimationDuration.page,
  curve: AnimationCurve.emphasized
})
```

- [ ] **Step 3: Add 3 to 4 section stagger states to `Index.ets`**

```ts
@State heroVisible: boolean = false
@State resumeVisible: boolean = false
@State prepVisible: boolean = false
@State featureVisible: boolean = false
```

- [ ] **Step 4: Trigger staggered visibility in `Index.ets` using `MotionTokens.staggerStepMs`**

```ts
setTimeout(() => { this.heroVisible = true }, MotionTokens.staggerStepMs)
setTimeout(() => { this.resumeVisible = true }, MotionTokens.staggerStepMs * 2)
setTimeout(() => { this.prepVisible = true }, MotionTokens.staggerStepMs * 3)
setTimeout(() => { this.featureVisible = true }, MotionTokens.staggerStepMs * 4)
```

- [ ] **Step 5: Bind `opacity` and `translate` to the corresponding home sections**

```ts
.opacity(this.resumeVisible ? 1 : 0)
.translate({ y: this.resumeVisible ? 0 : MotionTokens.sectionEnterOffsetY })
.animation({
  duration: AnimationDuration.normal,
  curve: AnimationCurve.smooth
})
```

- [ ] **Step 6: Replace hard-coded page enter offsets in `MeetingParticipantPage.ets` with `MotionTokens`**

```ts
@State pageSlideX: number = MotionTokens.pageEnterOffsetX
@State pageSlideOpacity: number = 0.92
```

- [ ] **Step 7: Replace hard-coded page enter offsets in `MeetingChatPage.ets` with `MotionTokens`**

```ts
@State pageSlideX: number = MotionTokens.pageEnterOffsetX
@State pageSlideOpacity: number = 0.92
```

- [ ] **Step 8: Align existing stagger values in `MeetingParticipantPage.ets` and `RecordsTab.ets` to the shared token**

```ts
const stepDelay: number = MotionTokens.staggerStepMs
```

- [ ] **Step 9: Run compile checkpoint**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`  
Expected: `Finished :entry:default@CompileArkTS`

---

### Task 4: Add Motion To Create Role And Explore Pages

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/CreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/AIDialogueCreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/ExplorePersonas.ets`
- Modify: `harmony/entry/src/main/ets/pages/UserCenter.ets`

- [ ] **Step 1: Add page enter state to `CreateRole.ets` and `AIDialogueCreateRole.ets`**

```ts
@State pageSlideX: number = MotionTokens.pageEnterOffsetX
@State pageOpacity: number = 0.92
```

- [ ] **Step 2: Trigger root enter animation in both create-role pages**

```ts
animateTo({
  duration: AnimationDuration.page,
  curve: AnimationCurve.emphasized
}, () => {
  this.pageSlideX = 0
  this.pageOpacity = 1
})
```

- [ ] **Step 3: Add section-level stagger for header, mode tabs, form content, and primary button**

```ts
@State sectionStep: number = 0
setTimeout(() => { this.sectionStep = 1 }, MotionTokens.staggerStepMs)
setTimeout(() => { this.sectionStep = 2 }, MotionTokens.staggerStepMs * 2)
setTimeout(() => { this.sectionStep = 3 }, MotionTokens.staggerStepMs * 3)
setTimeout(() => { this.sectionStep = 4 }, MotionTokens.staggerStepMs * 4)
```

- [ ] **Step 4: Bind sections in create-role pages to stagger state**

```ts
.opacity(this.sectionStep >= 2 ? 1 : 0)
.translate({ y: this.sectionStep >= 2 ? 0 : MotionTokens.sectionEnterOffsetY })
.animation({
  duration: AnimationDuration.normal,
  curve: AnimationCurve.smooth
})
```

- [ ] **Step 5: Add root page enter and section stagger to `ExplorePersonas.ets`**

```ts
@State pageSlideX: number = MotionTokens.pageEnterOffsetX
@State pageOpacity: number = 0.92
@State sectionStep: number = 0
```

- [ ] **Step 6: Apply first-screen-only list/card reveal to `ExplorePersonas.ets`**

```ts
.opacity(index < 6 && this.sectionStep >= 3 ? 1 : 0)
.translate({ y: index < 6 && this.sectionStep >= 3 ? 0 : MotionTokens.cardEnterOffsetY })
.animation({
  duration: AnimationDuration.normal,
  curve: AnimationCurve.smooth,
  delay: index * 26
})
```

- [ ] **Step 7: Add page enter and block-level reveal to `UserCenter.ets`**

```ts
.opacity(this.sectionStep >= 2 ? 1 : 0)
.translate({ y: this.sectionStep >= 2 ? 0 : MotionTokens.sectionEnterOffsetY })
```

- [ ] **Step 8: Run compile checkpoint**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`  
Expected: `Finished :entry:default@CompileArkTS`

---

### Task 5: Add Motion To Summary And Share Surfaces

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`
- Modify: `harmony/entry/src/main/ets/components/ShareSheet.ets`

- [ ] **Step 1: Add root page enter animation to summary list and detail pages**

```ts
@State pageSlideX: number = MotionTokens.pageEnterOffsetX
@State pageOpacity: number = 0.92
```

- [ ] **Step 2: Add stagger for title, filters/content, and bottom actions in summary pages**

```ts
@State sectionStep: number = 0
```

- [ ] **Step 3: Apply first-screen-only list reveal in `SummaryListPage.ets`**

```ts
.opacity(index < 6 && this.sectionStep >= 2 ? 1 : 0)
.translate({ y: index < 6 && this.sectionStep >= 2 ? 0 : MotionTokens.cardEnterOffsetY })
```

- [ ] **Step 4: Add bottom-sheet enter state to `ShareSheet.ets`**

```ts
@State sheetOpacity: number = 0
@State sheetTranslateY: number = MotionTokens.sheetEnterOffsetY
@State contentStep: number = 0
```

- [ ] **Step 5: Trigger staggered sheet enter in `ShareSheet.ets` when `isVisible` becomes true**

```ts
animateTo({
  duration: AnimationDuration.page,
  curve: AnimationCurve.emphasized
}, () => {
  this.sheetOpacity = 1
  this.sheetTranslateY = 0
})
setTimeout(() => { this.contentStep = 1 }, MotionTokens.staggerStepMs)
setTimeout(() => { this.contentStep = 2 }, MotionTokens.staggerStepMs * 2)
setTimeout(() => { this.contentStep = 3 }, MotionTokens.staggerStepMs * 3)
```

- [ ] **Step 6: Bind overlay and panel movement in `ShareSheet.ets`**

```ts
.opacity(this.sheetOpacity)
.translate({ y: this.sheetTranslateY })
.animation({
  duration: AnimationDuration.page,
  curve: AnimationCurve.emphasized
})
```

- [ ] **Step 7: Stagger near-field, social, and device sections inside `ShareSheet.ets`**

```ts
.opacity(this.contentStep >= 1 ? 1 : 0)
.translate({ y: this.contentStep >= 1 ? 0 : MotionTokens.sectionEnterOffsetY })
```

- [ ] **Step 8: Run compile checkpoint**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`  
Expected: `Finished :entry:default@CompileArkTS`

---

### Task 6: Final Motion Pass And Regression Verification

**Files:**
- Modify: `harmony/entry/src/main/ets/common/styles/Animation.ets`
- Modify: `harmony/entry/src/main/ets/pages/Index.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingParticipantPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/CreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/AIDialogueCreateRole.ets`
- Modify: `harmony/entry/src/main/ets/pages/ExplorePersonas.ets`
- Modify: `harmony/entry/src/main/ets/pages/UserCenter.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
- Modify: `harmony/entry/src/main/ets/pages/SummaryDetailPage.ets`
- Modify: `harmony/entry/src/main/ets/components/ShareSheet.ets`
- Modify: `harmony/entry/src/main/ets/components/RoleHomeActionCards.ets`
- Modify: `harmony/entry/src/main/ets/components/RoleCard.ets`
- Modify: `harmony/entry/src/main/ets/components/RecordsTab.ets`

- [ ] **Step 1: Smoke-check that no page now uses a visibly larger page enter offset than the shared token**

Run: `rg -n "pageSlideX: number = [0-9]+|translate\\(\\{ x: [0-9-]+" /Users/intmainjhy/Desktop/intmainjhy/idea/redmain/harmony/entry/src/main/ets/pages /Users/intmainjhy/Desktop/intmainjhy/idea/redmain/harmony/entry/src/main/ets/components`
Expected: remaining offsets are intentional or replaced with `MotionTokens`

- [ ] **Step 2: Smoke-check press feedback sites**

Run: `rg -n "pressed|isPressed|stateEffect\\(true\\)|MotionPress" /Users/intmainjhy/Desktop/intmainjhy/idea/redmain/harmony/entry/src/main/ets/components /Users/intmainjhy/Desktop/intmainjhy/idea/redmain/harmony/entry/src/main/ets/pages`
Expected: key cards and primary buttons now use shared press values where custom feedback is needed

- [ ] **Step 3: Run final compile checkpoint**

Run: `/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon`
Expected: `Finished :entry:default@CompileArkTS`

- [ ] **Step 4: Record the known packaging limitation**

```text
Current environment limitation after CompileArkTS:
Failed :entry:default@PackageHap
Unable to locate a Java Runtime.
```

---

## Self-Review

- Spec coverage: page enter, section stagger, cards, sheets, press/tap feedback, compile verification are all mapped to Tasks 1 through 6.
- Placeholder scan: no `TODO`, `TBD`, or “similar to previous task” shortcuts remain.
- Type consistency: shared motion names are consistently `MotionTokens` and `MotionPress` across all tasks.
