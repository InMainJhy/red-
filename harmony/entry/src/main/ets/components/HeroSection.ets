import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { MobileSpacing } from '../common/styles/Spacing'
import { AnimationDuration, AnimationCurve, BreathAnimation, PulseAnimation } from '../common/styles/Animation'

export interface HeroSectionProps {
  selectedProfileName: string
  connectionLabel: string
}

@Component
export struct HeroSection {
  @Prop public selectedProfileName: string = ''
  @Prop public connectionLabel: string = '连接中'
  @State private headerOpacity: number = 0
  @State private headerY: number = -14
  @State private avatarScale: number = 0.5
  @State private chipOpacity: number = 0
  @State private chipY: number = 10
  @State private avatarPulseScale: number = 1
  @State private avatarGlowOpacity: number = 0.18
  @State private statusDotScale: number = 1
  @State private statusDotOpacity: number = 1

  aboutToAppear(): void {
    setTimeout(() => {
      animateTo({ duration: AnimationDuration.slow, curve: AnimationCurve.emphasized }, () => {
        this.headerOpacity = 1
        this.headerY = 0
      })
    }, 40)
    setTimeout(() => {
      animateTo({ duration: AnimationDuration.slower, curve: Curve.FastOutSlowIn }, () => {
        this.avatarScale = 1
      })
    }, 80)
    setTimeout(() => {
      animateTo({ duration: AnimationDuration.normal, curve: AnimationCurve.emphasized }, () => {
        this.chipOpacity = 1
        this.chipY = 0
      })
    }, 240)

    // 启动头像呼吸效果
    this.startAvatarBreathing()
    // 启动状态点脉冲效果
    this.startStatusDotPulse()
  }

  private startAvatarBreathing(): void {
    animateTo({
      duration: BreathAnimation.duration,
      curve: BreathAnimation.curve,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.avatarPulseScale = 1.03
      this.avatarGlowOpacity = 0.28
    })
  }

  private startStatusDotPulse(): void {
    animateTo({
      duration: PulseAnimation.duration,
      curve: PulseAnimation.curve,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.statusDotScale = 1.4
      this.statusDotOpacity = 0.6
    })
  }

  private isLive(): boolean {
    const s = this.connectionLabel.toUpperCase()
    return s.includes('LIVE') || s.includes('成功') || s.includes('ONLINE')
  }

  private getInitial(): string {
    return this.selectedProfileName.length > 0 ? this.selectedProfileName.charAt(0) : '✦'
  }

  private getGreeting(): string {
    const h = new Date().getHours()
    if (h < 6)  return '深夜好'
    if (h < 12) return '早安 ☀️'
    if (h < 18) return '午后好'
    return '晚上好 🌙'
  }

  build() {
    Column({ space: 0 }) {
      // 主 Header：左文字 + 右渐变头像
      Row({ space: 0 }) {
        Column({ space: 5 }) {
          Text(`${this.getGreeting()}，思维旅行者`)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('rgba(107,123,150,0.72)')
            .letterSpacing(0.8)

          Text('时序人格')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .fontFamily('HarmonyOS Sans SC')
            .letterSpacing(0.4)

          Text('把一个人物拆成多个可对话阶段')
            .fontSize(12)
            .fontColor(Colors.textSecondary)
            .lineHeight(17)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 渐变头像圆 — 显示当前人格首字
        Stack({ alignContent: Alignment.Center }) {
          // 外光晕
          Column()
            .width(72)
            .height(72)
            .borderRadius(36)
            .linearGradient({
              angle: 135,
              colors: [['rgba(99,149,255,0.25)', 0], ['rgba(196,181,253,0.18)', 1]]
            })
            .blur(14)
            .opacity(this.avatarGlowOpacity)
            .scale({ x: this.avatarPulseScale, y: this.avatarPulseScale })

          // 主体
          Column() {
            Text(this.getInitial())
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textInverse)
          }
          .width(54)
          .height(54)
          .borderRadius(27)
          .linearGradient({
            angle: 135,
            colors: [['#6395FF', 0], ['#A78BFA', 0.55], ['#F472B6', 1]]
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .shadow({
            radius: 18,
            color: 'rgba(99,149,255,0.28)',
            offsetX: 0,
            offsetY: 6
          })
        }
        .width(64)
        .height(64)
        .scale({ x: this.avatarScale, y: this.avatarScale })
        .animation({ duration: AnimationDuration.slower, curve: Curve.FastOutSlowIn })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .opacity(this.headerOpacity)
      .translate({ x: 0, y: this.headerY })
      .animation({ duration: AnimationDuration.slow, curve: AnimationCurve.emphasized })

      // 状态芯片
      Row({ space: 8 }) {
        // 当前人格
        Row({ space: 6 }) {
          Column()
            .width(7).height(7).borderRadius(4)
            .backgroundColor('#6395FF')
            .shadow({ radius: 5, color: 'rgba(99,149,255,0.40)', offsetX: 0, offsetY: 0 })
          Text(this.selectedProfileName.length > 0 ? this.selectedProfileName : '待选择角色')
            .fontSize(11)
            .fontColor('#6395FF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor('rgba(99,149,255,0.09)')
        .borderRadius(BorderRadius.pill)
        .border({ width: 1, color: 'rgba(99,149,255,0.18)', radius: BorderRadius.pill })

        // 连接状态
        Row({ space: 6 }) {
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(12).height(12).borderRadius(6)
              .backgroundColor(this.isLive() ? Colors.success : Colors.warning)
              .opacity(this.statusDotOpacity)
              .scale({ x: this.statusDotScale, y: this.statusDotScale })
            Column()
              .width(7).height(7).borderRadius(4)
              .backgroundColor(this.isLive() ? Colors.success : Colors.warning)
          }
          Text(this.connectionLabel)
            .fontSize(11)
            .fontColor(this.isLive() ? Colors.success : Colors.warning)
        }
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.isLive() ? 'rgba(16,185,129,0.09)' : 'rgba(245,158,11,0.09)')
        .borderRadius(BorderRadius.pill)
        .border({
          width: 1,
          color: this.isLive() ? 'rgba(16,185,129,0.20)' : 'rgba(245,158,11,0.20)',
          radius: BorderRadius.pill
        })
      }
      .width('100%')
      .margin({ top: 14 })
      .opacity(this.chipOpacity)
      .translate({ x: 0, y: this.chipY })
      .animation({ duration: AnimationDuration.normal, curve: AnimationCurve.emphasized })
    }
    .padding({
      left: 0,
      right: 0,
      top: MobileSpacing.sm,
      bottom: MobileSpacing.sm
    })
  }
}
