import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import pasteboard from '@ohos.pasteboard'
import promptAction from '@ohos.promptAction'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { QrCodeService } from '../common/QrCodeService'
import { BackButton } from '../components/BackButton'
import { DynamicGlassBackground } from '../components/DynamicGlassBackground'
import { Colors } from '../common/styles/Colors'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'

interface QrLinkRouteParams {
  title?: string
  subtitle?: string
  qrValue?: string
}

const FALLBACK_SAFE_TOP_VP: number = 52

@Entry
@Component
struct QrLinkPage {
  @State private title: string = '扫码直达'
  @State private subtitle: string = '使用另一台设备扫码，直接打开对应内容'
  @State private qrValue: string = ''
  @State private qrImageUrl: string = ''
  @State private loading: boolean = true
  @State private errorText: string = ''
  @State private safeTopVp: number = 0

  aboutToAppear(): void {
    this.loadSafeInsets()

    const params = router.getParams() as QrLinkRouteParams
    this.title = params?.title && params.title.trim().length > 0 ? params.title.trim() : '扫码直达'
    this.subtitle = params?.subtitle && params.subtitle.trim().length > 0
      ? params.subtitle.trim()
      : '使用另一台设备扫码，直接打开对应内容'
    this.qrValue = params?.qrValue && params.qrValue.trim().length > 0 ? params.qrValue.trim() : ''

    if (this.qrValue.length <= 0) {
      this.loading = false
      this.errorText = '当前没有可生成的二维码内容'
      return
    }

    void this.generateQrCode()
  }

  private loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
      })
    } catch (_error) {
    }
  }

  private topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  private async generateQrCode(): Promise<void> {
    this.loading = true
    this.errorText = ''
    try {
      this.qrImageUrl = await QrCodeService.buildSvgDataUrl(this.qrValue, 420)
      if (this.qrImageUrl.length <= 0) {
        this.errorText = '二维码生成失败'
      }
    } catch (error) {
      console.error('[QrLinkPage] generateQrCode failed:', error)
      this.errorText = '二维码生成失败，请稍后重试'
    } finally {
      this.loading = false
    }
  }

  private showToast(message: string): void {
    try {
      void promptAction.openToast({ message: message })
    } catch (_error) {
    }
  }

  private async copyQrValue(): Promise<void> {
    if (this.qrValue.length <= 0) {
      this.showToast('暂无可复制链接')
      return
    }

    try {
      const board = pasteboard.getSystemPasteboard()
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.qrValue)
      await board.setData(data)
      this.showToast('已复制原始链接')
    } catch (error) {
      console.error('[QrLinkPage] copyQrValue failed:', error)
      this.showToast('复制失败')
    }
  }

  private goBack(): void {
    try {
      router.back()
    } catch (_error) {
    }
  }

  @Builder
  private buildNav() {
    Row({ space: Spacing.md }) {
      BackButton({
        iconSize: 22,
        iconColor: MintColors.mintDark,
        bgColor: MintColors.surfaceGlass,
        buttonSize: 44,
        customOnClick: () => this.goBack()
      })

      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.textPrimary)
        Text('二维码 / 深链直达')
          .fontSize(Typography.size.xs)
          .fontColor(MintColors.textMuted)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: this.topInsetVp() + 8, bottom: Spacing.sm })
  }

  @Builder
  private buildCard() {
    Column({ space: Spacing.lg }) {
      Column({ space: Spacing.xs }) {
        Text(this.title)
          .width('100%')
          .fontSize(Typography.size.xl)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)
          .textAlign(TextAlign.Center)

        Text(this.subtitle)
          .width('100%')
          .fontSize(Typography.size.sm)
          .lineHeight(22)
          .fontColor(MintColors.textMuted)
          .textAlign(TextAlign.Center)
      }

      if (this.loading) {
        Column({ space: Spacing.sm }) {
          LoadingProgress()
            .color(MintColors.mintDark)
            .width(36)
            .height(36)

          Text('正在生成二维码...')
            .fontSize(Typography.size.sm)
            .fontColor(MintColors.textMuted)
        }
        .width('100%')
        .padding({ top: 36, bottom: 36 })
      } else if (this.errorText.length > 0) {
        Column({ space: Spacing.sm }) {
          Text(this.errorText)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.warning)
            .textAlign(TextAlign.Center)

          Button('复制原始链接')
            .height(42)
            .fontSize(Typography.size.sm)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textInverse)
            .backgroundColor(MintColors.mintDark)
            .borderRadius(BorderRadius.pill)
            .onClick(() => {
              void this.copyQrValue()
            })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
      } else {
        Column({ space: Spacing.md }) {
          Column() {
            Image(this.qrImageUrl)
              .width(260)
              .height(260)
              .objectFit(ImageFit.Contain)
          }
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(BorderRadius.xxl2)

          Text(this.qrValue)
            .width('100%')
            .fontSize(Typography.size.xs)
            .lineHeight(20)
            .fontColor(MintColors.textMuted)
            .maxLines(4)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)

          Button('复制原始链接')
            .width('100%')
            .height(46)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textInverse)
            .linearGradient({
              angle: 135,
              colors: [
                ['#79B8F9', 0],
                ['#5E95E2', 1]
              ]
            })
            .borderRadius(BorderRadius.xxl)
            .onClick(() => {
              void this.copyQrValue()
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(MintColors.surfaceGlass)
    .backdropBlur(40)
    .linearGradient({
      angle: 135,
      colors: [
        [MintColors.cardPrimary, 0],
        [MintColors.surfaceGlass, 1]
      ]
    })
    .border({
      width: 1.5,
      color: MintColors.cardPrimary,
      radius: BorderRadius.xxl3
    })
    .borderRadius(BorderRadius.xxl3)
    .shadow({
      radius: 32,
      color: 'rgba(92, 168, 255, 0.18)',
      offsetX: -4,
      offsetY: 12
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      DynamicGlassBackground()

      Column({ space: Spacing.md }) {
        this.buildNav()

        Column() {
          this.buildCard()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: Spacing.md, bottom: 24 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.background)
  }
}
