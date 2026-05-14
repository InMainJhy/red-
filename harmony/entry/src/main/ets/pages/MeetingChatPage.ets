import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import {
  ARENA_USER_TOPIC_AGENT_ID,
  ArenaMessage,
  ArenaRun,
  ArenaStreamEvent,
  ArenaSummary,
  PersonaSpec,
  ReasoningEffort,
  RouteParams
} from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { BreakpointSystem, BreakpointType } from '../common/BreakpointSystem'
import { ResponsiveLayoutMetrics, responsiveLayoutForBreakpoint } from '../common/ResponsiveLayout'
import { PersonaApi } from '../service/PersonaApi'
import { SummaryService } from '../service/SummaryService'
import { MeetingSessionStore } from '../utils/MeetingSessionStore'
import { buildHistoryRecordFromArenaRun } from '../utils/MeetingSessionPersistence'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import { AnimationDuration, AnimationCurve } from '../common/styles/Animation'
import { parseMeetingSelection } from '../common/MeetingSelection'
import promptAction from '@ohos.promptAction'
import { BackButton } from '../components/BackButton'
import { DynamicGlassBackground } from '../components/DynamicGlassBackground'
import { Colors } from '../common/styles/Colors'

type ThemeColor = ResourceColor | string
const FALLBACK_SAFE_TOP_VP: number = 52
const DEFAULT_TOPIC: string = ''
const MEETING_GLASS_BG: ThemeColor = MintColors.surfaceGlass
const MEETING_GLASS_BORDER: ThemeColor = MintColors.border
const MEETING_DEEP_BLUE: ThemeColor = Colors.accent
const MEETING_BRIGHT_BLUE: ThemeColor = MintColors.lavenderDark

/** 为 true 时显示底部输入条；当前也用于“输入议题后启动会议” */
const SHOW_MEETING_COMPOSER: boolean = true
/** 为 false 时隐藏会议进行中状态条上的红色「打断」按钮 */
const SHOW_MEETING_INTERRUPT_BUTTON: boolean = false

type MeetingStage = 'init' | 'checking' | 'loading' | 'running' | 'done' | 'interrupted' | 'error'

@Entry
@Component
struct MeetingChatPage {
  @State profileId: string = ''
  @State profileIds: string[] = []
  @State topic: string = DEFAULT_TOPIC
  @State selectedAgents: PersonaSpec[] = []
  @State selectedAgentIds: string[] = []
  @State reasoningEffort: ReasoningEffort = 'medium'

  @State messages: ArenaMessage[] = []
  @State liveDraftText: string = ''  // 当前发言中的草稿文本
  @State liveSpeakerId: string = ''  // 当前正在发言的人格 ID
  @State summary: ArenaSummary | null = null
  @State stage: MeetingStage = 'init'
  @State errorMessage: string = ''
  @State connectionStatus: string = '连接中...'
  @State progressText: string = ''

  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0

  @State fallbackNotice: string = ''

  @State activeSessionId: string = ''  // 用于中断功能的会话 ID
  @State canInterrupt: boolean = false  // 当前是否可以中断

  @State liveSummaryText: string = ''  // 实时累积的总结文本
  @State lastRunId: string = ''  // run_started / 流内 runId，用于结果兜底拉取

  @State userInputDraft: string = ''
  @State composerBusy: boolean = false
  @State localUserBubbleSeq: number = 0

  @State pageSlideX: number = 36
  @State pageSlideOpacity: number = 0.92
  @State currentBreakpoint: BreakpointType = 'sm'

  private detachBreakpointListener?: () => void

  aboutToAppear(): void {
    this.attachResponsiveBreakpoint()
    this.loadSafeInsets()
    this.initializeLocalStores()
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.page,
        curve: AnimationCurve.emphasized
      }, () => {
        this.pageSlideX = 0
        this.pageSlideOpacity = 1
      })
    }, 10)

    const rawParams = router.getParams()
    const params: RouteParams = rawParams ? rawParams as RouteParams : {}
    this.profileId = params.profileId ?? ''

    const sel = parseMeetingSelection(params)
    if (sel.profileIds.length > 0) {
      this.profileIds = sel.profileIds
    }
    if (sel.selectedAgentIds.length > 0) {
      this.selectedAgentIds = sel.selectedAgentIds
    }

    const rawTopic = params.topic ?? ''
    if (rawTopic.length > 0) {
      try {
        this.topic = decodeURIComponent(rawTopic)
      } catch (_e) {
        this.topic = rawTopic
      }
    } else {
      this.topic = ''
    }

    this.applyReasoningEffortFromRoute(params)

    if (this.profileIds.length === 0 && this.profileId.length > 0) {
      this.profileIds = [this.profileId]
    }
    if (this.profileIds.length === 0) {
      const sessionIds = MeetingSessionStore.getProfileIds()
      if (sessionIds.length > 0) {
        this.profileIds = [...sessionIds]
      }
    }
    if (this.profileId.length === 0 && this.profileIds.length > 0) {
      this.profileId = this.profileIds[0]
    }
    if (this.profileId.length === 0) {
      const sessionProfileId = MeetingSessionStore.getProfileId()
      if (sessionProfileId.length > 0) {
        this.profileId = sessionProfileId
        if (this.profileIds.length === 0) {
          this.profileIds = [sessionProfileId]
        }
      }
    }

    if (this.selectedAgentIds.length === 0) {
      this.selectedAgentIds = MeetingSessionStore.getSelectedAgents()
    }

    if (this.topic.length === 0) {
      const sessionTopic = MeetingSessionStore.getTopic()
      if (sessionTopic.length > 0) {
        this.topic = sessionTopic
      }
    }

    const continueFromRunId = (params.continueFromRunId ?? MeetingSessionStore.getContinueFromRunId()).trim()
    const continuedSessionId = (params.sessionId ?? MeetingSessionStore.getSessionId()).trim()
    if (continueFromRunId.length > 0) {
      this.lastRunId = continueFromRunId
    }
    if (continuedSessionId.length > 0) {
      this.activeSessionId = continuedSessionId
    }

    const effectiveProfiles: string[] = this.profileIds.length > 0 ? this.profileIds :
      (this.profileId.length > 0 ? [this.profileId] : [])
    if (effectiveProfiles.length === 0 || this.selectedAgentIds.length < 2) {
      this.stage = 'error'
      this.errorMessage = '会议尚未准备完成，请先到会议准备里添加至少 2 位参会人格。'
      return
    }

    if (this.lastRunId.length > 0) {
      void this.preloadSelectedAgents()
      this.stage = 'init'
      this.connectionStatus = '等待续聊'
      this.progressText = '在下方输入插话，继续上一场会议'
      return
    }

    if (this.topic.trim().length === 0) {
      void this.preloadSelectedAgents()
      this.stage = 'init'
      this.connectionStatus = '等待议题'
      this.progressText = '在下方输入议题后开始会议'
      return
    }

    this.initializeAndStart()
  }

  private initializeLocalStores(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      void MeetingSessionStore.init(ctx)
      void SummaryService.init(ctx)
    } catch (_error) {
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

  /** 生成过程中也要展示已收到的消息 */
  private ensureContentVisible(): void {
  }

  private async preloadSelectedAgents(): Promise<void> {
    if (this.selectedAgents.length > 0 || this.selectedAgentIds.length < 2) {
      return
    }
    try {
      const bundle = await PersonaApi.getSelectedAgentsForMeeting(
        this.profileIds.length > 0 ? this.profileIds : [this.profileId],
        this.selectedAgentIds
      )
      this.selectedAgents = bundle.selectedAgents
    } catch (_error) {
    }
  }

  private async initializeAndStart(): Promise<void> {
    this.stage = 'checking'
    this.connectionStatus = '正在连接服务器...'
    this.progressText = '检查后端连接状态'

    try {
      const health = await PersonaApi.checkHealth()
      if (!health) {
        this.connectionStatus = '后端连接失败'
        this.stage = 'error'
        this.errorMessage = '无法连接到后端服务器，请检查网络或后端服务状态。'
        return
      }

      this.connectionStatus = `已连接: ${PersonaApi.getConnectionLabel()}`
      this.progressText = '正在加载参会人格...'
      this.stage = 'loading'

      const bundle = await PersonaApi.getSelectedAgentsForMeeting(
        this.profileIds.length > 0 ? this.profileIds : [this.profileId],
        this.selectedAgentIds
      )
      this.selectedAgents = bundle.selectedAgents

      if (this.selectedAgents.length < 2) {
        this.stage = 'error'
        this.errorMessage = `只找到 ${this.selectedAgents.length} 位人格，需要至少 2 位。请返回重新选择。`
        return
      }

      this.progressText = '人格加载完成，开始生成会议...'
      this.stage = 'running'

      this.messages = []
      this.liveDraftText = ''
      this.liveSpeakerId = ''

      this.progressText = '正在连接流式对话...'
      this.lastRunId = ''
      this.activeSessionId = ''
      this.canInterrupt = false

      try {
        await PersonaApi.streamArena(
          this.topic,
          this.selectedAgents,
          'chat',
          (event: ArenaStreamEvent) => this.handleStreamEvent(event),
          (error: string) => this.handleStreamError(error),
          () => this.handleStreamComplete()
        )
      } catch (_streamError) {
        await this.runMeetingFallback()
      }
    } catch (error) {
      this.connectionStatus = '生成失败'
      this.stage = 'error'
      const errorText = error instanceof Error ? error.message : '未知错误'
      this.errorMessage = `会议生成失败：${errorText}`
    }
  }

  private handleStreamEvent(event: ArenaStreamEvent): void {
    const eventType = event.type

    if (eventType === 'run_started') {
      const runIdTrim = event.runId.trim()
      const sessionTrim = (event.sessionId ?? '').trim()
      if (runIdTrim.length > 0) {
        this.lastRunId = runIdTrim
      }
      // 仅使用服务端下发的 sessionId；runId 与 session 语义不同，冒充会导致 /sessions/:id/interrupt 报 Parameter error
      if (sessionTrim.length > 0) {
        this.activeSessionId = sessionTrim
        this.canInterrupt = true
      } else {
        this.canInterrupt = false
      }
      this.progressText = '会议开始...'
    } else if (eventType === 'phase_started') {
      const phaseLabels: Record<string, string> = {
        'opening': '开场阶段...',
        'reflection': '反思阶段...',
        'rebuttal': '反驳阶段...',
        'synthesis': '综合阶段...',
        'closing': '收尾阶段...',
        'manual': '手动模式...'
      }
      this.progressText = phaseLabels[event.phase ?? ''] ?? '生成中...'
    } else if (eventType === 'speaker_started') {
      this.liveSpeakerId = event.agentId ?? ''
      this.liveDraftText = ''
      const aid = event.agentId ?? ''
      if (aid.length > 0) {
        const ag = this.selectedAgents.find((a: PersonaSpec) => a.agentId === aid)
        this.progressText = ag ? `${ag.stageLabel} · 正在流式输出` : '人格正在发言…'
      } else {
        this.progressText = '人格正在发言…'
      }
    } else if (eventType === 'speaker_delta') {
      if (event.channel === 'thinking') {
        return
      }
      if (event.delta && event.delta.length > 0) {
        this.liveDraftText = this.liveDraftText + event.delta
      } else if (event.accumulatedText && event.accumulatedText.length > 0) {
        this.liveDraftText = event.accumulatedText
      }
    } else if (eventType === 'speaker_completed') {
      if (event.message) {
        this.messages = [...this.messages, event.message]
      }
      this.liveDraftText = ''
      this.liveSpeakerId = ''
    } else if (eventType === 'message') {
      if (event.message) {
        this.messages = [...this.messages, event.message]
      }
    } else if (eventType === 'summary_delta') {
      if (event.delta && event.delta.length > 0) {
        this.liveSummaryText = this.liveSummaryText + event.delta
      } else if (event.accumulatedText && event.accumulatedText.length > 0) {
        this.liveSummaryText = event.accumulatedText
      }
    } else if (eventType === 'summary') {
      if (event.summary) {
        this.summary = event.summary
      } else if (this.liveSummaryText.length > 0) {
        this.summary = {
          title: '会议总结',
          consensus: this.liveSummaryText,
          disagreements: [],
          actionableAdvice: [],
          narrativeHook: ''
        }
      }
    } else if (eventType === 'done') {
      if (event.runId && event.runId.length > 0) {
        this.lastRunId = event.runId
      }
      if (event.result) {
        const resSid = event.result.sessionId?.trim()
        if (resSid !== undefined && resSid.length > 0) {
          this.activeSessionId = resSid
        }
        if (event.result.messages && event.result.messages.length > 0) {
          this.messages = [...event.result.messages]
        }
        if (event.result.summary) {
          this.summary = event.result.summary
        }
      }
      this.liveDraftText = ''
      this.liveSpeakerId = ''
      this.stage = 'done'
      this.canInterrupt = false
      this.connectionStatus = '会议生成完成'
      const completedRun: ArenaRun | null = event.result ? event.result : this.buildCompletedRunSnapshot()
      if (completedRun) {
        void this.persistCompletedMeeting(completedRun)
      }
    } else if (eventType === 'error') {
      this.connectionStatus = '生成失败'
      this.stage = 'error'
      this.errorMessage = event.error ?? '会议发生错误'
    }
  }

  /** 打断当前会议 */
  async interruptMeeting(): Promise<void> {
    if (!this.activeSessionId || !this.canInterrupt) return

    try {
      await PersonaApi.interruptArenaSession(this.activeSessionId)
      this.stage = 'interrupted'
      this.canInterrupt = false
      this.connectionStatus = '已打断'
      this.progressText = '会议已被中断'
    } catch (error) {
      const errorText = error instanceof Error ? error.message : '未知错误'
      this.errorMessage = `打断失败：${errorText}`
    }
  }

  private handleStreamError(error: string): void {
    if (this.selectedAgents.length >= 2 && this.messages.length === 0 && this.stage === 'running') {
      this.fallbackNotice = '流式连接异常，已自动切换为普通会议模式。'
      void this.runMeetingFallback().catch((fallbackError: Error) => {
        this.connectionStatus = '生成失败'
        this.stage = 'error'
        const errorText = fallbackError instanceof Error ? fallbackError.message : `${fallbackError}`
        this.errorMessage = `流式传输错误：${error}；普通模式也失败：${errorText}`
      })
      return
    }
    this.connectionStatus = '生成失败'
    this.stage = 'error'
    this.errorMessage = `流式传输错误：${error}`
  }

  private handleStreamComplete(): void {
    if (this.stage === 'running') {
      this.stage = 'done'
      this.connectionStatus = '会议生成完成'
    }
  }

  private revealResult(): void {
  }

  private async runMeetingFallback(): Promise<void> {
    this.connectionStatus = '普通模式生成中'
    this.progressText = '流式连接不稳定，正在切换普通会议模式...'
    this.fallbackNotice = '流式连接不稳定，已自动切换为普通会议模式。'

    try {
      const result = await PersonaApi.runArena(
        this.topic,
        this.selectedAgents,
        'chat'
      )

      this.lastRunId = result.runId
      this.messages = result.messages ?? []
      this.summary = result.summary ?? null
      this.liveDraftText = ''
      this.liveSpeakerId = ''
      this.liveSummaryText = ''
      this.stage = 'done'
      this.canInterrupt = false
      this.connectionStatus = '会议生成完成'
      this.progressText = '会议已完成'
      await this.persistCompletedMeeting(result)
      this.revealResult()
    } catch (fallbackError) {
      const errorText = fallbackError instanceof Error ? fallbackError.message : '未知错误'
      this.connectionStatus = '生成失败'
      this.stage = 'error'
      this.errorMessage = `会议生成失败：${errorText}`
    }
  }

  private liveSpeakerLabel(): string {
    if (this.liveSpeakerId.length === 0) {
      return ''
    }
    const agent = this.selectedAgents.find((a: PersonaSpec) => a.agentId === this.liveSpeakerId)
    return agent ? agent.displayName : this.liveSpeakerId
  }

  private getAgentAccentColor(agentId: string): ThemeColor {
    const index = this.selectedAgents.findIndex((a: PersonaSpec) => a.agentId === agentId)
    const colors: ThemeColor[] = [
      MintColors.mint,
      MintColors.lavender,
      MintColors.warning,
      Colors.textMuted,
      MintColors.mintDark
    ]
    return colors[Math.max(0, index) % colors.length]
  }

  private getMessageBubbleBackground(agentId: string): ThemeColor {
    const index = this.selectedAgents.findIndex((a: PersonaSpec) => a.agentId === agentId)
    const alt = Math.max(0, index) % 2 === 0
    return alt ? MintColors.cardPrimary : 'rgba(17, 17, 17, 0.11)'
  }

  private applyReasoningEffortFromRoute(params: RouteParams): void {
    const raw = params.reasoningEffort
    if (raw === 'low' || raw === 'medium' || raw === 'high' || raw === 'xhigh') {
      this.reasoningEffort = raw
      return
    }
    this.reasoningEffort = MeetingSessionStore.getReasoningEffort()
  }

  private reasoningEffortLabel(value: ReasoningEffort): string {
    if (value === 'low') {
      return '快速'
    }
    if (value === 'high') {
      return '深入'
    }
    if (value === 'xhigh') {
      return '极致'
    }
    return '均衡'
  }

  private goBack(): void {
    router.back()
  }

  private backToMeetingSetup(): void {
    const effectiveProfiles: string[] = this.profileIds.length > 0 ? this.profileIds :
      (this.profileId.length > 0 ? [this.profileId] : [])

    if (effectiveProfiles.length === 0) {
      router.replaceUrl({
        url: 'pages/Index'
      })
      return
    }

    router.replaceUrl({
      url: 'pages/MeetingParticipantPage',
      params: {
        profileId: effectiveProfiles[0],
        profileIds: effectiveProfiles.join(','),
        selectedAgentIds: this.selectedAgentIds.join(','),
        topic: this.topic,
        reasoningEffort: this.reasoningEffort,
        focus: 'roles'
      }
    })
  }

  private isUserMessage(msg: ArenaMessage): boolean {
    return msg.kind === 'user' || msg.agentId === ARENA_USER_TOPIC_AGENT_ID
  }

  private shouldShowComposer(): boolean {
    return SHOW_MEETING_COMPOSER &&
      this.selectedAgentIds.length >= 2 &&
      (
        this.stage === 'init' ||
        (
          this.selectedAgents.length >= 2 &&
          (this.stage === 'running' || this.stage === 'done' || this.stage === 'interrupted') &&
          this.lastRunId.length > 0
        )
      )
  }

  private composerReserveBottomVp(): number {
    return this.shouldShowComposer() ? 128 : 0
  }

  private appendLocalUserBubble(text: string): void {
    this.localUserBubbleSeq = this.localUserBubbleSeq + 1
    const msg: ArenaMessage = {
      id: `local-user-${this.localUserBubbleSeq}`,
      kind: 'user',
      agentId: ARENA_USER_TOPIC_AGENT_ID,
      displayName: '我',
      stageLabel: '参会者',
      content: text,
      stance: 'neutral'
    }
    this.messages = [...this.messages, msg]
    this.ensureContentVisible()
  }

  private async sendUserIntervention(): Promise<void> {
    const text = this.userInputDraft.trim()
    if (this.composerBusy) {
      return
    }
    if (this.stage === 'init' && this.lastRunId.length === 0) {
      await this.startMeetingFromDraft(text)
      return
    }
    if (text.length === 0) {
      try {
        promptAction.openToast({ message: '请先输入要插话的内容' })
      } catch (_e) {
      }
      return
    }
    if (this.lastRunId.length === 0) {
      this.errorMessage = '请等待会议开始后再插话。'
      return
    }
    if (this.selectedAgents.length < 2) {
      await this.preloadSelectedAgents()
    }
    if (this.selectedAgents.length < 2) {
      this.errorMessage = '历史参会人格尚未加载完成，请稍后再试。'
      return
    }

    const continueFrom = this.lastRunId
    const sessionForContinue = this.activeSessionId.length > 0 ? this.activeSessionId : undefined

    this.composerBusy = true
    this.errorMessage = ''

    try {
      if (this.stage === 'running' && this.canInterrupt && this.activeSessionId.length > 0) {
        try {
          await PersonaApi.interruptArenaSession(this.activeSessionId)
          this.stage = 'interrupted'
          this.canInterrupt = false
          this.connectionStatus = '已打断'
          this.progressText = '已打断，正在按你的插话续聊…'
        } catch (interruptErr) {
          const errorText = interruptErr instanceof Error ? interruptErr.message : '未知错误'
          this.errorMessage = `打断失败：${errorText}`
          this.composerBusy = false
          return
        }
      }

      this.userInputDraft = ''
      this.appendLocalUserBubble(text)

      this.liveDraftText = ''
      this.liveSpeakerId = ''
      this.liveSummaryText = ''
      this.summary = null
      this.stage = 'running'
      this.connectionStatus = `已连接: ${PersonaApi.getConnectionLabel()}`
      this.progressText = '正在根据你的插话继续会议…'

      try {
        await PersonaApi.streamArena(
          this.topic,
          this.selectedAgents,
          'chat',
          (event: ArenaStreamEvent) => this.handleStreamEvent(event),
          (error: string) => this.handleStreamError(error),
          () => this.handleStreamComplete(),
          undefined,
          {
            guidance: text,
            continueFromRunId: continueFrom,
            sessionId: sessionForContinue
          }
        )
      } catch (streamErr) {
        const errText = streamErr instanceof Error ? streamErr.message : '未知错误'
        this.connectionStatus = '续聊流式失败'
        this.stage = 'done'
        this.errorMessage = `续聊流式连接失败：${errText}`
      }
    } catch (outer) {
      const errorText = outer instanceof Error ? outer.message : '未知错误'
      this.connectionStatus = '续聊失败'
      this.stage = this.messages.length > 0 ? 'done' : 'error'
      this.errorMessage = `续聊失败：${errorText}`
    } finally {
      this.composerBusy = false
    }
  }

  private async startMeetingFromDraft(text: string): Promise<void> {
    if (text.length === 0) {
      try {
        promptAction.openToast({ message: '请先输入议题' })
      } catch (_e) {
      }
      return
    }

    this.userInputDraft = ''
    this.topic = text
    MeetingSessionStore.setTopic(text)
    this.errorMessage = ''
    await this.initializeAndStart()
  }

  private buildCompletedRunSnapshot(): ArenaRun | null {
    if (this.lastRunId.length <= 0 || this.selectedAgents.length < 2 || !this.summary) {
      return null
    }

    return {
      runId: this.lastRunId,
      sessionId: this.activeSessionId.length > 0 ? this.activeSessionId : undefined,
      status: 'completed',
      mode: 'chat',
      topic: this.topic,
      participants: [...this.selectedAgents],
      messages: [...this.messages],
      summary: this.summary,
      createdAt: new Date().toISOString()
    }
  }

  private async persistCompletedMeeting(run: ArenaRun): Promise<void> {
    const effectiveProfiles: string[] = this.profileIds.length > 0 ? [...this.profileIds] :
      (this.profileId.length > 0 ? [this.profileId] : [])
    const primaryProfileId = effectiveProfiles.length > 0 ? effectiveProfiles[0] : undefined

    MeetingSessionStore.setContinueContext(run.runId, run.sessionId)
    MeetingSessionStore.upsertHistoryRecord(buildHistoryRecordFromArenaRun(run, effectiveProfiles))

    try {
      if (!SummaryService.isReady()) {
        const ctx = getContext(this) as common.UIAbilityContext
        await SummaryService.init(ctx)
      }
      await SummaryService.createSummary(run, primaryProfileId)
      this.progressText = '会议已完成，已同步到纪要'
      promptAction.openToast({ message: '会议已同步到纪要' })
    } catch (error) {
      console.error('[MeetingChatPage] persistCompletedMeeting failed:', error)
      this.progressText = '会议已完成，纪要同步失败'
      try {
        promptAction.openToast({ message: '会议已完成，但纪要同步失败' })
      } catch (_toastError) {
      }
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.buildBackground()

      Column() {
        this.buildTopBar()

        Column() {
          Scroll() {
            Column({ space: Spacing.lg }) {
              if (this.stage === 'init') {
                this.buildWaitingTopicHint()
              }

              if (this.stage === 'checking' || this.stage === 'loading') {
                this.buildLoadingState()
              }

              if (this.stage === 'running') {
                this.buildConversationArea(true)
              }

              if (this.stage === 'interrupted') {
                this.buildInterruptedState()
              }

              if (this.stage === 'error') {
                this.buildErrorDisplay()
              }

              if (this.stage === 'done' || this.stage === 'interrupted') {
                if (this.messages.length > 0) {
                  this.buildConversationArea(false)
                }
              }

              if (this.summary && this.stage === 'done') {
                this.buildSummaryCard()
              }

              if (this.stage === 'done' && this.messages.length === 0 && this.summary === null) {
                this.buildEmptyOutcomeHint()
              }
            }
            .width('100%')
            .constraintSize({ maxWidth: this.responsiveLayout().contentWideMaxWidth })
            .alignItems(HorizontalAlign.Start)
            .padding({
              left: this.responsiveLayout().pageHorizontalPadding,
              right: this.responsiveLayout().pageHorizontalPadding,
              top: Spacing.sm,
              bottom: this.safeBottomVp + Spacing.xl + this.composerReserveBottomVp()
            })
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)

          if (this.shouldShowComposer()) {
            Column({ space: 6 }) {
              if (this.errorMessage.length > 0) {
                Text(this.errorMessage)
                  .fontSize(Typography.size.caption)
                  .fontColor(MintColors.error)
                  .width('100%')
                  .lineHeight(18)
              }

              Row({ space: 8 }) {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(MintColors.mint)

                Text(this.stage === 'init'
                  ? (this.lastRunId.length > 0 ? '继续上一场会议' : '输入议题后发送')
                  : '作为参会者加入讨论')
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('rgba(47, 124, 200, 0.76)')
              }
                .width('100%')
                .padding({ left: 4, right: 4 })

              Row({ space: 7 }) {
                TextArea({
                  text: this.userInputDraft,
                  placeholder: this.stage === 'init'
                    ? (this.lastRunId.length > 0 ? '输入你的插话，继续上一场会议…' : '输入这场会议想讨论的议题…')
                    : '随时输入观点，发送后人格会围绕你的插话继续讨论…'
                })
                  .layoutWeight(1)
                  .height(44)
                  .fontSize(15)
                  .fontColor(MintColors.textPrimary)
                  .placeholderColor(MintColors.textPlaceholder)
                  .backgroundColor(MintColors.cardSecondary)
                  .linearGradient({
                    direction: GradientDirection.Right,
                    colors: [
                      [Colors.overlayMedium, 0],
                      [MintColors.cardSecondary, 1]
                    ]
                  })
                  .borderRadius(24)
                  .border({
                    width: 1.1,
                    color: MintColors.border,
                    radius: 24
                  })
                  .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                  .enabled(!this.composerBusy)
                  .onChange((value: string) => {
                    this.userInputDraft = value
                  })

                Button('发送')
                  .height(44)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Colors.textInverse)
                  .backgroundColor(MintColors.mint)
                  .linearGradient({
                    direction: GradientDirection.Right,
                    colors: [
                      ['#18C6E0', 0],
                      ['#198FDD', 1]
                    ]
                  })
                  .border({
                    width: 1,
                    color: 'rgba(255, 255, 255, 0.24)',
                    radius: 24
                  })
                  .borderRadius(24)
                  .padding({ left: 18, right: 18 })
                  .shadow({
                    radius: 14,
                    color: 'rgba(24, 158, 221, 0.24)',
                    offsetX: 0,
                    offsetY: 5
                  })
                  .stateEffect(true)
                  .enabled(!this.composerBusy)
                  .onClick(() => {
                    void this.sendUserIntervention()
                  })
              }
              .width('100%')
              .padding({ left: 7, right: 7, top: 7, bottom: 7 })
              .backgroundColor(MintColors.cardPrimary)
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [
                  [Colors.overlayMedium, 0],
                  [MintColors.cardSecondary, 1]
                ]
              })
              .border({
                width: 1,
                color: MintColors.border,
                radius: 26
              })
              .borderRadius(26)
              .shadow({
                radius: 10,
                color: Colors.shadowSoft,
                offsetX: 0,
                offsetY: 4
              })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .padding({
              left: this.responsiveLayout().pageHorizontalPadding,
              right: this.responsiveLayout().pageHorizontalPadding,
              top: 10,
              bottom: this.safeBottomVp + 10
            })
            .backgroundColor(MintColors.surfaceGlass)
            .backdropBlur(20)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                ['rgba(255, 255, 255, 0.95)', 0],
                ['rgba(232, 247, 255, 0.90)', 0.64],
                ['rgba(244, 250, 255, 0.94)', 1]
              ]
            })
            .borderRadius({ topLeft: 28, topRight: 28 })
            .borderWidth({ top: 1 })
            .borderColor({ top: MEETING_GLASS_BORDER })
            .shadow({
              radius: 20,
              color: 'rgba(82, 142, 190, 0.12)',
              offsetX: 0,
              offsetY: -4
            })
            .zIndex(50)
          }
        }
        .layoutWeight(1)
        .width('100%')
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
        iconColor: MEETING_DEEP_BLUE,
        bgColor: MintColors.surfaceGlass,
        buttonSize: 42,
        customOnClick: () => this.goBack()
      })
      .translate({ x: -6 })

      Column({ space: 2 }) {
        Text(
          this.stage === 'init'
            ? '等待议题'
            : (this.stage === 'done' ? '会议已结束' : (this.stage === 'error' ? '生成失败' : '会议进行中'))
        )
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textMuted)

        Text(this.summary?.title ?? (this.topic.length > 0 ? this.topic : '人格会议'))
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => this.goBack())

      Text(`${this.selectedAgents.length} 位`)
        .fontSize(Typography.size.xs)
        .fontWeight(FontWeight.Bold)
        .fontColor(MEETING_BRIGHT_BLUE)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('rgba(227, 244, 255, 0.92)')
        .border({
          width: 1,
          color: MintColors.cardPrimary,
          radius: BorderRadius.pill
        })
        .borderRadius(BorderRadius.pill)
    }
    .width('100%')
    .padding({
      left: this.responsiveLayout().pageHorizontalPadding,
      right: this.responsiveLayout().pageHorizontalPadding,
      top: this.topInsetVp() + 12,
      bottom: 10
    })
  }

  /** 固定在顶部的精简头部，像普通聊天页面一样 */
  @Builder
  buildFixedHeader(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(180)
        .height(120)
        .borderRadius(70)
        .backgroundColor('rgba(88, 216, 232, 0.12)')
        .blur(18)
        .position({ right: -54, y: -26 })

      Column({ space: Spacing.sm }) {
      Row({ space: Spacing.md }) {
        Column({ space: 4 }) {
          Text('议题')
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Bold)
            .fontColor('rgba(92, 111, 140, 0.72)')

          Text(this.topic.length > 0 ? this.topic : '请在下方输入这场会议的议题')
            .fontSize(Typography.size.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.topic.length > 0 ? MintColors.textPrimary : MintColors.textMuted)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.stage === 'init') {
          Text(`Agent 准度 · ${this.reasoningEffortLabel(this.reasoningEffort)}`)
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.mintDark)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MintColors.mintBg)
            .borderRadius(BorderRadius.pill)
        } else if (this.stage === 'running') {
          Row({ space: 6 }) {
            LoadingProgress()
              .width(14)
              .height(14)
              .color(MintColors.mint)

            Text(this.progressText)
              .fontSize(Typography.size.xs)
              .fontColor(MintColors.mintDark)
          }
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MintColors.mintBg)
          .borderRadius(BorderRadius.pill)
        } else if (this.stage === 'done') {
          Text('已完成')
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.mintDark)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MintColors.mintBg)
            .borderRadius(BorderRadius.pill)
        }
      }
      .width('100%')

      if (this.fallbackNotice.length > 0) {
        Text(this.fallbackNotice)
          .fontSize(Typography.size.xs)
          .fontColor(MintColors.warning)
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .backgroundColor('rgba(17, 17, 17, 0.12)')
          .borderRadius(BorderRadius.md)
      }
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 15, bottom: 15 })
    .backgroundColor(MEETING_GLASS_BG)
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [
        [MintColors.cardPrimary, 0],
        ['rgba(236, 248, 255, 0.86)', 0.68],
        ['rgba(246, 251, 255, 0.76)', 1]
      ]
    })
    .borderRadius(24)
    .border({
      width: 0.9,
      color: MEETING_GLASS_BORDER,
      radius: 24
    })
    .shadow({
      radius: 16,
      color: 'rgba(109, 152, 191, 0.10)',
      offsetX: 0,
      offsetY: 8
    })
    .clip(true)
  }

  @Builder
  buildLoadingState(): void {
    Column({ space: Spacing.lg }) {
      Column({ space: Spacing.sm }) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(MintColors.mint)

        Text(this.progressText)
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.textPrimary)

        Text(this.connectionStatus)
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textMuted)
          .textAlign(TextAlign.Center)

        if (this.fallbackNotice.length > 0) {
          Text(this.fallbackNotice)
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.warning)
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row({ space: Spacing.md }) {
        ForEach(this.selectedAgents, (agent: PersonaSpec, index: number) => {
          Column({ space: 6 }) {
            Column() {
              Text(agent.displayName.length > 0 ? agent.displayName.charAt(0) : '?')
                .fontSize(Typography.size.body)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.textInverse)
            }
            .width(44)
            .height(44)
            .borderRadius(22)
            .backgroundColor(this.getAgentAccentColor(agent.agentId))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text(agent.stageLabel)
              .fontSize(Typography.size.caption)
              .fontColor(MintColors.textSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .textAlign(TextAlign.Center)
          }
          .width(70)
        }, (agent: PersonaSpec) => agent.agentId)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      Text('连接成功后将进入下方实时对话区')
        .fontSize(Typography.size.xs)
        .fontColor(MintColors.textMuted)
    }
    .width('100%')
    .padding(Spacing.card.large)
    .backgroundColor(MintColors.surfaceGlass)
    .borderRadius(BorderRadius.xxl2)
    .border({
      width: 1,
      color: 'rgba(17, 17, 17, 0.32)',
      radius: BorderRadius.xxl2
    })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildWaitingTopicHint(): void {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Column({ space: 8 }) {
          Text('READY')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(MEETING_BRIGHT_BLUE)
            .letterSpacing(1.2)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(Colors.overlayMedium)
            .borderRadius(BorderRadius.pill)

          Text('准备开聊')
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(`${this.selectedAgentIds.length} 位人格`)
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MEETING_BRIGHT_BLUE)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(Colors.overlayMedium)
          .border({
            width: 1,
            color: MintColors.border,
            radius: BorderRadius.pill
          })
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')

      Text('这次不再提前设置议题。直接在下方输入框里发出问题，发送后会议就会开始。')
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)
        .width('100%')

      Row({ space: Spacing.sm }) {
        Text(this.reasoningEffortLabel(this.reasoningEffort))
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MEETING_DEEP_BLUE)
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .backgroundColor(MintColors.cardSecondary)
          .border({
            width: 1,
            color: MintColors.border,
            radius: BorderRadius.pill
          })
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.card.large)
    .backgroundColor(MintColors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [Colors.overlayMedium, 0],
        [MintColors.cardSecondary, 0.56],
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
      radius: 16,
      color: 'rgba(109, 152, 191, 0.10)',
      offsetX: 0,
      offsetY: 8
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildConversationArea(isStreamingMode: boolean): void {
    Column({ space: Spacing.lg }) {
      Row({ space: 8 }) {
        Text(isStreamingMode ? '实时对话' : '对话流')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)

        Blank()

        Text(`${this.messages.length} 条`)
          .fontSize(Typography.size.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.lavenderDark)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('rgba(17, 17, 17, 0.12)')
          .borderRadius(BorderRadius.pill)
      }
      .width('100%')

      Column({ space: Spacing.md }) {
        if (isStreamingMode && this.messages.length === 0 &&
          this.liveSpeakerId.length === 0 && this.liveDraftText.length === 0) {
          Column({ space: Spacing.sm }) {
            LoadingProgress()
              .width(28)
              .height(28)
              .color(MintColors.mint)
            Text('已连接流式通道，等待首位发言…')
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textSecondary)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(Spacing.lg)
          .alignItems(HorizontalAlign.Center)
        }

        ForEach(this.messages, (msg: ArenaMessage, index: number) => {
          this.buildMessageBubble(msg, index)
        }, (msg: ArenaMessage) => msg.id)

        if (isStreamingMode && (this.liveSpeakerId.length > 0 || this.liveDraftText.length > 0)) {
          this.buildStreamingMessageBubble()
        }

        if (isStreamingMode && this.liveSummaryText.length > 0 && this.summary === null) {
          Column({ space: Spacing.sm }) {
            Text('总结生成中…')
              .fontSize(Typography.size.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MintColors.lavenderDark)

            Text(this.liveSummaryText)
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textPrimary)
              .lineHeight(Typography.lineHeight.relaxed)
              .width('100%')
          }
          .width('100%')
          .padding(Spacing.md)
          .backgroundColor('rgba(17, 17, 17, 0.12)')
          .borderRadius(BorderRadius.lg)
        }
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor(MEETING_GLASS_BG)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [MintColors.cardPrimary, 0],
        ['rgba(243, 250, 255, 0.82)', 1]
      ]
    })
    .borderRadius(26)
    .border({
      width: 0.9,
      color: MEETING_GLASS_BORDER,
      radius: 26
    })
    .shadow({
      radius: 14,
      color: 'rgba(109, 152, 191, 0.08)',
      offsetX: 0,
      offsetY: 8
    })
    .opacity(1)
    .translate({ y: 0 })
    .animation({
      duration: AnimationDuration.page,
      curve: AnimationCurve.smooth
    })
  }

  /** 当前正在输出的一条（流式 delta），与已完成气泡同布局，虚线边框表示进行中 */
  @Builder
  buildStreamingMessageBubble(): void {
    Row({ space: 10 }) {
      Column() {
        Text(this.liveSpeakerLabel().length > 0 ? this.liveSpeakerLabel().charAt(0) : '…')
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textInverse)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.liveSpeakerId.length > 0 ? this.getAgentAccentColor(this.liveSpeakerId) :
        MintColors.mint)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 6 }) {
        Row({ space: 8 }) {
          Text(this.liveSpeakerLabel().length > 0 ? this.liveSpeakerLabel() : '发言中')
            .fontSize(Typography.size.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)
            .layoutWeight(1)
            .maxLines(2)

          Text('输出中')
            .fontSize(10)
            .fontColor(MintColors.mintDark)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(MintColors.mintBg)
            .borderRadius(BorderRadius.pill)
        }
        .width('100%')

        Column() {
          if (this.liveDraftText.length > 0) {
            Text(this.liveDraftText)
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textPrimary)
              .lineHeight(Typography.lineHeight.relaxed)
              .width('100%')
          } else {
            Row({ space: 4 }) {
              Text('●')
                .fontSize(12)
                .fontColor(MintColors.mintDark)
              Text('●')
                .fontSize(12)
                .fontColor(MintColors.mintDark)
              Text('●')
                .fontSize(12)
                .fontColor(MintColors.mintDark)
              Text(' 正在组织语言…')
                .fontSize(Typography.size.caption)
                .fontColor(MintColors.textMuted)
            }
            .padding({ top: 4, bottom: 4 })
          }
        }
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .backgroundColor('rgba(17, 17, 17, 0.14)')
        .borderRadius(18)
        .border({
          width: 1.2,
          color: MintColors.mint,
          style: BorderStyle.Dashed,
          radius: 18
        })
        .shadow({
          radius: 10,
          color: 'rgba(17, 17, 17, 0.12)',
          offsetX: 0,
          offsetY: 3
        })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildEmptyOutcomeHint(): void {
    Column({ space: Spacing.sm }) {
      Text('暂无对话与总结')
        .fontSize(Typography.size.bodyLg)
        .fontWeight(FontWeight.Medium)
        .fontColor(MintColors.textPrimary)

      Text('若刚结束仍为空，可能是网络中断或流式解析异常。请点「重试」或返回后重新开始会议。')
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)
    }
    .width('100%')
    .padding(Spacing.lg)
    .backgroundColor(MintColors.surfaceGlass)
    .borderRadius(BorderRadius.xxl2)
    .border({
      width: 1,
      color: MintColors.borderLight,
      radius: BorderRadius.xxl2
    })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildErrorDisplay(): void {
    Column({ space: Spacing.lg }) {
      Column({ space: Spacing.sm }) {
        Text('⚠')
          .fontSize(48)
          .fontColor(MintColors.error)

        Text(this.errorMessage)
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
            this.stage = 'init'
            this.errorMessage = ''
            this.initializeAndStart()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(BorderRadius.xxl2)
    .border({
      width: 1,
      color: 'rgba(17, 17, 17, 0.32)',
      radius: BorderRadius.xxl2
    })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildInterruptedState(): void {
    Column({ space: Spacing.lg }) {
      Column({ space: Spacing.sm }) {
        Text('⏸')
          .fontSize(48)
          .fontColor(MintColors.warning)

        Text('会议已中断')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor(MintColors.textPrimary)

        Text(`已完成 ${this.messages.length} 条发言`)
          .fontSize(Typography.size.body)
          .fontColor(MintColors.textSecondary)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Row({ space: Spacing.md }) {
        Button('返回')
          .fontSize(Typography.size.body)
          .fontColor(Colors.textInverse)
          .backgroundColor(MintColors.textMuted)
          .borderRadius(BorderRadius.pill)
          .height(44)
          .width('45%')
          .stateEffect(true)
          .onClick(() => this.goBack())

        Button('继续生成')
          .fontSize(Typography.size.body)
          .fontColor(Colors.textInverse)
          .backgroundColor(MintColors.mint)
          .borderRadius(BorderRadius.pill)
          .height(44)
          .width('45%')
          .stateEffect(true)
          .onClick(() => {
            this.stage = 'init'
            this.initializeAndStart()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(Spacing.xl)
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(BorderRadius.xxl2)
    .border({
      width: 1,
      color: 'rgba(17, 17, 17, 0.5)',
      radius: BorderRadius.xxl2
    })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildUserMessageBubble(msg: ArenaMessage, index: number): void {
    Row({ space: 10 }) {
      Blank()
        .layoutWeight(1)

      Column({ space: 6 }) {
        if (index === 0 || !this.isUserMessage(this.messages[index - 1])) {
          Column({ space: 2 }) {
            Text(`${msg.displayName} · ${msg.stageLabel}`)
              .fontSize(Typography.size.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MintColors.textPrimary)
              .maxLines(2)
              .textAlign(TextAlign.End)
          }
          .alignItems(HorizontalAlign.End)
          .constraintSize({ maxWidth: '100%' })
        }

        Column() {
          Text(msg.content)
            .fontSize(Typography.size.body)
            .fontColor(Colors.textInverse)
            .lineHeight(Typography.lineHeight.relaxed)
            .textAlign(TextAlign.Start)
        }
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(MEETING_DEEP_BLUE)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [
            [Colors.accent, 0],
            [MintColors.lavenderDark, 1]
          ]
        })
        .borderRadius(20)
        .border({
          width: 0.8,
          color: MintColors.surfaceGlass,
          radius: 20
        })
        .shadow({
          radius: 12,
          color: 'rgba(47, 124, 200, 0.18)',
          offsetX: 0,
          offsetY: 5
        })
        .constraintSize({ maxWidth: '100%' })
      }
      .constraintSize({ maxWidth: '78%' })
      .alignItems(HorizontalAlign.End)

      Column() {
        Text(msg.displayName.length > 0 ? msg.displayName.charAt(0) : '我')
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textInverse)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(MintColors.mintDark)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ top: (index === 0 || !this.isUserMessage(this.messages[index - 1])) ? 2 : 0 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  buildMessageBubble(msg: ArenaMessage, index: number): void {
    if (this.isUserMessage(msg)) {
      this.buildUserMessageBubble(msg, index)
    } else {
      Row({ space: 10 }) {
      Column() {
        Text(msg.displayName.length > 0 ? msg.displayName.charAt(0) : '?')
          .fontSize(Typography.size.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textInverse)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.getAgentAccentColor(msg.agentId))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ top: (index === 0 || this.messages[index - 1].agentId !== msg.agentId) ? 2 : 0 })

      Column({ space: 6 }) {
        if (index === 0 || this.messages[index - 1].agentId !== msg.agentId) {
          Column({ space: 2 }) {
            Text(msg.displayName)
              .fontSize(Typography.size.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MintColors.textPrimary)
              .maxLines(2)

            Text(msg.stageLabel)
              .fontSize(10)
              .fontColor(MintColors.textMuted)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }

        Column() {
          Text(msg.content)
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textPrimary)
            .lineHeight(Typography.lineHeight.relaxed)
            .width('100%')
        }
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(this.getMessageBubbleBackground(msg.agentId))
        .borderRadius(18)
        .border({
          width: 1,
          color: 'rgba(17, 17, 17, 0.22)',
          radius: 18
        })
        .shadow({
          radius: 8,
          color: 'rgba(17, 17, 17, 0.06)',
          offsetX: 0,
          offsetY: 2
        })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    }
  }

  @Builder
  buildSummaryCard(): void {
    Column({ space: Spacing.sm }) {
      Text('会议已完成')
        .fontSize(Typography.size.bodyLg)
        .fontWeight(FontWeight.Bold)
        .fontColor(MintColors.textPrimary)

      Text('本次会议纪要已经自动同步到纪要页。你可以继续在下方插话续聊，或稍后去纪要页查看沉淀内容。')
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.lg)
    .backgroundColor(MintColors.cardPrimary)
    .borderRadius(BorderRadius.xxl2)
    .border({
      width: 1,
      color: MintColors.cardPrimary,
      radius: BorderRadius.xxl2
    })
    .shadow({
      radius: 26,
      color: Colors.loadingBg,
      offsetX: 0,
      offsetY: 10
    })
    .opacity(1)
    .translate({ y: 0 })
    .scale({ x: 1, y: 1 })
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.friction
    })
  }
}
