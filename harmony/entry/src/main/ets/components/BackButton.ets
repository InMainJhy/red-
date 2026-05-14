import { Colors, LiquidGlass } from '../common/styles/Colors'
import { BorderRadius } from '../common/styles/BorderRadius'

/**
 * 华为风格返回按钮组件
 * 遵循 HarmonyOS 设计语言，采用圆形毛玻璃背景 + 渐变箭头
 */
@Component
export struct BackButton {
  @Prop iconSize: number = 20
  @Prop iconColor: ResourceColor = Colors.primary
  @Prop bgColor: ResourceColor = LiquidGlass.surface
  @Prop customBorderColor: ResourceColor = LiquidGlass.border
  @Prop buttonSize: number = 40
  @Prop showShadow: boolean = true
  @State private isPressed: boolean = false
  customOnClick: () => void = () => {}

  build() {
    Button() {
      Text('返回')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.iconColor)
    }
    .width(60) // 调整宽度以适应文字
    .height(this.buttonSize)
    .type(ButtonType.Capsule) // 改为胶囊形状以适应文字
    .backgroundColor(this.bgColor)
    .backdropBlur(30)
    .linearGradient({
      angle: 135,
      colors: [
        [Colors.overlayMedium, 0],
        [Colors.overlaySoft, 1]
      ]
    })
    .border({
      width: 1.5,
      color: this.customBorderColor,
      radius: this.buttonSize / 2
    })
    .shadow(this.showShadow ? {
      radius: this.isPressed ? 8 : 14,
      color: Colors.shadowMedium,
      offsetX: 0,
      offsetY: this.isPressed ? 3 : 5
    } : null)
    .scale({
      x: this.isPressed ? 0.9 : 1,
      y: this.isPressed ? 0.9 : 1
    })
    .rotate({
      x: 0,
      y: 1,
      z: 0,
      angle: this.isPressed ? -15 : 0,
      centerX: '50%',
      centerY: '50%'
    })
    .animation({
      duration: 260,
      curve: Curve.Friction
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
    .onClick(() => {
      this.customOnClick()
    })
  }
}

/**
 * 华为风格取消按钮组件 (关闭当前模态框/页面)
 */
@Component
export struct CloseButton {
  @Prop iconSize: number = 20
  @Prop iconColor: ResourceColor = Colors.primary
  @Prop bgColor: ResourceColor = Colors.cardPrimary
  @Prop customBorderColor: ResourceColor = Colors.border
  @Prop buttonSize: number = 40
  @Prop showShadow: boolean = true
  customOnClick: () => void = () => {}

  build() {
    Button() {
      Text('关闭')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.iconColor)
    }
    .width(60) // 调整宽度以适应文字
    .height(this.buttonSize)
    .type(ButtonType.Capsule) // 改为胶囊形状以适应文字
    .backgroundColor(this.bgColor)
    .border({
      width: this.showShadow ? 0.5 : 0,
      color: this.customBorderColor,
      radius: this.buttonSize / 2
    })
    .shadow(this.showShadow ? {
      radius: 8,
      color: Colors.shadowSoft,
      offsetX: 0,
      offsetY: 2
    } : null)
    .onClick(() => this.customOnClick())
  }
}

/**
 * 简洁风格的返回按钮（仅使用箭头符号）
 */
@Component
export struct BackButtonSimple {
  @Prop iconSize: number = 24
  @Prop iconColor: ResourceColor = Colors.primary
  @Prop bgColor: ResourceColor = LiquidGlass.surface
  @Prop customBorderColor: ResourceColor = LiquidGlass.border
  @Prop buttonSize: number = 40
  @Prop showShadow: boolean = true
  @State private isPressed: boolean = false
  customOnClick: () => void = () => {}

  build() {
    Button() {
      Text('返回')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.iconColor)
    }
    .width(60) // 调整宽度以适应文字
    .height(this.buttonSize)
    .type(ButtonType.Capsule) // 改为胶囊形状以适应文字
    .backgroundColor(this.bgColor)
    .backdropBlur(30)
    .linearGradient({
      angle: 135,
      colors: [
        [Colors.overlayMedium, 0],
        [Colors.overlaySoft, 1]
      ]
    })
    .border({
      width: 1.5,
      color: this.customBorderColor,
      radius: this.buttonSize / 2
    })
    .shadow(this.showShadow ? {
      radius: this.isPressed ? 8 : 14,
      color: Colors.shadowMedium,
      offsetX: 0,
      offsetY: this.isPressed ? 3 : 5
    } : null)
    .scale({
      x: this.isPressed ? 0.9 : 1,
      y: this.isPressed ? 0.9 : 1
    })
    .rotate({
      x: 0,
      y: 1,
      z: 0,
      angle: this.isPressed ? -15 : 0,
      centerX: '50%',
      centerY: '50%'
    })
    .animation({
      duration: 260,
      curve: Curve.Friction
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false
      }
    })
    .onClick(() => this.customOnClick())
  }
}

/**
 * 渐变风格的返回按钮（华为高端机型风格）
 */
@Component
export struct BackButtonGradient {
  @Prop iconSize: number = 18
  @Prop buttonSize: number = 36
  @Prop startColor: ResourceColor = Colors.primary
  @Prop endColor: ResourceColor = Colors.accentPurple
  customOnClick: () => void = () => {}

  build() {
    Button() {
      Stack({ alignContent: Alignment.Center }) {
        // 左箭头 - 使用渐变色
        Text('←')
          .fontSize(this.iconSize)
          .fontColor(this.endColor)
          .fontWeight(FontWeight.Bold)
      }
      .width(this.buttonSize - 8)
      .height(this.buttonSize - 8)
    }
    .width(this.buttonSize)
    .height(this.buttonSize)
    .backgroundColor(Colors.overlayMedium)
    .borderRadius(this.buttonSize / 2)
    .shadow({
      radius: 6,
      color: Colors.shadowMedium,
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => this.customOnClick())
  }
}

/**
 * 毛玻璃风格的返回按钮（iOS/HarmonyOS 通用）
 */
@Component
export struct BackButtonGlass {
  @Prop iconSize: number = 20
  @Prop buttonSize: number = 44
  @Prop iconColor: ResourceColor = Colors.textPrimary
  customOnClick: () => void = () => {}

  build() {
    Button() {
      Text('‹')
        .fontSize(this.iconSize + 4)
        .fontColor(this.iconColor)
        .fontWeight(FontWeight.Normal)
    }
    .width(this.buttonSize)
    .height(this.buttonSize)
    .backgroundColor(Colors.overlaySoft)
    .borderRadius(this.buttonSize / 2)
    .backdropBlur(12)
    .onClick(() => this.customOnClick())
  }
}

/**
 * 文字风格的返回按钮（简洁文字版）
 */
@Component
export struct BackButtonText {
  @Prop fontSize: number = 15
  @Prop fontColor: ResourceColor = Colors.primary
  @Prop bgColor: ResourceColor = Colors.cardPrimary
  @Prop btnBorderColor: ResourceColor = Colors.border
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
      color: Colors.shadowSoft,
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => this.customOnClick())
  }
}
