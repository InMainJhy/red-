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
  @Prop public message: string = ''
  @State private overlayOpacity: number = 1
  @State private overlayScale: number = 1

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
      .backgroundColor(Colors.overlayStrong)
      .borderRadius(BorderRadius.huge)
      .border({
        width: 1,
        color: Colors.border,
        radius: BorderRadius.huge
      })
      .shadow({
        radius: 10,
        color: Colors.shadowSoft,
        offsetX: 0,
        offsetY: 2
      })
      .opacity(this.overlayOpacity)
      .scale({
        x: this.overlayScale,
        y: this.overlayScale
      })
    }
  }
}
