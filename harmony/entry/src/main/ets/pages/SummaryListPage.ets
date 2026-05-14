import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { SummaryListItem } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import { SummaryService, formatTimeAgo, getParticipantColor } from '../service/SummaryService'
import { AnimatedCloudMascot, DynamicGlassBackground, Icon } from '../components'
import { MintColors } from '../common/styles/MintColors'

const FALLBACK_SAFE_TOP_VP: number = 52

interface SummaryCalendarDay {
  id: string
  weekLabel: string
  dayNumber: number
  dayLabel: string
  fullDateLabel: string
  isToday: boolean
}

interface MeetingCardData {
  summaryId: string
  arenaRunId: string
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

@Entry
@Component
struct SummaryListPage {
  @State private allCards: MeetingCardData[] = []
  @State private visibleCards: MeetingCardData[] = []
  @State private isLoading: boolean = true
  @State private errorMessage: string = ''
  @State private safeTopVp: number = 0
  @State private safeBottomVp: number = 0
  @State private bodyOpacity: number = 1
  @State private bodyTranslateY: number = 0
  @State private listRefreshOpacity: number = 1
  @State private listRefreshTranslateY: number = 0
  @State private selectedCalendarYear: number = new Date().getFullYear()
  @State private selectedCalendarMonth: number = new Date().getMonth() + 1
  @State private selectedCalendarDay: number = new Date().getDate()
  @State private pressedCalendarDayId: string = ''
  @State private pressedCalendarControl: string = ''
  @State private pressedCardId: string = ''
  private calendarScroller: Scroller = new Scroller()
  private hasLoadedOnce: boolean = false
  private hasShownOnce: boolean = false
  private historyRequestToken: number = 0
  private calendarScrollTimer: number = -1

  aboutToAppear(): void {
    this.loadSafeInsets()
    this.initializeSummaryStore()
    if (!this.hasLoadedOnce) {
      this.hasLoadedOnce = true
      void this.loadHistory()
    }
  }

  private initializeSummaryStore(): void {
    const ctx = this.getHostContext()
    if (!ctx) {
      return
    }
    void SummaryService.init(ctx).then(() => {
      if (this.hasLoadedOnce) {
        void this.loadHistory()
      }
    }).catch((_error: Error) => {
    })
  }

  onPageShow(): void {
    if (!this.hasShownOnce) {
      this.hasShownOnce = true
      return
    }
    void this.loadHistory()
  }

  private getHostContext(): common.UIAbilityContext | null {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      return hostContext as common.UIAbilityContext
    }
    return null
  }

  private loadSafeInsets(): void {
    const ctx = this.getHostContext()
    if (!ctx) {
      return
    }
    fetchSafeAreaInsets(ctx).then((insets) => {
      this.safeTopVp = insets.topVp
      this.safeBottomVp = insets.bottomVp
    }).catch((_error: Error) => {
    })
  }

  private topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  private playBodyEntrance(): void {
    this.bodyOpacity = 0
    this.bodyTranslateY = 18
    setTimeout(() => {
      this.bodyOpacity = 1
      this.bodyTranslateY = 0
    }, 16)
  }

  private playListRefreshTransition(): void {
    this.listRefreshOpacity = 0.72
    this.listRefreshTranslateY = 6
    setTimeout(() => {
      this.listRefreshOpacity = 1
      this.listRefreshTranslateY = 0
    }, 70)
  }

  private async loadHistory(): Promise<void> {
    const requestToken = ++this.historyRequestToken
    this.isLoading = true
    this.errorMessage = ''
    try {
      const response = await SummaryService.getSummaryList(undefined)
      if (requestToken !== this.historyRequestToken) {
        return
      }
      const invalidSummaryIds: string[] = []
      const validCards: MeetingCardData[] = []

      response.items.forEach((item: SummaryListItem) => {
        const createdAt = item.createdAt ?? ''
        const parsedDate = createdAt.length > 0 ? new Date(createdAt) : null
        if (createdAt.length === 0 || !parsedDate || Number.isNaN(parsedDate.getTime())) {
          invalidSummaryIds.push(item.id)
          return
        }
        validCards.push(this.mapToCard(item))
      })

      if (invalidSummaryIds.length > 0) {
        console.warn(`[SummaryListPage] filtered ${invalidSummaryIds.length} invalid summary records: ${invalidSummaryIds.join(', ')}`)
      }

      this.allCards = validCards
      this.applyVisibleCardsForSelectedDate()
    } catch (error) {
      if (requestToken !== this.historyRequestToken) {
        return
      }
      console.error('[SummaryListPage] loadHistory failed:', error)
      this.errorMessage = '加载失败，请检查网络连接'
      this.allCards = []
      this.visibleCards = []
    } finally {
      if (requestToken !== this.historyRequestToken) {
        return
      }
      this.isLoading = false
      this.playBodyEntrance()
    }
  }

  private mapToCard(item: SummaryListItem): MeetingCardData {
    const participantColors = item.participantNames.map((_name: string, index: number) =>
      getParticipantColor(index)
    )

    return {
      summaryId: item.id,
      arenaRunId: '',
      title: item.title && item.title.length > 0 ? item.title : '会议纪要',
      topic: item.topic,
      timeAgo: item.createdAt ? formatTimeAgo(item.createdAt) : '刚刚',
      participantNames: item.participantNames,
      participantColors: participantColors,
      consensusPreview: item.consensusPreview,
      messageCount: item.messageCount ?? 0,
      mode: 'chat',
      createdAt: item.createdAt ?? ''
    }
  }

  private navigateToDetail(card: MeetingCardData): void {
    router.pushUrl({
      url: 'pages/SummaryDetailPage',
      params: {
        summaryId: card.summaryId,
        arenaRunId: card.arenaRunId
      }
    })
  }

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

  private resetCalendarToToday(): void {
    const today = new Date()
    this.selectedCalendarYear = today.getFullYear()
    this.selectedCalendarMonth = today.getMonth() + 1
    this.selectedCalendarDay = today.getDate()
    this.scheduleCalendarScroll()
  }

  private scheduleCalendarScroll(): void {
    if (this.calendarScrollTimer !== -1) {
      clearTimeout(this.calendarScrollTimer)
    }

    this.calendarScrollTimer = setTimeout((): void => {
      this.calendarScrollTimer = -1
      this.scrollCalendarToSelectedDay()
    }, 60)
  }

  private scrollCalendarToSelectedDay(): void {
    const itemWidth = 72
    const itemGap = 10
    const sideInset = 4
    const targetOffset = Math.max(0, (this.selectedCalendarDay - 2) * (itemWidth + itemGap) - sideInset)
    this.calendarScroller.scrollTo({ xOffset: targetOffset, yOffset: 0, animation: true })
  }

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
    this.visibleCards = [...this.allCards]
    if (!this.isLoading) {
      this.playListRefreshTransition()
    }
  }

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
    this.scheduleCalendarScroll()
    this.applyVisibleCardsForSelectedDate()
  }

  private changeCalendarYear(delta: number): void {
    this.selectedCalendarYear += delta

    const today = new Date()
    if (this.selectedCalendarYear === today.getFullYear() && this.selectedCalendarMonth === today.getMonth() + 1) {
      this.selectedCalendarDay = today.getDate()
    } else {
      this.selectedCalendarDay = 1
    }

    this.syncCalendarSelection()
    this.scheduleCalendarScroll()
    this.applyVisibleCardsForSelectedDate()
  }

  private summaryCountLabel(): string {
    if (this.isLoading) {
      return '正在整理会议纪要'
    }
    if (this.allCards.length === 0) {
      return '还没有生成会议纪要'
    }
    return `共 ${this.visibleCards.length} 条纪要`
  }

  @Builder
  private buildHeader() {
    Row({ space: 16 }) {
      Column({ space: 8 }) {
        Text('会议纪要')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
          .fontFamily('HarmonyOS Sans SC')

        Text(this.summaryCountLabel())
          .fontSize(13)
          .fontColor('rgba(77, 96, 128, 0.68)')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(60)
          .height(60)
          .borderRadius(30)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              ['rgba(255, 255, 255, 0.9)', 0],
              ['rgba(240, 246, 255, 0.8)', 1]
            ]
          })
          .shadow({
            radius: 14,
            color: 'rgba(92, 168, 255, 0.12)',
            offsetX: 0,
            offsetY: 6
          })

        AnimatedCloudMascot({
          mascotSize: 58,
          mood: 'shy',
          enableFloat: false,
          enableBlink: false,
          backgroundGlow: false,
          motionLevel: 'still'
        })
      }
      .width(64)
      .height(64)
    }
    .width('100%')
    .padding({
      left: Spacing.page.horizontal,
      right: Spacing.page.horizontal,
      top: this.topInsetVp() + 8,
      bottom: 12
    })
  }

  @Builder
  private buildCalendarWorkbench() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 4 }) {
          Text('日期工作台')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)

          Text('默认定位到今天，按日查看纪要')
            .fontSize(10)
            .fontColor('rgba(98, 114, 138, 0.66)')
        }
        .alignItems(HorizontalAlign.Start)

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
      .width('100%')

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
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor('rgba(255, 255, 255, 0.45)')
    .backdropBlur(30)
    .linearGradient({
      angle: 135,
      colors: [
        ['rgba(255, 255, 255, 0.95)', 0],
        ['rgba(255, 255, 255, 0.35)', 1]
      ]
    })
    .border({
      width: 1.5,
      color: 'rgba(255, 255, 255, 0.92)',
      radius: 32
    })
    .borderRadius(32)
    .shadow({
      radius: 20,
      color: 'rgba(92, 168, 255, 0.14)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  private buildCalendarStepper(key: string, label: string, onMinus: () => void, onPlus: () => void) {
    Row({ space: 6 }) {
      Button() {
        Icon({
          iconType: 'minus',
          iconSize: 11,
          iconColor: Colors.textPrimary,
          strokeWidth: 1.8
        })
      }
      .width(24)
      .height(24)
      .backgroundColor('rgba(255, 255, 255, 0.98)')
      .border({
        width: 1,
        color: 'rgba(214, 224, 240, 0.96)',
        radius: 12
      })
      .borderRadius(12)
      .scale({
        x: this.pressedCalendarControl === `${key}-minus` ? 0.92 : 1,
        y: this.pressedCalendarControl === `${key}-minus` ? 0.92 : 1
      })
      .animation({
        duration: 160,
        curve: Curve.FastOutSlowIn
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressedCalendarControl = `${key}-minus`
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressedCalendarControl = ''
        }
      })
      .onClick(() => {
        onMinus()
      })

      Text(label)
        .fontSize(11.5)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textSecondary)
        .padding({ left: 2, right: 2 })

      Button() {
        Icon({
          iconType: 'plus',
          iconSize: 11,
          iconColor: Colors.textPrimary,
          strokeWidth: 1.8
        })
      }
      .width(24)
      .height(24)
      .backgroundColor('rgba(255, 255, 255, 0.98)')
      .border({
        width: 1,
        color: 'rgba(214, 224, 240, 0.96)',
        radius: 12
      })
      .borderRadius(12)
      .scale({
        x: this.pressedCalendarControl === `${key}-plus` ? 0.92 : 1,
        y: this.pressedCalendarControl === `${key}-plus` ? 0.92 : 1
      })
      .animation({
        duration: 160,
        curve: Curve.FastOutSlowIn
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressedCalendarControl = `${key}-plus`
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressedCalendarControl = ''
        }
      })
      .onClick(() => {
        onPlus()
      })
    }
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .backgroundColor('rgba(246, 250, 255, 0.98)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 0.98)', 0],
        ['rgba(244, 248, 255, 0.96)', 1]
      ]
    })
    .border({
      width: 1,
      color: 'rgba(206, 218, 238, 0.94)',
      radius: 17
    })
    .borderRadius(17)
    .shadow({
      radius: 8,
      color: 'rgba(147, 172, 207, 0.06)',
      offsetX: 0,
      offsetY: 3
    })
  }

  @Builder
  private buildCalendarDayItem(day: SummaryCalendarDay) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(72)
        .height(88)
        .borderRadius(20)
        .backgroundColor(day.dayNumber === this.selectedCalendarDay ? 'rgba(109, 175, 255, 0.26)' : 'rgba(205, 222, 247, 0.14)')
        .translate({ x: 0, y: 9 })
        .opacity(day.dayNumber === this.selectedCalendarDay ? 0.88 : 0.42)

      Column()
        .width(72)
        .height(88)
        .borderRadius(20)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: day.dayNumber === this.selectedCalendarDay ? [
            ['rgba(102, 167, 255, 1)', 0],
            ['rgba(81, 146, 243, 0.98)', 0.54],
            ['rgba(71, 128, 226, 0.96)', 1]
          ] : [
            ['rgba(255, 255, 255, 0.99)', 0],
            ['rgba(247, 250, 255, 0.98)', 0.56],
            ['rgba(241, 246, 255, 0.96)', 1]
          ]
        })

      Column()
        .width(54)
        .height(14)
        .borderRadius(9)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(255, 255, 255, 0.58)', 0],
            ['rgba(255, 255, 255, 0)', 1]
          ]
        })
        .position({ x: 8, y: 8 })
        .opacity(day.dayNumber === this.selectedCalendarDay ? 0.92 : 0.62)

      Column({ space: 6 }) {
        Text(day.weekLabel)
          .fontSize(10)
          .fontWeight(day.isToday ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(day.dayNumber === this.selectedCalendarDay ? Colors.cardPrimary : (day.isToday ? Colors.accent : Colors.textMuted))

        Text(day.dayLabel)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(day.dayNumber === this.selectedCalendarDay ? '#FFFFFF' : Colors.textPrimary)

        Text(day.fullDateLabel)
          .fontSize(9)
          .fontColor(day.dayNumber === this.selectedCalendarDay ? 'rgba(255, 255, 255, 0.80)' : Colors.textMuted)
      }
      .width(72)
      .height(88)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .border({
      width: day.dayNumber === this.selectedCalendarDay ? 1.1 : 1,
      color: day.dayNumber === this.selectedCalendarDay ? 'rgba(118, 183, 255, 0.96)' : 'rgba(208, 219, 237, 0.92)',
      radius: 20
    })
    .borderRadius(20)
    .shadow({
      radius: day.dayNumber === this.selectedCalendarDay ? 18 : 10,
      color: day.dayNumber === this.selectedCalendarDay ? 'rgba(75, 142, 255, 0.28)' : 'rgba(124, 150, 190, 0.08)',
      offsetX: 0,
      offsetY: day.dayNumber === this.selectedCalendarDay ? 8 : 4
    })
    .scale({
      x: this.pressedCalendarDayId === day.id ? 0.93 : 1,
      y: this.pressedCalendarDayId === day.id ? 0.93 : 1
    })
    .translate({
      x: 0,
      y: this.pressedCalendarDayId === day.id ? 3 : 0
    })
    .animation({
      duration: 160,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedCalendarDayId = day.id
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedCalendarDayId = ''
      }
    })
    .onClick(() => {
      this.selectedCalendarDay = day.dayNumber
      this.syncCalendarSelection()
      this.scheduleCalendarScroll()
      this.applyVisibleCardsForSelectedDate()
    })
  }

  @Builder
  private buildParticipantTags(participantNames: string[], colors: string[]) {
    Row({ space: 8 }) {
      ForEach(participantNames.slice(0, 4), (name: string, index: number) => {
        Row({ space: 6 }) {
          Column()
            .width(7)
            .height(7)
            .borderRadius(3.5)
            .backgroundColor(colors[index] ?? MintColors.mint)

          Text(name)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('rgba(22, 33, 51, 0.74)')
        }
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('rgba(255, 255, 255, 0.65)')
        .border({
          width: 1,
          color: 'rgba(255, 255, 255, 0.95)',
          radius: BorderRadius.pill
        })
        .borderRadius(BorderRadius.pill)
      }, (name: string, index: number) => name + index)
    }
  }

  @Builder
  private buildModeTag(mode: string) {
    Row({ space: 4 }) {
      Icon({
        iconType: mode === 'debate' ? 'sparkles' : 'chat',
        iconSize: 11,
        iconColor: 'rgba(22, 33, 51, 0.74)',
        strokeWidth: 1.7
      })

      Text(mode === 'debate' ? '辩论模式' : '对话模式')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('rgba(22, 33, 51, 0.74)')
    }
  }

  @Builder
  private buildMeetingCard(card: MeetingCardData) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(card.participantNames.length > 0 ? 172 : 138)
        .borderRadius(32)
        .backgroundColor('rgba(214, 225, 242, 0.12)')
        .translate({ x: 0, y: 12 })
        .opacity(0.88)

      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Column({ space: 6 }) {
            Text(card.title)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(card.topic.length > 0 ? card.topic : '未填写议题')
              .fontSize(12)
              .fontColor('rgba(77, 96, 128, 0.68)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(card.timeAgo)
            .fontSize(11)
            .fontColor('rgba(77, 96, 128, 0.48)')
        }
        .width('100%')

        if (card.participantNames.length > 0) {
          this.buildParticipantTags(card.participantNames, card.participantColors)
        }

        Text(card.consensusPreview.length > 0 ? card.consensusPreview : '点击查看完整会议纪要内容')
          .fontSize(13)
          .fontColor('rgba(22, 33, 51, 0.74)')
          .lineHeight(20)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row() {
          Row({ space: 8 }) {
            Text(`${card.messageCount} 条消息`)
              .fontSize(11)
              .fontColor('rgba(77, 96, 128, 0.48)')

            Text('·')
              .fontSize(11)
              .fontColor('rgba(77, 96, 128, 0.28)')

            this.buildModeTag(card.mode)
          }

          Blank()

          Icon({
            iconType: 'arrowRight',
            iconSize: 14,
            iconColor: 'rgba(80, 97, 126, 0.42)',
            strokeWidth: 1.7
          })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor('rgba(255, 255, 255, 0.45)')
    .backdropBlur(30)
    .linearGradient({
      angle: 135,
      colors: [
        ['rgba(255, 255, 255, 0.95)', 0],
        ['rgba(255, 255, 255, 0.35)', 1]
      ]
    })
    .borderRadius(32)
    .clip(true)
    .border({
      width: 1.5,
      color: this.pressedCardId === card.summaryId ? 'rgba(255, 255, 255, 0.98)' : 'rgba(255, 255, 255, 0.92)',
      radius: 32
    })
    .shadow({
      radius: this.pressedCardId === card.summaryId ? 14 : 20,
      color: 'rgba(92, 168, 255, 0.14)',
      offsetX: 0,
      offsetY: this.pressedCardId === card.summaryId ? 4 : 8
    })
    .scale({
      x: this.pressedCardId === card.summaryId ? 0.985 : 1,
      y: this.pressedCardId === card.summaryId ? 0.985 : 1
    })
    .translate({ x: 0, y: this.pressedCardId === card.summaryId ? 2 : 0 })
    .animation({
      duration: 160,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedCardId = card.summaryId
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedCardId = ''
      }
    })
    .onClick(() => this.navigateToDetail(card))
  }

  @Builder
  private buildLoadingState() {
    Column({ space: 14 }) {
      LoadingProgress()
        .width(42)
        .height(42)
        .color(MintColors.lavenderDark)

      Text('正在整理会议纪要...')
        .fontSize(14)
        .fontColor('rgba(77, 96, 128, 0.68)')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private buildErrorState() {
    Column({ space: 16 }) {
      Text('加载失败')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)

      Text(this.errorMessage)
        .fontSize(13)
        .fontColor('rgba(77, 96, 128, 0.68)')
        .textAlign(TextAlign.Center)

      Button('重新加载')
        .height(42)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textInverse)
        .backgroundColor(MintColors.lavenderDark)
        .borderRadius(BorderRadius.pill)
        .padding({ left: 20, right: 20 })
        .onClick(() => this.loadHistory())
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ left: Spacing.page.horizontal, right: Spacing.page.horizontal })
  }

  @Builder
  private buildEmptyState() {
    Column({ space: 16 }) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(72)
          .height(72)
          .borderRadius(36)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              ['rgba(236, 244, 255, 0.98)', 0],
              ['rgba(205, 226, 255, 0.92)', 1]
            ]
          })

        AnimatedCloudMascot({
          mascotSize: 66,
          mood: 'sleep',
          enableFloat: false,
          enableBlink: false,
          backgroundGlow: false,
          motionLevel: 'still'
        })
      }
      .width(80)
      .height(80)

      Text('还没有生成会议纪要')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)

      Text('从首页功能卡片或底部加号开始一场新会议。')
        .fontSize(13)
        .fontColor('rgba(77, 96, 128, 0.68)')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ left: Spacing.page.horizontal, right: Spacing.page.horizontal })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      DynamicGlassBackground()

      Column({ space: 12 }) {
        this.buildHeader()

        Column({ space: 14 }) {
          Column() {
            if (this.isLoading) {
              this.buildLoadingState()
            } else if (this.errorMessage.length > 0) {
              this.buildErrorState()
            } else if (this.allCards.length === 0) {
              this.buildEmptyState()
            } else {
              Scroll() {
                Column({ space: 14 }) {
                  if (this.visibleCards.length === 0) {
                    this.buildEmptyState()
                  } else {
                    ForEach(this.visibleCards, (card: MeetingCardData) => {
                      this.buildMeetingCard(card)
                    }, (card: MeetingCardData) => card.summaryId)
                  }
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding({
                  left: 1,
                  right: 1,
                  top: 2,
                  bottom: this.safeBottomVp + 28
                })
              }
              .layoutWeight(1)
              .width('100%')
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
              .opacity(this.listRefreshOpacity)
              .translate({ y: this.listRefreshTranslateY })
              .animation({
                duration: 140,
                curve: Curve.FastOutSlowIn
              })
            }
          }
          .width('100%')
          .layoutWeight(1)
          .opacity(this.bodyOpacity)
          .translate({ y: this.bodyTranslateY })
          .animation({
            duration: 220,
            curve: Curve.FastOutSlowIn
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({
          left: Spacing.page.horizontal,
          right: Spacing.page.horizontal
        })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.backgroundSecondary)
  }
}
