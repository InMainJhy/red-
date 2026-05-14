import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { ShareData, HapShareData } from '../common/Models'
import { MintColors } from '../common/styles/MintColors'

const SHARE_SHEET_BLUE: ResourceColor = MintColors.lavenderDark
const SHARE_SHEET_CYAN: ResourceColor = '#17BFD6'
const SHARE_SHEET_GLASS: ResourceColor = 'rgba(255, 255, 255, 0.88)'
const SHARE_SHEET_BORDER: ResourceColor = 'rgba(215, 231, 244, 0.92)'

/**
 * 碰一碰分享状态
 */
export type NfcTapState = 'idle' | 'waiting' | 'writing' | 'success' | 'error'

export interface ShareTarget {
  id: string
  name: string
  monogram: string
  subtitle: string
  type: 'social' | 'device' | 'system'
  available: boolean
  tone: ResourceColor
  tint: ResourceColor
}

export interface ShareSheetProps {
  isVisible: boolean
  shareData: ShareData
  hapShareData?: HapShareData
  onClose: () => void
  onShareToSocial: (targetId: string) => void
  onHapShare: () => void
  onDeviceShare: (deviceId: string) => void
  onSystemShare: () => void
  onCopyLink: () => void
}

@Component
export struct ShareSheet {
  @Prop isVisible: boolean = false
  @Prop shareData: ShareData = {
    title: '',
    description: '',
    content: '',
    tags: []
  }
  @Prop hapShareData: HapShareData | undefined = undefined

  onClose: () => void = () => {}
  onShareToSocial: (targetId: string) => void = () => {}
  onHapShare: () => void = () => {}
  onDeviceShare: (deviceId: string) => void = () => {}
  onSystemShare: () => void = () => {}
  onCopyLink: () => void = () => {}

  /** 碰一碰分享状态 */
  @State private nfcTapState: NfcTapState = 'idle'
  @State private nfcTapMessage: string = ''
  @State private nfcAvailable: boolean = false
  @State private nfcPulseOpacity: number = 0.4

  private readonly socialTargets: ShareTarget[] = [
    {
      id: 'wechat',
      name: '微信',
      monogram: '微',
      subtitle: '发给联系人',
      type: 'social',
      available: true,
      tone: Colors.loadingBg,
      tint: Colors.textPrimary
    },
    {
      id: 'xiaohongshu',
      name: '小红书',
      monogram: '书',
      subtitle: '适合卡片分享',
      type: 'social',
      available: true,
      tone: Colors.loadingBg,
      tint: Colors.textPrimary
    },
    {
      id: 'weibo',
      name: '微博',
      monogram: '博',
      subtitle: '公开传播',
      type: 'social',
      available: true,
      tone: Colors.loadingBg,
      tint: Colors.textPrimary
    },
    {
      id: 'system',
      name: '系统分享',
      monogram: '享',
      subtitle: '调用系统面板',
      type: 'system',
      available: true,
      tone: Colors.loadingBg,
      tint: Colors.textPrimary
    },
    {
      id: 'copy',
      name: '复制内容',
      monogram: '复',
      subtitle: '复制摘要文本',
      type: 'system',
      available: true,
      tone: Colors.loadingBg,
      tint: Colors.textPrimary
    }
  ]

  private readonly deviceTargets: ShareTarget[] = [
    {
      id: 'tablet',
      name: '平板',
      monogram: '板',
      subtitle: '流转到平板',
      type: 'device',
      available: true,
      tone: Colors.loadingBg,
      tint: Colors.textSecondary
    },
    {
      id: 'smarttv',
      name: '智慧屏',
      monogram: '屏',
      subtitle: '大屏展示',
      type: 'device',
      available: true,
      tone: Colors.loadingBg,
      tint: Colors.textSecondary
    }
  ]

  aboutToAppear(): void {
    this.checkNfcAvailability()
  }

  /** 检查设备 NFC 能力 */
  private checkNfcAvailability(): void {
    // NFC P2P 需要实际硬件支持，此处默认不可用，进入演示模式
    this.nfcAvailable = false
  }

  /** 启动碰一碰分享流程 */
  private startNfcTapShare(): void {
    if (!this.hapShareData) {
      this.nfcTapState = 'error'
      this.nfcTapMessage = '暂无可分享的纪要数据'
      return
    }

    if (!this.nfcAvailable) {
      // NFC 不可用时降级到系统分享
      this.nfcTapState = 'error'
      this.nfcTapMessage = 'NFC 不可用，已降级到系统分享'
      this.onHapShare()
      return
    }

    // 进入等待碰一碰状态
    this.nfcTapState = 'waiting'
    this.nfcTapMessage = '请将手机背部靠近对方设备…'
    this.startNfcPulseAnimation()

    // 尝试使用 tagManager 写入 NDEF（模拟碰一碰）
    this.attemptNfcWrite()
  }

  /** 启动脉冲动画 */
  private startNfcPulseAnimation(): void {
    animateTo({
      duration: 1200,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.nfcPulseOpacity = 1.0
    })
  }

  /** 尝试 NFC 写入 */
  private attemptNfcWrite(): void {
    if (!this.hapShareData) return

    try {
      // 碰一碰 NFC P2P 需要硬件支持，此处进入演示模式
      console.info('[ShareSheet] 进入 NFC 演示模式')
      this.simulateNfcTapForDemo()
    } catch (err) {
      console.info('[ShareSheet] NFC API 异常，进入演示模式:', JSON.stringify(err))
      this.simulateNfcTapForDemo()
    }
  }

  /** 开发/演示模式：模拟碰一碰流程 */
  private simulateNfcTapForDemo(): void {
    // 模拟 1.5 秒后的碰一碰成功
    setTimeout(() => {
      if (this.nfcTapState === 'waiting') {
        this.nfcTapState = 'writing'
        this.nfcTapMessage = '正在传输纪要卡片…'

        setTimeout(() => {
          if (this.nfcTapState === 'writing') {
            this.nfcTapState = 'success'
            this.nfcTapMessage = '碰一碰分享成功！纪要卡片已发送'

            // 3 秒后自动重置状态
            setTimeout(() => {
              this.resetNfcState()
            }, 3000)
          }
        }, 800)
      }
    }, 1500)
  }

  /** 重置碰一碰状态 */
  private resetNfcState(): void {
    this.nfcTapState = 'idle'
    this.nfcTapMessage = ''
    this.nfcPulseOpacity = 0.4
  }

  build() {
    if (this.isVisible) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.34)')
          .onClick(() => {
            this.onClose()
          })

        Column({ space: Spacing.md }) {
          Column()
            .width(52)
            .height(5)
            .borderRadius(6)
            .backgroundColor('rgba(178, 198, 216, 0.84)')
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [
                ['rgba(255, 255, 255, 0.96)', 0],
                ['rgba(196, 215, 232, 0.90)', 1]
              ]
            })
            .margin({ top: Spacing.sm })

          Row() {
            Column({ space: 4 }) {
              Text('SHARE')
                .fontSize(Typography.size.xs)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.accent)
                .letterSpacing(1.6)

              Text('选择分享方式')
                .fontSize(Typography.size.bodyLg)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.textPrimary)
            }
            .alignItems(HorizontalAlign.Start)

            Blank()

            if (this.shareData.title.length > 0) {
              Text('当前纪要')
                .fontSize(Typography.size.xs)
                .fontWeight(FontWeight.Bold)
                .fontColor(SHARE_SHEET_BLUE)
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor('rgba(228, 242, 255, 0.94)')
                .border({
                  width: 1,
                  color: Colors.cardPrimary,
                  radius: BorderRadius.pill
                })
                .borderRadius(BorderRadius.pill)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          this.buildNearFieldSection()
          this.buildSocialSection()
          this.buildDeviceShareSection()

          Button('取消')
            .width('100%')
            .height(46)
            .fontSize(Typography.size.body)
            .fontColor(Colors.textPrimary)
            .backgroundColor(Colors.cardSecondary)
            .borderRadius(BorderRadius.xxl)
            .border({
              width: 1,
              color: LiquidGlass.border,
              radius: BorderRadius.xxl
            })
            .margin({ bottom: Spacing.sm })
            .onClick(() => {
              this.onClose()
            })
        }
        .width('100%')
        .padding({
          left: Spacing.page.horizontal,
          right: Spacing.page.horizontal,
          top: 6,
          bottom: Spacing.page.vertical + 20
        })
        .backgroundColor(SHARE_SHEET_GLASS)
        .backdropBlur(26)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(255, 255, 255, 0.98)', 0],
            ['rgba(239, 247, 253, 0.96)', 0.56],
            ['rgba(245, 249, 252, 0.98)', 1]
          ]
        })
        .border({
          width: 1,
          color: SHARE_SHEET_BORDER,
          radius: BorderRadius.xxl2
        })
        .borderRadius({
          topLeft: BorderRadius.xxl2,
          topRight: BorderRadius.xxl2,
          bottomLeft: 0,
          bottomRight: 0
        })
        .shadow({
          radius: 28,
          color: 'rgba(92, 139, 181, 0.18)',
          offsetX: 0,
          offsetY: -10
        })
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  private buildNearFieldSection() {
    Column({ space: Spacing.md }) {
      Row() {
        Column({ space: 4 }) {
          Text('HUAWEI SHARE')
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.accent)
            .letterSpacing(1.6)

          Text('近场分享')
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('近场更快')
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Bold)
          .fontColor(SHARE_SHEET_BLUE)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('rgba(226, 242, 255, 0.96)')
          .border({
            width: 1,
            color: 'rgba(255, 255, 255, 0.92)',
            radius: BorderRadius.pill
          })
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')

      Text('适合把会议纪要、卡片或视频快速递给身边的华为设备。')
        .fontSize(Typography.size.caption)
        .fontColor(Colors.textSecondary)
        .lineHeight(Typography.lineHeight.normal)
        .width('100%')

      Row({ space: Spacing.md }) {
        this.buildNearFieldButton('碰一碰', '把纪要发给对方设备', true)
        this.buildNearFieldButton('抓一抓', '近场发起分享', false)
      }
      .width('100%')

      // NFC 碰一碰状态指示器
      if (this.nfcTapState !== 'idle') {
        this.buildNfcStateIndicator()
      }
    }
    .width('100%')
    .padding(Spacing.card.small)
    .backgroundColor('rgba(243, 248, 252, 0.92)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 0.96)', 0],
        ['rgba(235, 244, 250, 0.96)', 1]
      ]
    })
    .borderRadius(BorderRadius.xxl2)
    .border({
      width: 1,
      color: 'rgba(201, 220, 235, 0.96)',
      radius: BorderRadius.xxl2
    })
    .shadow({
      radius: 18,
      color: 'rgba(122, 168, 203, 0.14)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  private buildNearFieldButton(title: string, description: string, active: boolean) {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Text(title)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(active ? Colors.textPrimary : Colors.textSecondary)

        // NFC 动画圆点（等待状态时显示）
        if (active && this.nfcTapState === 'waiting') {
          Text('·')
            .fontSize(Typography.size.bodyLg)
            .fontColor(SHARE_SHEET_BLUE)
            .opacity(this.nfcPulseOpacity)
        }

        // 成功图标
        if (active && this.nfcTapState === 'success') {
          Text('✓')
            .fontSize(Typography.size.body)
            .fontColor(SHARE_SHEET_BLUE)
        }

        // 错误图标
        if (active && this.nfcTapState === 'error') {
          Text('!')
            .fontSize(Typography.size.body)
            .fontColor(Colors.errorLight)
        }
      }
      .justifyContent(FlexAlign.Center)

      Text(this.nfcTapState === 'idle' ? description : this.nfcTapMessage)
        .fontSize(Typography.size.xs)
        .fontColor(this.nfcTapState === 'success' ? SHARE_SHEET_BLUE :
                   this.nfcTapState === 'error' ? Colors.errorLight : Colors.textMuted)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding({ top: Spacing.md, bottom: Spacing.md, left: Spacing.sm, right: Spacing.sm })
    .backgroundColor(active ? 'rgba(255, 255, 255, 0.98)' : 'rgba(250, 252, 254, 0.84)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: active
        ? [
            ['rgba(255, 255, 255, 0.99)', 0],
            ['rgba(239, 247, 255, 0.95)', 1]
          ]
        : [
            ['rgba(255, 255, 255, 0.90)', 0],
            ['rgba(243, 247, 251, 0.82)', 1]
          ]
    })
    .border({
      width: 1,
      color: active ? 'rgba(186, 218, 243, 0.96)' : 'rgba(220, 229, 238, 0.92)',
      radius: BorderRadius.xl
    })
    .borderRadius(BorderRadius.xl)
    .shadow({
      radius: active ? 14 : 8,
      color: active ? 'rgba(110, 171, 214, 0.16)' : 'rgba(150, 171, 190, 0.08)',
      offsetX: 0,
      offsetY: active ? 7 : 4
    })
    .opacity(active ? 1 : 0.7)
    .onClick(() => {
      if (active) {
        this.startNfcTapShare()
      }
    })
  }

  @Builder
  private buildNfcStateIndicator() {
    Column({ space: Spacing.sm }) {
      if (this.nfcTapState === 'waiting') {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(SHARE_SHEET_BLUE)
            .opacity(this.nfcPulseOpacity)

          Text('等待对方设备靠近…')
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textPrimary)

          Text('将手机背部NFC区域靠近对方设备即可分享')
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(255, 255, 255, 0.74)')
        .borderRadius(BorderRadius.lg)
        .border({ width: 1, color: 'rgba(212, 228, 241, 0.90)', radius: BorderRadius.lg })
        .onClick(() => {
          this.resetNfcState()
        })
      } else if (this.nfcTapState === 'writing') {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(SHARE_SHEET_CYAN)

          Text(this.nfcTapMessage)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textPrimary)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(233, 247, 255, 0.80)')
        .borderRadius(BorderRadius.lg)
        .border({ width: 1, color: 'rgba(195, 224, 244, 0.96)', radius: BorderRadius.lg })
      } else if (this.nfcTapState === 'success') {
        Row({ space: 8 }) {
          Text('✓')
            .fontSize(Typography.size.bodyLg)
            .fontColor(SHARE_SHEET_BLUE)

          Text(this.nfcTapMessage)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textPrimary)

          Text('点击关闭提示')
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(235, 248, 255, 0.90)')
        .borderRadius(BorderRadius.lg)
        .border({ width: 1, color: 'rgba(189, 221, 244, 0.96)', radius: BorderRadius.lg })
        .onClick(() => {
          this.resetNfcState()
        })
      } else if (this.nfcTapState === 'error') {
        Row({ space: 8 }) {
          Text('!')
            .fontSize(Typography.size.body)
            .fontColor(Colors.errorLight)

          Text(this.nfcTapMessage)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.errorLight)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(255, 243, 244, 0.92)')
        .borderRadius(BorderRadius.lg)
        .border({ width: 1, color: 'rgba(236, 201, 205, 0.94)', radius: BorderRadius.lg })
        .onClick(() => {
          this.resetNfcState()
        })
      }
    }
    .width('100%')
    .transition(TransitionEffect.OPACITY.animation({ duration: 300 }))
  }

  @Builder
  private buildSocialSection() {
    Column({ space: Spacing.md }) {
      Row() {
        Text('常用分享')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()

        Text('卡片 / 文本 / 系统面板')
          .fontSize(Typography.size.xs)
          .fontColor(Colors.textMuted)
      }
      .width('100%')

      Scroll() {
        Row({ space: Spacing.md }) {
          ForEach(this.socialTargets, (target: ShareTarget) => {
            this.buildShareTarget(target)
          }, (target: ShareTarget) => target.id)
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  private buildShareTarget(target: ShareTarget) {
    Column({ space: 10 }) {
      Column() {
        Text(target.monogram)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(target.tint)
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(target.tone)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(target.name)
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.textPrimary)

        Text(target.subtitle)
          .fontSize(Typography.size.xs)
          .fontColor(Colors.textMuted)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width(132)
    .padding(Spacing.md)
    .backgroundColor('rgba(255, 255, 255, 0.84)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 0.98)', 0],
        ['rgba(243, 248, 252, 0.90)', 1]
      ]
    })
    .borderRadius(BorderRadius.xl)
    .border({
      width: 1,
      color: 'rgba(216, 228, 239, 0.90)',
      radius: BorderRadius.xl
    })
    .shadow({
      radius: 10,
      color: 'rgba(121, 165, 196, 0.10)',
      offsetX: 0,
      offsetY: 5
    })
    .opacity(target.available ? 1 : 0.5)
    .enabled(target.available)
    .onClick(() => {
      if (!target.available) {
        return
      }
      if (target.type === 'social') {
        this.onShareToSocial(target.id)
      } else if (target.type === 'system' && target.id === 'copy') {
        this.onCopyLink()
      } else if (target.type === 'system') {
        this.onSystemShare()
      }
    })
  }

  @Builder
  private buildDeviceShareSection() {
    Column({ space: Spacing.md }) {
      Row() {
        Text('设备流转')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()

        Text('流转到平板或大屏')
          .fontSize(Typography.size.xs)
          .fontColor(Colors.textMuted)
      }
      .width('100%')

      Row({ space: Spacing.md }) {
        ForEach(this.deviceTargets, (device: ShareTarget) => {
          this.buildDeviceTarget(device)
        }, (device: ShareTarget) => device.id)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildDeviceTarget(target: ShareTarget) {
    Column({ space: 8 }) {
      Column() {
        Text(target.monogram)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(target.tint)
      }
      .width(42)
      .height(42)
      .borderRadius(21)
      .backgroundColor(target.tone)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(target.name)
        .fontSize(Typography.size.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textPrimary)

      Text(target.subtitle)
        .fontSize(Typography.size.xs)
        .fontColor(Colors.textMuted)
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .padding(Spacing.md)
    .backgroundColor('rgba(255, 255, 255, 0.84)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 0.98)', 0],
        ['rgba(242, 247, 251, 0.92)', 1]
      ]
    })
    .borderRadius(BorderRadius.xl)
    .border({
      width: 1,
      color: 'rgba(216, 228, 239, 0.90)',
      radius: BorderRadius.xl
    })
    .shadow({
      radius: 10,
      color: 'rgba(121, 165, 196, 0.10)',
      offsetX: 0,
      offsetY: 5
    })
    .enabled(target.available)
    .onClick(() => {
      if (target.available) {
        this.onDeviceShare(target.id)
      }
    })
  }
}

@Component
export struct SharePreviewCard {
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop tags: string[] = []

  build() {
    Column({ space: Spacing.md }) {
      Text('会议卡片')
        .fontSize(Typography.size.xs)
        .fontWeight(FontWeight.Bold)
        .fontColor(SHARE_SHEET_BLUE)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor('rgba(229, 243, 255, 0.92)')
        .border({
          width: 1,
          color: 'rgba(255, 255, 255, 0.92)',
          radius: BorderRadius.pill
        })
        .borderRadius(BorderRadius.pill)
        .alignSelf(ItemAlign.Start)

      Text(this.title.length > 0 ? this.title : '当前还没有可分享的纪要')
        .fontSize(Typography.size.bodyLg)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Start)

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(Typography.size.body)
          .fontColor(Colors.textSecondary)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
          .lineHeight(Typography.lineHeight.relaxed)
      }

      if (this.tags.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.tags.slice(0, 4), (tag: string) => {
            Text(`#${tag}`)
              .fontSize(Typography.size.xs)
              .fontColor(Colors.accent)
              .padding({ left: Spacing.sm, right: Spacing.sm, top: 4, bottom: 4 })
              .backgroundColor(LiquidGlass.surfaceStrong)
              .borderRadius(BorderRadius.pill)
              .border({
                width: 1,
                color: LiquidGlass.border,
                radius: BorderRadius.pill
              })
              .margin({ right: Spacing.sm, bottom: Spacing.sm })
          }, (tag: string) => tag)
        }
        .width('100%')
      }

      Row({ space: Spacing.xs }) {
        Column()
          .width(4)
          .height(4)
          .borderRadius(2)
          .backgroundColor(Colors.accent)

        Text('阶段人格会议纪要')
          .fontSize(Typography.size.xs)
          .fontColor(Colors.textMuted)
      }
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(Spacing.card.small)
    .backgroundColor('rgba(255, 255, 255, 0.90)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 0.99)', 0],
        ['rgba(240, 246, 251, 0.96)', 1]
      ]
    })
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 1,
      color: SHARE_SHEET_BORDER,
      radius: BorderRadius.xxl
    })
    .shadow({
      radius: 16,
      color: 'rgba(117, 157, 188, 0.12)',
      offsetX: 0,
      offsetY: 8
    })
  }
}
