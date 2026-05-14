import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { PersonaSpec, ProfileBundle, ReasoningEffort, RouteParams } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { BreakpointSystem, BreakpointType } from '../common/BreakpointSystem'
import { ResponsiveLayoutMetrics, responsiveLayoutForBreakpoint } from '../common/ResponsiveLayout'
import { PersonaApi } from '../service/PersonaApi'
import { MeetingSessionStore } from '../utils/MeetingSessionStore'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import { AnimationDuration, AnimationCurve } from '../common/styles/Animation'
import { parseMeetingSelection } from '../common/MeetingSelection'
import { DynamicGlassBackground } from '../components/DynamicGlassBackground'
import { BackButton } from '../components/BackButton'
import { Colors } from '../common/styles/Colors'

type ThemeColor = ResourceColor | string
const FALLBACK_SAFE_TOP_VP: number = 52
type MeetingPrepFocus = '' | 'roles' | 'topic'
export class ReasoningEffortOption {
  value: ReasoningEffort = 'medium'
  label: string = ''
  description: string = ''
}

const REASONING_EFFORT_OPTIONS: ReasoningEffortOption[] = [
  { value: 'low', label: '快速', description: '更快回应' },
  { value: 'medium', label: '均衡', description: '速度质量平衡' },
  { value: 'high', label: '深入', description: '分析更稳' },
  { value: 'xhigh', label: '极致', description: '最强推理' }
]

export class ProfileAgentsGroup {
  profileId: string = ''
  displayName: string = ''
  agents: PersonaSpec[] = []
}

@Entry
@Component
struct MeetingParticipantPage {
  @State agents: PersonaSpec[] = []
  @State profileGroups: ProfileAgentsGroup[] = []
  @State profileIds: string[] = []
  @State selectedAgentIds: string[] = []
  @State loading: boolean = true
  @State error: string = ''
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0
  @State topic: string = ''
  @State meetingReasoningEffort: ReasoningEffort = 'medium'
  @State profileNameSummary: string = ''

  @State headerOpacity: number = 0
  @State headerTranslateY: number = 14
  @State contentOpacity: number = 0
  @State contentTranslateY: number = 22
  @State topicInputOpacity: number = 0
  @State topicInputTranslateY: number = 26
  @State pressingAgentId: string = ''
  /** 整页自右侧滑入（模拟路由转场） */
  @State pageSlideX: number = 36
  @State pageSlideOpacity: number = 0.92
  /** 列表与底部区块错峰：1=标题行，2+i=第 i 个人格卡片，之后为添加/议题/开始 */
  @State listStaggerStep: number = 0
  @State requestedFocus: MeetingPrepFocus = ''
  @State currentBreakpoint: BreakpointType = 'sm'

  private pageScroller: Scroller = new Scroller()
  private detachBreakpointListener?: () => void

  aboutToAppear(): void {
    this.attachResponsiveBreakpoint()
    this.loadSafeInsets()
    this.initializeSessionStore()

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.page,
        curve: AnimationCurve.emphasized
      }, () => {
        this.pageSlideX = 0
        this.pageSlideOpacity = 1
      })
    }, 10)

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.emphasized
      }, () => {
        this.headerOpacity = 1
        this.headerTranslateY = 0
      })
    }, 60)

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.friction
      }, () => {
        if (this.loading) {
          this.contentOpacity = 1
          this.contentTranslateY = 0
        }
      })
    }, 120)

    const rawParams = router.getParams()
    const params: RouteParams = rawParams ? rawParams as RouteParams : {}

    const sel = parseMeetingSelection(params)
    let ids: string[] = sel.profileIds.length > 0 ? sel.profileIds : []
    const single = params.profileId ?? ''
    if (ids.length === 0 && single.length > 0) {
      ids = [single]
    }
    if (ids.length === 0) {
      const sessionIds = MeetingSessionStore.getProfileIds()
      if (sessionIds.length > 0) {
        ids = [...sessionIds]
      } else {
        const one = MeetingSessionStore.getProfileId()
        if (one.length > 0) {
          ids = [one]
        }
      }
    }

    this.profileIds = ids
    MeetingSessionStore.setProfileIds(this.profileIds)

    if (sel.selectedAgentIds.length > 0) {
      this.selectedAgentIds = [...sel.selectedAgentIds]
    } else {
      this.syncSelectionFromSession()
    }

    const routeTopic = params.topic ?? ''
    if (routeTopic.length > 0) {
      try {
        this.topic = decodeURIComponent(routeTopic)
      } catch (_e) {
        this.topic = routeTopic
      }
    } else {
      const sessionTopic = MeetingSessionStore.getTopic()
      if (sessionTopic.length > 0) {
        this.topic = sessionTopic
      }
    }

    this.applyReasoningEffortFromRouteOrSession(params)
    this.applyFocusFromRoute(params)

    if (this.profileIds.length === 0) {
      this.error = '缺少人物信息，请返回重新选择。'
      this.loading = false
      return
    }

    this.loadAllProfiles()
  }

  private initializeSessionStore(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      void MeetingSessionStore.init(ctx).then(() => {
        this.syncSelectionFromSession()
      })
    } catch (_error) {
    }
  }

  onPageShow(): void {
    const pending = MeetingSessionStore.takePendingAddProfileId()
    if (pending.length > 0 && this.profileIds.indexOf(pending) < 0) {
      this.profileIds = [...this.profileIds, pending]
      MeetingSessionStore.setProfileIds(this.profileIds)
      this.loadAllProfiles()
    }
    this.syncSelectionFromSession()
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

  private normIds(arr: string[]): string {
    const copy: string[] = [...arr]
    copy.sort()
    return copy.join(',')
  }

  private syncSelectionFromSession(): void {
    const sessionIds = MeetingSessionStore.getProfileIds()
    if (sessionIds.length > 0 && this.normIds(sessionIds) !== this.normIds(this.profileIds)) {
      return
    }

    const sessionSelectedAgentIds = MeetingSessionStore.getSelectedAgents()
    if (sessionSelectedAgentIds.length > 0) {
      this.selectedAgentIds = [...sessionSelectedAgentIds]
    }

    const sessionTopic = MeetingSessionStore.getTopic()
    if (sessionTopic.length > 0) {
      this.topic = sessionTopic
    }

    this.meetingReasoningEffort = MeetingSessionStore.getReasoningEffort()
  }

  private applyReasoningEffortFromRouteOrSession(params: RouteParams): void {
    const raw = params.reasoningEffort
    if (raw === 'low' || raw === 'medium' || raw === 'high' || raw === 'xhigh') {
      this.meetingReasoningEffort = raw
      return
    }
    this.meetingReasoningEffort = MeetingSessionStore.getReasoningEffort()
  }

  private loadAllProfiles(): void {
    this.loading = true
    this.error = ''
    this.listStaggerStep = 0

    const loadTasks = this.profileIds.map((pid: string) => PersonaApi.getProfileBundle(pid))
    Promise.all(loadTasks)
      .then((bundles: ProfileBundle[]) => {
        const groups: ProfileAgentsGroup[] = bundles.map((b) => {
          const g: ProfileAgentsGroup = {
            profileId: b.profile.id,
            displayName: b.profile.displayName,
            agents: b.agents
          }
          return g
        })
        this.profileGroups = groups

        const seenAgent = new Set<string>()
        const merged: PersonaSpec[] = []
        bundles.forEach((b) => {
          b.agents.forEach((agent: PersonaSpec) => {
            if (!seenAgent.has(agent.agentId)) {
              seenAgent.add(agent.agentId)
              merged.push(agent)
            }
          })
        })
        this.agents = merged

        this.selectedAgentIds = this.selectedAgentIds.filter((agentId: string) =>
          merged.some((agent: PersonaSpec) => agent.agentId === agentId)
        )

        const names = groups.map((g: ProfileAgentsGroup) => g.displayName)
        if (names.length <= 2) {
          this.profileNameSummary = names.join('、')
        } else {
          this.profileNameSummary = `${names[0]} 等 ${names.length} 人`
        }

        this.loading = false
        this.scheduleContentStagger()
        this.scheduleFocusScroll()
      })
      .catch((err: Error) => {
        const errorMsg = err.message || '未知错误'
        this.error = `加载角色失败：${errorMsg}`
        this.loading = false
        this.listStaggerStep = 1
        animateTo({
          duration: AnimationDuration.normal,
          curve: AnimationCurve.emphasized
        }, () => {
          this.contentOpacity = 1
          this.contentTranslateY = 0
          this.topicInputOpacity = 1
          this.topicInputTranslateY = 0
        })
      })
  }

  /** 角色卡片与下方模块依次滑入 */
  private scheduleContentStagger(): void {
    animateTo({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.emphasized
    }, () => {
      this.contentOpacity = 1
      this.contentTranslateY = 0
      this.topicInputOpacity = 1
      this.topicInputTranslateY = 0
    })
    const n = this.agents.length
    const totalSteps = 1 + n + 2
    this.listStaggerStep = 0
    for (let s = 0; s < totalSteps; s++) {
      const stepIndex = s
      setTimeout(() => {
        animateTo({
          duration: AnimationDuration.normal,
          curve: AnimationCurve.emphasized
        }, () => {
          this.listStaggerStep = stepIndex + 1
        })
      }, 20 + stepIndex * 42)
    }
  }

  private applyFocusFromRoute(params: RouteParams): void {
    const rawFocus = params.focus ?? ''
    if (rawFocus === 'roles') {
      this.requestedFocus = rawFocus
      return
    }
    this.requestedFocus = ''
  }

  private scheduleFocusScroll(): void {
    if (this.requestedFocus.length === 0) {
      return
    }

    setTimeout(() => {
      this.pageScroller.scrollTo({ xOffset: 0, yOffset: this.rolesSectionOffset(), animation: true })
    }, 320)
  }

  private rolesSectionOffset(): number {
    return 180
  }

  private topicSectionOffset(): number {
    const agentRows = this.agents.length
    const profileHeaders = this.profileGroups.length
    const estimated = 420 + agentRows * 84 + profileHeaders * 42
    return Math.max(320, estimated)
  }

  private topicStaggerStep(): number {
    return 2 + this.agents.length + 1
  }

  private reasoningStaggerStep(): number {
    return 2 + this.agents.length + 3
  }

  private startStaggerStep(): number {
    return 2 + this.agents.length + 1
  }

  private staggerTopicVisible(): boolean {
    return this.listStaggerStep >= this.topicStaggerStep()
  }

  private staggerReasoningVisible(): boolean {
    return this.listStaggerStep >= this.reasoningStaggerStep()
  }

  private staggerStartVisible(): boolean {
    return this.listStaggerStep >= this.startStaggerStep()
  }

  private loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
        this.safeBottomVp = insets.bottomVp
      })
    } catch (_e) {
    }
  }

  private topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  private toggleAgent(agentId: string): void {
    if (this.selectedAgentIds.includes(agentId)) {
      this.selectedAgentIds = this.selectedAgentIds.filter((id: string) => id !== agentId)
    } else {
      this.selectedAgentIds = [...this.selectedAgentIds, agentId]
    }

    MeetingSessionStore.setProfileIds(this.profileIds)
    MeetingSessionStore.setSelectedAgents(this.selectedAgentIds)
  }

  private isSelected(agentId: string): boolean {
    return this.selectedAgentIds.includes(agentId)
  }

  private globalIndexFor(agentId: string): number {
    return this.agents.findIndex((a: PersonaSpec) => a.agentId === agentId)
  }

  private getAgentAccentColor(index: number): ThemeColor {
    const colors: ThemeColor[] = [
      MintColors.mint,
      MintColors.lavender,
      MintColors.warning,
      Colors.textMuted,
      MintColors.mintDark
    ]
    return colors[index % colors.length]
  }

  private removeProfile(pid: string): void {
    if (this.profileIds.length <= 1) {
      return
    }
    this.profileIds = this.profileIds.filter((p: string) => p !== pid)
    MeetingSessionStore.setProfileIds(this.profileIds)
    this.loadAllProfiles()
  }

  private addAnotherPerson(): void {
    MeetingSessionStore.setProfileIds(this.profileIds)
    MeetingSessionStore.setTopic(this.topic)
    MeetingSessionStore.setReasoningEffort(this.meetingReasoningEffort)
    MeetingSessionStore.setSelectedAgents(this.selectedAgentIds)
    router.pushUrl({
      url: 'pages/MeetingProfilePickerPage'
    })
  }

  private saveSelectionAndBack(): void {
    MeetingSessionStore.setProfileIds(this.profileIds)
    MeetingSessionStore.setProfileId(this.profileIds[0])
    MeetingSessionStore.setSelectedAgents(this.selectedAgentIds)
    MeetingSessionStore.setTopic(this.topic)
    MeetingSessionStore.setReasoningEffort(this.meetingReasoningEffort)
    router.replaceUrl({
      url: 'pages/Index',
      params: {
        profileId: this.profileIds[0],
        profileIds: this.profileIds.join(','),
        selectedAgentIds: this.selectedAgentIds.join(',')
      }
    })
  }

  private goBack(): void {
    router.back()
  }

  private openProfileDetailFor(profileId: string): void {
    MeetingSessionStore.setProfileIds(this.profileIds)
    MeetingSessionStore.setSelectedAgents(this.selectedAgentIds)
    MeetingSessionStore.setTopic(this.topic)
    MeetingSessionStore.setReasoningEffort(this.meetingReasoningEffort)
    router.pushUrl({
      url: 'pages/ProfileDetail',
      params: {
        profileId: profileId,
        selectedAgentIds: this.selectedAgentIds.join(','),
        returnToMeeting: '1'
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.buildBackground()

      Column() {
        this.buildTopBar()

        Column() {
          Scroll(this.pageScroller) {
            Column({ space: 12 }) {
              this.buildHeader()

              if (this.loading) {
                this.buildLoadingState()
              } else if (this.error) {
                this.buildErrorState()
              } else {
                this.buildContent()
              }
            }
            .width('100%')
            .constraintSize({ maxWidth: this.responsiveLayout().contentMaxWidth })
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({
          left: this.responsiveLayout().pageHorizontalPadding,
          right: this.responsiveLayout().pageHorizontalPadding,
          top: 14,
          bottom: this.safeBottomVp + Spacing.xl
        })
      }
      .width('100%')
      .height('100%')
      .translate({ x: this.pageSlideX })
      .opacity(this.pageSlideOpacity)
      .animation({
        duration: AnimationDuration.page,
        curve: AnimationCurve.emphasized
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildBackground() {
    DynamicGlassBackground()
  }

  @Builder
  buildTopBar() {
    Row({ space: 12 }) {
      BackButton({
        iconSize: 18,
        iconColor: MintColors.mintDark,
        bgColor: MintColors.surfaceGlass,
        buttonSize: 40,
        customOnClick: () => this.goBack()
      })
      .translate({ x: -10 })

      Text('选择参会者')
        .fontSize(Typography.size.bodyLg)
        .fontWeight(FontWeight.Bold)
        .fontColor(MintColors.textPrimary)
        .layoutWeight(1)
        .onClick(() => this.goBack())

      Text(this.profileNameSummary.length > 0 ? this.profileNameSummary : ' ')
        .fontSize(Typography.size.caption)
        .fontColor(MintColors.textMuted)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(MintColors.surfaceGlass)
        .borderRadius(BorderRadius.pill)
        .constraintSize({ maxWidth: '46%' })
    }
    .width('100%')
    .padding({
      left: this.responsiveLayout().pageHorizontalPadding,
      right: this.responsiveLayout().pageHorizontalPadding,
      top: this.topInsetVp() + 12
    })
    .opacity(this.headerOpacity)
    .translate({ y: this.headerTranslateY })
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.emphasized
    })
  }

  @Builder
  buildHeader(): void {
    Column({ space: 10 }) {
      Row() {
        Text('参会阵容')
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.accent)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(Colors.overlayMedium)
          .borderRadius(BorderRadius.pill)

        Blank()

        Text(this.selectedAgentIds.length > 0 ? `已选 ${this.selectedAgentIds.length} 位` : '待选择')
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedAgentIds.length > 0 ? '#FFFFFF' : MintColors.textSecondary)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.selectedAgentIds.length > 0 ? Colors.accent : Colors.overlaySoft)
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')

      Text('挑选这场会议的声音')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(MintColors.textPrimary)

      Text('从不同阶段里选出参会人格，让讨论更有冲突和层次。')
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 16, bottom: 18 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(MintColors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [Colors.overlayMedium, 0],
        [MintColors.cardSecondary, 0.48],
        [MintColors.cardElevated, 1]
      ]
    })
    .borderRadius(28)
    .border({
      width: 0.9,
      color: MintColors.border,
      radius: 28
    })
    .shadow({
      radius: 12,
      color: Colors.shadowMedium,
      offsetX: 0,
      offsetY: 6
    })
    .opacity(this.headerOpacity)
    .translate({ y: this.headerTranslateY })
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.emphasized
    })
  }

  @Builder
  buildLoadingState(): void {
    Column({ space: Spacing.md }) {
      LoadingProgress()
        .width(36)
        .height(36)
        .color(MintColors.mint)

      Text('加载角色中...')
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textMuted)

      if (this.profileIds.length > 0) {
        Text(`人物数：${this.profileIds.length}`)
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textSecondary)
      }
    }
    .width('100%')
    .padding(Spacing.xl)
    .alignItems(HorizontalAlign.Center)
    .opacity(this.contentOpacity)
    .translate({ y: this.contentTranslateY })
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.friction
    })
  }

  @Builder
  buildErrorState(): void {
    Column({ space: Spacing.lg }) {
      Column({ space: Spacing.sm }) {
        Text('⚠')
          .fontSize(48)
          .fontColor(MintColors.error)

        Text(this.error)
          .fontSize(Typography.size.body)
          .fontColor(MintColors.error)
          .textAlign(TextAlign.Center)
          .lineHeight(Typography.lineHeight.relaxed)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row({ space: Spacing.md }) {
        Button('返回上一页')
          .fontSize(Typography.size.body)
          .fontColor(Colors.textInverse)
          .backgroundColor(MintColors.mintDark)
          .borderRadius(BorderRadius.pill)
          .height(44)
          .width('45%')
          .stateEffect(true)
          .onClick(() => this.goBack())

        Button('重试')
          .fontSize(Typography.size.body)
          .fontColor(MintColors.mintDark)
          .backgroundColor('rgba(17, 17, 17, 0.12)')
          .borderRadius(BorderRadius.pill)
          .height(44)
          .width('45%')
          .stateEffect(true)
          .onClick(() => {
            this.loading = true
            this.error = ''
            this.loadAllProfiles()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(Spacing.xl)
    .alignItems(HorizontalAlign.Center)
    .opacity(this.contentOpacity)
    .translate({ y: this.contentTranslateY })
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.friction
    })
  }

  @Builder
  buildContent(): void {
    Column() {
      if (this.responsiveLayout().useSplitMeetingPrepLayout) {
        Row({ space: this.responsiveLayout().splitPanelGap }) {
          Column() {
            this.buildRoleList()
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: 12 }) {
            this.buildSaveButton()
          }
          .width('36%')
          .constraintSize({ minWidth: 260, maxWidth: 360 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        Column({ space: 12 }) {
          this.buildRoleList()
          this.buildSaveButton()
        }
        .width('100%')
      }
    }
    .width('100%')
    .opacity(this.contentOpacity)
    .translate({ y: this.contentTranslateY })
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.friction
    })
  }

  @Builder
  buildRoleList(): void {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('候选人格')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)

        Blank()

        Text(`${this.selectedAgentIds.length}/${this.agents.length} 已入席`)
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.accent)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(Colors.overlayMedium)
          .borderRadius(BorderRadius.pill)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .opacity(this.listStaggerStep >= 1 ? 1 : 0)
      .translate({ y: this.listStaggerStep >= 1 ? 0 : 14 })
      .animation({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.emphasized
      })

      Text('点一下加入阵容，再点一下移出。保存后首页会同步。')
        .fontSize(Typography.size.caption)
        .fontColor(MintColors.textMuted)
        .width('100%')

      Column({ space: 12 }) {
        ForEach(this.profileGroups, (group: ProfileAgentsGroup) => {
          Column({ space: 10 }) {
            Row({ space: 8 }) {
              Text(group.displayName)
                .fontSize(Typography.size.body)
                .fontWeight(FontWeight.Bold)
                .fontColor(MintColors.textPrimary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              if (this.profileIds.length > 1) {
                Button('移除')
                  .fontSize(Typography.size.caption)
                  .fontColor(MintColors.error)
                  .backgroundColor(Colors.loadingBg)
                  .borderRadius(BorderRadius.pill)
                  .height(30)
                  .padding({ left: 12, right: 12 })
                  .stateEffect(true)
                  .onClick(() => {
                    this.removeProfile(group.profileId)
                  })
              }
            }
            .width('100%')
            .padding({ left: 2, right: 2 })

            ForEach(group.agents, (agent: PersonaSpec) => {
              this.buildRoleItem(agent, this.globalIndexFor(agent.agentId))
            }, (agent: PersonaSpec) => `${group.profileId}_${agent.agentId}`)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }, (group: ProfileAgentsGroup) => group.profileId)
      }
      .width('100%')

      Button() {
        Row({ space: 8 }) {
          Text('+')
            .fontSize(18)
            .fontColor(MintColors.mintDark)
          Text('添加另一个人物')
            .fontSize(Typography.size.body)
            .fontColor(MintColors.mintDark)
        }
      }
      .type(ButtonType.Normal)
      .width('100%')
      .height(46)
      .backgroundColor(MintColors.cardSecondary)
      .borderRadius(20)
      .border({
        width: 1,
        color: MintColors.border,
        radius: 20
      })
      .stateEffect(true)
      .onClick(() => this.addAnotherPerson())
      .opacity(this.listStaggerStep >= 2 + this.agents.length ? 1 : 0)
      .translate({ y: this.listStaggerStep >= 2 + this.agents.length ? 0 : 16 })
      .animation({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.emphasized
      })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 16, bottom: 16 })
    .backgroundColor(MintColors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [MintColors.cardPrimary, 0],
        [MintColors.cardSecondary, 0.58],
        [MintColors.cardElevated, 1]
      ]
    })
    .borderRadius(26)
    .border({
      width: 0.9,
      color: MintColors.border,
      radius: 26
    })
    .shadow({
      radius: 14,
      color: Colors.shadowMedium,
      offsetX: 0,
      offsetY: 6
    })
  }

  @Builder
  buildRoleItem(agent: PersonaSpec, index: number): void {
    Row({ space: Spacing.md }) {
      Column() {
        Text(agent.displayName.length > 0 ? agent.displayName.charAt(0) : '?')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSelected(agent.agentId) ? '#FFFFFF' : this.getAgentAccentColor(index))
      }
      .width(42)
      .height(42)
      .borderRadius(16)
      .backgroundColor(this.isSelected(agent.agentId) ? this.getAgentAccentColor(index) : MintColors.backgroundSecondary)
      .border({
        width: this.isSelected(agent.agentId) ? 0 : 1.2,
        color: this.isSelected(agent.agentId) ? this.getAgentAccentColor(index) : MintColors.borderLight,
        radius: 16
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Text(agent.stageLabel)
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)

        Text(agent.timeLabel)
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textMuted)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.isSelected(agent.agentId)) {
        Column() {
          Text('✓')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textInverse)
        }
        .width(30)
        .height(30)
        .borderRadius(15)
        .backgroundColor(Colors.accent)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          Text('+')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.mintDark)
        }
        .width(30)
        .height(30)
        .borderRadius(15)
        .backgroundColor(MintColors.backgroundSecondary)
        .border({
          width: 1,
          color: MintColors.border,
          radius: 15
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 14, right: 12, top: 10, bottom: 10 })
    .borderRadius(22)
    .backgroundColor(this.isSelected(agent.agentId) ? Colors.overlaySoft : MintColors.cardSecondary)
    .border({
      width: this.isSelected(agent.agentId) ? 0.8 : 0.5,
      color: this.isSelected(agent.agentId) ? Colors.accent : MintColors.borderLight,
      radius: 22
    })
    .shadow({
      radius: this.isSelected(agent.agentId) ? 8 : 0,
      color: this.isSelected(agent.agentId) ? Colors.shadowSoft : 'rgba(255, 255, 255, 0.00)',
      offsetX: 0,
      offsetY: 4
    })
    .scale({
      x: this.pressingAgentId === agent.agentId ? 0.98 : 1,
      y: this.pressingAgentId === agent.agentId ? 0.98 : 1
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressingAgentId = agent.agentId
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressingAgentId = ''
      }
    })
    .opacity(this.listStaggerStep >= 2 + index ? 1 : 0)
    .translate({ y: this.listStaggerStep >= 2 + index ? 0 : 20 })
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.emphasized
    })
    .onClick(() => {
      this.toggleAgent(agent.agentId)
    })
  }

  @Builder
  buildTopicSection(): void {
    Column({ space: Spacing.md }) {
      Text('设置议题')
        .fontSize(Typography.size.bodyLg)
        .fontWeight(FontWeight.Bold)
        .fontColor(MintColors.textPrimary)

      TextInput({ placeholder: '输入你想讨论的议题...', text: this.topic })
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textPrimary)
        .placeholderColor(MintColors.textMuted)
        .backgroundColor(MintColors.cardPrimary)
        .borderRadius(BorderRadius.lg)
        .height(56)
        .padding({ left: 16, right: 16 })
        .border({
          width: 1,
          color: MintColors.borderLight,
          radius: BorderRadius.lg
        })
        .onChange((value: string) => {
          this.topic = value
          MeetingSessionStore.setTopic(value)
        })
    }
    .width('100%')
    .opacity(this.staggerTopicVisible() ? this.topicInputOpacity : 0)
    .translate({
      y: this.staggerTopicVisible() ? this.topicInputTranslateY : 18
    })
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.smooth
    })
  }

  @Builder
  buildReasoningEffortSection(): void {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
        Text('Agent 准度')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)
          .layoutWeight(1)

        Text(this.reasoningEffortLabel(this.meetingReasoningEffort))
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.mintDark)
      }
      .width('100%')

      Text('控制会议发言的推理强度，越高越稳，但整体耗时也会更长。')
        .fontSize(Typography.size.xs)
        .fontColor(MintColors.textMuted)
        .width('100%')

      Row({ space: 10 }) {
        ForEach(REASONING_EFFORT_OPTIONS, (option: ReasoningEffortOption) => {
          this.buildReasoningEffortChip(option)
        }, (option: ReasoningEffortOption) => option.value)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(BorderRadius.xxl2)
    .border({
      width: 0.8,
      color: MintColors.borderLight,
      radius: BorderRadius.xxl2
    })
    .opacity(this.staggerReasoningVisible() ? this.topicInputOpacity : 0)
    .translate({
      y: this.staggerReasoningVisible() ? this.topicInputTranslateY : 18
    })
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.smooth
    })
  }

  @Builder
  buildReasoningEffortChip(option: ReasoningEffortOption) {
    Column({ space: 4 }) {
      Text(option.label)
        .fontSize(Typography.size.body)
        .fontWeight(this.meetingReasoningEffort === option.value ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.meetingReasoningEffort === option.value ? '#FFFFFF' : MintColors.textPrimary)

      Text(option.description)
        .fontSize(10)
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .fontColor(this.meetingReasoningEffort === option.value ? MintColors.surfaceGlass : MintColors.textMuted)
    }
    .layoutWeight(1)
    .height(74)
    .padding({ left: 8, right: 8, top: 10, bottom: 10 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(BorderRadius.lg)
    .backgroundColor(this.meetingReasoningEffort === option.value ? MintColors.mintDark : MintColors.cardPrimary)
    .border({
      width: 1,
      color: this.meetingReasoningEffort === option.value ? MintColors.mintDark : MintColors.borderLight,
      radius: BorderRadius.lg
    })
    .onClick(() => {
      this.meetingReasoningEffort = option.value
      MeetingSessionStore.setReasoningEffort(option.value)
    })
  }

  private reasoningEffortLabel(value: ReasoningEffort): string {
    const found = REASONING_EFFORT_OPTIONS.find((option) => option.value === value)
    return found ? found.label : '均衡'
  }

  @Builder
  buildSaveButton(): void {
    Column({ space: Spacing.sm }) {
      Text(`已选 ${this.selectedAgentIds.length} 位角色 · ${this.profileIds.length} 位人物`)
        .fontSize(Typography.size.caption)
        .fontColor(this.selectedAgentIds.length > 0 ? Colors.accent : MintColors.textMuted)

      Button(this.selectedAgentIds.length > 0 ? '保存并返回首页' : '暂未选择角色')
        .fontSize(Typography.size.body)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.selectedAgentIds.length > 0 ? '#FFFFFF' : MintColors.textSecondary)
        .backgroundColor(this.selectedAgentIds.length > 0 ? Colors.accent : Colors.overlaySoft)
        .linearGradient({
          angle: 135,
          colors: this.selectedAgentIds.length > 0
            ? [
              [Colors.primary, 0],
              [Colors.accent, 1]
            ]
            : [
              [Colors.overlayMedium, 0],
              [Colors.cardSecondary, 1]
            ]
        })
        .border({
          width: 1,
          color: this.selectedAgentIds.length > 0 ? Colors.primary : MintColors.border,
          radius: BorderRadius.pill
        })
        .borderRadius(BorderRadius.pill)
        .height(50)
        .width('100%')
        .shadow({
          radius: this.selectedAgentIds.length > 0 ? 14 : 0,
          color: this.selectedAgentIds.length > 0 ? Colors.shadowMedium : 'rgba(255, 255, 255, 0.00)',
          offsetX: 0,
          offsetY: 5
        })
        .stateEffect(true)
        .onClick(() => this.saveSelectionAndBack())

      Text('保存后回到首页，参数和会议入口会自动同步。')
        .fontSize(Typography.size.caption)
        .fontColor(MintColors.textMuted)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(22)
    .border({
      width: 0.7,
      color: MintColors.border,
      radius: 22
    })
    .shadow({
      radius: 12,
      color: Colors.shadowSoft,
      offsetX: 0,
      offsetY: 5
    })
    .opacity(this.staggerStartVisible() ? this.topicInputOpacity : 0)
    .translate({
      y: this.staggerStartVisible() ? this.topicInputTranslateY : 18
    })
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.smooth
    })
  }
}
