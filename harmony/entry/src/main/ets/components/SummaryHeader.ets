import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'

// SummaryHeader 组件属性
export interface SummaryHeaderProps {
  hasContent: boolean
}

// SummaryHeader 组件 - 纪要页头部
@Component
export struct SummaryHeader {
  @Prop hasContent: boolean = false

  build() {
    Column({ space: Spacing.card.large }) {
      Text('EXPORT / SUMMARY')
        .fontSize(Typography.size.caption)
        .fontColor(Colors.accent)
        .letterSpacing(Typography.letterSpacing.wide)

      Text('会议纪要与来源')
        .fontSize(Typography.size.xxl)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)

      Text(this.hasContent
        ? '议会已经生成纪要，可在这里快速回看共识、分歧与行动建议。'
        : '这里承接议会结果，在移动端只保留最关键的输出。')
        .fontSize(Typography.size.body)
        .fontColor(Colors.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.huge)
    .backgroundColor(LiquidGlass.surface)
    .backdropBlur(30)
    .linearGradient({
      angle: 135,
      colors: [
        [Colors.overlayMedium, 0],
        [Colors.overlaySoft, 1]
      ]
    })
    .borderRadius(BorderRadius.card.large)
    .clip(true)
    .border({
      width: 1.5,
      color: LiquidGlass.borderStrong,
      radius: BorderRadius.card.large
    })
    .shadow({
      radius: 18,
      color: Colors.shadowMedium,
      offsetX: 0,
      offsetY: 6
    })
  }
}
