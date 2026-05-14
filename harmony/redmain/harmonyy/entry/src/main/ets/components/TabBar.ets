import { Icon, IconType } from './CustomIcon'

export interface TabBarProps {
  activeIndex: number
  safeBottomVp?: number
}

@Component
export struct TabBar {
  @Prop activeIndex: number = 0
  @Prop safeBottomVp: number = 0
  @State private pressedIndex: number = -1
  @State private barOpacity: number = 0
  @State private barTranslateY: number = 16
  onTabChange: (index: number) => void = () => {}

  private tabLabels: string[] = ['角色', '会议', '纪要']
  private readonly tabActiveFg: string = '#6366F1'
  private readonly tabActiveBg: string = '#EEF2FF'
  private readonly tabInactiveFg: string = '#94A3B8'

  aboutToAppear(): void {
    setTimeout(() => {
      animateTo({
        duration: 260,
        curve: Curve.EaseOut
      }, () => {
        this.barOpacity = 1
        this.barTranslateY = 0
      })
    }, 80)
  }

  private getTabFg(index: number): string {
    return this.activeIndex === index ? this.tabActiveFg : this.tabInactiveFg
  }

  private getTabIconType(index: number): IconType {
    if (index === 0) {
      return 'person'
    }
    if (index === 1) {
      return 'chat'
    }
    return 'bookOpen'
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Row({ space: 0 }) {
          ForEach(this.tabLabels, (label: string, index: number) => {
            this.buildTabItem(label, index)
          }, (label: string) => label)
        }
        .width('100%')
        .height(56)
        .padding({
          left: 8,
          right: 8,
          top: 6,
          bottom: 6
        })
        .justifyContent(FlexAlign.SpaceEvenly)
        .backgroundColor('rgba(255, 255, 255, 0.94)')
        .borderRadius(28)
        .border({
          width: 1,
          color: 'rgba(255, 255, 255, 0.88)',
          radius: 28
        })
        .backdropBlur(24)
        .shadow({
          radius: 24,
          color: 'rgba(15, 23, 42, 0.10)',
          offsetX: 0,
          offsetY: 8
        })
      }
      .width('100%')

      Column()
        .width('82%')
        .height(1)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [
            ['rgba(99, 102, 241, 0)', 0],
            ['rgba(99, 102, 241, 0.22)', 0.5],
            ['rgba(99, 102, 241, 0)', 1]
          ]
        })
        .position({ y: 1 })
    }
    .width('100%')
    .padding({
      left: 24,
      right: 24,
      bottom: 10 + this.safeBottomVp
    })
    .opacity(this.barOpacity)
    .translate({ x: 0, y: this.barTranslateY })
    .animation({
      duration: 260,
      curve: Curve.EaseOut
    })
  }

  @Builder
  buildTabItem(label: string, index: number) {
    Column({ space: 2 }) {
      this.buildIcon(index)

      Text(label)
        .fontSize(10)
        .fontWeight(this.activeIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.getTabFg(index))

      Column()
        .width(this.activeIndex === index ? 12 : 4)
        .height(3)
        .borderRadius(2)
        .backgroundColor(this.activeIndex === index ? this.tabActiveFg : 'rgba(0, 0, 0, 0)')
        .opacity(this.activeIndex === index ? 1 : 0)
        .animation({
          duration: 180,
          curve: Curve.EaseOut
        })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({
      left: 8,
      right: 8,
      top: 6,
      bottom: 6
    })
    .borderRadius(16)
    .backgroundColor(this.activeIndex === index ? this.tabActiveBg : 'rgba(0, 0, 0, 0)')
    .shadow({
      radius: this.activeIndex === index ? 10 : 0,
      color: this.activeIndex === index ? 'rgba(99, 102, 241, 0.10)' : 'rgba(0, 0, 0, 0)',
      offsetX: 0,
      offsetY: 4
    })
    .scale({
      x: this.pressedIndex === index ? 0.95 : 1,
      y: this.pressedIndex === index ? 0.95 : 1
    })
    .translate({
      x: 0,
      y: this.activeIndex === index ? -1 : 0
    })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedIndex = index
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedIndex = -1
      }
    })
    .onClick(() => {
      if (this.activeIndex !== index) {
        animateTo({
          duration: 150,
          curve: Curve.FastOutLinearIn
        }, () => {
          this.onTabChange(index)
        })
      }
    })
  }

  @Builder
  buildIcon(index: number) {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.activeIndex === index ? 24 : 18)
        .height(this.activeIndex === index ? 24 : 18)
        .borderRadius(12)
        .backgroundColor(this.activeIndex === index ? 'rgba(255, 255, 255, 0.72)' : 'rgba(0, 0, 0, 0)')
        .animation({
          duration: 180,
          curve: Curve.EaseOut
        })

      Column({ space: 1 }) {
        Icon({
          iconType: this.getTabIconType(index),
          iconSize: this.activeIndex === index ? 16 : 15,
          iconColor: this.getTabFg(index)
        })
      }
      .width(18)
      .height(18)
      .alignItems(HorizontalAlign.Center)
      .scale({
        x: this.activeIndex === index ? 1.08 : 1,
        y: this.activeIndex === index ? 1.08 : 1
      })
      .animation({
        duration: 200,
        curve: Curve.EaseOut
      })
    }
  }

  @Builder
  buildIconContent(index: number) {
    if (index === 0) {
      this.buildPersonIcon()
    } else if (index === 1) {
      this.buildWaveIcon()
    } else {
      this.buildBookIcon()
    }
  }

  @Builder
  buildPersonIcon() {
    Column({ space: 1 }) {
      Column()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor(this.getTabFg(0))
      Column()
        .width(10)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.getTabFg(0))
    }
  }

  @Builder
  buildWaveIcon() {
    Column({ space: 2 }) {
      this.waveLine(this.getTabFg(1), 0)
      this.waveLine(this.getTabFg(1), 1)
      this.waveLine(this.getTabFg(1), 2)
    }
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  waveLine(color: string, rowIndex: number) {
    Row({ space: 1 }) {
      ForEach([0, 1, 2, 3, 4], (i: number) => {
        Column()
          .width(2.2)
          .height(1.8)
          .borderRadius(0.9)
          .backgroundColor(color)
          .margin({ bottom: ((i + rowIndex) % 2 === 0) ? 1 : 0 })
      }, (i: number) => `wave-${rowIndex}-${i}`)
    }
  }

  @Builder
  buildBookIcon() {
    Column({ space: 0 }) {
      Column()
        .width(12)
        .height(10)
        .borderRadius(2)
        .backgroundColor(this.getTabFg(2))
      Column()
        .width(2)
        .height(10)
        .backgroundColor(this.activeIndex === 2 ? this.tabActiveFg : this.tabInactiveFg)
        .position({ x: 1 })
    }
  }
}
