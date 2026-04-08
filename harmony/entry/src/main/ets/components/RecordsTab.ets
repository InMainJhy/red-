import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'

// RecordItem 记录项接口（纪要列表卡片数据）
export interface RecordItem {
  id: string
  title: string
  /** 头像内短文案（一字或「我」） */
  participants: string[]
  /** 展示用全名，如「秦始皇 / 乔布斯」 */
  participantLine: string
  avatarColors: string[]
  /** 头像内文字颜色，与背景对比 */
  avatarTextColors: string[]
  content: string
  timeAgo: string
  /** 左侧竖条强调色 */
  accentColor: string
  /** 第二张头像是否显示火花图标（设计稿第二张卡） */
  secondAvatarSparkle?: boolean
}

// RecordsTab 组件属性
export interface RecordsTabProps {
  records: RecordItem[]
  onRecordClick: (record: RecordItem) => void
}

// 纪要页内容预览区背景（设计稿浅灰）
const RECORD_PREVIEW_BG: string = '#F5F7F9'
// 卡片纯白底
const RECORD_CARD_BG: string = '#FFFFFF'

// RecordsTab 组件 - 纪要页面（灵感纪要列表）
@Component
export struct RecordsTab {
  @Prop records: RecordItem[] = []
  onRecordClick: (record: RecordItem) => void = () => {}

  private mockRecords: RecordItem[] = [
    {
      id: '1',
      title: '关于"绝对权力下的孤独感"的探讨',
      participants: ['秦', '乔'],
      participantLine: '秦始皇 / 乔布斯',
      avatarColors: ['#FEE2E2', '#DBEAFE'],
      avatarTextColors: ['#DC2626', '#2563EB'],
      content: '秦始皇认为权力需要绝对的集中来保证系统的运转，而乔布斯反驳道：没有对极简与纯粹的热爱，权力只会制造出平庸的废品...',
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
      content: '融合意识指出：不要试图在第一份工作中寻找一生的意义，去打破既定的轨道，把它当作一个收集数据点的实验场...',
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
      Column({ space: Spacing.sm }) {
        Text('灵感纪要')
          .fontSize(Typography.size.xxl)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Text('留存每一次思想的碰撞与回响')
          .fontSize(Typography.size.bodyLg)
          .fontColor(Colors.textTertiary)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: Spacing.lg })

      Column({ space: 16 }) {
        ForEach(this.listSource(), (record: RecordItem) => {
          this.buildRecordCard(record)
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
  buildRecordCard(record: RecordItem) {
    Row() {
      Column()
        .width(5)
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

          Row({ space: 4 }) {
            Text('🕐')
              .fontSize(12)
            Text(record.timeAgo)
              .fontSize(Typography.size.xs)
              .fontColor(Colors.textMuted)
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row({ space: 10 }) {
          Row() {
            ForEach(record.participants, (_name: string, index: number) => {
              this.buildAvatarCell(record, index)
            }, (_name: string, index: number) => `${record.id}-av-${index}`)
          }
          .alignItems(VerticalAlign.Center)

          Text(record.participantLine)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textTertiary)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
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
          .padding({
            left: 12,
            right: 12,
            top: 10,
            bottom: 10
          })
          .backgroundColor(RECORD_PREVIEW_BG)
          .borderRadius(BorderRadius.md)
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
      radius: 24,
      color: 'rgba(15, 23, 42, 0.08)',
      offsetX: 0,
      offsetY: 6
    })
    .onClick(() => {
      this.onRecordClick(record)
    })
  }

  @Builder
  buildAvatarCell(record: RecordItem, index: number) {
    if (record.secondAvatarSparkle === true && index === 1) {
      Column() {
        Text('✨')
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
