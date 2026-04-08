// TabBar 组件属性
export interface TabBarProps {
  activeIndex: number
  safeBottomVp?: number
}

// TabBar 组件 - 悬浮白色胶囊底栏（图标在上、选中项浅紫圆角底）
@Component
export struct TabBar {
  @Prop activeIndex: number = 0
  @Prop safeBottomVp: number = 0
  onTabChange: (index: number) => void = () => {}

  // Tab 文案（与产品设计稿一致：会议）
  private tabLabels: string[] = ['角色', '会议', '纪要']
  // 选中态：紫罗兰主色与浅紫底（与参考图一致）
  private readonly tabActiveFg: string = '#6366F1'
  private readonly tabActiveBg: string = '#EEF2FF'
  private readonly tabInactiveFg: string = '#94A3B8'

  private getTabFg(index: number): string {
    return this.activeIndex === index ? this.tabActiveFg : this.tabInactiveFg
  }

  build() {
    Column() {
      Row({ space: 0 }) {
        ForEach(this.tabLabels, (label: string, index: number) => {
          this.buildTabItem(label, index)
        }, (label: string) => label)
      }
      .width('100%')
      .height(52)
      .padding({
        left: 8,
        right: 8,
        top: 6,
        bottom: 6
      })
      .justifyContent(FlexAlign.SpaceEvenly)
      .backgroundColor('#FFFFFF')
      .borderRadius(26)
      .shadow({
        radius: 20,
        color: 'rgba(15, 23, 42, 0.08)',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .padding({
      left: 24,
      right: 24,
      bottom: 10 + this.safeBottomVp
    })
  }

  @Builder
  buildTabItem(label: string, index: number) {
    Column({ space: 3 }) {
      this.buildIcon(index)

      Text(label)
        .fontSize(10)
        .fontWeight(this.activeIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.getTabFg(index))
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
    .borderRadius(14)
    .backgroundColor(this.activeIndex === index ? this.tabActiveBg : 'rgba(0, 0, 0, 0)')
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      if (this.activeIndex !== index) {
        this.onTabChange(index)
      }
    })
  }

  @Builder
  buildIcon(index: number) {
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
    .width(18)
    .height(18)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildWaveIcon() {
    // 三条横向波纹线（风/气流意象）
    Column({ space: 2 }) {
      this.waveLine(this.getTabFg(1), 0)
      this.waveLine(this.getTabFg(1), 1)
      this.waveLine(this.getTabFg(1), 2)
    }
    .width(18)
    .height(18)
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
    .width(18)
    .height(18)
    .alignItems(HorizontalAlign.Center)
  }
}
