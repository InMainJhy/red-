import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { Durations, Curves } from '../common/styles/Effects'

// 角色首页顶部双入口卡片
@Component
export struct RoleHomeActionCards {
  onCreateClick: () => void = () => {}
  onImportClick: () => void = () => {}
  @State private pressedLeft: boolean = false
  @State private pressedRight: boolean = false

  build() {
    Row({ space: Spacing.card.medium }) {
      this.buildCreateCard()
      this.buildImportCard()
    }
    .width('100%')
  }

  @Builder
  buildCreateCard() {
    Column({ space: Spacing.sm }) {
      // 图标区域
      Stack({ alignContent: Alignment.TopStart }) {
        // 装饰圆形
        Column()
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#EEF2FF')
          .border({
            width: 1,
            color: 'rgba(99, 102, 241, 0.15)',
            radius: 22
          })

        // 叠加的图标
        Stack({ alignContent: Alignment.Center }) {
          Column({ space: 2 }) {
            Column()
              .width(16)
              .height(16)
              .borderRadius(4)
              .backgroundColor('rgba(99, 102, 241, 0.6)')
            Column()
              .width(20)
              .height(12)
              .borderRadius(6)
              .backgroundColor('rgba(99, 102, 241, 0.4)')
          }
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text('+')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width(14)
          .height(14)
          .borderRadius(7)
          .backgroundColor('#6366F1')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .position({ x: 20, y: 0 })
        }
        .width(44)
        .height(44)
      }
      .width(44)
      .height(44)

      Text('创造新识')
        .fontSize(Typography.size.subtitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')
        .textAlign(TextAlign.Start)

      Text('定义一个全新的人格')
        .fontSize(Typography.size.caption)
        .fontColor(Colors.textTertiary)
        .width('100%')
        .textAlign(TextAlign.Start)
        .maxLines(2)
        .lineHeight(18)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.card.large)
    .backgroundColor('#EEF2FF')
    .borderRadius(BorderRadius.huge)
    .border({
      width: 1,
      color: 'rgba(99, 102, 241, 0.2)',
      radius: BorderRadius.huge
    })
    .shadow({
      radius: this.pressedLeft ? 12 : 20,
      color: 'rgba(99, 102, 241, 0.15)',
      offsetX: 0,
      offsetY: this.pressedLeft ? 2 : 6
    })
    .scale({
      x: this.pressedLeft ? 0.97 : 1,
      y: this.pressedLeft ? 0.97 : 1
    })
    .animation({
      duration: Durations.fast,
      curve: Curves.emphasized
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedLeft = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedLeft = false
      }
    })
    .onClick(() => {
      this.onCreateClick()
    })
  }

  @Builder
  buildImportCard() {
    Column({ space: Spacing.sm }) {
      // 图标区域
      Stack({ alignContent: Alignment.Center }) {
        // 背景装饰圆形
        Column()
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#ECFDF5')
          .border({
            width: 1,
            color: 'rgba(16, 185, 129, 0.2)',
            radius: 22
          })

        // 导入图标
        Column({ space: 3 }) {
          Column()
            .width(3)
            .height(14)
            .borderRadius(1.5)
            .backgroundColor('#10B981')

          Column()
            .width(12)
            .height(3)
            .borderRadius(1.5)
            .backgroundColor('#10B981')
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width(44)
      .height(44)

      Text('寻访前人')
        .fontSize(Typography.size.subtitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')
        .textAlign(TextAlign.Start)

      Text('导入已有的人物传记')
        .fontSize(Typography.size.caption)
        .fontColor(Colors.textTertiary)
        .width('100%')
        .textAlign(TextAlign.Start)
        .maxLines(2)
        .lineHeight(18)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.card.large)
    .backgroundColor('#ECFDF5')
    .borderRadius(BorderRadius.huge)
    .border({
      width: 1,
      color: 'rgba(16, 185, 129, 0.2)',
      radius: BorderRadius.huge
    })
    .shadow({
      radius: this.pressedRight ? 12 : 20,
      color: 'rgba(16, 185, 129, 0.12)',
      offsetX: 0,
      offsetY: this.pressedRight ? 2 : 6
    })
    .scale({
      x: this.pressedRight ? 0.97 : 1,
      y: this.pressedRight ? 0.97 : 1
    })
    .animation({
      duration: Durations.fast,
      curve: Curves.emphasized
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedRight = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedRight = false
      }
    })
    .onClick(() => {
      this.onImportClick()
    })
  }
}
