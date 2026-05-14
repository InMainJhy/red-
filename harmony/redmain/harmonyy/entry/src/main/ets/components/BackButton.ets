import { Colors } from '../common/styles/Colors'
import { BorderRadius } from '../common/styles/BorderRadius'

/**
 * 文字风格的返回按钮（简洁文字版）
 */
@Component
export struct BackButtonText {
  @Prop fontSize: number = 15
  @Prop fontColor: string = Colors.primary
  @Prop bgColor: string = 'rgba(255, 255, 255, 0.92)'
  @Prop btnBorderColor: string = Colors.border
  @Prop paddingH: number = 14
  @Prop paddingV: number = 8
  customOnClick: () => void = () => {}

  build() {
    Button() {
      Text('返回')
        .fontSize(this.fontSize)
        .fontColor(this.fontColor)
        .fontWeight(FontWeight.Medium)
    }
    .padding({
      left: this.paddingH,
      right: this.paddingH,
      top: this.paddingV,
      bottom: this.paddingV
    })
    .backgroundColor(this.bgColor)
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 0.5,
      color: this.btnBorderColor,
      radius: BorderRadius.xxl
    })
    .shadow({
      radius: 6,
      color: 'rgba(0, 0, 0, 0.06)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => this.customOnClick())
  }
}
