import { Colors } from '../common/styles/Colors'

@Entry
@Component
struct SplashPage {
  @State private hasNavigated: boolean = false
  private readonly videoController: VideoController = new VideoController()
  private fallbackTimer: number = -1

  aboutToAppear(): void {
    this.fallbackTimer = setTimeout(() => {
      void this.goToHome()
    }, 9000)
  }

  aboutToDisappear(): void {
    if (this.fallbackTimer >= 0) {
      clearTimeout(this.fallbackTimer)
      this.fallbackTimer = -1
    }

    try {
      this.videoController.stop()
    } catch (_error) {
    }
  }

  private async goToHome(): Promise<void> {
    if (this.hasNavigated) {
      return
    }

    this.hasNavigated = true

    try {
      await this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' })
    } catch (_error) {
      this.hasNavigated = false
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Video({
        src: $rawfile('app_splash_intro.mp4'),
        controller: this.videoController
      })
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .controls(false)
        .autoPlay(true)
        .loop(false)
        .muted(false)
        .onAppear(() => {
          try {
            this.videoController.start()
          } catch (_error) {
          }
        })
        .onFinish(() => {
          void this.goToHome()
        })

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(255, 255, 255, 0)', 0],
            ['rgba(241, 247, 255, 0.10)', 0.62],
            ['rgba(241, 247, 255, 0.22)', 1]
          ]
        })

      Text('点击跳过')
        .fontSize(13)
        .fontColor('rgba(255, 255, 255, 0.92)')
        .padding({ left: 18, right: 18, top: 10, bottom: 10 })
        .backgroundColor('rgba(75, 112, 167, 0.20)')
        .borderRadius(18)
        .backdropBlur(12)
        .margin({ bottom: 52 })
        .onClick(() => {
          void this.goToHome()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.background)
  }
}
