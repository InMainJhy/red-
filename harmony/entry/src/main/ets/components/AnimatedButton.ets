import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { AnimationDuration, AnimationCurve } from '../common/styles/Animation'

// AnimatedButton 组件属性
export interface AnimatedButtonProps {
  label: string
  type?: 'primary' | 'secondary' | 'outline'
  disabled?: boolean
  loading?: boolean
  icon?: Resource
  size?: 'small' | 'normal' | 'large'
}

// AnimatedButton 组件 - 带微交互的按钮
@Component
export struct AnimatedButton {
  @Prop label: string = ''
  @Prop type: string = 'primary'
  @Prop disabled: boolean = false
  @Prop loading: boolean = false
  @Prop icon: Resource | null = null
  @Prop size: string = 'normal'
  @State private isPressed: boolean = false
  @State private isHovered: boolean = false
  @State private rippleScale: number = 0
  @State private rippleOpacity: number = 0
  @State private glowOpacity: number = 0
  @State private glowScale: number = 1
  onClick: () => void = () => {}

  private getButtonHeight(): number {
    switch (this.size) {
      case 'small': return 40
      case 'large': return 56
      default: return 48
    }
  }

  private getFontSize(): number {
    switch (this.size) {
      case 'small': return Typography.size.bodyMd
      case 'large': return Typography.size.bodyXl
      default: return Typography.size.bodyLg
    }
  }

  private getBackgroundColor(): string {
    if (this.disabled) {
      return Colors.borderLight
    }
    if (this.isHovered) {
      switch (this.type) {
        case 'primary':
          return Colors.primary + 'ee'
        case 'secondary':
          return Colors.cardPrimary + 'ee'
        case 'outline':
          return Colors.primary + '15'
        default:
          return Colors.primary + 'ee'
      }
    }
    switch (this.type) {
      case 'primary':
        return Colors.primary
      case 'secondary':
        return Colors.cardPrimary
      case 'outline':
        return 'transparent'
      default:
        return Colors.primary
    }
  }

  private getTextColor(): string {
    if (this.disabled) {
      return Colors.textMuted
    }
    switch (this.type) {
      case 'primary':
        return Colors.backgroundElevated
      case 'secondary':
        return Colors.textSecondary
      case 'outline':
        return Colors.primary
      default:
        return Colors.backgroundElevated
    }
  }

  private getBorderColor(): string {
    if (this.type === 'outline') {
      if (this.disabled) return Colors.borderLight
      if (this.isHovered) return Colors.primary
      return Colors.primary
    }
    return 'transparent'
  }

  private getBorderWidth(): number {
    if (this.type === 'outline') {
      return this.isHovered ? 2 : 1.5
    }
    return 0
  }

  private triggerRipple(): void {
    this.rippleScale = 0
    this.rippleOpacity = 0.3

    animateTo({
      duration: 600,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.rippleScale = 2
      this.rippleOpacity = 0
    })
  }

  private triggerGlow(): void {
    this.glowOpacity = 0.4
    this.glowScale = 0.8

    animateTo({
      duration: 400,
      curve: AnimationCurve.emphasized
    }, () => {
      this.glowOpacity = 0
      this.glowScale = 1.3
    })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 光晕效果
      if (this.type === 'primary' && !this.disabled) {
        Column()
          .width('100%')
          .height('100%')
          .borderRadius(BorderRadius.huge)
          .backgroundColor('rgba(91, 164, 255, 0.4)')
          .blur(12)
          .scale({
            x: this.glowScale,
            y: this.glowScale
          })
          .opacity(this.glowOpacity)
          .animation({
            duration: 400,
            curve: AnimationCurve.emphasized
          })
      }

      // 涟漪效果
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(BorderRadius.huge)
        .backgroundColor(this.type === 'primary' ? '#FFFFFF' : Colors.primary)
        .scale({
          x: this.rippleScale,
          y: this.rippleScale
        })
        .opacity(this.rippleOpacity)

      // 按钮主体
      Row({ space: this.size === 'small' ? Spacing.xs : Spacing.sm }) {
        if (this.loading) {
          LoadingProgress()
            .width(this.size === 'small' ? 14 : 18)
            .height(this.size === 'small' ? 14 : 18)
            .color(this.getTextColor())
        } else if (this.icon) {
          Image(this.icon)
            .width(this.size === 'small' ? 16 : 20)
            .height(this.size === 'small' ? 16 : 20)
            .fillColor(this.getTextColor())
            .scale({ x: this.isHovered ? 1.1 : 1, y: this.isHovered ? 1.1 : 1 })
            .animation({
              duration: AnimationDuration.normal,
              curve: AnimationCurve.smooth
            })
        }

        Text(this.label)
          .fontSize(this.getFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextColor())
          .scale({ x: this.isHovered ? 1.02 : 1, y: this.isHovered ? 1.02 : 1 })
          .animation({
            duration: AnimationDuration.normal,
            curve: AnimationCurve.smooth
          })
      }
      .width('100%')
      .height(this.getButtonHeight())
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(BorderRadius.huge)
      .border({
        width: this.getBorderWidth(),
        color: this.getBorderColor(),
        radius: BorderRadius.huge
      })
      .shadow({
        radius: this.type === 'primary'
          ? (this.isPressed ? (this.size === 'small' ? 6 : 8) : (this.isHovered ? (this.size === 'small' ? 16 : 20) : (this.size === 'small' ? 12 : 15)))
          : (this.isPressed ? 6 : (this.isHovered ? 14 : 10)),
        color: this.type === 'primary'
          ? (this.isHovered ? 'rgba(91, 164, 255, 0.35)' : Colors.loadingBg)
          : (this.isHovered ? 'rgba(0, 0, 0, 0.08)' : 'rgba(0, 0, 0, 0.04)'),
        offsetX: 0,
        offsetY: this.isPressed ? (this.size === 'small' ? 1 : 2) : (this.isHovered ? (this.size === 'small' ? 4 : 6) : (this.size === 'small' ? 3 : 4))
      })
      .scale({
        x: this.isPressed ? (this.size === 'small' ? 0.97 : 0.96) : (this.isHovered ? (this.size === 'small' ? 1.015 : 1.02) : 1),
        y: this.isPressed ? (this.size === 'small' ? 0.97 : 0.96) : (this.isHovered ? (this.size === 'small' ? 1.015 : 1.02) : 1)
      })
      .animation({
        duration: this.isPressed ? AnimationDuration.instant : AnimationDuration.fast,
        curve: this.isPressed ? Curve.Sharp : Curve.FastOutSlowIn
      })
      .onTouch((event: TouchEvent) => {
        if (this.disabled || this.loading) {
          return
        }

        if (event.type === TouchType.Down) {
          animateTo({
            duration: AnimationDuration.instant,
            curve: Curve.Sharp
          }, () => {
            this.isPressed = true
          })
          this.isHovered = true
          this.triggerRipple()
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          animateTo({
            duration: AnimationDuration.fast,
            curve: Curve.FastOutSlowIn
          }, () => {
            this.isPressed = false
          })
          if (event.type === TouchType.Up) {
            this.triggerGlow()
          }
          setTimeout(() => {
            this.isHovered = false
          }, 150)
        }
      })
      .onClick(() => {
        if (!this.disabled && !this.loading) {
          this.onClick()
        }
      })
    }
    .width('100%')
    .height(this.getButtonHeight())
  }
}
