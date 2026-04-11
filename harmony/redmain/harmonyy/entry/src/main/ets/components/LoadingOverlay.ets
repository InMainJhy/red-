import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'

// LoadingOverlay 组件属性
export interface LoadingOverlayProps {
  message: string
}

// LoadingOverlay 组件 - 清新风格加载状态遮罩
@Component
export struct LoadingOverlay {
  @Prop message: string = ''

  build() {
    if (this.message.length > 0) {
      Column({ space: Spacing.md }) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color(Colors.primary)

        Text(this.message)
          .fontSize(Typography.size.bodyLg)
          .fontColor(Colors.accent)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(Spacing.huge)
      .backgroundColor(Colors.cardSecondary)
      .backdropBlur(30)
      .borderRadius(BorderRadius.huge)
      .shadow({
        radius: 20,
        color: 'rgba(99, 102, 241, 0.08)',
        offsetX: 0,
        offsetY: 4
      })
      .transition(TransitionEffect.OPACITY.animation({
        duration: 200,
        curve: Curve.EaseOut
      }))
    }
  }
}
