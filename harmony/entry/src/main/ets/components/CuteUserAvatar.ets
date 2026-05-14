import { Icon } from './CustomIcon'
import { Colors } from '../common/styles/Colors'

@Component
export struct CuteUserAvatar {
  @Prop avatarSize: number = 56
  @Prop userAvatar: string = ''
  @Prop userName: string = '时序人格'
  @Prop showStatusDot: boolean = false
  @Prop statusColor: ResourceColor = Colors.success

  private px(scale: number): number {
    return this.avatarSize * scale
  }

  private fallbackLetter(): string {
    if (this.userName.length > 0) {
      return this.userName.charAt(0)
    }
    return '时'
  }

  @Builder
  private buildFallbackFace() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(this.px(0.68))
        .height(this.px(0.68))
        .borderRadius(this.px(0.34))
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(255, 250, 245, 1)', 0],
            ['rgba(255, 238, 227, 1)', 1]
          ]
        })

      Column()
        .width(this.px(0.56))
        .height(this.px(0.23))
        .borderRadius(this.px(0.14))
        .backgroundColor('rgba(72, 89, 126, 0.96)')
        .position({ x: this.px(0.12), y: this.px(0.16) })

      Column()
        .width(this.px(0.07))
        .height(this.px(0.07))
        .borderRadius(this.px(0.035))
        .backgroundColor('rgba(66, 76, 103, 0.92)')
        .position({ x: this.px(0.24), y: this.px(0.42) })

      Column()
        .width(this.px(0.07))
        .height(this.px(0.07))
        .borderRadius(this.px(0.035))
        .backgroundColor('rgba(66, 76, 103, 0.92)')
        .position({ x: this.px(0.50), y: this.px(0.42) })

      Column()
        .width(this.px(0.12))
        .height(this.px(0.03))
        .borderRadius(this.px(0.015))
        .backgroundColor('rgba(145, 121, 113, 0.72)')
        .position({ x: this.px(0.38), y: this.px(0.57) })

      Column()
        .width(this.px(0.11))
        .height(this.px(0.07))
        .borderRadius(this.px(0.06))
        .backgroundColor('rgba(255, 196, 205, 0.54)')
        .blur(3)
        .position({ x: this.px(0.18), y: this.px(0.50) })

      Column()
        .width(this.px(0.11))
        .height(this.px(0.07))
        .borderRadius(this.px(0.06))
        .backgroundColor('rgba(255, 196, 205, 0.54)')
        .blur(3)
        .position({ x: this.px(0.54), y: this.px(0.50) })

      Text(this.fallbackLetter())
        .fontSize(this.px(0.18))
        .fontWeight(FontWeight.Bold)
        .fontColor('rgba(80, 96, 132, 0.16)')
        .position({ x: this.px(0.36), y: this.px(0.28) })
    }
    .width(this.px(0.82))
    .height(this.px(0.82))
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(this.px(1.10))
          .height(this.px(1.10))
          .borderRadius(this.px(0.55))
          .backgroundColor('rgba(207, 223, 248, 0.42)')
          .blur(this.px(0.06))
          .opacity(0.72)
          .translate({ x: 0, y: this.px(0.10) })

        Column()
          .width(this.avatarSize)
          .height(this.avatarSize)
          .borderRadius(this.avatarSize / 2)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              ['rgba(255, 255, 255, 0.98)', 0],
              ['rgba(235, 243, 255, 0.98)', 0.52],
              ['rgba(212, 226, 251, 0.98)', 1]
            ]
          })
          .border({
            width: 1,
            color: 'rgba(255, 255, 255, 0.92)',
            radius: this.avatarSize / 2
          })
          .shadow({
            radius: this.px(0.24),
            color: 'rgba(122, 151, 201, 0.22)',
            offsetX: 0,
            offsetY: this.px(0.12)
          })

        Column()
          .width(this.px(0.84))
          .height(this.px(0.84))
          .borderRadius(this.px(0.42))
          .backgroundColor('rgba(255, 255, 255, 0.76)')
          .border({
            width: 0.8,
            color: 'rgba(255, 255, 255, 0.88)',
            radius: this.px(0.42)
          })

        if (this.userAvatar.length > 0) {
          Image(this.userAvatar)
            .width(this.px(0.76))
            .height(this.px(0.76))
            .borderRadius(this.px(0.38))
            .objectFit(ImageFit.Cover)
        } else {
          this.buildFallbackFace()
        }

        Column()
          .width(this.px(0.48))
          .height(this.px(0.16))
          .borderRadius(this.px(0.10))
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              ['rgba(255, 255, 255, 0.92)', 0],
              ['rgba(255, 255, 255, 0.06)', 1]
            ]
          })
          .blur(3)
          .translate({ x: -this.px(0.06), y: -this.px(0.22) })

        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(this.px(0.26))
            .height(this.px(0.26))
            .borderRadius(this.px(0.13))
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                ['rgba(136, 181, 255, 1)', 0],
                ['rgba(79, 126, 217, 1)', 1]
              ]
            })
            .shadow({
              radius: this.px(0.14),
              color: 'rgba(87, 132, 218, 0.24)',
              offsetX: 0,
              offsetY: this.px(0.05)
            })

          Icon({
            iconType: 'sparkles',
            iconSize: this.px(0.12),
            iconColor: '#FFFFFF',
            strokeWidth: 1.6
          })
        }
        .position({ x: this.px(0.06), y: this.px(0.08) })
      }

      if (this.showStatusDot) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(this.px(0.24))
            .height(this.px(0.24))
            .borderRadius(this.px(0.12))
            .backgroundColor(Colors.backgroundElevated)

          Column()
            .width(this.px(0.17))
            .height(this.px(0.17))
            .borderRadius(this.px(0.085))
            .backgroundColor(this.statusColor)
        }
        .position({ x: this.px(0.76), y: this.px(0.76) })
      }
    }
    .width(this.px(1.10))
    .height(this.px(1.10))
  }
}
