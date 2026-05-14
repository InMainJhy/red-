import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { PersonaSpec, PresetProfile, ProfileBundle, RouteParams, TimelineNode, EMPTY_PROFILE, SourceDocumentSummary } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
import { MeetingSessionStore } from '../utils/MeetingSessionStore'
import { SmartFillService, FillType } from '../service/SmartFillService'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing, MobileSpacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import { BackButtonText } from '../components/BackButton'
import { DynamicGlassBackground } from '../components/DynamicGlassBackground'
import { Colors } from '../common/styles/Colors'

type ThemeColor = ResourceColor | string
const FALLBACK_SAFE_TOP_VP: number = 52
const TIMELINE_TEASER_MAX_CHARS: number = 44

@Entry
@Component
struct ProfileDetail {
  @State profile: PresetProfile = EMPTY_PROFILE
  @State nodes: TimelineNode[] = []
  @State agents: PersonaSpec[] = []
  @State selectedPersonaIds: string[] = []
  @State meetingAgentIds: string[] = []
  @State expandedNodeIds: string[] = []
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0
  @State returnToMeeting: boolean = false
  @State sourceDocument: SourceDocumentSummary | null = null
  @State isGeneratingBackground: boolean = false
  @State generatedBackground: string = ''
  @State showBackgroundModal: boolean = false

  private isViewOnlyMode(): boolean {
    return !this.returnToMeeting
  }

  aboutToAppear(): void {
    this.loadSafeInsets()
    const rawParams = router.getParams()
    const params: RouteParams = rawParams ? rawParams as RouteParams : {}
    const profileId = params.profileId ?? MeetingSessionStore.getProfileId() ?? ''
    const routeSelectedAgentIds = params.selectedAgentIds
      ? params.selectedAgentIds.split(',').filter((agentId: string) => agentId.length > 0)
      : []
    this.returnToMeeting = params.returnToMeeting === '1'
    const sessionProfileId = MeetingSessionStore.getProfileId()
    const sessionSelectedAgentIds = this.returnToMeeting && sessionProfileId === profileId
      ? MeetingSessionStore.getSelectedAgents()
      : []
    const initialSelectedAgentIds = routeSelectedAgentIds.length > 0 ? routeSelectedAgentIds : sessionSelectedAgentIds

    if (!profileId.length) {
      return
    }

    PersonaApi.getProfileBundle(profileId).then((bundle: ProfileBundle) => {
      const initialAgentIds = initialSelectedAgentIds.filter((agentId: string) =>
        bundle.agents.some((agent: PersonaSpec) => agent.agentId === agentId)
      )

      this.profile = bundle.profile
      this.nodes = bundle.nodes
      this.agents = bundle.agents
      this.selectedPersonaIds = [...initialAgentIds]
      this.meetingAgentIds = [...initialAgentIds]
      this.sourceDocument = bundle.sourceDocument || null
      this.expandedNodeIds = this.isViewOnlyMode() ? bundle.nodes.map((node: TimelineNode) => node.nodeId) : []
    }).catch(() => {})
  }

  loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
        this.safeBottomVp = insets.bottomVp
      })
    } catch (_e) {
    }
  }

  topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  isTimelineNodeExpanded(nodeId: string): boolean {
    return this.expandedNodeIds.includes(nodeId)
  }

  toggleTimelineNode(nodeId: string): void {
    if (this.isViewOnlyMode()) {
      return
    }
    if (this.expandedNodeIds.includes(nodeId)) {
      this.expandedNodeIds = this.expandedNodeIds.filter((id: string) => id !== nodeId)
      return
    }

    this.expandedNodeIds = [...this.expandedNodeIds, nodeId]
  }

  isPersonaSelected(agentId: string): boolean {
    return this.selectedPersonaIds.includes(agentId)
  }

  isAgentInMeeting(agentId: string): boolean {
    return this.meetingAgentIds.includes(agentId)
  }

  togglePersonaSelection(agentId: string): void {
    if (this.selectedPersonaIds.includes(agentId)) {
      this.selectedPersonaIds = this.selectedPersonaIds.filter((item: string) => item !== agentId)
      return
    }

    this.selectedPersonaIds = [...this.selectedPersonaIds, agentId]
  }

  hasSelectedPersonas(): boolean {
    return this.selectedPersonaIds.length > 0
  }

  getMeetingAgentIdsForStart(): string[] {
    if (this.meetingAgentIds.length > 0) {
      return [...this.meetingAgentIds]
    }
    return [...this.selectedPersonaIds]
  }

  canStartFromDetail(): boolean {
    return this.getMeetingAgentIdsForStart().length >= 2
  }

  selectedProfileTopicHint(): string {
    if (this.profile.suggestedTopics.length > 0) {
      return this.profile.suggestedTopics[0]
    }
    return '选择两个以上阶段人格后，即可围绕当前人生议题发起讨论。'
  }

  addSelectedPersonasToMeeting(): void {
    if (!this.hasSelectedPersonas()) {
      return
    }

    const preservedAgentIds = this.meetingAgentIds.filter((agentId: string) => !this.selectedPersonaIds.includes(agentId))
    const nextMeetingAgentIds = [...preservedAgentIds, ...this.selectedPersonaIds]
    this.meetingAgentIds = nextMeetingAgentIds

    if (this.returnToMeeting) {
      const existing = MeetingSessionStore.getProfileIds()
      if (existing.length === 0) {
        MeetingSessionStore.setProfileIds([this.profile.id])
      } else if (existing.indexOf(this.profile.id) < 0) {
        MeetingSessionStore.setProfileIds([...existing, this.profile.id])
      } else {
        MeetingSessionStore.setProfileIds(existing)
      }
      MeetingSessionStore.setProfileId(this.profile.id)
      MeetingSessionStore.setSelectedAgents(nextMeetingAgentIds)
      router.back()
    }
  }

  startMeeting(): void {
    const meetingAgentIds = this.getMeetingAgentIdsForStart()
    if (meetingAgentIds.length < 2) {
      return
    }

    router.pushUrl({
      url: 'pages/MeetingParticipantPage',
      params: {
        profileId: this.profile.id,
        profileIds: this.profile.id,
        selectedAgentIds: meetingAgentIds.join(',')
      }
    })
  }

  /**
   * AI 生成角色背景故事
   * 基于现有信息生成完整的人物小传
   */
  private async generateCharacterBackground(): Promise<void> {
    if (this.isGeneratingBackground || this.generatedBackground.length > 0) {
      return
    }

    this.isGeneratingBackground = true
    try {
      const smartService = SmartFillService.getInstance()

      // 收集角色的特点信息
      const traits = this.nodes
        .flatMap(node => node.traits)
        .filter((trait, index, self) => self.indexOf(trait) === index)
        .join('、')

      const result = await smartService.fillWithCharacter(
        traits || this.profile.biography,
        this.profile.displayName
      )

      if (result.success) {
        this.generatedBackground = result.content
        this.showBackgroundModal = true
      } else {
        // 显示本地模拟结果
        this.generatedBackground = `【${this.profile.displayName}的背景故事】

${this.profile.biography}

【性格特点】
${traits || '性格复杂多面'}

【人生经历】
在人生的各个阶段，${this.profile.displayName}经历了诸多重要时刻，每一个选择都塑造了今天的他/她。

【价值观与信念】
${this.nodes[0]?.values.join('、') || '追求真善美'}`

        this.showBackgroundModal = true
      }
    } catch (err) {
      console.error('[ProfileDetail] generateCharacterBackground failed:', err)
    } finally {
      this.isGeneratingBackground = false
    }
  }

  /**
   * 关闭背景故事弹窗
   */
  private closeBackgroundModal(): void {
    this.showBackgroundModal = false
  }

  timelineCollapsedTeaser(node: TimelineNode): string {
    const summary = node.summary.trim()
    const fallback = node.keyEvent.trim()
    let core: string = summary.length > 0 ? summary : fallback

    if (core.length > TIMELINE_TEASER_MAX_CHARS) {
      core = core.substring(0, TIMELINE_TEASER_MAX_CHARS) + '...'
    }

    const age = node.ageLabel ? node.ageLabel.trim() : ''
    if (age.length > 0 && core.length > 0) {
      return `${age} · ${core}`
    }

    return core
  }

  getStageColor(stageType: string): ThemeColor {
    const colors: Record<string, ThemeColor> = {
      'early': MintColors.stage.early,
      'turning-point': MintColors.stage.turningPoint,
      'crisis': MintColors.stage.crisis,
      'rebuild': MintColors.stage.rebuild,
      'peak': MintColors.stage.peak
    }
    return colors[stageType] || MintColors.stage.default
  }

  private getAgentForNode(node: TimelineNode, index: number): PersonaSpec | undefined {
    const exactMatch = this.agents.find((agent: PersonaSpec) =>
      agent.stageLabel === node.stageLabel &&
      agent.timeLabel === node.timeLabel
    )
    if (exactMatch) {
      return exactMatch
    }

    const stageMatch = this.agents.find((agent: PersonaSpec) => agent.stageLabel === node.stageLabel)
    if (stageMatch) {
      return stageMatch
    }

    const eventMatch = this.agents.find((agent: PersonaSpec) => agent.keyEvent === node.keyEvent)
    if (eventMatch) {
      return eventMatch
    }

    return this.agents[index]
  }

  private getAgentIdForNode(node: TimelineNode, index: number): string {
    const agent = this.getAgentForNode(node, index)
    return agent ? agent.agentId : ''
  }

  getPersonaButtonLabel(node: TimelineNode, index: number): string {
    const agentId = this.getAgentIdForNode(node, index)
    if (!agentId.length) {
      return '+ 选择人格'
    }

    if (this.isPersonaSelected(agentId)) {
      return '✓ 已选人格'
    }

    if (this.isAgentInMeeting(agentId)) {
      return '已在会议中'
    }

    return '+ 选择人格'
  }

  private isNodeExpandedForCurrentMode(nodeId: string): boolean {
    return this.isViewOnlyMode() ? true : this.isTimelineNodeExpanded(nodeId)
  }

  getPersonaButtonFontColor(node: TimelineNode, index: number): ThemeColor {
    const agentId = this.getAgentIdForNode(node, index)
    if (!agentId.length) {
      return MintColors.textMuted
    }

    if (this.isPersonaSelected(agentId)) {
      return Colors.backgroundElevated
    }

    if (this.isAgentInMeeting(agentId)) {
      return MintColors.lavenderDark
    }

    return MintColors.mintDark
  }

  getPersonaButtonBackgroundColor(node: TimelineNode, index: number): ThemeColor {
    const agentId = this.getAgentIdForNode(node, index)
    if (!agentId.length) {
      return MintColors.backgroundSecondary
    }

    if (this.isPersonaSelected(agentId)) {
      return MintColors.mint
    }

    if (this.isAgentInMeeting(agentId)) {
      return MintColors.lavenderPale
    }

    return MintColors.surfaceGlass
  }

  getPersonaButtonBorderColor(node: TimelineNode, index: number): ThemeColor {
    const agentId = this.getAgentIdForNode(node, index)
    if (!agentId.length) {
      return MintColors.border
    }

    if (this.isPersonaSelected(agentId)) {
      return MintColors.mint
    }

    if (this.isAgentInMeeting(agentId)) {
      return MintColors.lavenderLight
    }

    return MintColors.border
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      DynamicGlassBackground()

      Scroll() {
        Column({ space: Spacing.lg }) {
          Column({ space: Spacing.md }) {
            Text(this.profile.displayName)
              .fontSize(Typography.size.hero)
              .fontWeight(Typography.weight.bold)
              .fontColor(MintColors.textPrimary)

            Text(this.profile.biography)
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textSecondary)
              .lineHeight(Typography.lineHeight.relaxed)

            if (this.generatedBackground.length > 0) {
              Text('✨ AI 生成背景故事')
                .fontSize(Typography.size.sm)
                .fontColor(Colors.textPrimary)
                .padding({ top: Spacing.sm })
                .onClick(() => {
                  this.showBackgroundModal = true
                })
            } else {
              Button(this.isGeneratingBackground ? '生成中...' : '✨ AI 生成背景故事')
                .height(36)
                .fontSize(Typography.size.sm)
                .fontColor(Colors.textInverse)
                .backgroundColor(this.isGeneratingBackground ? Colors.textMuted : Colors.textPrimary)
                .borderRadius(BorderRadius.xxl)
                .onClick(() => {
                  void this.generateCharacterBackground()
                })
            }

            Divider()
              .color(MintColors.divider)
              .margin({ top: Spacing.sm, bottom: Spacing.sm })

            Row() {
              Column({ space: 2 }) {
                Text(`${this.nodes.length}`)
                  .fontSize(Typography.size.xl)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MintColors.mint)

                Text('时间节点')
                  .fontSize(Typography.size.xs)
                  .fontColor(MintColors.textMuted)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              if (this.returnToMeeting) {
                Column({ space: 2 }) {
                  Text(`${this.selectedPersonaIds.length}`)
                    .fontSize(Typography.size.xl)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MintColors.textPrimary)

                  Text('本页已选人格')
                    .fontSize(Typography.size.xs)
                    .fontColor(MintColors.textMuted)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Column({ space: 2 }) {
                  Text(`${this.getMeetingAgentIdsForStart().length}`)
                    .fontSize(Typography.size.xl)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MintColors.lavenderDark)

                  Text('准备带入会议')
                    .fontSize(Typography.size.xs)
                    .fontColor(MintColors.textMuted)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              } else {
                Column({ space: 2 }) {
                  Text(`${this.agents.length}`)
                    .fontSize(Typography.size.xl)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MintColors.lavenderDark)

                  Text('阶段人格')
                    .fontSize(Typography.size.xs)
                    .fontColor(MintColors.textMuted)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
            }
            .width('100%')
          }
          .width('100%')
          .padding(MobileSpacing.md)
          .backgroundColor(MintColors.cardPrimary)
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 0.5,
            color: MintColors.border,
            radius: BorderRadius.xxl
          })
          .shadow({
            radius: 20,
            color: Colors.loadingBg,
            offsetX: 0,
            offsetY: 6
          })

          Column({ space: Spacing.sm }) {
            Text(this.returnToMeeting ? '先读时间线，再决定谁进入会议' : '人物详细信息')
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Bold)
              .fontColor(MintColors.textPrimary)
              .width('100%')

            Text(this.returnToMeeting ? this.selectedProfileTopicHint() : '这里展示该人物的阶段轨迹、关键事件、价值观与证据引用。')
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textSecondary)
              .lineHeight(Typography.lineHeight.relaxed)
              .width('100%')

            Text(this.returnToMeeting ? '你正在从会议准备页返回补充人格，确认后可直接带回去。' : '资料页默认直接展开完整内容，方便你先理解这个人物。')
              .fontSize(Typography.size.caption)
              .fontColor(MintColors.textMuted)
              .lineHeight(18)
              .width('100%')

            if (this.sourceDocument) {
              Text(`来源文档：${this.sourceDocument.title}`)
                .fontSize(Typography.size.caption)
                .fontColor(MintColors.textMuted)
                .width('100%')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .width('100%')
          .padding(MobileSpacing.md)
          .backgroundColor(MintColors.surfaceGlass)
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 0.5,
            color: MintColors.border,
            radius: BorderRadius.xxl
          })

          Row() {
            Text('人生时间线')
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Medium)
              .fontColor(MintColors.textPrimary)
          }
          .width('100%')
          .padding({ top: MobileSpacing.sm })

          ForEach(this.nodes, (node: TimelineNode, index: number) => {
            this.buildTimelineNode(node, index)
          }, (node: TimelineNode) => node.nodeId)
        }
        .padding({
          left: MobileSpacing.page.horizontal,
          right: MobileSpacing.page.horizontal,
          top: this.topInsetVp() + 60,
          bottom: this.safeBottomVp + 132
        })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      BackButtonText({
        fontColor: MintColors.mintDark,
        customOnClick: () => {
          router.back()
        }
      })
      .position({ x: MobileSpacing.page.horizontal, y: this.topInsetVp() + 12 })

      if (this.returnToMeeting) {
        this.buildBottomActionBar()
      }

      // 背景故事弹窗
      if (this.showBackgroundModal) {
        this.buildBackgroundModal()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MintColors.background)
  }

  @Builder
  buildBottomActionBar() {
    Column({ space: Spacing.sm }) {
      Row() {
        Column({ space: 2 }) {
          Text(this.canStartFromDetail() ? '已可发起会议' : '至少选择 2 位人格')
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Text(`当前选中 ${this.selectedPersonaIds.length} 位 · 会议中将带入 ${this.getMeetingAgentIdsForStart().length} 位`)
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.textMuted)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row({ space: Spacing.sm }) {
        Button(this.returnToMeeting ? '带回会议选择页' : '加入会议准备')
          .layoutWeight(1)
          .height(46)
          .fontSize(Typography.size.body)
          .fontColor(this.hasSelectedPersonas() ? '#FFFFFF' : MintColors.textMuted)
          .backgroundColor(this.hasSelectedPersonas() ? MintColors.mint : MintColors.backgroundSecondary)
          .borderRadius(BorderRadius.xxl)
          .enabled(this.hasSelectedPersonas())
          .onClick(() => {
            this.addSelectedPersonasToMeeting()
          })

        Button('直接开始')
          .layoutWeight(1)
          .height(46)
          .fontSize(Typography.size.body)
          .fontColor(this.canStartFromDetail() ? '#FFFFFF' : MintColors.textMuted)
          .backgroundColor(this.canStartFromDetail() ? MintColors.lavenderDark : MintColors.backgroundSecondary)
          .borderRadius(BorderRadius.xxl)
          .enabled(this.canStartFromDetail())
          .onClick(() => {
            this.startMeeting()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({
      left: MobileSpacing.page.horizontal,
      right: MobileSpacing.page.horizontal,
      top: Spacing.sm,
      bottom: this.safeBottomVp + Spacing.sm
    })
    .backgroundColor(MintColors.cardPrimary)
    .borderWidth({ top: 1 })
    .borderColor({ top: MintColors.borderLight })
    .shadow({
      radius: 12,
      color: 'rgba(17, 17, 17, 0.06)',
      offsetX: 0,
      offsetY: -2
    })
    .position({ x: 0, y: '100%' })
    .translate({ x: 0, y: -104 - this.safeBottomVp })
  }

  /**
   * 背景故事弹窗
   */
  @Builder
  buildBackgroundModal() {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => this.closeBackgroundModal())

      // 内容卡片
      Column({ space: Spacing.md }) {
        Row({ space: Spacing.sm }) {
          Text(`${this.profile.displayName}的背景故事`)
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Blank()

          Text('✕')
            .fontSize(20)
            .fontColor(MintColors.textMuted)
            .onClick(() => this.closeBackgroundModal())
        }
        .width('100%')

        Scroll() {
          Text(this.generatedBackground)
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textPrimary)
            .lineHeight(Typography.lineHeight.relaxed)
            .width('100%')
        }
        .layoutWeight(1)
        .width('100%')

        Button('关闭')
          .width('100%').height(44)
          .fontColor(Colors.textInverse)
          .backgroundColor(MintColors.mint)
          .borderRadius(BorderRadius.xxl)
          .onClick(() => this.closeBackgroundModal())
      }
      .width('90%')
      .constraintSize({ maxHeight: '70%' })
      .padding(Spacing.lg)
      .backgroundColor(Colors.backgroundElevated)
      .borderRadius(BorderRadius.xxl2)
    }
    .width('100%')
    .height('100%')
    .zIndex(1000)
  }

  @Builder
  buildTimelineNode(node: TimelineNode, index: number) {
    Column({ space: Spacing.md }) {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(28)
            .height(28)
            .borderRadius(14)
            .backgroundColor(this.getStageColor(node.stageType))

          Text(`${index + 1}`)
            .fontSize(Typography.size.sm)
            .fontColor(Colors.textInverse)
            .textAlign(TextAlign.Center)
        }
        .width(28)
        .height(28)

        Text(node.stageLabel)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.textPrimary)
          .margin({ left: Spacing.sm })
          .layoutWeight(1)

        Text(node.timeLabel)
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textMuted)
          .margin({ right: Spacing.xs })

        if (this.returnToMeeting) {
          Text(this.isTimelineNodeExpanded(node.nodeId) ? '▼' : '▶')
            .fontSize(11)
            .fontColor(MintColors.textMuted)
            .width(20)
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })
      .onClick(() => {
        this.toggleTimelineNode(node.nodeId)
      })

      if (!this.isNodeExpandedForCurrentMode(node.nodeId) && this.timelineCollapsedTeaser(node).length > 0) {
        Text(this.timelineCollapsedTeaser(node))
          .fontSize(Typography.size.sm)
          .fontColor(MintColors.textMuted)
          .lineHeight(20)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      if (this.isNodeExpandedForCurrentMode(node.nodeId)) {
        Column({ space: Spacing.md }) {
          Text(node.summary)
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)

          Row({ space: Spacing.xs }) {
            Text('关键事件：')
              .fontSize(Typography.size.sm)
              .fontColor(MintColors.textMuted)
              .flexShrink(0)

            Text(node.keyEvent)
              .fontSize(Typography.size.sm)
              .fontColor(MintColors.textPrimary)
              .layoutWeight(1)
              .lineHeight(22)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
            ForEach(node.traits, (trait: string) => {
              Text(trait)
                .fontSize(Typography.size.xs)
                .fontColor(MintColors.mintDark)
                .padding({
                  left: Spacing.sm,
                  right: Spacing.sm,
                  top: 3,
                  bottom: 3
                })
                .backgroundColor(MintColors.mintBg)
                .borderRadius(BorderRadius.chip)
                .margin({ right: Spacing.xs, bottom: Spacing.xs })
            }, (trait: string) => trait)
          }
          .width('100%')

          if (node.values.length > 0) {
            Row({ space: Spacing.xs }) {
              Text('价值观：')
                .fontSize(Typography.size.sm)
                .fontColor(MintColors.textMuted)
                .flexShrink(0)

              Text(node.values.join(' / '))
                .fontSize(Typography.size.sm)
                .fontColor(MintColors.textPrimary)
                .layoutWeight(1)
                .lineHeight(22)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }

          if (node.sourceEvidence.length > 0) {
            Column({ space: Spacing.xs }) {
              Text('证据引用：')
                .fontSize(Typography.size.sm)
                .fontColor(MintColors.textMuted)

              Text(`"${node.sourceEvidence[0].quote}"`)
                .fontSize(Typography.size.body)
                .fontColor(MintColors.lavenderDark)
                .lineHeight(Typography.lineHeight.relaxed)
                .fontStyle(FontStyle.Italic)
            }
            .width('100%')
            .padding(Spacing.md)
            .backgroundColor(MintColors.lavenderPale)
            .borderRadius(BorderRadius.lg)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })
      }

      if (this.returnToMeeting) {
        Button(this.getPersonaButtonLabel(node, index))
          .width('100%')
          .height(42)
          .fontSize(Typography.size.body)
          .fontColor(this.getPersonaButtonFontColor(node, index))
          .backgroundColor(this.getPersonaButtonBackgroundColor(node, index))
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 1,
            color: this.getPersonaButtonBorderColor(node, index),
            radius: BorderRadius.xxl
          })
          .animation({
            duration: 200,
            curve: Curve.EaseOut
          })
          .onClick(() => {
            const agentId = this.getAgentIdForNode(node, index)
            if (agentId.length > 0) {
              this.togglePersonaSelection(agentId)
            }
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(BorderRadius.xxl)
    .border({
      width: 0.5,
      color: MintColors.border,
      radius: BorderRadius.xxl
    })
    .transition(TransitionEffect.OPACITY.animation({
      duration: 300,
      curve: Curve.EaseOut
    }))
  }
}
