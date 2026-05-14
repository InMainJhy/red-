# Harmony Summary Date Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Harmony summary list page into a date-driven workspace that defaults to today, auto-scrolls the date strip to today, and filters meeting summaries by the selected year, month, and day.

**Architecture:** Keep the implementation scoped to `harmony/entry/src/main/ets/pages/SummaryListPage.ets`, reusing the existing summary fetching flow and borrowing the calendar selection and horizontal scroller pattern already present in `Index.ets`. Fetch the full recent history once, map it into richer card data with raw timestamps, then derive the visible list entirely on the frontend from the currently selected date state.

**Tech Stack:** HarmonyOS ArkTS, existing `PersonaApi.getArenaHistory`, `Scroller`, current card-based summary UI, and local date parsing through `Date`.

---

### Task 1: Add Calendar State and Date Helpers

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`

- [ ] **Step 1: Add a day model and richer card timestamp fields**

Introduce a local day interface near `MeetingCardData` and keep the raw ISO timestamp on each summary card:

```ts
interface SummaryCalendarDay {
  id: string
  weekLabel: string
  dayNumber: number
  dayLabel: string
  fullDateLabel: string
  isToday: boolean
}

interface MeetingCardData {
  runId: string
  title: string
  topic: string
  timeAgo: string
  participantNames: string[]
  participantColors: string[]
  consensusPreview: string
  messageCount: number
  mode: string
  createdAt: string
}
```

- [ ] **Step 2: Add selected date state and calendar interaction state**

Add these page-level states and scroller next to the existing body / press state:

```ts
@State private allCards: MeetingCardData[] = []
@State private visibleCards: MeetingCardData[] = []
@State private selectedCalendarYear: number = new Date().getFullYear()
@State private selectedCalendarMonth: number = new Date().getMonth() + 1
@State private selectedCalendarDay: number = new Date().getDate()
@State private pressedCalendarDayId: string = ''
@State private pressedCalendarControl: string = ''
private calendarScroller: Scroller = new Scroller()
```

- [ ] **Step 3: Copy and adapt the calendar helper methods from the homepage**

Add the `SummaryListPage` equivalents of the homepage helpers:

```ts
private calendarDays(): SummaryCalendarDay[] {
  const weekLabels: string[] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
  const days: SummaryCalendarDay[] = []
  const totalDays = new Date(this.selectedCalendarYear, this.selectedCalendarMonth, 0).getDate()
  const today = new Date()

  for (let day = 1; day <= totalDays; day++) {
    const nextDate = new Date(this.selectedCalendarYear, this.selectedCalendarMonth - 1, day)
    days.push({
      id: `${nextDate.getFullYear()}-${nextDate.getMonth() + 1}-${nextDate.getDate()}`,
      weekLabel: weekLabels[nextDate.getDay()],
      dayNumber: day,
      dayLabel: `${day}`.padStart(2, '0'),
      fullDateLabel: `${nextDate.getMonth() + 1}月${nextDate.getDate()}日`,
      isToday: nextDate.getFullYear() === today.getFullYear()
        && nextDate.getMonth() === today.getMonth()
        && nextDate.getDate() === today.getDate()
    })
  }

  return days
}

private syncCalendarSelection(): void {
  const totalDays = new Date(this.selectedCalendarYear, this.selectedCalendarMonth, 0).getDate()
  if (this.selectedCalendarDay > totalDays) {
    this.selectedCalendarDay = totalDays
  }
  if (this.selectedCalendarDay <= 0) {
    this.selectedCalendarDay = 1
  }
}
```

- [ ] **Step 4: Add “default to today” and scroll-to-day helpers**

Add the date reset and horizontal auto-scroll helpers:

```ts
private resetCalendarToToday(): void {
  const today = new Date()
  this.selectedCalendarYear = today.getFullYear()
  this.selectedCalendarMonth = today.getMonth() + 1
  this.selectedCalendarDay = today.getDate()
  this.scrollCalendarToSelectedDay()
}

private scrollCalendarToSelectedDay(): void {
  const itemWidth = 72
  const itemGap = 10
  const sideInset = 4
  const targetOffset = Math.max(0, (this.selectedCalendarDay - 2) * (itemWidth + itemGap) - sideInset)
  this.calendarScroller.scrollTo({ xOffset: targetOffset, yOffset: 0, animation: true })
}
```

- [ ] **Step 5: Verify the calendar helper names exist only in `SummaryListPage`**

Run: `rg -n "calendarDays\\(|resetCalendarToToday\\(|scrollCalendarToSelectedDay\\(|selectedCalendarYear" harmony/entry/src/main/ets/pages/SummaryListPage.ets`

Expected: The new helpers and date state are present in `SummaryListPage.ets`.

### Task 2: Store Raw History and Filter It by Selected Date

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`

- [ ] **Step 1: Preserve raw `createdAt` when mapping API data**

Update `mapToCard` so every card retains its timestamp:

```ts
return {
  runId: item.runId,
  title: title,
  topic: item.topic,
  timeAgo: item.createdAt ? formatTimeAgo(item.createdAt) : '刚刚',
  participantNames: item.participantNames,
  participantColors: participantColors,
  consensusPreview: consensusPreview,
  messageCount: item.messageCount ?? 0,
  mode: item.mode,
  createdAt: item.createdAt ?? ''
}
```

- [ ] **Step 2: Split fetched history into `allCards` and derived `visibleCards`**

Change `loadHistory()` so it saves the entire recent history and then filters the current day:

```ts
private async loadHistory(): Promise<void> {
  this.isLoading = true
  this.errorMessage = ''
  try {
    const response = await PersonaApi.getArenaHistory(100)
    this.allCards = response.runs.map((item: ArenaRunHistoryItem) => this.mapToCard(item))
    this.applyVisibleCardsForSelectedDate()
  } catch (error) {
    console.error('[SummaryListPage] loadHistory failed:', error)
    this.errorMessage = '加载失败，请检查网络连接'
    this.allCards = []
    this.visibleCards = []
  } finally {
    this.isLoading = false
    this.playBodyEntrance()
  }
}
```

- [ ] **Step 3: Add a single date match helper and visible-card derivation**

Add a helper that compares a card’s `createdAt` with the currently selected year/month/day:

```ts
private isCardOnSelectedDate(card: MeetingCardData): boolean {
  if (card.createdAt.length === 0) {
    return false
  }
  const date = new Date(card.createdAt)
  if (Number.isNaN(date.getTime())) {
    return false
  }
  return date.getFullYear() === this.selectedCalendarYear
    && date.getMonth() + 1 === this.selectedCalendarMonth
    && date.getDate() === this.selectedCalendarDay
}

private applyVisibleCardsForSelectedDate(): void {
  this.visibleCards = this.allCards.filter((card: MeetingCardData) => this.isCardOnSelectedDate(card))
}
```

- [ ] **Step 4: Add month/year switching rules that follow the spec**

Adapt the homepage stepping logic, but obey the summary-page rules:

```ts
private changeCalendarMonth(delta: number): void {
  const currentDate = new Date(this.selectedCalendarYear, this.selectedCalendarMonth - 1 + delta, 1)
  this.selectedCalendarYear = currentDate.getFullYear()
  this.selectedCalendarMonth = currentDate.getMonth() + 1

  const today = new Date()
  if (this.selectedCalendarYear === today.getFullYear() && this.selectedCalendarMonth === today.getMonth() + 1) {
    this.selectedCalendarDay = today.getDate()
  } else {
    this.selectedCalendarDay = 1
  }

  this.syncCalendarSelection()
  this.scrollCalendarToSelectedDay()
  this.applyVisibleCardsForSelectedDate()
}

private changeCalendarYear(delta: number): void {
  this.selectedCalendarYear += delta

  const today = new Date()
  if (this.selectedCalendarYear === today.getFullYear() && this.selectedCalendarMonth === today.getMonth() + 1) {
    this.selectedCalendarDay = today.getDate()
  } else if (this.selectedCalendarDay <= 0) {
    this.selectedCalendarDay = 1
  }

  this.syncCalendarSelection()
  this.scrollCalendarToSelectedDay()
  this.applyVisibleCardsForSelectedDate()
}
```

- [ ] **Step 5: Verify the visible list no longer reads directly from `cards`**

Run: `rg -n "visibleCards|allCards|applyVisibleCardsForSelectedDate|isCardOnSelectedDate" harmony/entry/src/main/ets/pages/SummaryListPage.ets`

Expected: The file now uses `allCards` as source data and `visibleCards` as the rendered list.

### Task 3: Add the Date Workbench UI Above the Summary List

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`

- [ ] **Step 1: Add a summary-specific count label that reflects the selected day**

Replace the old total-history copy with selected-day-aware copy:

```ts
private summaryCountLabel(): string {
  if (this.isLoading) {
    return '正在整理所选日期的会议纪要'
  }
  if (this.visibleCards.length === 0) {
    return '当前日期还没有会议纪要'
  }
  return `${this.selectedCalendarMonth}月${this.selectedCalendarDay}日 · 共 ${this.visibleCards.length} 条纪要`
}
```

- [ ] **Step 2: Add the calendar workbench builders**

Create `buildCalendarWorkbench`, `buildCalendarStepper`, and `buildCalendarDayItem`, adapting the homepage calendar visuals:

```ts
@Builder
private buildCalendarWorkbench() {
  Column({ space: 10 }) {
    Row() {
      Row({ space: 8 }) {
        Column()
          .width(4)
          .height(18)
          .borderRadius(2)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              ['rgba(91, 162, 255, 0.96)', 0],
              ['rgba(178, 210, 255, 0.88)', 1]
            ]
          })

        Column({ space: 2 }) {
          Text('日期导航')
          Text('默认定位到今天')
        }
      }

      Blank()

      Row({ space: 6 }) {
        this.buildCalendarStepper('year', `${this.selectedCalendarYear}年`, () => {
          this.changeCalendarYear(-1)
        }, () => {
          this.changeCalendarYear(1)
        })

        this.buildCalendarStepper('month', `${this.selectedCalendarMonth}月`, () => {
          this.changeCalendarMonth(-1)
        }, () => {
          this.changeCalendarMonth(1)
        })
      }
    }

    Scroll(this.calendarScroller) {
      Row({ space: 10 }) {
        ForEach(this.calendarDays(), (day: SummaryCalendarDay) => {
          this.buildCalendarDayItem(day)
        }, (day: SummaryCalendarDay) => day.id)
      }
      .padding({ right: 8 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
```

- [ ] **Step 3: Make date selection refresh the visible list immediately**

In `buildCalendarDayItem`, update the click handler to change the selected day and refilter:

```ts
.onClick(() => {
  this.selectedCalendarDay = day.dayNumber
  this.applyVisibleCardsForSelectedDate()
  this.scrollCalendarToSelectedDay()
})
```

- [ ] **Step 4: Insert the date workbench between the header and the list body**

Update the `build()` layout so the sequence becomes:

```ts
Column({ space: 14 }) {
  this.buildOverviewCard()
  this.buildCalendarWorkbench()

  Column() {
    ...
  }
}
```

- [ ] **Step 5: Verify the UI builders are wired into the page tree**

Run: `rg -n "buildCalendarWorkbench|buildCalendarStepper|buildCalendarDayItem" harmony/entry/src/main/ets/pages/SummaryListPage.ets`

Expected: All three builders exist and `buildCalendarWorkbench()` is called from `build()`.

### Task 4: Make Today the Default and Add Date-Specific Empty State

**Files:**
- Modify: `harmony/entry/src/main/ets/pages/SummaryListPage.ets`
- Read: `docs/superpowers/specs/2026-05-12-summary-date-navigation-design.md`

- [ ] **Step 1: Reset the page to today on every entry**

Update `aboutToAppear()` so the date state always resets before history is loaded:

```ts
aboutToAppear(): void {
  this.loadSafeInsets()
  this.resetCalendarToToday()
  this.loadHistory()
}
```

- [ ] **Step 2: Ensure the page auto-scrolls to today after data and layout settle**

After `loadHistory()` succeeds or after `aboutToAppear()`, trigger a delayed scroll once the page has mounted:

```ts
setTimeout(() => {
  this.scrollCalendarToSelectedDay()
}, 60)
```

Place this after `resetCalendarToToday()` and after data load finalization if needed to ensure the strip has measurable content.

- [ ] **Step 3: Replace the generic empty state with a date-specific message**

Update `buildEmptyState()` so it reflects the currently selected date:

```ts
Text('这一天还没有会议纪要')
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .fontColor(Colors.textPrimary)

Text(`${this.selectedCalendarMonth}月${this.selectedCalendarDay}日 暂无记录，切换其他日期看看，或先开始一场新会议。`)
  .fontSize(13)
  .fontColor(Colors.textSecondary)
  .textAlign(TextAlign.Center)
```

- [ ] **Step 4: Render only the selected day’s summaries in the scroll list**

Change the list `ForEach` from:

```ts
ForEach(this.cards, (card: MeetingCardData) => {
```

to:

```ts
ForEach(this.visibleCards, (card: MeetingCardData) => {
```

and change the empty-state branch from `this.cards.length === 0` to `this.visibleCards.length === 0` while preserving the separate error/loading branches.

- [ ] **Step 5: Run static validation and manual Harmony verification**

Run: `git diff --check -- harmony/entry/src/main/ets/pages/SummaryListPage.ets`

Expected: No whitespace or merge-marker issues.

Run in DevEco Studio: `Build > Make Module 'entry'`

Expected: `SummaryListPage.ets` compiles successfully.

Manual verification checklist:

1. Enter the summary page on today’s date and confirm the strip auto-scrolls to today.
2. Confirm the default list shows only today’s summaries.
3. Tap a previous date and confirm the list updates to that day’s summaries.
4. Switch to another month and confirm day `1` becomes selected unless that month is the current month.
5. Return to the current month and confirm today becomes selected again.
