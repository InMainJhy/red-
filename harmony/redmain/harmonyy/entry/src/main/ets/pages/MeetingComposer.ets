import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { PersonaSpec, ProfileBundle, RouteParams, TimelineNode } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import {
  buildMeetingRouteParams,
  MAX_MEETING_PARTICIPANTS,
  parseMeetingSelection
} from '../common/MeetingSelection'
import { PersonaApi } from '../service/PersonaApi'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'

const FALLBACK_SAFE_TOP_VP: number = 52

@Entry
@Component
struct MeetingComposer {
  @State bundles: ProfileBundle[] = []
  @State selectedAgentIds: string[] = []
  @State focusedAgentId: string = ''
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0
  @State isLoading: boolean = false
  @State noticeMessage: string = ''

  aboutToAppear(): void {
    this.loadSafeInsets()
    void this.loadMeetingBundles()
  }

  loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
        this.safeBottomVp = insets.bottomVp
      })
    } catch (_error) {
      // Ignore and use fallback safe area.
    }
  }

  topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  async loadMeetingBundles(): Promise<void> {
    const params = router.getParams() as RouteParams
    const selection = parseMeetingSelection(params)
    this.selectedAgentIds = selection.selectedAgentIds
    this.noticeMessage = ''

    if (selection.profileIds.length === 0) {
      this.bundles = []
      this.focusedAgentId = ''
      return
    }

    this.isLoading = true
    let loadedBundles: ProfileBundle[] = []

    for (let index = 0; index < selection.profileIds.length; index++) {
      const profileId = selection.profileIds[index]
      try {
        const bundle = await PersonaApi.getProfileBundle(profileId)
        loadedBundles = [...loadedBundles, bundle]
      } catch (_error) {
        this.noticeMessage = '部分角色暂时无法加载，会议编排页仅保留了成功读取的角色内容。'
      }
    }

    this.bundles = loadedBundles
    this.selectedAgentIds = this.selectedAgentIds.filter((agentId: string) => this.findAgentByIdFromBundles(loadedBundles, agentId) !== null)

    if (this.focusedAgentId.length === 0 || this.findAgentById(this.focusedAgentId) === null) {
      if (this.selectedAgentIds.length > 0) {
        this.focusedAgentId = this.selectedAgentIds[0]
      } else if (loadedBundles.length > 0 && loadedBundles[0].agents.length > 0) {
        this.focusedAgentId = loadedBundles[0].agents[0].agentId
      } else {
        this.focusedAgentId = ''
      }
    }

    this.isLoading = false
  }

  currentProfileIds(): string[] {
    return this.bundles.map((bundle: ProfileBundle) => bundle.profile.id)
  }

  selectedAgentIdForProfile(profileId: string): string {
    for (let index = 0; index < this.selectedAgentIds.length; index++) {
      const agentId = this.selectedAgentIds[index]
      const agent = this.findAgentById(agentId)
      if (agent && agent.personId === profileId) {
        return agentId
      }
    }
    return ''
  }

  hasSelectedAgentForProfile(profileId: string): boolean {
    return this.selectedAgentIdForProfile(profileId).length > 0
  }

  selectedAgentForProfile(profileId: string): PersonaSpec | null {
    const agentId = this.selectedAgentIdForProfile(profileId)
    if (agentId.length === 0) {
      return null
    }
    return this.findAgentById(agentId)
  }

  findAgentById(agentId: string): PersonaSpec | null {
    return this.findAgentByIdFromBundles(this.bundles, agentId)
  }

  findAgentByIdFromBundles(bundles: ProfileBundle[], agentId: string): PersonaSpec | null {
    for (let bundleIndex = 0; bundleIndex < bundles.length; bundleIndex++) {
      const bundle = bundles[bundleIndex]
      for (let agentIndex = 0; agentIndex < bundle.agents.length; agentIndex++) {
        const agent = bundle.agents[agentIndex]
        if (agent.agentId === agentId) {
          return agent
        }
      }
    }
    return null
  }

  findNodeByAgentId(agentId: string): TimelineNode | null {
    for (let bundleIndex = 0; bundleIndex < this.bundles.length; bundleIndex++) {
      const bundle = this.bundles[bundleIndex]
      for (let agentIndex = 0; agentIndex < bundle.agents.length; agentIndex++) {
        const agent = bundle.agents[agentIndex]
        if (agent.agentId === agentId) {
          return bundle.nodes[agentIndex] ? bundle.nodes[agentIndex] : null
        }
      }
    }
    return null
  }

  isSelected(agentId: string): boolean {
    return this.selectedAgentIds.includes(agentId)
  }

  openAgent(agentId: string): void {
    this.focusedAgentId = agentId
  }

  toggleAgentFocus(agentId: string): void {
    this.focusedAgentId = this.focusedAgentId === agentId ? '' : agentId
  }

  toggleSelectedAgent(agent: PersonaSpec): void {
    this.noticeMessage = ''
    const selectedAgentId = this.selectedAgentIdForProfile(agent.personId)
    const nextSelected = this.selectedAgentIds.filter((item: string) => {
      const selectedAgent = this.findAgentById(item)
      if (!selectedAgent) {
        return true
      }
      return selectedAgent.personId !== agent.personId
    })

    this.focusedAgentId = agent.agentId

    if (selectedAgentId === agent.agentId) {
      this.selectedAgentIds = nextSelected
      return
    }

    this.selectedAgentIds = [...nextSelected, agent.agentId]
  }

  removeProfile(profileId: string): void {
    this.noticeMessage = ''
    this.bundles = this.bundles.filter((bundle: ProfileBundle) => bundle.profile.id !== profileId)
    this.selectedAgentIds = this.selectedAgentIds.filter((agentId: string) => {
      const agent = this.findAgentById(agentId)
      return agent ? agent.personId !== profileId : false
    })

    const focusedAgent = this.findAgentById(this.focusedAgentId)
    if (!focusedAgent || focusedAgent.personId === profileId) {
      if (this.selectedAgentIds.length > 0) {
        this.focusedAgentId = this.selectedAgentIds[0]
      } else if (this.bundles.length > 0 && this.bundles[0].agents.length > 0) {
        this.focusedAgentId = this.bundles[0].agents[0].agentId
      } else {
        this.focusedAgentId = ''
      }
    }
  }

  canConfirm(): boolean {
    return this.bundles.length >= 2 && this.selectedAgentIds.length === this.bundles.length
  }

  canQuickStart(): boolean {
    return this.bundles.length >= 2
  }

  quickStart(): void {
    if (this.bundles.length < 2) {
      this.noticeMessage = '至少需要 2 位角色，才能开始会议。'
      return
    }

    let agentIds = this.selectedAgentIds.slice()
    this.bundles.forEach((bundle: ProfileBundle) => {
      const hasSelected = this.hasSelectedAgentForProfile(bundle.profile.id)
      if (!hasSelected && bundle.agents.length > 0) {
        agentIds.push(bundle.agents[0].agentId)
      }
    })

    router.pushUrl({
      url: 'pages/Arena',
      params: buildMeetingRouteParams({
        profileIds: this.currentProfileIds(),
        selectedAgentIds: agentIds
      })
    })
  }

  goPickMoreRoles(): void {
    if (this.bundles.length >= MAX_MEETING_PARTICIPANTS) {
      this.noticeMessage = `当前会议最多容纳 ${MAX_MEETING_PARTICIPANTS} 位角色，请先替换现有角色。`
      return
    }

    router.pushUrl({
      url: 'pages/ExplorePersonas',
      params: buildMeetingRouteParams({
        profileIds: this.currentProfileIds(),
        selectedAgentIds: this.selectedAgentIds
      })
    })
  }

  confirmSelection(): void {
    if (!this.canConfirm()) {
      this.noticeMessage = '请先为每位角色各锁定一个发言人格，再开始会议。'
      return
    }

    router.pushUrl({
      url: 'pages/Arena',
      params: buildMeetingRouteParams({
        profileIds: this.currentProfileIds(),
        selectedAgentIds: this.selectedAgentIds
      })
    })
  }

  selectedCount(): number {
    return this.selectedAgentIds.length
  }

  remainingSelectionCount(): number {
    return Math.max(this.bundles.length - this.selectedCount(), 0)
  }

  totalTimelineNodes(): number {
    let total = 0
    this.bundles.forEach((bundle: ProfileBundle) => {
      total += bundle.nodes.length
    })
    return total
  }

  meetingStatusTitle(): string {
    if (this.bundles.length === 0) {
      return '先添加角色，会议内容才会丰富起来'
    }
    if (this.bundles.length < 2) {
      return '还需要至少 2 位角色，才能开始会议'
    }
    if (this.canConfirm()) {
      return '会议角色已经准备就绪'
    }
    return `还差 ${this.remainingSelectionCount()} 位角色未锁定发言人格`
  }

  meetingStatusDescription(): string {
    if (this.bundles.length === 0) {
      return '从角色页加入 2 到 3 位角色，再从各自的人生阶段中挑选最适合发言的版本。'
    }
    if (this.bundles.length < 2) {
      return '你已经有了初步阵容，继续补充角色之后，讨论会更有对照和张力。'
    }
    if (this.canConfirm()) {
      return '每位角色都已经选定发言人格，现在可以直接进入会议开始讨论。'
    }
    return '继续浏览下方时间线，为每位角色选择一个最能代表当前立场和情绪的阶段人格。'
  }

  primaryActionLabel(): string {
    if (this.canConfirm()) {
      return `开始 ${this.selectedCount()} 人会议`
    }
    if (this.bundles.length < 2) {
      return '至少 2 位角色后可开始'
    }
    return '为每位角色锁定发言人格'
  }

  primaryValue(agent: PersonaSpec): string {
    return agent.values.length > 0 ? agent.values[0] : '尚未提炼核心价值'
  }

  agentHeadline(agent: PersonaSpec): string {
    const parts: string[] = []
    if (agent.timeLabel.length > 0) {
      parts.push(agent.timeLabel)
    }
    if (agent.stageLabel.length > 0) {
      parts.push(agent.stageLabel)
    }
    parts.push(this.primaryValue(agent))
    return parts.join(' / ')
  }

  profileSelectionHint(bundle: ProfileBundle): string {
    if (this.hasSelectedAgentForProfile(bundle.profile.id)) {
      return '发言人格已锁定，你可以继续展开时间线，对比其他阶段再决定是否替换。'
    }
    return `请从 ${bundle.nodes.length} 个关键阶段中，挑一个最适合代表 Ta 参与会议的发言人格。`
  }

  isFocusedAgent(agentId: string): boolean {
    return this.focusedAgentId === agentId
  }

  rosterChipLabel(bundle: ProfileBundle): string {
    const selectedAgent = this.selectedAgentForProfile(bundle.profile.id)
    if (!selectedAgent) {
      return '待选择发言人格'
    }
    const previewNode = this.findNodeByAgentId(selectedAgent.agentId)
    return `${previewNode ? previewNode.stageLabel : selectedAgent.stageLabel} / ${this.primaryValue(selectedAgent)}`
  }

  getStageColor(stageType: string): string {
    const colors: Record<string, string> = {
      'early': MintColors.stage.early,
      'turning-point': MintColors.stage.turningPoint,
      'stable': MintColors.mintDark,
      'crisis': MintColors.stage.crisis,
      'rebuild': MintColors.stage.rebuild,
      'peak': MintColors.stage.peak
    }
    return colors[stageType] || MintColors.stage.default
  }

  getStageTint(stageType: string): string {
    const tints: Record<string, string> = {
      'early': 'rgba(78, 205, 196, 0.12)',
      'turning-point': 'rgba(61, 189, 156, 0.12)',
      'stable': 'rgba(78, 205, 196, 0.10)',
      'crisis': 'rgba(224, 120, 128, 0.12)',
      'rebuild': 'rgba(184, 169, 217, 0.16)',
      'peak': 'rgba(232, 184, 109, 0.14)'
    }
    return tints[stageType] || 'rgba(143, 165, 176, 0.12)'
  }

  meetingReadinessRatio(): number {
    if (this.bundles.length === 0) {
      return 0
    }
    return Math.min(this.selectedCount() / this.bundles.length, 1)
  }

  meetingProgressWidth(): string {
    const percent = this.bundles.length === 0
      ? 18
      : Math.max(Math.round(this.meetingReadinessRatio() * 100), 18)
    return `${Math.min(percent, 100)}%`
  }

  topStatusLabel(): string {
    if (this.isLoading) {
      return '正在整理角色资料'
    }
    if (this.canConfirm()) {
      return '阵容完成，可以直接开始会议'
    }
    if (this.bundles.length === 0) {
      return '等待加入会议角色'
    }
    if (this.bundles.length < 2) {
      return '至少还需要 1 位角色'
    }
    return `已锁定 ${this.selectedCount()}/${this.bundles.length} 位发言人格`
  }

  topStatusCounter(): string {
    if (this.bundles.length === 0) {
      return `0/${MAX_MEETING_PARTICIPANTS}`
    }
    return `${this.selectedCount()}/${this.bundles.length}`
  }

  topStatusCaption(): string {
    if (this.canConfirm()) {
      return '已就绪'
    }
    if (this.bundles.length < 2) {
      return '待补齐'
    }
    return '已锁定'
  }

  rosterSummaryText(): string {
    if (this.bundles.length === 0) {
      return '先加入角色，下面的阵容概览就会开始工作。'
    }
    if (this.canConfirm()) {
      return '阵容已经齐整，继续向下检查各阶段卡片后就能开始会议。'
    }
    return '左右滑动查看当前阵容，优先补齐还未锁定发言人格的角色。'
  }

  profileStageSummary(bundle: ProfileBundle): string {
    return `${bundle.nodes.length} 个阶段候选`
  }

  focusActionLabel(bundle: ProfileBundle): string {
    if (this.hasSelectedAgentForProfile(bundle.profile.id)) {
      return '查看已选'
    }
    return '浏览阶段'
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(MintColors.background)

        Column()
          .width(360)
          .height(260)
          .borderRadius(180)
          .backgroundColor('rgba(78, 205, 196, 0.12)')
          .blur(118)
          .position({ x: -140, y: -86 })

        Column()
          .width(310)
          .height(220)
          .borderRadius(155)
          .backgroundColor('rgba(184, 169, 217, 0.12)')
          .blur(96)
          .position({ right: -84, y: -12 })

        Column()
          .width(240)
          .height(180)
          .borderRadius(120)
          .backgroundColor('rgba(232, 184, 109, 0.10)')
          .blur(78)
          .position({ x: 92, y: 256 })

        Column()
          .width(180)
          .height(180)
          .borderRadius(90)
          .backgroundColor('rgba(61, 189, 156, 0.08)')
          .blur(70)
          .position({ right: -36, y: 520 })
      }
      .width('100%')
      .height('100%')

      Scroll() {
        Column({ space: Spacing.lg }) {
          this.buildHeaderPanel()

          if (this.isLoading) {
            this.buildLoadingPanel()
          } else if (this.bundles.length === 0) {
            this.buildEmptyPanel()
          } else {
            this.buildRosterPanel()
            ForEach(this.bundles, (bundle: ProfileBundle, bundleIndex: number) => {
              this.buildProfileTimeline(bundle, bundleIndex)
            }, (bundle: ProfileBundle) => bundle.profile.id)
          }
        }
        .padding({
          left: Spacing.page.horizontal,
          right: Spacing.page.horizontal,
          top: this.topInsetVp() + 86,
          bottom: this.safeBottomVp + Spacing.giant
        })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      this.buildFloatingTopBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MintColors.background)
  }

  @Builder
  buildFloatingTopBar() {
    Column() {
      Row({ space: Spacing.md }) {
        Button() {
          Text('<')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.mintDark)
        }
        .width(42)
        .height(42)
        .backgroundColor('rgba(255, 255, 255, 0.96)')
        .borderRadius(21)
        .border({
          width: 0.5,
          color: MintColors.border,
          radius: 21
        })
        .shadow({
          radius: 12,
          color: 'rgba(78, 205, 196, 0.10)',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          router.back()
        })

        Column({ space: 2 }) {
          Text('会议编排')
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.textPrimary)

          Text(this.topStatusLabel())
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 2 }) {
          Text(this.topStatusCounter())
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.canConfirm() ? MintColors.mintDark : MintColors.textPrimary)

          Text(this.topStatusCaption())
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.textMuted)
        }
        .padding({
          left: Spacing.md,
          right: Spacing.md,
          top: Spacing.sm,
          bottom: Spacing.sm
        })
        .backgroundColor(this.canConfirm() ? MintColors.mintBg : 'rgba(255, 255, 255, 0.82)')
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 0.5,
          color: this.canConfirm() ? MintColors.mint : MintColors.borderLight,
          radius: BorderRadius.xxl
        })
      }
      .width('100%')
      .padding({
        left: Spacing.md,
        right: Spacing.md,
        top: Spacing.sm,
        bottom: Spacing.sm
      })
      .backgroundColor('rgba(255, 255, 255, 0.74)')
      .borderRadius(BorderRadius.huge)
      .border({
        width: 0.5,
        color: 'rgba(255, 255, 255, 0.82)',
        radius: BorderRadius.huge
      })
      .backdropBlur(30)
      .shadow({
        radius: 18,
        color: 'rgba(78, 205, 196, 0.10)',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .padding({
      left: Spacing.page.horizontal,
      right: Spacing.page.horizontal,
      top: this.topInsetVp() + 10
    })
  }

  @Builder
  buildHeroMetric(
    label: string,
    value: string,
    hint: string,
    backgroundColor: string,
    valueColor: string
  ) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(Typography.size.xs)
        .fontColor(MintColors.textSecondary)
        .fontWeight(FontWeight.Medium)
        .letterSpacing(1.5)

      Text(value)
        .fontSize(Typography.size.xl)
        .fontWeight(FontWeight.Bold)
        .fontColor(valueColor)

      Text(hint)
        .fontSize(Typography.size.xs)
        .fontColor(MintColors.textSecondary)
        .maxLines(2)
        .lineHeight(18)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.md)
    .backgroundColor(backgroundColor)
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 0.5,
      color: MintColors.borderLight,
      radius: BorderRadius.xxl
    })
    .backdropBlur(18)
    .shadow({
      radius: 10,
      color: 'rgba(78, 205, 196, 0.05)',
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  buildMeetingProgressBar() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(8)
        .backgroundColor('rgba(255, 255, 255, 0.62)')
        .borderRadius(BorderRadius.pill)

      Column()
        .width(this.meetingProgressWidth())
        .height(8)
        .borderRadius(BorderRadius.pill)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [
            ['rgba(78, 205, 196, 0.96)', 0],
            ['rgba(61, 189, 156, 0.94)', 0.58],
            ['rgba(184, 169, 217, 0.92)', 1]
          ]
        })
    }
    .width('100%')
  }

  @Builder
  buildStatusPill(label: string, textColor: string, backgroundColor: string, borderColor: string) {
    Text(label)
      .fontSize(Typography.size.xs)
      .fontColor(textColor)
      .padding({
        left: Spacing.sm,
        right: Spacing.sm,
        top: 5,
        bottom: 5
      })
      .backgroundColor(backgroundColor)
      .borderRadius(BorderRadius.pill)
      .border({
        width: 0.5,
        color: borderColor,
        radius: BorderRadius.pill
      })
  }

  @Builder
  buildHeaderPanel() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(150)
        .height(150)
        .borderRadius(75)
        .backgroundColor('rgba(78, 205, 196, 0.12)')
        .blur(42)
        .position({ right: -12, y: -20 })

      Column()
        .width(108)
        .height(108)
        .borderRadius(54)
        .backgroundColor('rgba(184, 169, 217, 0.16)')
        .blur(34)
        .position({ right: 84, y: 138 })

      Column({ space: Spacing.lg }) {
        Row({ space: Spacing.md }) {
          Column({ space: Spacing.sm }) {
            this.buildStatusPill('MEETING WORKBENCH', MintColors.mintDark, MintColors.mintBg, 'rgba(78, 205, 196, 0.16)')

            Text('会议编排')
              .fontSize(Typography.size.hero)
              .fontWeight(FontWeight.Bold)
              .fontColor(MintColors.textPrimary)

            Text('把角色的人生阶段铺开对比，为每位角色锁定一个最适合上桌发言的人格版本，再带着阵容进入会议。')
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textSecondary)
              .lineHeight(Typography.lineHeight.relaxed)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 4 }) {
            Text('准备度')
              .fontSize(Typography.size.xs)
              .fontColor(MintColors.textMuted)
              .letterSpacing(1.5)

            Text(`${Math.round(this.meetingReadinessRatio() * 100)}%`)
              .fontSize(Typography.size.xxl)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.canConfirm() ? MintColors.mintDark : MintColors.textPrimary)

            Text(this.canConfirm() ? '已可直接进入会议' : '锁定完毕后即可开始')
              .fontSize(Typography.size.xs)
              .fontColor(MintColors.textSecondary)
              .lineHeight(18)
          }
          .padding(Spacing.md)
          .backgroundColor('rgba(255, 255, 255, 0.78)')
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 0.5,
            color: MintColors.borderLight,
            radius: BorderRadius.xxl
          })
          .backdropBlur(18)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Column({ space: Spacing.sm }) {
          Row({ space: Spacing.sm }) {
            Text(this.meetingStatusTitle())
              .layoutWeight(1)
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Medium)
              .fontColor(MintColors.textPrimary)

            this.buildStatusPill(
              this.canConfirm() ? 'READY' : (this.bundles.length < 2 ? 'SETUP' : 'IN PROGRESS'),
              this.canConfirm() ? MintColors.mintDark : MintColors.textSecondary,
              this.canConfirm() ? MintColors.mintBg : 'rgba(255, 255, 255, 0.70)',
              this.canConfirm() ? MintColors.mint : MintColors.borderLight
            )
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.meetingStatusDescription())
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)

          this.buildMeetingProgressBar()

          Row({ space: Spacing.sm }) {
            this.buildStatusPill('建议 2-3 位角色', MintColors.mintDark, MintColors.mintBg, 'rgba(78, 205, 196, 0.16)')
            this.buildStatusPill(`已锁定 ${this.selectedCount()} 位`, MintColors.lavenderDark, MintColors.lavenderPale, 'rgba(184, 169, 217, 0.20)')
            this.buildStatusPill(`共 ${this.totalTimelineNodes()} 个阶段`, '#B88632', 'rgba(232, 184, 109, 0.14)', 'rgba(232, 184, 109, 0.24)')
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(Spacing.lg)
        .backgroundColor('rgba(255, 255, 255, 0.76)')
        .borderRadius(BorderRadius.xxl3)
        .border({
          width: 0.5,
          color: 'rgba(255, 255, 255, 0.80)',
          radius: BorderRadius.xxl3
        })
        .backdropBlur(20)

        Row({ space: Spacing.sm }) {
          this.buildHeroMetric(
            '角色数',
            `${this.bundles.length}/${MAX_MEETING_PARTICIPANTS}`,
            this.bundles.length === 0 ? '建议至少 2 位角色' : '当前会议阵容',
            'rgba(78, 205, 196, 0.10)',
            MintColors.mintDark
          )
          this.buildHeroMetric(
            '已锁定',
            `${this.selectedCount()}`,
            this.bundles.length === 0 ? '等待开始选择' : `还差 ${this.remainingSelectionCount()} 位`,
            'rgba(184, 169, 217, 0.14)',
            MintColors.lavenderDark
          )
          this.buildHeroMetric(
            '时间节点',
            `${this.totalTimelineNodes()}`,
            this.bundles.length === 0 ? '角色加入后生成' : '可切换查看阶段人格',
            'rgba(232, 184, 109, 0.14)',
            '#B88632'
          )
        }
        .width('100%')

        Column({ space: Spacing.sm }) {
          Row({ space: Spacing.sm }) {
            Button(this.bundles.length >= MAX_MEETING_PARTICIPANTS ? '阵容已满' : '继续添加角色')
              .layoutWeight(1)
              .height(46)
              .fontSize(Typography.size.body)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.bundles.length >= MAX_MEETING_PARTICIPANTS ? MintColors.textMuted : MintColors.mintDark)
              .backgroundColor('rgba(255, 255, 255, 0.92)')
              .borderRadius(BorderRadius.xxl)
              .border({
                width: 0.5,
                color: MintColors.border,
                radius: BorderRadius.xxl
              })
              .enabled(this.bundles.length < MAX_MEETING_PARTICIPANTS)
              .onClick(() => {
                this.goPickMoreRoles()
              })

            Button(this.primaryActionLabel())
              .layoutWeight(1)
              .height(46)
              .fontSize(Typography.size.body)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor(this.canConfirm() ? MintColors.mint : MintColors.textMuted)
              .borderRadius(BorderRadius.xxl)
              .enabled(this.canConfirm())
              .onClick(() => {
                this.confirmSelection()
              })
          }
          .width('100%')

          if (this.canQuickStart() && !this.canConfirm()) {
            Button('快速开始，未锁定角色使用默认人格')
              .height(42)
              .fontSize(Typography.size.body)
              .fontColor(MintColors.mintDark)
              .backgroundColor(MintColors.mintBg)
              .borderRadius(BorderRadius.xxl)
              .border({
                width: 0.5,
                color: MintColors.mint,
                radius: BorderRadius.xxl
              })
              .width('100%')
              .onClick(() => {
                this.quickStart()
              })
          }
        }
        .width('100%')
        .padding(Spacing.md)
        .backgroundColor('rgba(255, 255, 255, 0.62)')
        .borderRadius(BorderRadius.xxl3)
        .border({
          width: 0.5,
          color: 'rgba(255, 255, 255, 0.74)',
          radius: BorderRadius.xxl3
        })

        if (this.noticeMessage.length > 0) {
          Row({ space: Spacing.sm }) {
            Text('提示')
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Medium)
              .fontColor(MintColors.error)
              .padding({
                left: Spacing.sm,
                right: Spacing.sm,
                top: 4,
                bottom: 4
              })
              .backgroundColor('rgba(255, 255, 255, 0.62)')
              .borderRadius(BorderRadius.pill)

            Text(this.noticeMessage)
              .layoutWeight(1)
              .fontSize(Typography.size.caption)
              .fontColor(MintColors.error)
              .lineHeight(Typography.lineHeight.relaxed)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .padding(Spacing.md)
          .backgroundColor('rgba(224, 120, 128, 0.10)')
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 0.5,
            color: 'rgba(224, 120, 128, 0.18)',
            radius: BorderRadius.xxl
          })
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.xl)
    }
    .width('100%')
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [
        ['rgba(255, 255, 255, 0.96)', 0],
        ['rgba(246, 251, 250, 0.98)', 0.58],
        ['rgba(250, 247, 255, 0.96)', 1]
      ]
    })
    .borderRadius(BorderRadius.xxl3)
    .border({
      width: 0.5,
      color: MintColors.border,
      radius: BorderRadius.xxl3
    })
    .backdropBlur(28)
    .shadow({
      radius: 24,
      color: 'rgba(78, 205, 196, 0.10)',
      offsetX: 0,
      offsetY: 10
    })
  }

  @Builder
  buildLoadingPanel() {
    Column({ space: Spacing.lg }) {
      Column({ space: Spacing.sm }) {
        this.buildStatusPill('LOADING', MintColors.mintDark, MintColors.mintBg, 'rgba(78, 205, 196, 0.16)')

        Text('正在整理会议角色的时间线...')
          .fontSize(Typography.size.xl)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)

        Text('我们会为每位角色拉取完整阶段、发言人格和资料摘要，完成后你就可以直接挑选。')
          .fontSize(Typography.size.body)
          .fontColor(MintColors.textSecondary)
          .lineHeight(Typography.lineHeight.relaxed)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      this.buildMeetingProgressBar()

      Row({ space: Spacing.sm }) {
        this.buildStatusPill('读取角色', MintColors.mintDark, MintColors.mintBg, 'rgba(78, 205, 196, 0.16)')
        this.buildStatusPill('匹配时间节点', MintColors.lavenderDark, MintColors.lavenderPale, 'rgba(184, 169, 217, 0.18)')
        this.buildStatusPill('整理发言人格', '#B88632', 'rgba(232, 184, 109, 0.14)', 'rgba(232, 184, 109, 0.24)')
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.xl)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [
        ['rgba(255, 255, 255, 0.92)', 0],
        ['rgba(246, 251, 250, 0.94)', 1]
      ]
    })
    .borderRadius(BorderRadius.xxl3)
    .border({
      width: 0.5,
      color: MintColors.border,
      radius: BorderRadius.xxl3
    })
    .backdropBlur(22)
    .shadow({
      radius: 18,
      color: 'rgba(78, 205, 196, 0.08)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  buildEmptyPanel() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(124)
        .height(124)
        .borderRadius(62)
        .backgroundColor('rgba(184, 169, 217, 0.14)')
        .blur(34)
        .position({ right: -16, y: -8 })

      Column({ space: Spacing.lg }) {
        Column({ space: Spacing.sm }) {
          this.buildStatusPill('EMPTY STATE', MintColors.lavenderDark, MintColors.lavenderPale, 'rgba(184, 169, 217, 0.20)')

          Text('还没有角色进入会议')
            .fontSize(Typography.size.xl)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Text('先从角色页加入 2 到 3 位角色，再回到这里为每个人挑选一个最合适的发言人格。')
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Row({ space: Spacing.sm }) {
          this.buildStatusPill('1. 添加角色', MintColors.mintDark, MintColors.mintBg, 'rgba(78, 205, 196, 0.16)')
          this.buildStatusPill('2. 选择阶段人格', MintColors.lavenderDark, MintColors.lavenderPale, 'rgba(184, 169, 217, 0.20)')
          this.buildStatusPill('3. 开始会议', '#B88632', 'rgba(232, 184, 109, 0.14)', 'rgba(232, 184, 109, 0.24)')
        }
        .width('100%')

        Button('去角色页添加')
          .height(46)
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor(MintColors.mint)
          .borderRadius(BorderRadius.xxl)
          .onClick(() => {
            this.goPickMoreRoles()
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.xl)
    }
    .width('100%')
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [
        ['rgba(255, 255, 255, 0.94)', 0],
        ['rgba(249, 247, 255, 0.96)', 1]
      ]
    })
    .borderRadius(BorderRadius.xxl3)
    .border({
      width: 0.5,
      color: MintColors.border,
      radius: BorderRadius.xxl3
    })
    .backdropBlur(24)
    .shadow({
      radius: 18,
      color: 'rgba(184, 169, 217, 0.08)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  buildRosterPanel() {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.md }) {
        Column({ space: 6 }) {
          Text('当前会议阵容')
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.textPrimary)

          Text(this.rosterSummaryText())
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 2 }) {
          Text(`${this.selectedCount()}/${this.bundles.length}`)
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Text('已锁定')
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.textMuted)
        }
        .padding({
          left: Spacing.md,
          right: Spacing.md,
          top: Spacing.sm,
          bottom: Spacing.sm
        })
        .backgroundColor('rgba(255, 255, 255, 0.82)')
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 0.5,
          color: MintColors.borderLight,
          radius: BorderRadius.xxl
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      this.buildMeetingProgressBar()

      Row({ space: Spacing.sm }) {
        this.buildStatusPill(`待锁定 ${this.remainingSelectionCount()} 位`, MintColors.textSecondary, 'rgba(255, 255, 255, 0.70)', MintColors.borderLight)
        this.buildStatusPill(`最多 ${MAX_MEETING_PARTICIPANTS} 位角色`, MintColors.mintDark, MintColors.mintBg, 'rgba(78, 205, 196, 0.16)')
      }
      .width('100%')

      Scroll() {
        Row({ space: Spacing.sm }) {
          ForEach(this.bundles, (bundle: ProfileBundle) => {
            this.buildRosterChip(bundle)
          }, (bundle: ProfileBundle) => bundle.profile.id)
        }
        .width('100%')
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor('rgba(255, 255, 255, 0.74)')
    .borderRadius(BorderRadius.xxl3)
    .border({
      width: 0.5,
      color: MintColors.borderLight,
      radius: BorderRadius.xxl3
    })
    .backdropBlur(18)
  }

  @Builder
  buildRosterChip(bundle: ProfileBundle) {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(42)
            .height(42)
            .borderRadius(21)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                ['rgba(78, 205, 196, 0.92)', 0],
                ['rgba(184, 169, 217, 0.88)', 1]
              ]
            })

          Text(bundle.profile.displayName.length > 0 ? bundle.profile.displayName.charAt(0) : '?')
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }

        Column({ space: 4 }) {
          Text(bundle.profile.displayName)
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.hasSelectedAgentForProfile(bundle.profile.id) ? '发言人格已锁定' : '等待锁定发言人格')
            .fontSize(Typography.size.xs)
            .fontColor(this.hasSelectedAgentForProfile(bundle.profile.id) ? MintColors.mintDark : MintColors.textMuted)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.rosterChipLabel(bundle))
        .fontSize(Typography.size.caption)
        .fontColor(MintColors.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row({ space: Spacing.sm }) {
        this.buildStatusPill(
          this.profileStageSummary(bundle),
          MintColors.textSecondary,
          'rgba(255, 255, 255, 0.72)',
          MintColors.borderLight
        )

        if (this.hasSelectedAgentForProfile(bundle.profile.id)) {
          this.buildStatusPill('已锁定', MintColors.mintDark, MintColors.mintBg, MintColors.mint)
        }
      }
      .width('100%')
    }
    .width(228)
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.md)
    .backgroundColor(this.selectedAgentForProfile(bundle.profile.id) ? 'rgba(255, 255, 255, 0.94)' : MintColors.surfaceGlass)
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 0.5,
      color: this.selectedAgentForProfile(bundle.profile.id) ? MintColors.mint : MintColors.border,
      radius: BorderRadius.xxl
    })
    .backdropBlur(16)
  }

  @Builder
  buildProfileTimeline(bundle: ProfileBundle, bundleIndex: number) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(116)
        .height(116)
        .borderRadius(58)
        .backgroundColor(bundleIndex % 2 === 0 ? 'rgba(78, 205, 196, 0.12)' : 'rgba(184, 169, 217, 0.14)')
        .blur(34)
        .position({ right: -18, y: -14 })

      Column({ space: Spacing.md }) {
        Row({ space: Spacing.md }) {
          Stack({ alignContent: Alignment.Center }) {
            Column()
              .width(58)
              .height(58)
              .borderRadius(29)
              .linearGradient({
                direction: GradientDirection.Bottom,
                colors: bundleIndex % 2 === 0
                  ? [
                      ['rgba(78, 205, 196, 0.92)', 0],
                      ['rgba(184, 169, 217, 0.86)', 1]
                    ]
                  : [
                      ['rgba(184, 169, 217, 0.92)', 0],
                      ['rgba(78, 205, 196, 0.86)', 1]
                    ]
              })

            Text(bundle.profile.displayName.length > 0 ? bundle.profile.displayName.charAt(0) : '?')
              .fontSize(Typography.size.subtitle)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            if (this.hasSelectedAgentForProfile(bundle.profile.id)) {
              Column()
                .width(58)
                .height(58)
                .borderRadius(29)
                .border({
                  width: 3,
                  color: MintColors.mint,
                  radius: 29
                })
            }
          }

          Column({ space: 6 }) {
            this.buildStatusPill(
              `角色 ${bundleIndex + 1}`,
              bundleIndex % 2 === 0 ? MintColors.mintDark : MintColors.lavenderDark,
              bundleIndex % 2 === 0 ? MintColors.mintBg : MintColors.lavenderPale,
              bundleIndex % 2 === 0 ? 'rgba(78, 205, 196, 0.16)' : 'rgba(184, 169, 217, 0.20)'
            )

            Row({ space: Spacing.xs }) {
              Text(bundle.profile.displayName)
                .fontSize(Typography.size.bodyLg)
                .fontWeight(FontWeight.Medium)
                .fontColor(MintColors.textPrimary)

              this.buildStatusPill(
                this.hasSelectedAgentForProfile(bundle.profile.id) ? '已锁定' : '待选择',
                this.hasSelectedAgentForProfile(bundle.profile.id) ? '#FFFFFF' : MintColors.textMuted,
                this.hasSelectedAgentForProfile(bundle.profile.id) ? MintColors.mint : MintColors.surfaceGlass,
                this.hasSelectedAgentForProfile(bundle.profile.id) ? MintColors.mint : MintColors.borderLight
              )
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            Text(this.profileSelectionHint(bundle))
              .fontSize(Typography.size.caption)
              .fontColor(MintColors.textSecondary)
              .lineHeight(Typography.lineHeight.relaxed)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: Spacing.sm }) {
            Button(this.focusActionLabel(bundle))
              .height(34)
              .fontSize(Typography.size.caption)
              .fontColor(MintColors.mintDark)
              .backgroundColor(MintColors.mintBg)
              .borderRadius(BorderRadius.xxl)
              .onClick(() => {
                if (this.hasSelectedAgentForProfile(bundle.profile.id)) {
                  this.openAgent(this.selectedAgentIdForProfile(bundle.profile.id))
                } else if (bundle.agents.length > 0) {
                  this.openAgent(bundle.agents[0].agentId)
                }
              })

            Button(this.hasSelectedAgentForProfile(bundle.profile.id) ? '移出角色' : '移出')
              .height(34)
              .fontSize(Typography.size.caption)
              .fontColor(MintColors.error)
              .backgroundColor('rgba(224, 120, 128, 0.08)')
              .borderRadius(BorderRadius.xxl)
              .onClick(() => {
                this.removeProfile(bundle.profile.id)
              })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row({ space: Spacing.sm }) {
          this.buildStatusPill(this.profileStageSummary(bundle), MintColors.textSecondary, 'rgba(255, 255, 255, 0.70)', MintColors.borderLight)

          if (bundle.sourceDocument && bundle.sourceDocument.title.length > 0) {
            this.buildStatusPill('已接入资料底稿', '#B88632', 'rgba(232, 184, 109, 0.14)', 'rgba(232, 184, 109, 0.24)')
          }
        }
        .width('100%')

        if (this.selectedAgentForProfile(bundle.profile.id)) {
          this.buildSelectedAgentSummary(this.selectedAgentForProfile(bundle.profile.id) as PersonaSpec, bundle)
        } else {
          Row({ space: Spacing.sm }) {
            Button('智能推荐当前默认人格')
              .height(40)
              .fontSize(Typography.size.caption)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor(MintColors.mint)
              .borderRadius(BorderRadius.xxl)
              .onClick(() => {
                if (bundle.agents.length > 0) {
                  this.toggleSelectedAgent(bundle.agents[0])
                }
              })

            Text('也可以直接点击下方任一时间节点，展开比较后再做决定。')
              .fontSize(Typography.size.xs)
              .fontColor(MintColors.textSecondary)
              .layoutWeight(1)
              .lineHeight(18)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding(Spacing.md)
          .backgroundColor('rgba(255, 255, 255, 0.78)')
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 0.5,
            color: MintColors.borderLight,
            radius: BorderRadius.xxl
          })
        }

        ForEach(bundle.nodes, (node: TimelineNode, nodeIndex: number) => {
          this.buildTimelineAgentNode(node, bundle.agents[nodeIndex], nodeIndex, bundle.nodes.length)
        }, (node: TimelineNode) => node.nodeId)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.xl)
    }
    .width('100%')
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(BorderRadius.xxl3)
    .border({
      width: 0.5,
      color: this.hasSelectedAgentForProfile(bundle.profile.id) ? MintColors.mint : MintColors.border,
      radius: BorderRadius.xxl3
    })
    .backdropBlur(22)
    .shadow({
      radius: this.hasSelectedAgentForProfile(bundle.profile.id) ? 22 : 16,
      color: this.hasSelectedAgentForProfile(bundle.profile.id) ? 'rgba(78, 205, 196, 0.12)' : 'rgba(184, 169, 217, 0.08)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  buildSelectedAgentSummary(agent: PersonaSpec, bundle: ProfileBundle) {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.md }) {
        Column({ space: 4 }) {
          Text('当前锁定的发言人格')
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.textMuted)
            .letterSpacing(1.5)

          Text(agent.displayName)
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.textPrimary)

          Text(this.agentHeadline(agent))
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.mintDark)
            .lineHeight(Typography.lineHeight.relaxed)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        this.buildStatusPill('已上桌发言', MintColors.mintDark, 'rgba(255, 255, 255, 0.76)', MintColors.mint)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row({ space: Spacing.sm }) {
        this.buildStatusPill(agent.timeLabel, MintColors.mintDark, MintColors.mintBg, 'rgba(78, 205, 196, 0.16)')
        this.buildStatusPill(agent.stageLabel, MintColors.lavenderDark, MintColors.lavenderPale, 'rgba(184, 169, 217, 0.20)')

        if (bundle.sourceDocument && bundle.sourceDocument.title.length > 0) {
          this.buildStatusPill('已接入资料底稿', '#B88632', 'rgba(232, 184, 109, 0.14)', 'rgba(232, 184, 109, 0.24)')
        }
      }
      .width('100%')

      Row({ space: Spacing.sm }) {
        this.buildMiniSummaryBlock('核心价值', this.primaryValue(agent), 'rgba(78, 205, 196, 0.12)')
        this.buildMiniSummaryBlock('当前目标', agent.goal, 'rgba(184, 169, 217, 0.14)')
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor('rgba(78, 205, 196, 0.08)')
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 0.5,
      color: MintColors.mint,
      radius: BorderRadius.xxl
    })
  }

  @Builder
  buildMiniSummaryBlock(label: string, value: string, backgroundColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(Typography.size.xs)
        .fontColor(MintColors.textMuted)
        .letterSpacing(1)

      Text(value.length > 0 ? value : '暂无内容')
        .fontSize(Typography.size.caption)
        .fontColor(MintColors.textPrimary)
        .lineHeight(Typography.lineHeight.relaxed)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.md)
    .backgroundColor(backgroundColor)
    .borderRadius(BorderRadius.lg)
  }

  @Builder
  buildTimelineAgentNode(
    node: TimelineNode,
    agent: PersonaSpec,
    index: number,
    total: number
  ) {
    Row({ space: Spacing.md }) {
      Column() {
        Column()
          .width(14)
          .height(14)
          .borderRadius(7)
          .backgroundColor(this.isSelected(agent.agentId) ? MintColors.mint : this.getStageColor(node.stageType))
          .margin({ bottom: Spacing.xs })

        if (index < total - 1) {
          Column()
            .width(2)
            .height(this.isFocusedAgent(agent.agentId) ? 192 : 104)
            .backgroundColor(this.isFocusedAgent(agent.agentId) ? 'rgba(78, 205, 196, 0.24)' : 'rgba(184, 169, 217, 0.18)')
        }
      }
      .alignItems(HorizontalAlign.Center)

      Column({ space: Spacing.sm }) {
        Row({ space: Spacing.md }) {
          Column({ space: Spacing.sm }) {
            Row({ space: Spacing.xs }) {
              this.buildStatusPill(node.timeLabel, MintColors.textMuted, MintColors.surfaceGlass, MintColors.borderLight)

              if (node.ageLabel && node.ageLabel.length > 0) {
                this.buildStatusPill(node.ageLabel, MintColors.textMuted, 'rgba(255, 255, 255, 0.80)', MintColors.borderLight)
              }

              this.buildStatusPill(node.stageLabel, this.getStageColor(node.stageType), this.getStageTint(node.stageType), this.getStageTint(node.stageType))

              if (this.isSelected(agent.agentId)) {
                this.buildStatusPill('当前发言人格', '#FFFFFF', MintColors.mint, MintColors.mint)
              } else if (this.isFocusedAgent(agent.agentId)) {
                this.buildStatusPill('已展开', MintColors.mintDark, MintColors.mintBg, MintColors.mint)
              }
            }
            .width('100%')

            Text(node.keyEvent)
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isFocusedAgent(agent.agentId) ? MintColors.mintDark : MintColors.textPrimary)
              .lineHeight(Typography.lineHeight.relaxed)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 2 }) {
            Text(this.isSelected(agent.agentId) ? '已选中' : (this.isFocusedAgent(agent.agentId) ? '收起' : '展开'))
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isSelected(agent.agentId) ? MintColors.mintDark : MintColors.textMuted)

            Text(this.isFocusedAgent(agent.agentId) ? '再次点击卡片' : '查看详情')
              .fontSize(Typography.size.xs)
              .fontColor(MintColors.textMuted)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Text(node.summary)
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textSecondary)
          .lineHeight(Typography.lineHeight.relaxed)
          .maxLines(this.isFocusedAgent(agent.agentId) ? 10 : 2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.isFocusedAgent(agent.agentId)) {
          Column({ space: Spacing.sm }) {
            Column()
              .width('100%')
              .height(1)
              .backgroundColor('rgba(184, 169, 217, 0.16)')

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(agent.traits, (trait: string) => {
                this.buildTraitChip(trait)
              }, (trait: string) => trait)
            }
            .width('100%')

            this.buildDetailBlock('此时最看重', agent.values.join(' / '), 'rgba(78, 205, 196, 0.10)')
            this.buildDetailBlock('想要达成', agent.goal, 'rgba(184, 169, 217, 0.14)')
            this.buildDetailBlock('最害怕失去', agent.fear, 'rgba(224, 120, 128, 0.10)')
            this.buildDetailBlock('说话方式', agent.voiceStyle, 'rgba(255, 255, 255, 0.82)')
            this.buildDetailBlock('知识边界', agent.knowledgeBoundary, 'rgba(255, 255, 255, 0.82)')

            if (node.tensions.length > 0) {
              this.buildDetailBlock('内在张力', node.tensions.join(' / '), 'rgba(232, 184, 109, 0.12)')
            }

            if (agent.sourceEvidence.length > 0) {
              Text(`“${agent.sourceEvidence[0].quote}”`)
                .fontSize(Typography.size.body)
                .fontColor(MintColors.lavenderDark)
                .fontStyle(FontStyle.Italic)
                .lineHeight(Typography.lineHeight.relaxed)
                .maxLines(4)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding(Spacing.md)
                .backgroundColor(MintColors.lavenderPale)
                .borderRadius(BorderRadius.lg)
            }

            Button(this.isSelected(agent.agentId) ? '取消作为当前发言人格' : '选择这个阶段参与会议')
              .height(42)
              .fontSize(Typography.size.body)
              .fontColor(this.isSelected(agent.agentId) ? MintColors.mintDark : '#FFFFFF')
              .backgroundColor(this.isSelected(agent.agentId) ? 'rgba(255, 255, 255, 0.92)' : MintColors.mint)
              .borderRadius(BorderRadius.xxl)
              .border({
                width: this.isSelected(agent.agentId) ? 1 : 0,
                color: MintColors.mint,
                radius: BorderRadius.xxl
              })
              .width('100%')
              .onClick(() => {
                this.toggleSelectedAgent(agent)
              })
          }
          .width('100%')
        } else {
          Row({ space: Spacing.sm }) {
            Text('点击卡片查看该阶段的人格细节、目标和发言风格。')
              .layoutWeight(1)
              .fontSize(Typography.size.xs)
              .fontColor(MintColors.textMuted)
              .lineHeight(18)

            Text('展开')
              .fontSize(Typography.size.xs)
              .fontColor(this.getStageColor(node.stageType))
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding(Spacing.lg)
      .backgroundColor(this.isFocusedAgent(agent.agentId) ? 'rgba(255, 255, 255, 0.98)' : 'rgba(255, 255, 255, 0.74)')
      .borderRadius(BorderRadius.xxl)
      .border({
        width: this.isFocusedAgent(agent.agentId) ? 1.5 : 0.5,
        color: this.isSelected(agent.agentId) ? MintColors.mint : (this.isFocusedAgent(agent.agentId) ? MintColors.mintDark : MintColors.border),
        radius: BorderRadius.xxl
      })
      .backdropBlur(this.isFocusedAgent(agent.agentId) ? 18 : 12)
      .shadow({
        radius: this.isFocusedAgent(agent.agentId) ? 16 : 8,
        color: this.isSelected(agent.agentId) ? 'rgba(78, 205, 196, 0.15)' : (this.isFocusedAgent(agent.agentId) ? 'rgba(184, 169, 217, 0.10)' : 'rgba(78, 205, 196, 0.04)'),
        offsetX: 0,
        offsetY: 4
      })
      .onClick(() => {
        this.toggleAgentFocus(agent.agentId)
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildTraitChip(trait: string) {
    Text(trait)
      .fontSize(Typography.size.xs)
      .fontColor(MintColors.mintDark)
      .padding({
        left: Spacing.sm,
        right: Spacing.sm,
        top: 4,
        bottom: 4
      })
      .backgroundColor(MintColors.mintBg)
      .borderRadius(BorderRadius.chip)
      .border({
        width: 0.5,
        color: 'rgba(78, 205, 196, 0.16)',
        radius: BorderRadius.chip
      })
      .margin({ right: Spacing.xs, bottom: Spacing.xs })
  }

  @Builder
  buildDetailBlock(label: string, value: string, backgroundColor: string) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(Typography.size.xs)
        .fontColor(MintColors.textMuted)
        .letterSpacing(1)

      Text(value.length > 0 ? value : '暂无内容')
        .fontSize(Typography.size.caption)
        .fontColor(MintColors.textPrimary)
        .lineHeight(Typography.lineHeight.relaxed)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.md)
    .backgroundColor(backgroundColor)
    .borderRadius(BorderRadius.lg)
    .border({
      width: 0.5,
      color: 'rgba(255, 255, 255, 0.70)',
      radius: BorderRadius.lg
    })
  }
}
