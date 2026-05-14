import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { MintColors } from '../common/styles/MintColors'

// SummaryCard 组件属性
export interface SummaryCardProps {
  summaryTitle: string
  consensus: string
  disagreements: string[]
  actionableAdvice: string[]
  narrativeHook: string
}

// SummaryCard 组件 - 清新风格会议纪要卡片
@Component
export struct SummaryCard {
  @Prop public summaryTitle: string = ''
  @Prop public consensus: string = ''
  @Prop public disagreements: string[] = []
  @Prop public actionableAdvice: string[] = []
  @Prop public narrativeHook: string = ''
  @State private cardOpacity: number = 1
  @State private cardScale: number = 1
  @State private itemsOpacity: number = 1
  public onGoArena: () => void = () => {}
  public onGoRole: () => void = () => {}

  build() {
    if (this.summaryTitle.length > 0) {
      Column({ space: Spacing.card.large }) {
        // 标题
        Text(this.summaryTitle)
          .fontSize(Typography.size.xxl)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
          .width('100%')
          .opacity(this.cardOpacity)

        // 共识区块
        Column({ space: Spacing.sm }) {
          Row({ space: Spacing.sm }) {
            Column()
              .width(4)
              .height(14)
              .borderRadius(2)
              .backgroundColor(MintColors.mint) // Mint主色
            Text('共识')
              .fontSize(Typography.size.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(MintColors.lavenderDark)
          }
          .width('100%')

          Text(this.consensus)
            .fontSize(Typography.size.body)
            .fontColor(Colors.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)
            .width('100%')
            .padding({ left: Spacing.md })
        }
        .width('100%')
        .opacity(this.itemsOpacity)

        // 分隔线
        Divider()
          .color(Colors.divider)
          .margin({ top: Spacing.sm, bottom: Spacing.sm })
          .opacity(this.itemsOpacity)

        // 主要分歧区块
        Column({ space: Spacing.sm }) {
          Row({ space: Spacing.sm }) {
            Column()
              .width(4)
              .height(14)
              .borderRadius(2)
              .backgroundColor(Colors.error) // 错误色/分歧色
            Text('主要分歧')
              .fontSize(Typography.size.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.error)
          }
          .width('100%')

          Column({ space: Spacing.sm }) {
            ForEach(this.disagreements, (item: string, index: number) => {
              Row({ space: Spacing.sm }) {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor('rgba(161, 75, 82, 0.5)')
                  .margin({ top: 7 })
                Text(item)
                  .fontSize(Typography.size.body)
                  .fontColor(Colors.textSecondary)
                  .lineHeight(Typography.lineHeight.relaxed)
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }, (item: string) => item)
          }
          .width('100%')
          .padding({ left: Spacing.md })
        }
        .width('100%')
        .opacity(this.itemsOpacity)

        // 分隔线
        Divider()
          .color(Colors.divider)
          .margin({ top: Spacing.sm, bottom: Spacing.sm })
          .opacity(this.itemsOpacity)

        // 行动建议区块
        Column({ space: Spacing.sm }) {
          Row({ space: Spacing.sm }) {
            Column()
              .width(4)
              .height(14)
              .borderRadius(2)
              .backgroundColor(Colors.accent) // 成功色/建议色
            Text('行动建议')
              .fontSize(Typography.size.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.accent)
          }
          .width('100%')

          Column({ space: Spacing.sm }) {
            ForEach(this.actionableAdvice, (item: string, index: number) => {
              Row({ space: Spacing.sm }) {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor('rgba(46, 92, 167, 0.5)')
                  .margin({ top: 7 })
                Text(item)
                  .fontSize(Typography.size.body)
                  .fontColor(Colors.textSecondary)
                  .lineHeight(Typography.lineHeight.relaxed)
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            }, (item: string) => item)
          }
          .width('100%')
          .padding({ left: Spacing.md })
        }
        .width('100%')
        .opacity(this.itemsOpacity)

        // 叙事钩子
        if (this.narrativeHook.length > 0) {
          Text(`"${this.narrativeHook}"`)
            .fontSize(Typography.size.body)
            .fontColor(Colors.textPrimary)
            .lineHeight(Typography.lineHeight.relaxed)
            .padding(Spacing.lg)
            .backgroundColor(Colors.overlaySoft)
            .borderRadius(BorderRadius.lg)
            .border({
              width: 1,
              color: Colors.border,
              radius: BorderRadius.lg
            })
            .shadow({
              radius: 8,
              color: Colors.shadowSoft,
              offsetX: 0,
              offsetY: 2
            })
            .width('100%')
            .opacity(this.itemsOpacity)
        }

        // 分隔线
        Divider()
          .color(Colors.divider)
          .margin({ top: Spacing.sm })
          .opacity(this.itemsOpacity)

        // 操作按钮
        Row({ space: Spacing.card.large }) {
          Button('回到议会')
            .layoutWeight(1)
            .height(44)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textInverse)
            .linearGradient({
              angle: 135,
              colors: [
                ['#79B8F9', 0],
                ['#5E95E2', 1]
              ]
            })
            .borderRadius(BorderRadius.huge)
            .shadow({
              radius: 12,
              color: 'rgba(94, 149, 226, 0.28)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              this.onGoArena()
            })

          Button('换角色')
            .layoutWeight(1)
            .height(44)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textPrimary)
            .backgroundColor(Colors.cardSecondary)
            .borderRadius(BorderRadius.huge)
            .border({
              width: 1,
              color: Colors.border,
              radius: BorderRadius.huge
            })
            .onClick(() => {
              this.onGoRole()
            })
        }
        .width('100%')
        .margin({ top: Spacing.sm })
        .opacity(this.itemsOpacity)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.huge)
      .backgroundColor(Colors.cardPrimary)
      .backdropBlur(30)
      .linearGradient({
        angle: 135,
        colors: [
          [Colors.overlayMedium, 0],
          [Colors.cardSecondary, 0.52],
          [Colors.backgroundElevated, 1]
        ]
      })
      .borderRadius(BorderRadius.huge)
      .clip(true)
      .border({
        width: 1.5,
        color: Colors.border,
        radius: BorderRadius.huge
      })
      .shadow({
        radius: 16,
        color: Colors.shadowMedium,
        offsetX: 0,
        offsetY: 6
      })
      .opacity(this.cardOpacity)
      .scale({
        x: this.cardScale,
        y: this.cardScale
      })
    } else {
      Column({ space: Spacing.md }) {
        Text('暂无纪要')
          .fontSize(Typography.size.lg)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Text('启动一次议会后，这里会直接显示会议纪要。')
          .fontSize(Typography.size.bodyLg)
          .fontColor('rgba(77, 96, 128, 0.68)')
          .lineHeight(Typography.lineHeight.relaxed)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.huge)
      .backgroundColor('rgba(255, 255, 255, 0.45)')
      .backdropBlur(30)
      .borderRadius(BorderRadius.huge)
      .clip(true)
      .border({
        width: 1.5,
        color: 'rgba(255, 255, 255, 0.92)',
        radius: BorderRadius.huge
      })
    }
  }
}
