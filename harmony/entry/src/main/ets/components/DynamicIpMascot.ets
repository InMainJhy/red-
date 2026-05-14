const DYNAMIC_IP_FRAMES: ResourceStr[] = [
  // 当前仓库未包含动态帧资源，先回退到现有项目资源，避免影响应用主图标。
  $r('app.media.ai_avatar_hourglass')
]

@Component
export struct DynamicIpMascot {
  @Prop mascotSize: number = 56
  @Prop enableFloat: boolean = true

  @State private floatShift: number = 0
  @State private tilt: number = 0
  @State private breatheScale: number = 1
  @State private glowOpacity: number = 0.16
  @State private currentFrameIndex: number = 0
  @State private hasStartedMotion: boolean = false

  private frameTimer: number = -1

  aboutToAppear(): void {
    this.startMotion()
    this.startFrameLoop()
  }

  aboutToDisappear(): void {
    this.stopFrameLoop()
  }

  private startMotion(): void {
    if (this.hasStartedMotion || !this.enableFloat) {
      return
    }

    this.hasStartedMotion = true

    setTimeout(() => {
      animateTo({
        duration: 2400,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      }, () => {
        this.floatShift = -this.mascotSize * 0.065
        this.tilt = 1.8
        this.breatheScale = 1.035
        this.glowOpacity = 0.24
      })
    }, 80)
  }

  private startFrameLoop(): void {
    if (DYNAMIC_IP_FRAMES.length <= 1) {
      return
    }

    if (this.frameTimer !== -1) {
      return
    }

    this.frameTimer = setInterval(() => {
      this.currentFrameIndex = (this.currentFrameIndex + 1) % DYNAMIC_IP_FRAMES.length
    }, 125)
  }

  private stopFrameLoop(): void {
    if (this.frameTimer !== -1) {
      clearInterval(this.frameTimer)
      this.frameTimer = -1
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.mascotSize * 0.54)
        .height(this.mascotSize * 0.54)
        .borderRadius(this.mascotSize * 0.27)
        .backgroundColor('rgba(193, 224, 255, 0.16)')
        .blur(this.mascotSize * 0.05)
        .opacity(this.glowOpacity)
        .scale({ x: this.breatheScale, y: this.breatheScale })

      Image(DYNAMIC_IP_FRAMES[this.currentFrameIndex])
        .width(this.mascotSize)
        .height(this.mascotSize)
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .renderMode(ImageRenderMode.Original)
        .opacity(0.98)
    }
    .width(this.mascotSize)
    .height(this.mascotSize)
    .scale({
      x: this.enableFloat ? this.breatheScale : 1,
      y: this.enableFloat ? this.breatheScale : 1
    })
    .translate({ x: 0, y: this.enableFloat ? this.floatShift : 0 })
    .rotate({ angle: this.enableFloat ? this.tilt : 0 })
  }
}
