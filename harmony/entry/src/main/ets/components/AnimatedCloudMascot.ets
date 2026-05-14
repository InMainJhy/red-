import { Colors } from '../common/styles/Colors'
export type CloudMascotMood = 'happy' | 'shy' | 'angry' | 'sleep'

@Component
export struct AnimatedCloudMascot {
  @Prop mascotSize: number = 120
  @Prop mood: CloudMascotMood = 'happy'
  @Prop enableFloat: boolean = true
  @Prop enableBlink: boolean = true
  @Prop backgroundGlow: boolean = true
  @Prop motionLevel: 'full' | 'gentle' | 'still' = 'full'

  @State private floatShift: number = 0
  @State private tilt: number = 0
  @State private breatheScale: number = 0.985
  @State private blinkScaleY: number = 1
  @State private glowOpacity: number = 0.18
  @State private sparkleOffset: number = 0
  @State private sparkleOpacity: number = 0.14
  @State private sproutTilt: number = -7
  @State private hasStartedAnimation: boolean = false
  @State private hasStartedBlink: boolean = false

  aboutToAppear(): void {
    this.startMotion()
    this.startBlink()
  }

  private startMotion(): void {
    if (this.hasStartedAnimation || this.motionLevel === 'still') {
      return
    }
    this.hasStartedAnimation = true

    this.floatShift = this.motionLevel === 'full' ? -this.px(0.06) : -this.px(0.025)
    this.tilt = this.motionLevel === 'full' ? 2.2 : 0.8
    this.breatheScale = this.motionLevel === 'full' ? 1.045 : 1.018
    this.glowOpacity = this.motionLevel === 'full' ? 0.30 : 0.22
    this.sparkleOffset = this.motionLevel === 'full' ? -this.px(0.05) : -this.px(0.02)
    this.sparkleOpacity = this.motionLevel === 'full' ? 0.42 : 0.20
    this.sproutTilt = this.motionLevel === 'full' ? 7 : 4
  }

  private startBlink(): void {
    if (!this.enableBlink || this.hasStartedBlink || this.mood === 'sleep' || this.mood === 'angry') {
      return
    }
    this.hasStartedBlink = true

    setTimeout(() => {
      animateTo({
        duration: 160,
        curve: Curve.EaseInOut,
        iterations: -1,
        tempo: 0.25,
        playMode: PlayMode.Normal
      }, () => {
        this.blinkScaleY = 0.08
      })
    }, this.motionLevel === 'full' ? 900 : 1400)
  }

  private imageForMood(): ResourceStr {
    // 当前仓库缺少正式云朵表情资源，先统一降级到现有项目资源，避免影响应用主图标。
    return $r('app.media.ai_avatar_persona')
  }

  private px(scale: number): number {
    return this.mascotSize * scale
  }

  private sparkleColor(): string {
    if (this.mood === 'angry') {
      return 'rgba(255, 201, 201, 0.94)'
    }
    if (this.mood === 'sleep') {
      return 'rgba(189, 221, 255, 0.92)'
    }
    return 'rgba(205, 235, 198, 0.94)'
  }

  private sproutTopOffset(): number {
    if (this.mood === 'happy') {
      return this.px(0.045)
    }
    if (this.mood === 'shy') {
      return this.px(0.050)
    }
    if (this.mood === 'angry') {
      return this.px(0.040)
    }
    return this.px(0.050)
  }

  private sproutSize(): number {
    if (this.mood === 'happy') {
      return this.px(0.27)
    }
    if (this.mood === 'sleep') {
      return this.px(0.23)
    }
    return this.px(0.26)
  }

  @Builder
  private buildGlow() {
    if (this.backgroundGlow) {
      Column()
        .width(this.px(0.86))
        .height(this.px(0.86))
        .borderRadius(this.px(0.43))
        .backgroundColor('rgba(198, 228, 255, 0.94)')
        .blur(this.px(this.motionLevel === 'full' ? 0.16 : 0.10))
        .opacity(this.glowOpacity)
        .scale({ x: this.breatheScale, y: this.breatheScale })
        .animation({
          duration: this.motionLevel === 'full' ? 2100 : 2800,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
    }
  }

  @Builder
  private buildSparkles() {
    if (this.motionLevel !== 'still' && this.mood !== 'sleep') {
      Column()
        .width(this.px(0.09))
        .height(this.px(0.09))
        .borderRadius(this.px(0.045))
        .backgroundColor(this.sparkleColor())
        .opacity(this.sparkleOpacity)
        .blur(1.4)
        .translate({ x: -this.px(0.32), y: -this.px(0.24) + this.sparkleOffset })
        .animation({
          duration: this.motionLevel === 'full' ? 1800 : 2600,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })

      Column()
        .width(this.px(0.06))
        .height(this.px(0.06))
        .borderRadius(this.px(0.03))
        .backgroundColor('rgba(255, 255, 255, 0.96)')
        .opacity(this.sparkleOpacity * 0.82)
        .blur(1)
        .translate({ x: this.px(0.30), y: -this.px(0.29) - this.sparkleOffset * 0.4 })
        .animation({
          duration: this.motionLevel === 'full' ? 2200 : 3000,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
    }
  }

  @Builder
  private buildBlinkMask() {
    if (this.enableBlink && this.mood !== 'sleep' && this.mood !== 'angry') {
      Column()
        .width(this.px(0.32))
        .height(this.px(0.05))
        .borderRadius(this.px(0.025))
        .backgroundColor(Colors.backgroundElevated)
        .scale({ x: 1, y: this.blinkScaleY })
        .opacity(this.blinkScaleY < 0.94 ? 0.94 : 0)
        .translate({ x: 0, y: -this.px(0.055) })
    }
  }

  @Builder
  private buildSproutSwing() {
    if (this.motionLevel !== 'still') {
      Image(this.imageForMood())
        .width(this.sproutSize())
        .height(this.sproutSize())
        .objectFit(ImageFit.Cover)
        .clip(true)
        .borderRadius(this.px(0.12))
        .position({ x: this.px(0.365), y: this.sproutTopOffset() })
        .rotate({
          angle: this.sproutTilt,
          centerX: this.px(0.135),
          centerY: this.px(0.205)
        })
        .animation({
          duration: this.motionLevel === 'full' ? 1300 : 1800,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.buildGlow()
      this.buildSparkles()

      Image(this.imageForMood())
        .width(this.mascotSize)
        .height(this.mascotSize)
        .objectFit(ImageFit.Contain)
        .draggable(false)

      this.buildSproutSwing()
      this.buildBlinkMask()
    }
    .width(this.mascotSize)
    .height(this.mascotSize)
    .translate({
      x: this.motionLevel === 'full' ? this.px(0.012) : 0,
      y: this.enableFloat && this.motionLevel !== 'still' ? this.floatShift : 0
    })
    .rotate({ angle: this.enableFloat ? this.tilt : 0 })
    .scale({
      x: this.motionLevel === 'still' ? 1 : this.breatheScale,
      y: this.motionLevel === 'still' ? 1 : this.breatheScale
    })
    .animation({
      duration: this.motionLevel === 'full' ? 2400 : 3000,
      curve: Curve.EaseInOut,
      iterations: this.motionLevel === 'still' ? 1 : -1,
      playMode: PlayMode.Alternate
    })
  }
}
