import { Colors, LiquidGlass } from '../common/styles/Colors'

@Component
export struct DynamicGlassBackground {
  @State private haloScale: number = 0.96
  @State private haloOpacity: number = 0.22

  aboutToAppear(): void {
    setTimeout(() => {
      animateTo({ duration: 900, curve: Curve.FastOutSlowIn }, () => {
        this.haloScale = 1
        this.haloOpacity = 0.34
      })
    }, 60)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.background)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [Colors.backgroundSecondary, 0],
            [Colors.background, 0.48],
            [Colors.backgroundTertiary, 1]
          ]
        })

      Column()
        .width(520)
        .height(520)
        .borderRadius(260)
        .linearGradient({
          angle: 135,
          colors: [
            [Colors.overlaySoft, 0],
            [LiquidGlass.glow, 0.42],
            ['rgba(255, 255, 255, 0.00)', 1]
          ]
        })
        .blur(132)
        .opacity(this.haloOpacity)
        .scale({ x: this.haloScale, y: this.haloScale })
        .position({ x: -150, y: -120 })

      Column()
        .width(420)
        .height(420)
        .borderRadius(210)
        .linearGradient({
          angle: 45,
          colors: [
            [Colors.overlaySoft, 0],
            ['rgba(255, 255, 255, 0.00)', 1]
          ]
        })
        .blur(118)
        .opacity(0.28)
        .position({ x: '52%', y: 86 })
    }
    .width('100%')
    .height('100%')
  }
}
