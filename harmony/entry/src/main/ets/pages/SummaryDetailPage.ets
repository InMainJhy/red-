import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import pasteboard from '@ohos.pasteboard'
import promptAction from '@ohos.promptAction'
import { ArenaRun, ExportFormatType, SummaryParticipant, SummaryRecord } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { BreakpointSystem, BreakpointType } from '../common/BreakpointSystem'
import { ResponsiveLayoutMetrics, responsiveLayoutForBreakpoint } from '../common/ResponsiveLayout'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import { AnimationCurve, AnimationDuration, getStaggerDelay } from '../common/styles/Animation'
import { PersonaApi } from '../service/PersonaApi'
import { SummaryService, convertArenaRunToSummaryRecord } from '../service/SummaryService'
import { SmartFillService } from '../service/SmartFillService'
import { ShareSheet } from '../components/ShareSheet'
import { BackButton } from '../components/BackButton'
import { DynamicGlassBackground } from '../components/DynamicGlassBackground'
import { Colors } from '../common/styles/Colors'
import { buildSummaryDetailUri } from '../common/LaunchIntent'
import { CalendarReminderService } from '../service/CalendarReminderService'
import { ServiceCollaborationService } from '../service/ServiceCollaborationService'

export interface SummaryDetailRouteParams {
  summaryId?: string
  arenaRunId?: string
  openSheet?: 'export' | 'share'
  exportFormat?: ExportFormatType
}

const FALLBACK_SAFE_TOP_VP: number = 52

function formatSummaryDate(iso: string): string {
  if (iso.length < 8) {
    return iso
  }
  try {
    const d = new Date(iso)
    if (Number.isNaN(d.getTime())) {
      return iso
    }
    const y = d.getFullYear()
    const m = d.getMonth() + 1
    const day = d.getDate()
    const hh = d.getHours().toString().padStart(2, '0')
    const min = d.getMinutes().toString().padStart(2, '0')
    return `${y}年${m}月${day}日 ${hh}:${min}`
  } catch (_e) {
    return iso
  }
}

@Entry
@Component
struct SummaryDetailPage {
  @State private summaryRecord: SummaryRecord | null = null
  @State private isLoading: boolean = true
  @State private error: string = ''
  @State private safeTopVp: number = 0
  @State private safeBottomVp: number = 0
  @State private heroOpacity: number = 0
  @State private heroTranslateY: number = 30
  @State private toolbarOpacity: number = 0
  @State private toolbarTranslateY: number = 24
  @State private bodyOpacity: number = 0
  @State private bodyTranslateY: number = 28
  @State private loadingPulse: number = 0.65
  @State private isExpanding: boolean = false
  @State private expandedSummary: string = ''
  @State private showExpandedContent: boolean = false
  @State private currentBreakpoint: BreakpointType = 'sm'

  private summaryId: string = ''
  private arenaRunId: string = ''
  private pendingSheet: 'none' | 'export' | 'share' = 'none'
  private entryExportFormat: ExportFormatType = 'image'
  @State private showShareSheet: boolean = false
  private detachBreakpointListener?: () => void

  aboutToAppear(): void {
    this.attachResponsiveBreakpoint()
    this.loadSafeInsets()
    this.startLoadingPulse()

    const params = router.getParams() as SummaryDetailRouteParams
    if (!params || (!params.summaryId && !params.arenaRunId)) {
      this.error = '缺少纪要标识'
      this.isLoading = false
      return
    }

    this.summaryId = params.summaryId ? params.summaryId : ''
    this.arenaRunId = params.arenaRunId ? params.arenaRunId : ''
    this.pendingSheet = params.openSheet ? params.openSheet : 'none'
    this.entryExportFormat = params.exportFormat ? params.exportFormat : 'image'

    try {
      const ctx = getContext(this) as common.UIAbilityContext
      void SummaryService.init(ctx).then(() => {
        void this.loadSummaryDetail()
      })
    } catch (_error) {
      void this.loadSummaryDetail()
    }
  }

  aboutToDisappear(): void {
    if (this.detachBreakpointListener) {
      this.detachBreakpointListener()
      this.detachBreakpointListener = undefined
    }
  }

  private attachResponsiveBreakpoint(): void {
    if (this.detachBreakpointListener) {
      return
    }
    this.detachBreakpointListener = BreakpointSystem.getInstance().subscribe((breakpoint: BreakpointType) => {
      this.currentBreakpoint = breakpoint
    })
  }

  private responsiveLayout(): ResponsiveLayoutMetrics {
    return responsiveLayoutForBreakpoint(this.currentBreakpoint)
  }

  private startLoadingPulse(): void {
    animateTo({
      duration: 900,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.loadingPulse = 1
    })
  }

  private loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
        this.safeBottomVp = insets.bottomVp
      })
    } catch (_error) {
    }
  }

  private topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  private buildRecordFromArenaRun(run: ArenaRun): SummaryRecord {
    const record = convertArenaRunToSummaryRecord(run, undefined)
    record.id = run.runId
    record.arenaRunId = run.runId
    if (run.createdAt && run.createdAt.length > 0) {
      record.createdAt = run.createdAt
      record.updatedAt = run.createdAt
    }
    return record
  }

  private scheduleContentEntrance(): void {
    this.heroOpacity = 0
    this.heroTranslateY = 30
    this.toolbarOpacity = 0
    this.toolbarTranslateY = 24
    this.bodyOpacity = 0
    this.bodyTranslateY = 28

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.smooth
      }, () => {
        this.heroOpacity = 1
        this.heroTranslateY = 0
      })
    }, getStaggerDelay(0, 40))

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.smooth
      }, () => {
        this.toolbarOpacity = 1
        this.toolbarTranslateY = 0
      })
    }, 180)

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.smooth
      }, () => {
        this.bodyOpacity = 1
        this.bodyTranslateY = 0
      })
    }, 320)
  }

  private async loadSummaryDetail(): Promise<void> {
    this.isLoading = true
    this.error = ''
    try {
      if (this.arenaRunId.length > 0) {
        const response = await PersonaApi.getArenaRunDetail(this.arenaRunId)
        this.summaryRecord = this.buildRecordFromArenaRun(response.result)
      } else {
        this.summaryRecord = await SummaryService.getSummaryDetail(this.summaryId)
      }

      if (!this.summaryRecord) {
        this.error = '未找到纪要内容'
        return
      }

      await this.runPendingActionIfNeeded()
      setTimeout(() => this.scheduleContentEntrance(), 30)
    } catch (error) {
      console.error('[SummaryDetailPage] loadSummaryDetail failed:', error)
      this.error = '加载失败，请检查网络后重试'
    } finally {
      this.isLoading = false
    }
  }

  private async runPendingActionIfNeeded(): Promise<void> {
    if (this.pendingSheet === 'share') {
      await this.handleCopyContent()
    } else if (this.pendingSheet === 'export') {
      if (this.entryExportFormat === 'video') {
        await this.handleExportVideo()
      } else if (this.entryExportFormat === 'text') {
        await this.handleExportText()
      } else {
        await this.openPosterPreviewFromPending()
      }
    }
    this.pendingSheet = 'none'
  }

  private async openPosterPreviewFromPending(): Promise<void> {
    const id = this.posterRunId()
    if (id.length === 0) {
      await this.copyTextToClipboard(this.shareText(), '已复制纪要文本')
      return
    }
    router.pushUrl({
      url: 'pages/PosterPreviewPage',
      params: {
        arenaRunId: id,
        title: this.summaryRecord ? this.summaryRecord.title : ''
      }
    })
  }

  private shareText(): string {
    if (!this.summaryRecord) {
      return ''
    }
    return SummaryService.generateShareText(this.summaryRecord)
  }

  private posterRunId(): string {
    if (this.arenaRunId.length > 0) {
      return this.arenaRunId
    }
    if (this.summaryRecord && this.summaryRecord.arenaRunId && this.summaryRecord.arenaRunId.length > 0) {
      return this.summaryRecord.arenaRunId
    }
    return ''
  }

  private showToast(message: string): void {
    try {
      void promptAction.openToast({ message: message })
    } catch (error) {
      console.error('[SummaryDetailPage] openToast failed:', error)
    }
  }

  private async copyTextToClipboard(text: string, successMessage: string): Promise<boolean> {
    if (text.trim().length === 0) {
      this.showToast('暂无可复制内容')
      return false
    }

    try {
      const board = pasteboard.getSystemPasteboard()
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
      await board.setData(data)
      this.showToast(successMessage)
      return true
    } catch (error) {
      console.error('[SummaryDetailPage] copyTextToClipboard failed:', error)
      this.showToast('复制失败')
      return false
    }
  }

  private openPosterPreview(): void {
    const id = this.posterRunId()
    if (id.length === 0) {
      this.showToast('当前纪要未关联会议 run，无法生成海报')
      return
    }
    router.pushUrl({
      url: 'pages/PosterPreviewPage',
      params: {
        arenaRunId: id,
        title: this.summaryRecord ? this.summaryRecord.title : ''
      }
    })
  }

  private summaryDetailUri(): string {
    return buildSummaryDetailUri(this.summaryId, this.posterRunId())
  }

  private openSummaryQrCode(): void {
    const qrValue = this.summaryDetailUri()
    if (qrValue.length <= 0) {
      this.showToast('当前纪要还不能生成二维码')
      return
    }

    router.pushUrl({
      url: 'pages/QrLinkPage',
      params: {
        title: '分享纪要详情',
        subtitle: '扫码后在另一台设备打开这份纪要',
        qrValue: qrValue
      }
    })
  }

  private async handleExportVideo(): Promise<void> {
    await this.copyTextToClipboard(this.shareText(), '已复制回放文案到剪贴板')
  }

  private async handleExportText(): Promise<void> {
    await this.copyTextToClipboard(this.shareText(), '已复制全文')
  }

  private async handleCopyContent(): Promise<void> {
    await this.copyTextToClipboard(this.shareText(), '已复制纪要全文')
  }

  private async toggleFavorite(): Promise<void> {
    if (!this.summaryRecord || this.arenaRunId.length > 0) {
      this.showToast('云端会议纪要不支持收藏，可导出文本到本地')
      return
    }
    const next = !this.summaryRecord.isFavorite
    this.summaryRecord.isFavorite = next
    const success = await SummaryService.toggleFavorite(this.summaryId, next)
    if (!success) {
      this.summaryRecord.isFavorite = !next
      this.showToast('收藏更新失败')
    } else {
      this.showToast(next ? '已加入收藏' : '已取消收藏')
    }
  }

  /**
   * 握拳保存 - 智感握姿功能
   * 用户握拳时自动保存纪要
   */
  private async handleGestureSave(): Promise<void> {
    if (!this.summaryRecord) {
      this.showToast('暂无可保存的纪要')
      return
    }
    // 保存到本地
    if (this.arenaRunId.length > 0) {
      // 云端纪要：复制文本
      await this.copyTextToClipboard(this.shareText(), '已复制纪要，可粘贴保存')
    } else {
      // 本地纪要：收藏
      await this.toggleFavorite()
    }
    this.showToast('握拳保存成功')
  }

  /**
   * 智能扩写会议纪要
   * 使用 AI 服务自动补全和扩写
   */
  private async expandSummary(): Promise<void> {
    if (!this.summaryRecord || this.isExpanding) {
      return
    }

    this.isExpanding = true
    try {
      const smartService = SmartFillService.getInstance()
      const result = await smartService.fillWithSummary(this.shareText())

      if (result.success) {
        this.expandedSummary = result.content
        this.showExpandedContent = true
        this.showToast('智能扩写完成！')
      } else {
        this.showToast('扩写失败，请重试')
      }
    } catch (err) {
      console.error('[SummaryDetailPage] expandSummary failed:', err)
      this.showToast('扩写失败，请重试')
    } finally {
      this.isExpanding = false
    }
  }

  /**
   * 关闭扩写内容展示
   */
  private closeExpandedContent(): void {
    this.showExpandedContent = false
  }

  /**
   * 复制扩写后的内容
   */
  private async copyExpandedContent(): Promise<void> {
    await this.copyTextToClipboard(this.expandedSummary, '已复制扩写内容')
    this.showExpandedContent = false
  }

  private async deleteSummary(): Promise<void> {
    if (this.arenaRunId.length > 0) {
      this.showToast('云端记录请在后端管理，此处无法删除')
      return
    }
    const success = await SummaryService.deleteSummary(this.summaryId)
    if (success) {
      this.showToast('已删除')
      router.back()
      return
    }
    this.showToast('删除失败')
  }

  private goBack(): void {
    try {
      router.back()
    } catch (_e) {
    }
  }

  private isLocalOnly(): boolean {
    return this.summaryId.length > 0 && this.arenaRunId.length === 0
  }

  private openShareSheet(): void {
    if (!this.summaryRecord) {
      this.showToast('暂无可分享的纪要')
      return
    }
    this.showShareSheet = true
  }

  private closeShareSheet(): void {
    this.showShareSheet = false
  }

  private handleShareToSocial(targetId: string): void {
    this.showShareSheet = false
    if (!this.summaryRecord) return

    // 复制分享文本到剪贴板，用户可以粘贴到社交平台
    const text = SummaryService.generateShareText(this.summaryRecord)
    void this.copyTextToClipboard(text, `已复制纪要文本，可粘贴到${targetId === 'wechat' ? '微信' : targetId === 'xiaohongshu' ? '小红书' : '微博'}`)
  }

  private handleHapShareFallback(): void {
    this.showShareSheet = false
    // NFC 不可用时的降级方案：复制文本
    if (!this.summaryRecord) return
    void this.handleCopyContent()
  }

  private handleDeviceShare(deviceId: string): void {
    this.showShareSheet = false
    if (!this.summaryRecord) {
      this.showToast('暂无可流转的纪要')
      return
    }

    const target = deviceId === 'tablet' ? 'tablet' : 'screen'
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      void ServiceCollaborationService.startSummaryCollaboration(ctx, target, {
        launchAction: 'open-summary-detail',
        summaryId: this.summaryId,
        arenaRunId: this.posterRunId()
      }).then((deviceName: string) => {
        this.showToast(`已流转到${deviceName}`)
      }).catch((error: Error) => {
        console.error('[SummaryDetailPage] startSummaryCollaboration failed:', error)
        this.showToast(error.message && error.message.length > 0 ? error.message : '设备协同失败')
      })
    } catch (error) {
      console.error('[SummaryDetailPage] handleDeviceShare failed:', error)
      this.showToast('当前设备不支持跨设备协同')
    }
  }

  private handleSystemShare(): void {
    this.showShareSheet = false
    if (!this.summaryRecord) return
    // 降级为复制文本
    void this.handleCopyContent()
  }

  private async createReviewReminder(): Promise<void> {
    if (!this.summaryRecord) {
      this.showToast('暂无可提醒的纪要')
      return
    }

    try {
      const ctx = getContext(this) as common.UIAbilityContext
      const reminderId = await CalendarReminderService.publishSummaryReviewReminder(this.summaryRecord, ctx)
      const reminderDate = CalendarReminderService.nextReviewDate(
        this.summaryRecord.updatedAt && this.summaryRecord.updatedAt.length > 0
          ? this.summaryRecord.updatedAt
          : this.summaryRecord.createdAt
      )
      this.showToast(`已创建复盘提醒 · ${CalendarReminderService.formatReviewDate(reminderDate)}`)
      console.info('[SummaryDetailPage] created review reminder:', reminderId)
    } catch (error) {
      console.error('[SummaryDetailPage] createReviewReminder failed:', error)
      this.showToast('创建提醒失败，请检查系统通知权限')
    }
  }

  @Builder
  buildNavBar() {
    Row({ space: Spacing.md }) {
      BackButton({
        iconSize: 22,
        iconColor: MintColors.mintDark,
        bgColor: MintColors.surfaceGlass,
        buttonSize: 44,
        customOnClick: () => this.goBack()
      })
      .translate({ x: -10 })
      .shadow({
        radius: 16,
        color: 'rgba(92, 168, 255, 0.18)',
        offsetX: -2,
        offsetY: 6
      })

      Column({ space: 2 }) {
        Text('纪要详情').fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
        Text('共识 / 分歧 / 行动').fontSize(Typography.size.xs).fontColor(MintColors.textMuted)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => this.goBack())

      Button('复制全文')
        .height(36)
        .padding({ left: 14, right: 14 })
        .fontSize(Typography.size.xs)
        .fontWeight(FontWeight.Medium)
        .fontColor(MintColors.mintDark)
        .backgroundColor(MintColors.surfaceGlass)
        .backdropBlur(40)
        .linearGradient({
          angle: 135,
          colors: [
            [MintColors.cardPrimary, 0],
            ['rgba(255, 255, 255, 0.28)', 1]
          ]
        })
        .border({
          width: 1.5,
          color: 'rgba(255, 255, 255, 0.95)',
          radius: BorderRadius.pill
        })
        .borderRadius(BorderRadius.pill)
        .shadow({
          radius: 16,
          color: 'rgba(92, 168, 255, 0.18)',
          offsetX: -2,
          offsetY: 6
        })
        .onClick(() => {
          void this.handleCopyContent()
        })

      Button('二维码')
        .height(36)
        .padding({ left: 14, right: 14 })
        .fontSize(Typography.size.xs)
        .fontWeight(FontWeight.Medium)
        .fontColor(MintColors.mintDark)
        .backgroundColor(MintColors.surfaceGlass)
        .backdropBlur(40)
        .linearGradient({
          angle: 135,
          colors: [
            [MintColors.cardPrimary, 0],
            ['rgba(255, 255, 255, 0.28)', 1]
          ]
        })
        .border({
          width: 1.5,
          color: 'rgba(255, 255, 255, 0.95)',
          radius: BorderRadius.pill
        })
        .borderRadius(BorderRadius.pill)
        .shadow({
          radius: 16,
          color: 'rgba(92, 168, 255, 0.18)',
          offsetX: -2,
          offsetY: 6
        })
        .onClick(() => this.openSummaryQrCode())

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Text(this.summaryRecord?.isFavorite ? '★' : '☆')
          .fontSize(22)
          .fontColor(this.summaryRecord?.isFavorite ? Colors.warning : MintColors.mintDark)
      }
      .width(36)
      .height(36)
      .backgroundColor(MintColors.surfaceGlass)
      .backdropBlur(40)
      .linearGradient({
        angle: 135,
        colors: [
          [MintColors.cardPrimary, 0],
          ['rgba(255, 255, 255, 0.28)', 1]
        ]
      })
      .border({ width: 1.5, color: 'rgba(255, 255, 255, 0.95)' })
      .shadow({
        radius: 16,
        color: 'rgba(92, 168, 255, 0.18)',
        offsetX: -2,
        offsetY: 6
      })
      .onClick(() => {
        void this.toggleFavorite()
      })
    }
    .width('100%')
    .padding({
      left: this.responsiveLayout().pageHorizontalPadding,
      right: this.responsiveLayout().pageHorizontalPadding,
      top: this.topInsetVp() + 8,
      bottom: Spacing.sm
    })
    .backgroundColor(MintColors.surfaceGlass)
    .backdropBlur(40)
    .linearGradient({
      angle: 180,
      colors: [
        [MintColors.cardPrimary, 0],
        ['rgba(255, 255, 255, 0.28)', 1]
      ]
    })
    .border({
      width: 1.5,
      color: 'rgba(255, 255, 255, 0.95)',
      radius: BorderRadius.xxl2
    })
    .borderRadius(BorderRadius.xxl2)
    .shadow({
      radius: 28,
      color: 'rgba(92, 168, 255, 0.18)',
      offsetX: -4,
      offsetY: 12
    })
  }

  @Builder
  buildHeroCard(record: SummaryRecord) {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.sm }) {
        Text('MEETING NOTE')
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.mintDark)
          .letterSpacing(0.8)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('rgba(230, 244, 255, 0.92)')
          .border({
            width: 1,
            color: 'rgba(216, 232, 247, 0.96)',
            radius: BorderRadius.pill
          })
          .borderRadius(BorderRadius.pill)

        Text('AI 纪要')
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Medium)
          .fontColor('rgba(86, 108, 138, 0.82)')
      }
      .width('100%')

      Text(record.title)
        .fontSize(Typography.size.xxl)
        .fontWeight(FontWeight.Bold)
        .fontColor(MintColors.textPrimary)
        .width('100%')
        .lineHeight(32)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: Spacing.sm }) {
        Text(formatSummaryDate(record.createdAt))
          .fontSize(Typography.size.caption)
          .fontColor('rgba(77, 101, 133, 0.82)')
        if (record.messageCount > 0) {
          Text('·')
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.textMuted)
          Text(`${record.messageCount} 条对话`)
            .fontSize(Typography.size.caption)
            .fontColor('rgba(77, 101, 133, 0.68)')
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('rgba(243, 248, 255, 0.82)')
      .border({
        width: 1,
        color: 'rgba(226, 237, 248, 0.94)',
        radius: BorderRadius.xxl
      })
      .borderRadius(BorderRadius.xxl)

      if (record.participants.length > 0) {
        Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
          ForEach(record.participants.slice(0, 6), (participant: SummaryParticipant, index: number) => {
            Text(`${participant.displayName}`)
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Medium)
              .fontColor(index % 2 === 0 ? MintColors.mintDark : Colors.textSecondary)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(index % 2 === 0 ? 'rgba(228, 244, 255, 0.92)' : 'rgba(235, 241, 255, 0.92)')
              .border({
                width: 1,
                color: index % 2 === 0 ? 'rgba(214, 232, 247, 0.96)' : 'rgba(220, 231, 248, 0.96)',
                radius: BorderRadius.pill
              })
              .borderRadius(BorderRadius.pill)
              .margin({ right: 8, bottom: 8 })
          }, (p: SummaryParticipant, index: number) => p.agentId + '-' + index)
          if (record.participants.length > 6) {
            Text(`+${record.participants.length - 6}`)
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Medium)
              .fontColor('rgba(86, 108, 138, 0.86)')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('rgba(255, 255, 255, 0.7)')
              .border({ width: 1, color: 'rgba(220, 231, 248, 0.96)', radius: BorderRadius.pill })
              .borderRadius(BorderRadius.pill)
              .margin({ right: 8, bottom: 8 })
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ left: Spacing.card.large, right: Spacing.card.large, top: Spacing.card.large, bottom: Spacing.card.large })
    .backgroundColor(MintColors.surfaceGlass)
    .backdropBlur(40)
    .linearGradient({
      angle: 135,
      colors: [
        [MintColors.cardPrimary, 0],
        [MintColors.surfaceGlass, 1]
      ]
    })
    .borderRadius(BorderRadius.xxl3)
    .border({ width: 1.5, color: MintColors.cardPrimary, radius: BorderRadius.xxl3 })
    .shadow({
      radius: 40,
      color: 'rgba(92, 168, 255, 0.28)',
      offsetX: -6,
      offsetY: 16
    })
    .opacity(this.heroOpacity)
    .translate({ y: this.heroTranslateY })
  }

  @Builder
  buildActionToolbar() {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
      Button('生成海报 · 全屏预览抓一抓')
          .layoutWeight(1)
          .height(48)
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
          .border({ width: 1.5, color: MintColors.surfaceGlass, radius: BorderRadius.xxl })
          .shadow({
            radius: 20,
            color: 'rgba(94, 149, 226, 0.4)',
            offsetX: -2,
            offsetY: 8
          })
          .onClick(() => this.openPosterPreview())

        Button('碰一碰')
          .height(48)
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.mintDark)
          .backgroundColor(MintColors.surfaceGlass)
          .backdropBlur(40)
          .linearGradient({
            angle: 135,
            colors: [
              [MintColors.cardPrimary, 0],
              ['rgba(255, 255, 255, 0.28)', 1]
            ]
          })
          .border({
            width: 1.5,
            color: 'rgba(255, 255, 255, 0.95)',
            radius: BorderRadius.xxl
          })
          .borderRadius(BorderRadius.xxl)
          .shadow({
            radius: 16,
            color: 'rgba(92, 168, 255, 0.18)',
            offsetX: -2,
            offsetY: 6
          })
          .onClick(() => this.openShareSheet())
      }
      .width('100%')

      Scroll() {
        Row({ space: Spacing.sm }) {
          this.buildChipAction('复制文本', () => {
            void this.handleExportText()
          })
          this.buildChipAction('视频脚本', () => {
            void this.handleExportVideo()
          })
          this.buildChipAction('二维码', () => {
            this.openSummaryQrCode()
          })
          this.buildChipAction('复盘提醒', () => {
            void this.createReviewReminder()
          })
          this.buildChipAction(this.isExpanding ? '扩写中...' : (this.expandedSummary.length > 0 ? '已扩写' : 'AI 扩写'), () => {
            void this.expandSummary()
          }, false, this.isExpanding || this.expandedSummary.length > 0)
          if (this.isLocalOnly()) {
            this.buildChipAction(this.summaryRecord && this.summaryRecord.isFavorite ? '已收藏' : '收藏', () => {
              void this.toggleFavorite()
            })
            this.buildChipAction('删除', () => {
              void this.deleteSummary()
            }, true)
          }
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.md)
    .backgroundColor(MintColors.surfaceGlass)
    .backdropBlur(40)
    .linearGradient({
      angle: 135,
      colors: [
        [MintColors.cardPrimary, 0],
        [MintColors.surfaceGlass, 1]
      ]
    })
    .border({ width: 1.5, color: MintColors.cardPrimary, radius: BorderRadius.xxl3 })
    .borderRadius(BorderRadius.xxl3)
    .shadow({
      radius: 40,
      color: 'rgba(92, 168, 255, 0.28)',
      offsetX: -6,
      offsetY: 16
    })
    .opacity(this.toolbarOpacity)
    .translate({ y: this.toolbarTranslateY })
  }

  @Builder
  buildChipAction(label: string, onTap: () => void, danger?: boolean, special?: boolean) {
    Button(label)
      .height(38)
      .padding({ left: Spacing.md, right: Spacing.md })
      .fontSize(Typography.size.caption)
      .fontWeight(FontWeight.Medium)
      .fontColor(danger ? MintColors.error : special ? '#FFFFFF' : MintColors.mintDark)
      .backgroundColor(danger ? 'rgba(255, 241, 242, 0.82)' : special ? 'rgba(94, 149, 226, 0.85)' : MintColors.surfaceGlass)
      .backdropBlur(40)
      .linearGradient({
        angle: 135,
        colors: danger ? [
          [MintColors.surfaceGlass, 0],
          ['rgba(255, 231, 234, 0.42)', 1]
        ] : special ? [
          ['rgba(140, 195, 255, 0.95)', 0],
          ['rgba(94, 149, 226, 0.78)', 1]
        ] : [
          [MintColors.cardPrimary, 0],
          ['rgba(255, 255, 255, 0.28)', 1]
        ]
      })
      .borderRadius(BorderRadius.pill)
      .border({
        width: 1.5,
        color: danger ? 'rgba(236, 196, 202, 0.8)' : special ? 'rgba(255, 255, 255, 0.55)' : MintColors.cardPrimary,
        radius: BorderRadius.pill
      })
      .shadow({
        radius: 16,
        color: danger ? 'rgba(239, 115, 128, 0.08)' : special ? 'rgba(92, 168, 255, 0.16)' : 'rgba(92, 168, 255, 0.18)',
        offsetX: -2,
        offsetY: 6
      })
      .onClick(onTap)
  }

  @Builder
  buildDetailCard(titleCn: string, content: string) {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
        Text(titleCn)
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.mintDark)
          .letterSpacing(0.5)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('rgba(230, 244, 255, 0.92)')
          .border({
            width: 1,
            color: 'rgba(216, 232, 247, 0.96)',
            radius: BorderRadius.pill
          })
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')

      Text(content.length > 0 ? content : '暂无')
        .fontSize(Typography.size.body)
        .fontColor(content.length > 0 ? MintColors.textPrimary : MintColors.textMuted)
        .lineHeight(Typography.lineHeight.relaxed)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor(MintColors.surfaceGlass)
    .backdropBlur(40)
    .linearGradient({
      angle: 135,
      colors: [
        [MintColors.cardPrimary, 0],
        ['rgba(255, 255, 255, 0.28)', 1]
      ]
    })
    .borderRadius(BorderRadius.xxl2)
    .border({ width: 1.5, color: MintColors.cardPrimary, radius: BorderRadius.xxl2 })
    .shadow({
      radius: 40,
      color: 'rgba(92, 168, 255, 0.28)',
      offsetX: -6,
      offsetY: 16
    })
  }


  @Builder
  buildBulletCard(titleCn: string, items: string[]) {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
        Text(titleCn)
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.lavenderDark)
          .letterSpacing(0.5)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('rgba(235, 241, 255, 0.94)')
          .border({
            width: 1,
            color: 'rgba(221, 231, 247, 0.98)',
            radius: BorderRadius.pill
          })
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')

      if (items.length === 0) {
        Text('暂无')
          .fontSize(Typography.size.body)
          .fontColor(MintColors.textMuted)
          .width('100%')
      } else {
        Column({ space: Spacing.sm }) {
          ForEach(items, (line: string, idx: number) => {
            Row({ space: Spacing.sm }) {
              Column()
                .width(8)
                .height(8)
                .borderRadius(4)
                .margin({ top: 7 })
                .backgroundColor(titleCn === '行动建议' ? '#7AADEF' : 'rgba(110, 135, 176, 0.62)')
              Text(line)
                .fontSize(Typography.size.body)
                .fontColor(MintColors.textPrimary)
                .lineHeight(Typography.lineHeight.relaxed)
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }, (line: string, idx: number) => `${titleCn}-${idx}-${line.length}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor(MintColors.surfaceGlass)
    .backdropBlur(40)
    .linearGradient({
      angle: 135,
      colors: [
        [MintColors.cardPrimary, 0],
        ['rgba(255, 255, 255, 0.28)', 1]
      ]
    })
    .borderRadius(BorderRadius.xxl2)
    .border({ width: 1.5, color: MintColors.cardPrimary, radius: BorderRadius.xxl2 })
    .shadow({
      radius: 40,
      color: 'rgba(92, 168, 255, 0.28)',
      offsetX: -6,
      offsetY: 16
    })
  }

  @Builder
  buildBody(record: SummaryRecord) {
    Column() {
      if (this.responsiveLayout().useSplitSummaryLayout) {
        Row({ space: this.responsiveLayout().splitPanelGap }) {
          Column({ space: Spacing.md }) {
            this.buildDetailCard('议题', record.topic)
            this.buildDetailCard('共识', record.consensus)
            this.buildBulletCard('分歧', record.disagreements)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: Spacing.md }) {
            this.buildBulletCard('行动建议', record.actionableAdvice)
            if (record.narrativeHook.length > 0) {
              this.buildDetailCard('一句总结', record.narrativeHook)
            }
            if (record.moderatorNote && record.moderatorNote.length > 0) {
              this.buildDetailCard('主持人备注', record.moderatorNote)
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        Column({ space: Spacing.md }) {
          this.buildDetailCard('议题', record.topic)
          this.buildDetailCard('共识', record.consensus)
          this.buildBulletCard('分歧', record.disagreements)
          this.buildBulletCard('行动建议', record.actionableAdvice)
          if (record.narrativeHook.length > 0) {
            this.buildDetailCard('一句总结', record.narrativeHook)
          }
          if (record.moderatorNote && record.moderatorNote.length > 0) {
            this.buildDetailCard('主持人备注', record.moderatorNote)
          }
        }
      }
    }
    .width('100%')
    .opacity(this.bodyOpacity)
    .translate({ y: this.bodyTranslateY })
  }

  @Builder
  buildLoadingState() {
    Column() {
      Column({ space: Spacing.lg }) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color(MintColors.mintDark)
          .opacity(this.loadingPulse)
        Text('正在加载纪要…')
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.textSecondary)
      }
      .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.xl, bottom: Spacing.xl })
      .backgroundColor(MintColors.surfaceGlass)
      .backdropBlur(40)
      .linearGradient({
        angle: 135,
        colors: [
          [MintColors.cardPrimary, 0],
          ['rgba(255, 255, 255, 0.28)', 1]
        ]
      })
      .border({
        width: 1.5,
        color: MintColors.cardPrimary,
        radius: BorderRadius.xxl3
      })
      .borderRadius(BorderRadius.xxl3)
      .shadow({
        radius: 40,
        color: 'rgba(92, 168, 255, 0.28)',
        offsetX: -6,
        offsetY: 16
      })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      DynamicGlassBackground()

      Column() {
        this.buildNavBar()

        if (this.isLoading) {
          this.buildLoadingState()
        } else if (this.error.length > 0) {
          Column() {
            Column({ space: Spacing.lg }) {
              Text(this.error)
                .fontSize(Typography.size.body)
                .fontColor(MintColors.error)
                .textAlign(TextAlign.Center)
                .width('100%')
              Button('重试')
                .height(44)
                .padding({ left: Spacing.xl, right: Spacing.xl })
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
                  void this.loadSummaryDetail()
                })
            }
            .width('100%')
            .padding({ left: Spacing.xl, right: Spacing.xl, top: Spacing.xl, bottom: Spacing.xl })
            .backgroundColor(MintColors.surfaceGlass)
            .backdropBlur(40)
            .linearGradient({
              angle: 135,
              colors: [
                [MintColors.cardPrimary, 0],
                ['rgba(255, 255, 255, 0.28)', 1]
              ]
            })
            .border({
              width: 1.5,
              color: MintColors.cardPrimary,
              radius: BorderRadius.xxl3
            })
            .borderRadius(BorderRadius.xxl3)
            .shadow({
              radius: 40,
              color: 'rgba(92, 168, 255, 0.28)',
              offsetX: -6,
              offsetY: 16
            })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding({ left: this.responsiveLayout().pageHorizontalPadding, right: this.responsiveLayout().pageHorizontalPadding })
        } else if (this.summaryRecord) {
          Scroll() {
            Column({ space: Spacing.lg }) {
              this.buildHeroCard(this.summaryRecord)
              if (this.responsiveLayout().useSplitSummaryLayout) {
                Row({ space: this.responsiveLayout().splitPanelGap }) {
                  Column() {
                    this.buildBody(this.summaryRecord)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Column() {
                    this.buildActionToolbar()
                  }
                  .width('32%')
                  .constraintSize({ minWidth: 260, maxWidth: 360 })
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              } else {
                this.buildActionToolbar()
                this.buildBody(this.summaryRecord)
              }
            }
            .width('100%')
            .constraintSize({ maxWidth: this.responsiveLayout().contentMaxWidth })
            .padding({
              left: this.responsiveLayout().pageHorizontalPadding,
              right: this.responsiveLayout().pageHorizontalPadding,
              top: Spacing.sm,
              bottom: this.safeBottomVp + Spacing.xl
            })
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%')
      .height('100%')

      if (this.showShareSheet && this.summaryRecord) {
        ShareSheet({
          isVisible: this.showShareSheet,
          shareData: SummaryService.generateShareData(this.summaryRecord),
          hapShareData: SummaryService.generateHapShareData(this.summaryRecord),
          onClose: () => this.closeShareSheet(),
          onShareToSocial: (targetId: string) => this.handleShareToSocial(targetId),
          onHapShare: () => this.handleHapShareFallback(),
          onDeviceShare: (deviceId: string) => this.handleDeviceShare(deviceId),
          onSystemShare: () => this.handleSystemShare(),
          onCopyLink: () => this.handleCopyContent()
        })
      }

      // AI 扩写内容弹窗
      if (this.showExpandedContent) {
        this.buildExpandedContentModal()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MintColors.background)
  }

  /**
   * 扩写内容弹窗
   */
  @Builder
  buildExpandedContentModal() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => this.closeExpandedContent())

      // 内容卡片
      Column({ space: Spacing.md }) {
        Row({ space: Spacing.sm }) {
          Text('AI 智能扩写')
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Blank()

          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Text('✕')
              .fontSize(18)
              .fontColor(MintColors.textSecondary)
          }
          .width(36)
          .height(36)
          .backgroundColor(MintColors.surfaceGlass)
          .backdropBlur(40)
          .linearGradient({
            angle: 135,
            colors: [
              [MintColors.cardPrimary, 0],
              ['rgba(255, 255, 255, 0.28)', 1]
            ]
          })
          .border({ width: 1.5, color: MintColors.cardPrimary })
          .shadow({ radius: 16, color: 'rgba(92, 168, 255, 0.18)', offsetX: -2, offsetY: 6 })
          .onClick(() => this.closeExpandedContent())
        }
        .width('100%')

        Scroll() {
          Text(this.expandedSummary)
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textPrimary)
            .lineHeight(Typography.lineHeight.relaxed)
            .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        Row({ space: Spacing.sm }) {
          Button('关闭')
            .layoutWeight(1).height(44)
            .fontColor(MintColors.mintDark)
            .backgroundColor(MintColors.surfaceGlass)
            .backdropBlur(40)
            .linearGradient({
              angle: 135,
              colors: [
                [MintColors.cardPrimary, 0],
                ['rgba(255, 255, 255, 0.28)', 1]
              ]
            })
            .border({ width: 1.5, color: MintColors.cardPrimary, radius: BorderRadius.xxl })
            .borderRadius(BorderRadius.xxl)
            .shadow({ radius: 16, color: 'rgba(92, 168, 255, 0.18)', offsetX: -2, offsetY: 6 })
            .onClick(() => this.closeExpandedContent())

          Button('复制全文')
            .layoutWeight(1).height(44)
            .fontColor(Colors.textInverse)
            .linearGradient({
              angle: 135,
              colors: [
                ['#79B8F9', 0],
                ['#5E95E2', 1]
              ]
            })
            .borderRadius(BorderRadius.xxl)
            .border({ width: 1.5, color: MintColors.surfaceGlass, radius: BorderRadius.xxl })
            .shadow({ radius: 20, color: 'rgba(94, 149, 226, 0.4)', offsetX: -2, offsetY: 8 })
            .onClick(() => void this.copyExpandedContent())
        }
        .width('100%')
      }
      .width('90%')
      .constraintSize({ maxHeight: '70%' })
      .padding(Spacing.lg)
      .backgroundColor(MintColors.surfaceGlass)
      .backdropBlur(40)
      .linearGradient({
        angle: 135,
        colors: [
          [MintColors.cardPrimary, 0],
          ['rgba(255, 255, 255, 0.28)', 1]
        ]
      })
      .border({
        width: 1.5,
        color: MintColors.cardPrimary,
        radius: BorderRadius.xxl2
      })
      .borderRadius(BorderRadius.xxl2)
      .shadow({
        radius: 40,
        color: 'rgba(92, 168, 255, 0.28)',
        offsetX: -6,
        offsetY: 16
      })
    }
    .width('100%')
    .height('100%')
    .zIndex(1000)
  }
}
