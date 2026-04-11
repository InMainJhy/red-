import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { ShareData, HapShareData } from '../common/Models'

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
  tone: string
  tint: string
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
      tone: 'rgba(16, 185, 129, 0.10)',
      tint: '#10B981'
    },
    {
      id: 'xiaohongshu',
      name: '小红书',
      monogram: '书',
      subtitle: '适合卡片分享',
      type: 'social',
      available: true,
      tone: 'rgba(244, 63, 94, 0.10)',
      tint: '#F43F5E'
    },
    {
      id: 'weibo',
      name: '微博',
      monogram: '博',
      subtitle: '公开传播',
      type: 'social',
      available: true,
      tone: 'rgba(249, 115, 22, 0.10)',
      tint: '#F97316'
    },
    {
      id: 'system',
      name: '系统分享',
      monogram: '享',
      subtitle: '调用系统面板',
      type: 'system',
      available: true,
      tone: 'rgba(99, 102, 241, 0.10)',
      tint: '#6366F1'
    },
    {
      id: 'copy',
      name: '复制内容',
      monogram: '复',
      subtitle: '复制摘要文本',
      type: 'system',
      available: true,
      tone: 'rgba(148, 163, 184, 0.14)',
      tint: '#475569'
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
      tone: 'rgba(14, 165, 233, 0.10)',
      tint: '#0EA5E9'
    },
    {
      id: 'smarttv',
      name: '智慧屏',
      monogram: '屏',
      subtitle: '大屏展示',
      type: 'device',
      available: true,
      tone: 'rgba(168, 85, 247, 0.10)',
      tint: '#A855F7'
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
          .backgroundColor('rgba(15, 23, 42, 0.34)')
          .onClick(() => {
            this.onClose()
          })

        Column({ space: Spacing.lg }) {
          Column()
            .width(40)
            .height(4)
            .borderRadius(2)
            .backgroundColor(Colors.textMuted)
            .margin({ top: Spacing.sm })

          Column({ space: 6 }) {
            Text('SHARE / FLOW')
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.primary)
              .letterSpacing(1.6)

            Text('分享会议纪要')
              .fontSize(Typography.size.lg)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)

            Text('可以直接转给朋友，也可以通过附近分享或设备流转，把纪要递到身边的人。')
              .fontSize(Typography.size.body)
              .fontColor(Colors.textSecondary)
              .lineHeight(Typography.lineHeight.relaxed)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          SharePreviewCard({
            title: this.shareData.title,
            description: this.shareData.description.length > 0 ? this.shareData.description : this.shareData.content,
            tags: this.shareData.tags
          })

          this.buildNearFieldSection()
          this.buildSocialSection()
          this.buildDeviceShareSection()

          Button('取消')
            .width('100%')
            .height(46)
            .fontSize(Typography.size.body)
            .fontColor(Colors.textSecondary)
            .backgroundColor('rgba(255, 255, 255, 0.74)')
            .borderRadius(BorderRadius.xxl)
            .margin({ bottom: Spacing.sm })
            .onClick(() => {
              this.onClose()
            })
        }
        .width('100%')
        .padding({
          left: Spacing.page.horizontal,
          right: Spacing.page.horizontal,
          bottom: Spacing.page.vertical + 20
        })
        .backgroundColor(Colors.background)
        .borderRadius({
          topLeft: BorderRadius.xxl2,
          topRight: BorderRadius.xxl2,
          bottomLeft: 0,
          bottomRight: 0
        })
        .shadow({
          radius: 24,
          color: 'rgba(15, 23, 42, 0.12)',
          offsetX: 0,
          offsetY: -6
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
            .fontColor('#F97316')
            .letterSpacing(1.2)

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
          .fontColor('#C2410C')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('rgba(249, 115, 22, 0.12)')
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
    .padding(Spacing.md)
    .backgroundColor('rgba(249, 115, 22, 0.08)')
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 1,
      color: 'rgba(249, 115, 22, 0.18)',
      radius: BorderRadius.xxl
    })
  }

  @Builder
  private buildNearFieldButton(title: string, description: string, active: boolean) {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Text(title)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(active ? '#C2410C' : Colors.textSecondary)

        // NFC 动画圆点（等待状态时显示）
        if (active && this.nfcTapState === 'waiting') {
          Text('·')
            .fontSize(Typography.size.bodyLg)
            .fontColor('#F97316')
            .opacity(this.nfcPulseOpacity)
        }

        // 成功图标
        if (active && this.nfcTapState === 'success') {
          Text('✓')
            .fontSize(Typography.size.body)
            .fontColor('#10B981')
        }

        // 错误图标
        if (active && this.nfcTapState === 'error') {
          Text('!')
            .fontSize(Typography.size.body)
            .fontColor('#EF4444')
        }
      }

      Text(this.nfcTapState === 'idle' ? description : this.nfcTapMessage)
        .fontSize(Typography.size.xs)
        .fontColor(this.nfcTapState === 'success' ? '#10B981' :
                   this.nfcTapState === 'error' ? '#EF4444' : Colors.textMuted)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .padding({ top: Spacing.md, bottom: Spacing.md, left: Spacing.sm, right: Spacing.sm })
    .backgroundColor(active ? 'rgba(255, 255, 255, 0.76)' : 'rgba(255, 255, 255, 0.44)')
    .borderRadius(BorderRadius.xl)
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
            .color('#F97316')
            .opacity(this.nfcPulseOpacity)

          Text('等待对方设备靠近…')
            .fontSize(Typography.size.caption)
            .fontColor('#C2410C')

          Text('将手机背部NFC区域靠近对方设备即可分享')
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(249, 115, 22, 0.08)')
        .borderRadius(BorderRadius.lg)
        .onClick(() => {
          this.resetNfcState()
        })
      } else if (this.nfcTapState === 'writing') {
        Row({ space: 8 }) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#10B981')

          Text(this.nfcTapMessage)
            .fontSize(Typography.size.caption)
            .fontColor('#10B981')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(16, 185, 129, 0.08)')
        .borderRadius(BorderRadius.lg)
      } else if (this.nfcTapState === 'success') {
        Row({ space: 8 }) {
          Text('✓')
            .fontSize(Typography.size.bodyLg)
            .fontColor('#10B981')

          Text(this.nfcTapMessage)
            .fontSize(Typography.size.caption)
            .fontColor('#10B981')

          Text('点击关闭提示')
            .fontSize(Typography.size.xs)
            .fontColor(Colors.textMuted)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(16, 185, 129, 0.08)')
        .borderRadius(BorderRadius.lg)
        .border({ width: 1, color: 'rgba(16, 185, 129, 0.2)', radius: BorderRadius.lg })
        .onClick(() => {
          this.resetNfcState()
        })
      } else if (this.nfcTapState === 'error') {
        Row({ space: 8 }) {
          Text('!')
            .fontSize(Typography.size.body)
            .fontColor('#EF4444')

          Text(this.nfcTapMessage)
            .fontSize(Typography.size.caption)
            .fontColor('#EF4444')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding(Spacing.sm)
        .backgroundColor('rgba(239, 68, 68, 0.08)')
        .borderRadius(BorderRadius.lg)
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
    .backgroundColor('rgba(255, 255, 255, 0.74)')
    .borderRadius(BorderRadius.xl)
    .border({
      width: 1,
      color: Colors.borderLight,
      radius: BorderRadius.xl
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
    .backgroundColor('rgba(255, 255, 255, 0.74)')
    .borderRadius(BorderRadius.xl)
    .border({
      width: 1,
      color: Colors.borderLight,
      radius: BorderRadius.xl
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
              .fontColor(Colors.primary)
              .padding({ left: Spacing.sm, right: Spacing.sm, top: 4, bottom: 4 })
              .backgroundColor('rgba(99, 102, 241, 0.10)')
              .borderRadius(BorderRadius.pill)
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
          .backgroundColor(Colors.primary)

        Text('阶段人格会议纪要')
          .fontSize(Typography.size.xs)
          .fontColor(Colors.textMuted)
      }
      .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(Spacing.md)
    .backgroundColor('rgba(255, 255, 255, 0.74)')
    .borderRadius(BorderRadius.xl)
    .border({
      width: 1,
      color: Colors.borderLight,
      radius: BorderRadius.xl
    })
  }
}
