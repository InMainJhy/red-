import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import {
  AnimationDuration,
  AnimationCurve
} from '../common/styles/Animation'

export interface HeroSectionProps {
  selectedProfileName: string
  connectionLabel: string
}

@Component
export struct HeroSection {
  @Prop selectedProfileName: string = ''
  @Prop connectionLabel: string = '连接中'
  @State private lineOpacity: number = 0
  @State private contentOpacity: number = 0
  @State private chipOpacity: number = 0
  @State private badgeTranslateY: number = 12

  aboutToAppear(): void {
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.emphasized
      }, () => {
        this.lineOpacity = 1
      })
    }, AnimationDuration.fast)

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.emphasized
      }, () => {
        this.contentOpacity = 1
      })
    }, AnimationDuration.normal)

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.emphasized
      }, () => {
        this.chipOpacity = 1
        this.badgeTranslateY = 0
      })
    }, AnimationDuration.slow)
  }

  private isLiveConnection(): boolean {
    const status = this.connectionLabel.toUpperCase()
    return status.includes('LIVE') || status.includes('成功') || status.includes('ONLINE')
  }

  private getRoleLabel(): string {
    return this.selectedProfileName.length > 0 ? this.selectedProfileName : '待选择角色'
  }

  private getStatusColor(): string {
    return this.isLiveConnection() ? Colors.success : Colors.warning
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(122)
        .height(122)
        .borderRadius(61)
        .backgroundColor('rgba(99, 102, 241, 0.08)')
        .blur(36)
        .position({ x: -28, y: -18 })

      Row({ space: Spacing.sm }) {
        Column()
          .width(4)
          .height(64)
          .borderRadius(2)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [['#6366F1', 0], ['#A78BFA', 1]]
          })
          .scale({
            x: 1,
            y: this.lineOpacity > 0 ? 1 : 0
          })
          .opacity(this.lineOpacity)
          .animation({
            duration: AnimationDuration.normal,
            curve: AnimationCurve.emphasized
          })

        Column({ space: Spacing.sm }) {
          Row({ space: Spacing.sm }) {
            Text('灵感岛屿')
              .fontSize(Typography.size.display)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .opacity(this.contentOpacity)
              .translate({
                x: this.contentOpacity > 0 ? 0 : -20,
                y: 0
              })
              .animation({
                duration: AnimationDuration.slow,
                curve: AnimationCurve.emphasized
              })

            Column()
              .width(10)
              .height(10)
              .borderRadius(5)
              .backgroundColor('#F59E0B')
              .margin({ top: 12 })
              .opacity(this.contentOpacity)
              .animation({
                duration: AnimationDuration.slow,
                curve: AnimationCurve.emphasized
              })
          }
          .width('100%')

          Text('收集与创造多元思想切片')
            .fontSize(Typography.size.bodyLg)
            .fontColor(Colors.textTertiary)
            .letterSpacing(0.5)
            .width('100%')
            .opacity(this.contentOpacity)
            .translate({
              x: this.contentOpacity > 0 ? 0 : -16,
              y: 0
            })
            .animation({
              duration: AnimationDuration.slow,
              delay: AnimationDuration.fast,
              curve: AnimationCurve.emphasized
            })

          Row({ space: Spacing.sm }) {
            this.buildInfoChip(this.getRoleLabel(), Colors.primary, 'rgba(99, 102, 241, 0.08)')
            this.buildInfoChip(this.connectionLabel, this.getStatusColor(), this.isLiveConnection() ? 'rgba(16, 185, 129, 0.10)' : 'rgba(245, 158, 11, 0.12)')
          }
          .width('100%')
          .opacity(this.chipOpacity)
          .translate({ x: 0, y: this.badgeTranslateY })
          .animation({
            duration: AnimationDuration.normal,
            curve: AnimationCurve.emphasized
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .padding({
      left: Spacing.xs,
      right: Spacing.xs,
      top: Spacing.lg,
      bottom: Spacing.md
    })
  }

  @Builder
  buildInfoChip(label: string, dotColor: string, backgroundColor: string) {
    Row({ space: 6 }) {
      Column()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(dotColor)

      Text(label)
        .fontSize(Typography.size.xs)
        .fontColor(Colors.textSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .padding({
      left: Spacing.sm,
      right: Spacing.sm,
      top: 6,
      bottom: 6
    })
    .backgroundColor(backgroundColor)
    .borderRadius(BorderRadius.pill)
    .border({
      width: 1,
      color: 'rgba(255, 255, 255, 0.55)',
      radius: BorderRadius.pill
    })
  }
}
