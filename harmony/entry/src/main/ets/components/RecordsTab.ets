import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'

export interface RecordItem {
  id: string
  title: string
  participants: string[]
  participantLine: string
  avatarColors: string[]
  avatarTextColors: string[]
  content: string
  timeAgo: string
  accentColor: string
  secondAvatarSparkle?: boolean
}

export interface RecordsTabProps {
  records: RecordItem[]
  onRecordClick: (record: RecordItem) => void
}

const RECORD_PREVIEW_BG: string = '#F5F7F9'
const RECORD_CARD_BG: string = '#FFFFFF'

@Component
export struct RecordsTab {
  @Prop records: RecordItem[] = []
  onRecordClick: (record: RecordItem) => void = () => {}

  private mockRecords: RecordItem[] = [
    {
      id: '1',
      title: '关于“绝对权力下的孤独感”的探讨',
      participants: ['秦', '乔'],
      participantLine: '秦始皇 / 乔布斯',
      avatarColors: ['#FEE2E2', '#DBEAFE'],
      avatarTextColors: ['#DC2626', '#2563EB'],
      content: '秦始皇认为权力需要绝对集中来保证系统运转，而乔布斯反问：没有对极简与纯粹的热爱，权力只会制造出平庸的废品。',
      timeAgo: '2天前',
      accentColor: '#3B82F6',
      secondAvatarSparkle: false
    },
    {
      id: '2',
      title: '如何面对旷野与轨道的选择？',
      participants: ['我', '融'],
      participantLine: '我 / 融合意识',
      avatarColors: ['#F1F5F9', '#D1FAE5'],
      avatarTextColors: ['#64748B', '#059669'],
      content: '融合意识指出：不要试图在第一份工作里寻找一生的意义，先去打破既定轨道，把它当作一个收集数据点的实验场。',
      timeAgo: '1周前',
      accentColor: '#14B8A6',
      secondAvatarSparkle: true
    }
  ]

  private listSource(): RecordItem[] {
    return this.records.length > 0 ? this.records : this.mockRecords
  }

  private getAvatarFg(record: RecordItem, index: number): string {
    if (index < record.avatarTextColors.length) {
      return record.avatarTextColors[index]
    }
    return index === 0 ? '#F43F5E' : Colors.primary
  }

  build() {
    Column({ space: Spacing.card.large }) {
      Row() {
        Column({ space: Spacing.sm }) {
          Row({ space: Spacing.sm }) {
            Column()
              .width(24)
              .height(3)
              .borderRadius(1.5)
              .backgroundColor('#6366F1')

            Text('灵感纪要')
              .fontSize(Typography.size.xxl)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
          }

          Text('留存每一次思想碰撞留下的回响与偏移')
            .fontSize(Typography.size.bodyLg)
            .fontColor(Colors.textTertiary)
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text(`${this.listSource().length} 条`)
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.primary)
          .padding({
            left: Spacing.sm,
            right: Spacing.sm,
            top: 4,
            bottom: 4
          })
          .backgroundColor('rgba(99, 102, 241, 0.08)')
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ top: Spacing.lg })

      Column({ space: 16 }) {
        ForEach(this.listSource(), (record: RecordItem, index: number) => {
          this.buildRecordCard(record, index)
        }, (record: RecordItem) => record.id)
      }
      .width('100%')

      Blank()
        .height(Spacing.giant)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildRecordCard(record: RecordItem, index: number) {
    Row() {
      Column()
        .width(6)
        .backgroundColor(record.accentColor)
        .alignSelf(ItemAlign.Stretch)

      Column({ space: 14 }) {
        Row() {
          Text(record.title)
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)

          Text(record.timeAgo)
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)
            .padding({
              left: Spacing.sm,
              right: Spacing.sm,
              top: 4,
              bottom: 4
            })
            .backgroundColor('rgba(241, 245, 249, 0.80)')
            .borderRadius(BorderRadius.pill)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row({ space: 10 }) {
          Row() {
            ForEach(record.participants, (_name: string, avatarIndex: number) => {
              this.buildAvatarCell(record, avatarIndex)
            }, (_name: string, avatarIndex: number) => `${record.id}-av-${avatarIndex}`)
          }
          .alignItems(VerticalAlign.Center)

          Column({ space: 4 }) {
            Text(record.participantLine)
              .fontSize(Typography.size.caption)
              .fontColor(Colors.textTertiary)
              .fontWeight(FontWeight.Medium)

            Text('已保存的思想交汇片段')
              .fontSize(Typography.size.xs)
              .fontColor(Colors.textMuted)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Column({ space: Spacing.sm }) {
          Row({ space: 6 }) {
            Column()
              .width(18)
              .height(18)
              .borderRadius(9)
              .backgroundColor('rgba(99, 102, 241, 0.08)')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

            Text('内容预览')
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.primary)
          }

          Text(record.content)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textSecondary)
            .lineHeight(20)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .padding({
              left: 12,
              right: 12,
              top: 10,
              bottom: 10
            })
            .backgroundColor(RECORD_PREVIEW_BG)
            .borderRadius(BorderRadius.md)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: 14,
        right: 16,
        top: 16,
        bottom: 16
      })
    }
    .width('100%')
    .backgroundColor(RECORD_CARD_BG)
    .borderRadius(BorderRadius.xxl2)
    .clip(true)
    .shadow({
      radius: 22,
      color: index === 0 ? 'rgba(15, 23, 42, 0.10)' : 'rgba(15, 23, 42, 0.07)',
      offsetX: 0,
      offsetY: 6
    })
    .transition(TransitionEffect.OPACITY.animation({
      duration: 220 + index * 50,
      curve: Curve.EaseOut
    }))
    .onClick(() => {
      this.onRecordClick(record)
    })
  }

  @Builder
  buildAvatarCell(record: RecordItem, index: number) {
    if (record.secondAvatarSparkle === true && index === 1) {
      Column() {
        Text('✦')
          .fontSize(11)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(record.avatarColors[index] || '#F1F5F9')
      .border({
        width: 2,
        color: RECORD_CARD_BG,
        radius: 14
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ left: -10 })
      .zIndex(record.participants.length - index)
    } else {
      Column() {
        Text(record.participants[index].length > 0 ? record.participants[index].charAt(0) : '?')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getAvatarFg(record, index))
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor(record.avatarColors[index] || '#F1F5F9')
      .border({
        width: 2,
        color: RECORD_CARD_BG,
        radius: 14
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ left: index === 0 ? 0 : -10 })
      .zIndex(record.participants.length - index)
    }
  }
}
