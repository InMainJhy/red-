import { MintColors } from '../common/styles/MintColors'
import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'

type ThemeColor = ResourceColor | string

export interface RecordItem {
  id: string
  sessionId?: string
  title: string
  topic: string
  participants: string[]
  selectedAgentIds?: string[]
  profileIds?: string[]
  participantLine: string
  avatarColors: string[]
  avatarTextColors: string[]
  content: string
  timeAgo: string
  accentColor: ThemeColor
  messageCount: number
  highlightCount: number
  durationLabel: string
  isFavorite: boolean
}

export interface RecordsTabProps {
  records: RecordItem[]
  onRecordClick: (record: RecordItem) => void
  onGenerateCard?: (record: RecordItem) => void
  onGenerateVideo?: (record: RecordItem) => void
  onShareRecord?: (record: RecordItem) => void
  onViewAll?: () => void
}

interface WorkspaceAction {
  id: string
  order: string
  title: string
  description: string
  actionLabel: string
  tint: ThemeColor
  tone: ThemeColor
}

const RECORD_CARD_BG: ThemeColor = MintColors.cardPrimary
const RECORD_PREVIEW_BG: ThemeColor = Colors.backgroundElevated
const HERO_CARD_BG: ThemeColor = MintColors.surfaceGlass
const HERO_BORDER: ThemeColor = MintColors.border

@Component
export struct RecordsTab {
  @Prop records: RecordItem[] = []
  onRecordClick: (record: RecordItem) => void = () => {}
  onGenerateCard: (record: RecordItem) => void = () => {}
  onGenerateVideo: (record: RecordItem) => void = () => {}
  onShareRecord: (record: RecordItem) => void = () => {}
  onViewAll: () => void = () => {}

  @State private heroOpacity: number = 0
  @State private heroTranslateY: number = 24
  @State private heroGlowOffset: number = 0
  @State private heroGlowScale: number = 0.96
  @State private heroHaloOpacity: number = 0.55
  @State private latestOpacity: number = 0
  @State private latestTranslateY: number = 20
  @State private latestScale: number = 0.97
  @State private historyOpacity: number = 0
  @State private historyTranslateY: number = 16
  @State private actionCardOpacities: number[] = [0, 0, 0]
  @State private actionCardTranslateX: number[] = [20, 20, 20]
  @State private actionPressedId: string = ''
  @State private historyCardOpacities: number[] = []
  @State private historyCardTranslateY: number[] = []
  @State private historyPressedId: string = ''

  private readonly workspaceActions: WorkspaceAction[] = [
    {
      id: 'card',
      order: '01',
      title: '生成卡片',
      description: '把亮点整理成可分享卡片。',
      actionLabel: '去导出',
      tint: Colors.textPrimary,
      tone: Colors.overlaySoft
    },
    {
      id: 'video',
      order: '02',
      title: '会议视频',
      description: '把纪要转成回顾视频。',
      actionLabel: '去生成',
      tint: Colors.accent,
      tone: Colors.overlayMedium
    },
    {
      id: 'share',
      order: '03',
      title: '快速分享',
      description: '一键发给同事或朋友。',
      actionLabel: '去分享',
      tint: MintColors.mintDark,
      tone: Colors.overlaySoft
    }
  ]

  aboutToAppear(): void {
    this.heroOpacity = 1
    this.heroTranslateY = 0
    this.heroGlowOffset = 0
    this.heroGlowScale = 1
    this.heroHaloOpacity = 0.32
    this.latestOpacity = 1
    this.latestTranslateY = 0
    this.latestScale = 1
    this.historyOpacity = 1
    this.historyTranslateY = 0
    this.actionCardOpacities = [1, 1, 1]
    this.actionCardTranslateX = [0, 0, 0]

    const count = this.historyRecords().length
    const historyOpacities: number[] = []
    const historyOffsets: number[] = []
    for (let i = 0; i < count; i++) {
      historyOpacities.push(1)
      historyOffsets.push(0)
    }
    this.historyCardOpacities = historyOpacities
    this.historyCardTranslateY = historyOffsets
  }

  private latestRecord(): RecordItem | null {
    if (this.records.length === 0) {
      return null
    }
    return this.records[0]
  }

  private historyRecords(): RecordItem[] {
    if (this.records.length <= 1) {
      return []
    }
    return this.records.slice(1)
  }

  private hasRecord(): boolean {
    return this.records.length > 0
  }

  private getAvatarFg(record: RecordItem, index: number): ResourceColor {
    if (index < record.avatarTextColors.length) {
      return record.avatarTextColors[index]
    }
    return Colors.backgroundElevated as ResourceColor
  }

  private summaryCountLabel(): string {
    if (this.records.length === 0) {
      return '等待生成'
    }
    return `${this.records.length} 份纪要`
  }

  private latestStatusLabel(): string {
    const latest = this.latestRecord()
    return latest ? `最近更新 · ${latest.timeAgo}` : '完成一场会议后会自动沉淀'
  }

  private actionEnabled(): boolean {
    return this.latestRecord() !== null
  }

  private actionHint(enabled: boolean): string {
    return enabled ? '点击打开' : '先完成一场会议'
  }

  private runWorkspaceAction(actionId: string): void {
    const latest = this.latestRecord()
    if (!latest) {
      return
    }

    if (actionId === 'card') {
      this.onGenerateCard(latest)
      return
    }

    if (actionId === 'video') {
      this.onGenerateVideo(latest)
      return
    }

    this.onShareRecord(latest)
  }

  private actionCardScale(actionId: string): number {
    return this.actionPressedId === actionId ? 0.97 : 1
  }

  private historyCardOpacity(index: number): number {
    return index < this.historyCardOpacities.length ? this.historyCardOpacities[index] : 1
  }

  private historyCardTranslate(index: number): number {
    return index < this.historyCardTranslateY.length ? this.historyCardTranslateY[index] : 0
  }

  build() {
    Column({ space: 18 }) {
      this.buildWorkspaceHero()

      if (this.hasRecord()) {
        this.buildLatestSummary(this.records[0])
      } else {
        this.buildEmptyState()
      }

      this.buildHistorySection()

      Blank()
        .height(118)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildWorkspaceHero() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 18 }) {
        Row() {
          Column({ space: 6 }) {
            Text('MEMO FLOW')
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.accent)
              .letterSpacing(2.2)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor(Colors.overlaySoft)
              .borderRadius(BorderRadius.pill)

            Text('纪要中心')
              .fontSize(38)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .lineHeight(46)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(this.summaryCountLabel())
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(LiquidGlass.surfaceStrong)
            .border({
              width: 1,
              color: LiquidGlass.border,
              radius: BorderRadius.pill
            })
            .borderRadius(BorderRadius.pill)
        }
        .width('100%')

        Text('自动沉淀会议亮点、共识与后续动作，让每一次讨论都有后续。')
          .fontSize(Typography.size.bodyLg)
          .fontColor(Colors.textSecondary)
          .lineHeight(Typography.lineHeight.relaxed)
          .width('100%')

        Row({ space: Spacing.sm }) {
          this.buildHeroChip('会后自动总结')
          this.buildHeroChip(this.latestStatusLabel())
        }
        .width('100%')

        Scroll() {
          Row({ space: Spacing.md }) {
            ForEach(this.workspaceActions, (action: WorkspaceAction, index: number) => {
              this.buildActionCard(action, index)
            }, (action: WorkspaceAction) => action.id)
          }
        }
        .width('100%')
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.card.large)
    }
    .width('100%')
    .backgroundColor(HERO_CARD_BG)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [MintColors.cardPrimary, 0],
        [Colors.overlayMedium, 0.56],
        [Colors.overlaySoft, 1]
      ]
    })
    .borderRadius(BorderRadius.xxl3)
    .border({
      width: 0.9,
      color: HERO_BORDER,
      radius: BorderRadius.xxl3
    })
    .shadow({
      radius: 18,
      color: 'rgba(108, 153, 192, 0.10)',
      offsetX: 0,
      offsetY: 8
    })
    .clip(true)
    .opacity(this.heroOpacity)
    .translate({ y: this.heroTranslateY })
    .scale({ x: this.heroOpacity * 0.03 + 0.97, y: this.heroOpacity * 0.03 + 0.97 })
  }

  @Builder
  private buildHeroChip(label: string) {
    Row({ space: 6 }) {
      Column()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor('rgba(126, 156, 210, 0.82)')

      Text(label)
        .fontSize(Typography.size.xs)
        .fontColor(Colors.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .backgroundColor(LiquidGlass.surfaceStrong)
    .borderRadius(BorderRadius.pill)
    .border({
      width: 1,
      color: LiquidGlass.border,
      radius: BorderRadius.pill
    })
  }

  @Builder
  private buildActionCard(action: WorkspaceAction, index: number) {
    Column({ space: 14 }) {
      Row() {
        Text(action.order)
          .fontSize(Typography.size.lg)
          .fontWeight(FontWeight.Bold)
          .fontColor(action.tint)

        Blank()

        Text(this.actionEnabled() ? action.actionLabel : '等待纪要')
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.actionEnabled() ? action.tint : MintColors.textMuted)
      }
      .width('100%')

      Column({ space: 6 }) {
        Text(action.title)
          .fontSize(Typography.size.subtitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
          .width('100%')
          .textAlign(TextAlign.Start)

        Text(action.description)
          .fontSize(Typography.size.caption)
          .fontColor(Colors.textTertiary)
          .lineHeight(Typography.lineHeight.normal)
          .width('100%')
        }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row({ space: 6 }) {
        Column()
          .width(18)
          .height(2)
          .borderRadius(1)
          .backgroundColor(action.tint)

        Text(this.actionHint(this.actionEnabled()))
          .fontSize(Typography.size.xs)
          .fontColor(Colors.textMuted)
      }
      .width('100%')
    }
    .width(184)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.actionEnabled() ? action.tone : Colors.overlaySoft)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [LiquidGlass.surfaceStrong, 0],
        [this.actionEnabled() ? action.tone : Colors.overlaySoft, 1]
      ]
    })
    .borderRadius(26)
    .border({
      width: 0.8,
      color: Colors.border,
      radius: 26
    })
    .shadow({
      radius: 12,
      color: Colors.shadowSoft,
      offsetX: 0,
      offsetY: 6
    })
    .enabled(this.actionEnabled())
    .opacity(index < this.actionCardOpacities.length ? this.actionCardOpacities[index] : 1)
    .translate({ x: index < this.actionCardTranslateX.length ? this.actionCardTranslateX[index] : 0 })
    .scale({ x: this.actionCardScale(action.id), y: this.actionCardScale(action.id) })
    .animation({
      duration: this.actionPressedId === action.id ? 120 : 220,
      curve: this.actionPressedId === action.id ? Curve.Sharp : Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (!this.actionEnabled()) {
        return
      }
      if (event.type === TouchType.Down) {
        this.actionPressedId = action.id
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.actionPressedId = ''
      }
    })
    .onClick(() => {
      this.runWorkspaceAction(action.id)
    })
  }

  @Builder
  private buildLatestSummary(record: RecordItem) {
    Column({ space: Spacing.lg }) {
      Row() {
        Column({ space: 6 }) {
          Text('最新一场会议')
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textMuted)
            .letterSpacing(1.6)

          Text('这份纪要已经可以直接分享')
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (record.isFavorite) {
          Text('已收藏')
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.warning)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('rgba(17, 17, 17, 0.14)')
            .borderRadius(BorderRadius.pill)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Column({ space: 12 }) {
        Row() {
          Column({ space: 6 }) {
            Text(record.title)
              .fontSize(Typography.size.xl)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .textAlign(TextAlign.Start)

            Text(record.topic)
              .fontSize(Typography.size.body)
              .fontColor(Colors.textMuted)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(record.timeAgo)
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.textMuted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(Colors.overlaySoft)
            .borderRadius(BorderRadius.pill)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

          Text(record.content)
            .fontSize(Typography.size.body)
            .fontColor(Colors.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)
            .width('100%')
            .padding(Spacing.md)
            .backgroundColor(RECORD_PREVIEW_BG)
            .border({
              width: 1,
              color: MintColors.surfaceGlass,
              radius: BorderRadius.lg
            })
            .borderRadius(BorderRadius.lg)

        Row({ space: Spacing.md }) {
          Row() {
            ForEach(record.participants.slice(0, 3), (_name: string, avatarIndex: number) => {
              this.buildAvatarCell(record, avatarIndex, 32, 16)
            }, (_name: string, avatarIndex: number) => `${record.id}-latest-${avatarIndex}`)
          }
          .alignItems(VerticalAlign.Center)

          Text(record.participantLine)
            .layoutWeight(1)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Flex({ wrap: FlexWrap.Wrap }) {
          this.buildMetricChip(`${record.messageCount} 条消息`)
          this.buildMetricChip(`${record.highlightCount} 个要点`)
          this.buildMetricChip(record.durationLabel)
        }
        .width('100%')

        Row({ space: Spacing.sm }) {
          Button('生成卡片')
            .layoutWeight(1)
            .height(44)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.accentAlt)
            .backgroundColor(Colors.accent)
            .borderRadius(BorderRadius.xxl)
            .onClick(() => {
              this.onGenerateCard(record)
            })

          Button('会议视频')
            .layoutWeight(1)
            .height(44)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textPrimary)
            .backgroundColor('rgba(235, 242, 252, 0.92)')
            .border({
              width: 1,
              color: MintColors.surfaceGlass,
              radius: BorderRadius.xxl
            })
            .borderRadius(BorderRadius.xxl)
            .onClick(() => {
              this.onGenerateVideo(record)
            })

          Button('去分享')
            .layoutWeight(1)
            .height(44)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textPrimary)
            .backgroundColor('rgba(233, 244, 239, 0.92)')
            .border({
              width: 1,
              color: MintColors.surfaceGlass,
              radius: BorderRadius.xxl
            })
            .borderRadius(BorderRadius.xxl)
            .onClick(() => {
              this.onShareRecord(record)
            })
        }
        .width('100%')

        Row({ space: Spacing.sm }) {
          Button('查看详情')
            .layoutWeight(1)
            .height(42)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textPrimary)
            .backgroundColor(MintColors.surfaceGlass)
            .border({
              width: 1,
              color: MintColors.surfaceGlass,
              radius: BorderRadius.xxl
            })
            .borderRadius(BorderRadius.xxl)
            .onClick(() => {
              this.onRecordClick(record)
            })

          Button('全部纪要')
            .layoutWeight(1)
            .height(42)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textSecondary)
            .backgroundColor(MintColors.surfaceGlass)
            .border({
              width: 1,
              color: MintColors.surfaceGlass,
              radius: BorderRadius.xxl
            })
            .borderRadius(BorderRadius.xxl)
            .onClick(() => {
              this.onViewAll()
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.card.large)
      .backgroundColor(RECORD_CARD_BG)
      .border({
        width: 1,
        color: MintColors.cardPrimary,
        radius: BorderRadius.xxl3
      })
      .borderRadius(BorderRadius.xxl3)
      .shadow({
        radius: 10,
        color: 'rgba(137, 160, 194, 0.05)',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .opacity(this.latestOpacity)
    .translate({ y: this.latestTranslateY })
    .scale({ x: this.latestScale, y: this.latestScale })
  }

  @Builder
  private buildMetricChip(label: string) {
    Text(label)
      .fontSize(Typography.size.xs)
      .fontWeight(FontWeight.Medium)
      .fontColor(MintColors.textSecondary)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('rgba(247, 247, 243, 0.92)')
      .borderRadius(BorderRadius.pill)
      .margin({ right: Spacing.sm, bottom: Spacing.sm })
  }

  @Builder
  private buildEmptyState() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          Text('EMPTY MEMO')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.accent)
            .letterSpacing(1.4)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(Colors.overlaySoft)
            .borderRadius(BorderRadius.pill)

          Text('还没有会议纪要')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .lineHeight(38)

          Text('完成第一场会议后，这里会自动沉淀结果。')
            .fontSize(Typography.size.body)
            .fontColor(Colors.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Column({ space: Spacing.sm }) {
          this.buildEmptyStep('1', '先完成一场会议讨论')
          this.buildEmptyStep('2', '系统自动整理要点')
          this.buildEmptyStep('3', '再导出或分享')
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(Spacing.card.large)
    .backgroundColor(MintColors.surfaceGlass)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [MintColors.cardPrimary, 0],
        [Colors.overlayMedium, 1]
      ]
    })
    .borderRadius(BorderRadius.xxl3)
    .border({
      width: 0.9,
      color: Colors.border,
      radius: BorderRadius.xxl3
    })
    .shadow({
      radius: 16,
      color: Colors.shadowSoft,
      offsetX: 0,
      offsetY: 8
    })
    .opacity(this.latestOpacity)
    .translate({ y: this.latestTranslateY })
  }

  @Builder
  private buildEmptyStep(index: string, label: string) {
    Row({ space: Spacing.md }) {
      Column() {
        Text(index)
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
      }
      .width(26)
      .height(26)
      .borderRadius(13)
      .backgroundColor(Colors.overlaySoft)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(label)
        .layoutWeight(1)
        .fontSize(Typography.size.body)
        .fontColor(Colors.textSecondary)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(MintColors.surfaceGlass)
    .borderRadius(22)
    .border({
      width: 0.7,
      color: 'rgba(214, 233, 247, 0.68)',
      radius: 22
    })
  }

  @Builder
  private buildHistorySection() {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.sm }) {
        Column({ space: 6 }) {
          Text('纪要历史')
            .fontSize(Typography.size.lg)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)

          Text(this.historyRecords().length > 0 ? '更早的会议都会沉淀在这里。' : '新的纪要生成后会出现在这里。')
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textMuted)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button('查看全部')
          .height(34)
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
          .backgroundColor(MintColors.surfaceGlass)
          .border({
            width: 1,
            color: MintColors.surfaceGlass,
            radius: BorderRadius.pill
          })
          .borderRadius(BorderRadius.pill)
          .onClick(() => {
            this.onViewAll()
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      if (this.historyRecords().length === 0) {
        Column({ space: 6 }) {
          Text('最新一条纪要已经置顶显示。')
            .fontSize(Typography.size.body)
            .fontColor(Colors.textSecondary)

          Text('继续发起新的会议后，这里会积累更多可回看的纪要。')
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textMuted)
        }
        .width('100%')
        .padding(Spacing.lg)
        .backgroundColor(MintColors.surfaceGlass)
        .border({
          width: 1,
          color: MintColors.surfaceGlass,
          radius: BorderRadius.xxl2
        })
        .borderRadius(BorderRadius.xxl2)
      } else {
        Column({ space: Spacing.md }) {
          ForEach(this.historyRecords(), (record: RecordItem, index: number) => {
            this.buildHistoryCard(record, index)
          }, (record: RecordItem) => record.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .opacity(this.historyOpacity)
    .translate({ y: this.historyTranslateY })
  }

  @Builder
  private buildHistoryCard(record: RecordItem, index: number) {
    Row() {
      Column()
        .width(6)
        .alignSelf(ItemAlign.Stretch)
        .backgroundColor(record.accentColor)

      Column({ space: 14 }) {
        Row() {
          Column({ space: 4 }) {
            Text(record.title)
              .fontSize(Typography.size.subtitle)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .textAlign(TextAlign.Start)

            Text(record.topic)
              .fontSize(Typography.size.caption)
              .fontColor(Colors.textMuted)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Text(record.timeAgo)
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.textMuted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor('rgba(247, 247, 243, 0.92)')
            .borderRadius(BorderRadius.pill)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row({ space: 10 }) {
          Row() {
            ForEach(record.participants.slice(0, 3), (_name: string, avatarIndex: number) => {
              this.buildAvatarCell(record, avatarIndex, 28, 14)
            }, (_name: string, avatarIndex: number) => `${record.id}-history-${avatarIndex}`)
          }
          .alignItems(VerticalAlign.Center)

          Text(record.participantLine)
            .layoutWeight(1)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(record.content)
          .fontSize(Typography.size.caption)
          .fontColor(Colors.textSecondary)
          .lineHeight(20)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor(RECORD_PREVIEW_BG)
          .border({
            width: 1,
            color: MintColors.surfaceGlass,
            radius: BorderRadius.md
          })
          .borderRadius(BorderRadius.md)

        Row({ space: Spacing.md }) {
          Text(`${record.messageCount} 条消息`)
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)

          Text(`${record.highlightCount} 个要点`)
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)

          Text(record.durationLabel)
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)

          Blank()

          Text('查看详情')
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 14, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .backgroundColor(RECORD_CARD_BG)
    .border({
      width: 1,
      color: MintColors.cardPrimary,
      radius: BorderRadius.xxl2
    })
    .borderRadius(BorderRadius.xxl2)
    .clip(true)
    .shadow({
      radius: index === 0 ? 20 : 16,
      color: index === 0 ? 'rgba(137, 160, 194, 0.10)' : 'rgba(137, 160, 194, 0.06)',
      offsetX: 0,
      offsetY: 6
    })
    .opacity(this.historyCardOpacity(index))
    .translate({ y: this.historyCardTranslate(index) })
    .scale({
      x: this.historyPressedId === record.id ? 0.985 : 1,
      y: this.historyPressedId === record.id ? 0.985 : 1
    })
    .animation({
      duration: this.historyPressedId === record.id ? 120 : 220,
      curve: this.historyPressedId === record.id ? Curve.Sharp : Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.historyPressedId = record.id
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.historyPressedId = ''
      }
    })
    .onClick(() => {
      this.onRecordClick(record)
    })
  }

  @Builder
  private buildAvatarCell(record: RecordItem, index: number, size: number, radius: number) {
    Column() {
      Text(record.participants[index].length > 0 ? record.participants[index].charAt(0) : '?')
        .fontSize(size >= 32 ? 12 : 11)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getAvatarFg(record, index))
    }
    .width(size)
    .height(size)
    .borderRadius(radius)
    .backgroundColor(record.avatarColors[index] || '#FFFFFF')
    .border({
      width: 2,
      color: RECORD_CARD_BG,
      radius: radius
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ left: index === 0 ? 0 : -10 })
    .zIndex(record.participants.length - index)
  }
}
