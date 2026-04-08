import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'

// HeroSection 组件属性（预留扩展，与设计稿标题区一致）
export interface HeroSectionProps {
  selectedProfileName: string
  connectionLabel: string
}

// HeroSection 组件 - 灵感岛屿标题区
@Component
export struct HeroSection {
  @Prop selectedProfileName: string = ''
  @Prop connectionLabel: string = '连接中'

  build() {
    Stack({ alignContent: Alignment.Start }) {
      // 左侧装饰线
      Column()
        .width(4)
        .height(48)
        .borderRadius(2)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#6366F1', 0], ['#A78BFA', 1]]
        })

      Column({ space: Spacing.sm }) {
        // 主标题
        Row({ space: Spacing.sm }) {
          Text('灵感岛屿')
            .fontSize(Typography.size.display)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .fontStyle(FontStyle.Normal)

          // 标题装饰点
          Column()
            .width(8)
            .height(8)
            .borderRadius(4)
            .backgroundColor('#F59E0B')
            .margin({ top: 10 })
        }
        .width('100%')

        // 副标题
        Text('收集与创造多元的思想切片')
          .fontSize(Typography.size.bodyLg)
          .fontColor(Colors.textTertiary)
          .width('100%')
          .textAlign(TextAlign.Start)
          .letterSpacing(0.5)

        // 连接状态指示器
        Row({ space: 6 }) {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(this.connectionLabel === '连接成功' ? '#10B981' : '#F59E0B')

          Text(this.connectionLabel)
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)
        }
        .margin({ top: Spacing.xs })
      }
      .padding({ left: Spacing.sm })
    }
    .padding({
      left: Spacing.xs,
      right: Spacing.xs,
      top: Spacing.lg,
      bottom: Spacing.md
    })
  }
}
