import { common } from '@kit.AbilityKit'
import promptAction from '@ohos.promptAction'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { Colors, LiquidGlass } from '../common/styles/Colors'
import { MobileSpacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import { CuteUserAvatar, DynamicGlassBackground, Icon } from '../components'

interface UserCenterRouteParams {
  userName?: string
  userAvatar?: string
  openId?: string
  unionId?: string
}

@Entry
@Component
struct UserCenter {
  @State private safeTopVp: number = 0
  @State private safeBottomVp: number = 0
  @State private userName: string = '时序人格用户'
  @State private userAvatar: string = ''
  @State private userOpenId: string = ''
  @State private userUnionId: string = ''
  @State private pressedCardTitle: string = ''

  aboutToAppear(): void {
    this.consumeRouteParams()
    this.loadSafeInsets()
  }

  private getHostContext(): common.UIAbilityContext | null {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      return hostContext as common.UIAbilityContext
    }
    return null
  }

  private router() {
    return this.getUIContext().getRouter()
  }

  private consumeRouteParams(): void {
    try {
      const rawParams = this.router().getParams()
      if (!rawParams) {
        return
      }

      const params: UserCenterRouteParams = rawParams as UserCenterRouteParams
      if (params.userName && params.userName.length > 0) {
        this.userName = params.userName
      }
      if (params.userAvatar) {
        this.userAvatar = params.userAvatar
      }
      if (params.openId) {
        this.userOpenId = params.openId
      }
      if (params.unionId) {
        this.userUnionId = params.unionId
      }
    } catch (_error) {
    }
  }

  private loadSafeInsets(): void {
    const ctx = this.getHostContext()
    if (!ctx) {
      return
    }

    fetchSafeAreaInsets(ctx).then((insets) => {
      this.safeTopVp = insets.topVp
      this.safeBottomVp = insets.bottomVp
    }).catch((_error: Error) => {
    })
  }

  private maskedValue(value: string): string {
    if (value.length <= 8) {
      return value.length > 0 ? value : '未提供'
    }
    return `${value.slice(0, 4)} •••• ${value.slice(value.length - 4)}`
  }

  private accountLabel(): string {
    if (this.userOpenId.length > 0) {
      return '华为帐号已连接'
    }
    return '体验模式'
  }

  private shortGreeting(): string {
    if (this.userName.length > 0) {
      return `${this.userName} 你好`
    }
    return '你好'
  }

  private profileDescription(): string {
    if (this.userOpenId.length > 0) {
      return '帐号信息已同步。'
    }
    return '当前为体验模式。'
  }

  private back(): void {
    try {
      this.router().back()
    } catch (_error) {
      this.showToast('暂时无法返回上一页')
    }
  }

  private showToast(message: string): void {
    try {
      void promptAction.openToast({ message })
    } catch (_error) {
    }
  }

  @Builder
  private buildRefinedBackButton() {
    Row({ space: 6 }) {
      Icon({
        iconType: 'arrowLeft',
        iconSize: 16,
        iconColor: Colors.accent,
        strokeWidth: 2
      })

      Text('返回')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textSecondary)
    }
      .height(44)
      .padding({ left: 12, right: 16 })
      .backgroundColor(Colors.cardPrimary)
      .border({
        width: 0.8,
        color: Colors.border,
        radius: 22
      })
      .borderRadius(22)
      .shadow({
        radius: 10,
        color: Colors.shadowSoft,
        offsetX: 0,
        offsetY: 4
      })
      .backdropBlur(12)
    .onClick(() => {
      this.back()
    })
  }

  @Builder
  private buildBackground() {
    DynamicGlassBackground()
  }

  @Builder
  private buildHeader() {
    Row() {
      this.buildRefinedBackButton()

      Blank()

      Text('我的')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
    }
    .width('100%')
    .padding({
      left: MobileSpacing.page.horizontal,
      right: MobileSpacing.page.horizontal,
      top: this.safeTopVp + 8,
      bottom: 12
    })
  }

  @Builder
  private buildHeroCard() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(190)
        .height(190)
        .borderRadius(95)
        .backgroundColor(Colors.overlaySoft)
        .blur(24)
        .position({ x: -48, y: -44 })

      Column()
        .width(150)
        .height(150)
        .borderRadius(75)
        .backgroundColor(Colors.overlayMedium)
        .blur(24)
        .position({ x: 320, y: 70 })

      Column({ space: 18 }) {
        Row({ space: 16 }) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(96)
            .height(96)
            .borderRadius(48)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                [Colors.overlayMedium, 0],
                [Colors.cardSecondary, 1]
              ]
            })
            .shadow({
              radius: 14,
              color: Colors.shadowMedium,
              offsetX: 0,
              offsetY: 6
            })
            .translate({ x: 0, y: 8 })

          CuteUserAvatar({
            avatarSize: 86,
            userAvatar: this.userAvatar,
            userName: this.userName,
            showStatusDot: true,
            statusColor: this.userOpenId.length > 0 ? Colors.success : Colors.warning
          })
        }
        .width(118)
        .height(118)

        Column({ space: 8 }) {
          Text('ACCOUNT CENTER')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.accent)
            .letterSpacing(1.1)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(Colors.overlayMedium)
            .borderRadius(14)

          Text(this.userName)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .fontFamily('HarmonyOS Sans SC')
            .lineHeight(36)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.accountLabel())
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.userOpenId.length > 0 ? Colors.accent : Colors.warning)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(this.userOpenId.length > 0 ? Colors.overlayMedium : Colors.overlaySoft)
            .borderRadius(BorderRadius.pill)
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: 10 }) {
        this.buildPill('Huawei ID')
        this.buildPill(this.userOpenId.length > 0 ? '已连接' : '体验模式')
        this.buildPill('同步安全')
      }
      .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 22, bottom: 22 })
    .backgroundColor(Colors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [Colors.cardPrimary, 0],
        [Colors.cardSecondary, 0.56],
        [Colors.backgroundElevated, 1]
      ]
    })
    .border({
      width: 1.1,
      color: Colors.border,
      radius: 34
    })
    .borderRadius(34)
    .shadow({
      radius: 14,
      color: Colors.shadowMedium,
      offsetX: 0,
      offsetY: 6
    })
  }

  @Builder
  private buildPill(label: string) {
    Text(label)
      .fontSize(10)
      .fontWeight(FontWeight.Bold)
      .fontColor(Colors.textSecondary)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(Colors.overlaySoft)
      .border({
        width: 0.8,
        color: Colors.border,
        radius: 16
      })
      .borderRadius(16)
  }

  @Builder
  private buildInfoCard(title: string, value: string, iconType: 'person' | 'sparkles' | 'list') {
    Row({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(48)
          .height(48)
          .borderRadius(18)
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [
              [Colors.overlayMedium, 0],
              [Colors.cardSecondary, 1]
            ]
          })
          .shadow({
            radius: 8,
            color: Colors.shadowSoft,
            offsetX: 0,
            offsetY: 4
          })

        Icon({
          iconType: iconType,
          iconSize: 18,
          iconColor: Colors.accent,
          strokeWidth: 1.8
        })
      }

      Column({ space: 4 }) {
        Text(title)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textMuted)
          .width('100%')

        Text(value)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
          .lineHeight(22)
          .width('100%')
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(value === '未提供' ? '待补全' : '已同步')
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(value === '未提供' ? Colors.warning : Colors.accent)
        .padding({ left: 9, right: 9, top: 5, bottom: 5 })
        .backgroundColor(value === '未提供' ? Colors.overlaySoft : Colors.overlayMedium)
        .borderRadius(BorderRadius.pill)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(Colors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [Colors.overlayMedium, 0],
        [Colors.cardSecondary, 1]
      ]
    })
    .border({
      width: 0.9,
      color: this.pressedCardTitle === title ? Colors.accent : Colors.border,
      radius: 24
    })
    .borderRadius(24)
    .shadow({
      radius: this.pressedCardTitle === title ? 10 : 14,
      color: this.pressedCardTitle === title ? Colors.shadowSoft : Colors.shadowMedium,
      offsetX: 0,
      offsetY: this.pressedCardTitle === title ? 4 : 6
    })
    .scale({
      x: this.pressedCardTitle === title ? 0.985 : 1,
      y: this.pressedCardTitle === title ? 0.985 : 1
    })
    .animation({
      duration: 160,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedCardTitle = title
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedCardTitle = ''
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.buildBackground()

      Column({ space: 0 }) {
        this.buildHeader()

        Scroll() {
          Column({ space: 16 }) {
            this.buildHeroCard()
            Text('帐号资料')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .margin({ top: 4 })
            this.buildInfoCard('昵称', this.userName, 'person')
            this.buildInfoCard('OpenID', this.maskedValue(this.userOpenId), 'sparkles')
            this.buildInfoCard('UnionID', this.maskedValue(this.userUnionId), 'list')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({
            left: MobileSpacing.page.horizontal,
            right: MobileSpacing.page.horizontal,
            top: 4,
            bottom: 28 + this.safeBottomVp
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.backgroundElevated)
  }
}
