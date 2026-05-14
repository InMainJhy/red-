import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Icon } from './CustomIcon'

export interface TabBarProps {
  activeIndex: number
  safeBottomVp?: number
}

@Component
export struct TabBar {
  @Prop public activeIndex: number = 0
  @Prop public safeBottomVp: number = 0
  @State private pressedTabIndex: number = -1
  @State private pressedPrimary: boolean = false
  public onTabChange: (index: number) => void = () => {}
  public onPrimaryAction: () => void = () => {}

  private tabLabel(index: number): string {
    return index === 0 ? '首页' : '纪要'
  }

  private iconType(index: number): 'grid' | 'list' {
    return index === 0 ? 'grid' : 'list'
  }

  private isActive(index: number): boolean {
    return this.activeIndex === index
  }

  private tabColor(index: number): ResourceColor {
    return this.isActive(index) ? '#FFFFFF' : Colors.textPlaceholder
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 底部沉浸式环境光垫层
      Column()
        .width('calc(100% - 16vp)')
        .height(72)
        .borderRadius(36)
        .linearGradient({
          angle: 120,
          colors: [
            [Colors.overlayMedium, 0],
            ['rgba(255, 255, 255, 0.0)', 0.5],
            [Colors.overlaySoft, 1]
          ]
        })
        .blur(8)
        .opacity(0.46)
        .margin({ left: 8, right: 8 })
        .translate({ x: 0, y: -4 })

      Row({ space: 0 }) {
        this.buildTabItem(0)

        this.buildPrimaryAction()

        this.buildTabItem(1)
      }
      .width('calc(100% - 24vp)')
      .height(64)
      .padding({
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + this.safeBottomVp
      })
      .backgroundColor(LiquidGlass.surface) // 改为更透明的液态玻璃感
      .backdropBlur(18)
      .linearGradient({
        angle: 120,
        colors: [
          [Colors.overlayMedium, 0],
          [Colors.overlaySoft, 0.5],
          [Colors.cardSecondary, 1]
        ]
      })
      .border({
        width: 1.5,
        color: LiquidGlass.borderStrong,
        radius: 32
      })
      .borderRadius(32)
      .shadow({
        radius: 12,
        color: Colors.shadowMedium,
        offsetX: 0,
        offsetY: 5
      })
      .alignItems(VerticalAlign.Center)
      .margin({ left: 12, right: 12 })
      .translate({ x: 0, y: -8 })

      Column()
        .width('100%')
        .height(18)
    }
    .width('100%')
    .height(84 + this.safeBottomVp)
  }

  @Builder
  private buildTabItem(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      if (this.isActive(index)) {
        Column()
          .width(72)
          .height(40)
          .borderRadius(20)
          .backgroundColor(Colors.primaryDark)
          .border({
            width: 1,
            color: Colors.overlaySoft,
            radius: 20
          })
          .shadow({
            radius: 12,
            color: Colors.shadowMedium,
            offsetX: 0,
            offsetY: 4
          })
      }

      Column({ space: 2 }) {
        Icon({
          iconType: this.iconType(index),
          iconSize: this.isActive(index) ? 17 : 16,
          iconColor: this.tabColor(index),
          strokeWidth: this.isActive(index) ? 2 : 1.85
        })

        Text(this.tabLabel(index))
          .fontSize(10)
          .fontWeight(this.isActive(index) ? FontWeight.Medium : FontWeight.Medium)
          .maxLines(1)
          .fontColor(this.tabColor(index))
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .height(46)
    .scale({
      x: this.pressedTabIndex === index ? 0.97 : 1,
      y: this.pressedTabIndex === index ? 0.97 : 1
    })
    .opacity(this.pressedTabIndex === index ? 0.92 : 1)
    .translate({ x: 0, y: 14 })
    .animation({
      duration: 220,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedTabIndex = index
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedTabIndex = -1
      }
    })
    .onClick(() => {
      if (!this.isActive(index)) {
        this.onTabChange(index)
      }
    })
  }

  @Builder
  private buildPrimaryAction() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(54)
        .height(54)
        .borderRadius(27)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['#33465F', 0],
            ['#1D2838', 0.46],
            ['#111722', 1]
          ]
        })
        .border({
          width: 1,
          color: Colors.overlaySoft,
          radius: 27
        })
        .shadow({
          radius: 18,
          color: Colors.shadowStrong,
          offsetX: 0,
          offsetY: 8
        })

      Column()
        .width(34)
        .height(12)
        .borderRadius(10)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [Colors.overlaySoft, 0],
            ['rgba(255, 255, 255, 0)', 1]
          ]
        })
        .translate({ x: 0, y: -13 })

      Column()
        .width(44)
        .height(44)
        .borderRadius(22)
        .border({
          width: 1,
          color: Colors.overlaySoft,
          radius: 22
        })
        .shadow({
          radius: 10,
          color: Colors.shadowSoft,
          offsetX: 0,
          offsetY: -1
        })

      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(18)
        .fontColor(['#FFFFFF'])
        .renderingStrategy(SymbolRenderingStrategy.SINGLE)
    }
    .layoutWeight(1)
    .height(46)
    .scale({
      x: this.pressedPrimary ? 0.92 : 1,
      y: this.pressedPrimary ? 0.92 : 1
    })
    .opacity(this.pressedPrimary ? 0.90 : 1)
    .translate({ x: 0, y: this.pressedPrimary ? 15 : 14 })
    .animation({
      duration: 180,
      curve: Curve.Friction
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedPrimary = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedPrimary = false
      }
    })
    .onClick(() => {
      this.onPrimaryAction()
    })
  }
}
