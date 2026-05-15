import { common } from '@kit.AbilityKit'
import promptAction from '@ohos.promptAction'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
import { MeetingSessionStore } from '../utils/MeetingSessionStore'
import { ProfileImportStore } from '../utils/ProfileImportStore'
import { SummaryService, formatTimeAgo, getAvatarTextColor, getParticipantColor } from '../service/SummaryService'
import { BreakpointSystem, BreakpointType } from '../common/BreakpointSystem'
import { ResponsiveLayoutMetrics, responsiveLayoutForBreakpoint } from '../common/ResponsiveLayout'
import {
  ArenaRunHistoryItem,
  PersonaSpec,
  PresetProfile,
  ProfileBundle,
  ReasoningEffort,
  RouteParams,
  SourceDocumentSummary,
  TimelineNode,
  EMPTY_PROFILE
} from '../common/Models'
import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { LoadingOverlay, ErrorToast, RecordsTab, RecordItem, TabBar, Icon, AnimatedCloudMascot } from '../components'
import { LaunchIntent, buildLaunchIntentFromQuickAction, buildRecentMeetingSnapshot, buildRouteParamsFromLaunchIntent } from '../common/LaunchIntent'
import { LaunchIntentStore } from '../common/LaunchIntentStore'

interface HomeRouteParams extends RouteParams {
  userName?: string
  userAvatar?: string
  openId?: string
  unionId?: string
}

interface IndexNavigationParams extends RouteParams {
  title?: string
  openSheet?: string
  userName?: string
  userAvatar?: string
  openId?: string
  unionId?: string
}

interface HomeCalendarDay {
  id: string
  weekLabel: string
  dayNumber: number
  dayLabel: string
  fullDateLabel: string
  isToday: boolean
}

type ThemeColor = ResourceColor | string

interface HomeReasoningEffortOption {
  value: ReasoningEffort
  label: string
  description: string
}

const HOME_REASONING_EFFORT_OPTIONS: HomeReasoningEffortOption[] = [
  { value: 'low', label: '快速', description: '更快回应' },
  { value: 'medium', label: '均衡', description: '速度质量平衡' },
  { value: 'high', label: '深入', description: '分析更稳' },
  { value: 'xhigh', label: '极致', description: '最强推理' }
]

@Entry
@Component
struct Index {
  @State private profiles: PresetProfile[] = []
  @State private customProfiles: PresetProfile[] = []
  @State private cachedCustomBundles: ProfileBundle[] = []
  @State private selectedProfile: PresetProfile = EMPTY_PROFILE
  @State private nodes: TimelineNode[] = []
  @State private agents: PersonaSpec[] = []
  @State private selectedAgentIds: string[] = []
  @State private topic: string = ''
  @State private meetingReasoningEffort: ReasoningEffort = 'medium'
  @State private loading: string = ''
  @State private error: string = ''
  @State private activeTab: number = 0
  @State private sourceDocument: SourceDocumentSummary | null = null
  @State private safeTopVp: number = 0
  @State private safeBottomVp: number = 0
  @State private records: RecordItem[] = []
  @State private connectionLabel: string = '连接中'
  @State private userName: string = ''
  @State private userAvatar: string = ''
  @State private userOpenId: string = ''
  @State private userUnionId: string = ''
  @State private selectedCalendarYear: number = new Date().getFullYear()
  @State private selectedCalendarMonth: number = new Date().getMonth() + 1
  @State private selectedCalendarDay: number = new Date().getDate()
  @State private pressedFeatureCardTag: string = ''
  @State private pressedCalendarDayId: string = ''
  @State private pressedCalendarControl: string = ''
  @State private pressedMeetingCardTag: string = ''
  @State private pressedLastMeetingHero: boolean = false
  @State private pressedActionBtn: boolean = false
  @State private calendarHeaderPressed: boolean = false
  @State private pressedProfileCard: boolean = false
  @State private showMeetingParameterPanel: boolean = false
  @State private meetingParameterPanelVisible: boolean = false
  @State private meetingParameterPanelOverlayOpacity: number = 0
  @State private meetingParameterPanelOpacity: number = 0.94
  @State private meetingParameterPanelTranslateY: number = 48
  @State private parameterDraftReasoningEffort: ReasoningEffort = 'medium'
  @State private tabContentOpacity: number = 1
  @State private tabContentOffsetY: number = 0
  @State private hasLoadedRecordsOnce: boolean = false
  @State private hasHydratedOnce: boolean = false
  @State private currentBreakpoint: BreakpointType = 'sm'
  private calendarScroller: Scroller = new Scroller()
  private detachBreakpointListener?: () => void
  private launchIntentListener?: (payload?: Object) => void

  private featureMood(tag: string): 'happy' | 'shy' | 'angry' | 'sleep' {
    if (tag === '01') {
      return 'happy'
    }
    if (tag === '02') {
      return 'shy'
    }
    if (tag === '03') {
      return 'angry'
    }
    return 'sleep'
  }

  aboutToAppear(): void {
    this.attachResponsiveBreakpoint()
    this.consumeRouteParams()
    this.syncMeetingWorkbenchFromSession()
    void this.restoreSelectedProfileFromSession()
    this.initializeLocalStores()
    this.resetCalendarToToday()
    if (!this.hasHydratedOnce) {
      this.hasHydratedOnce = true
      void this.hydratePresets()
    }
    this.loadSafeInsets()
    if (!this.hasLoadedRecordsOnce) {
      this.hasLoadedRecordsOnce = true
      void this.loadMeetingRecords()
    }
    this.attachLaunchIntentListener()
    void this.consumePendingLaunchIntent()
  }

  onPageShow(): void {
    this.resetCalendarToToday()
    this.consumeImportedBundle()
    this.syncMeetingWorkbenchFromSession()
    void this.restoreSelectedProfileFromSession()
    if (this.activeTab === 1) {
      void this.loadMeetingRecords()
    }
    void this.consumePendingLaunchIntent()
  }

  aboutToDisappear(): void {
    if (this.detachBreakpointListener) {
      this.detachBreakpointListener()
      this.detachBreakpointListener = undefined
    }
    this.detachLaunchIntentListener()
  }

  private attachLaunchIntentListener(): void {
    if (this.launchIntentListener) {
      return
    }

    const hostContext = this.getHostContext()
    if (!hostContext) {
      return
    }

    this.launchIntentListener = (_payload?: Object) => {
      void this.consumePendingLaunchIntent()
    }
    hostContext.eventHub.on('launchIntentReceived', this.launchIntentListener)
  }

  private detachLaunchIntentListener(): void {
    const hostContext = this.getHostContext()
    if (hostContext && this.launchIntentListener) {
      hostContext.eventHub.off('launchIntentReceived', this.launchIntentListener)
    }
    this.launchIntentListener = undefined
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

      const params: HomeRouteParams = rawParams as HomeRouteParams
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

  private allProfiles(): PresetProfile[] {
    return [...this.profiles, ...this.customProfiles]
  }

  private latestRecord(): RecordItem | null {
    if (this.records.length === 0) {
      return null
    }
    return this.records[0]
  }

  private selectedAgents(): PersonaSpec[] {
    const selectedAgentIds = this.effectiveSelectedAgentIds()
    return this.agents.filter((agent: PersonaSpec) => selectedAgentIds.includes(agent.agentId))
  }

  private effectiveSelectedAgentIds(): string[] {
    if (this.selectedAgentIds.length > 0) {
      return [...this.selectedAgentIds]
    }
    const storedSelectedAgentIds = MeetingSessionStore.getSelectedAgents()
    return storedSelectedAgentIds.length > 0 ? [...storedSelectedAgentIds] : []
  }

  private hasSelectedProfile(): boolean {
    return this.selectedProfile.id.length > 0
  }

  private hasReadyMeetingSelection(): boolean {
    return this.effectiveSelectedAgentIds().length >= 2
  }

  private syncMeetingWorkbenchFromSession(): void {
    const storedSelectedAgentIds = MeetingSessionStore.getSelectedAgents()
    if (storedSelectedAgentIds.length > 0) {
      this.selectedAgentIds = [...storedSelectedAgentIds]
    }

    this.meetingReasoningEffort = MeetingSessionStore.getReasoningEffort()
  }

  private initializeLocalStores(): void {
    const ctx = this.getHostContext()
    if (!ctx) {
      return
    }

    void MeetingSessionStore.init(ctx).then(() => {
      this.syncMeetingWorkbenchFromSession()
      void this.restoreSelectedProfileFromSession()
      if (this.hasLoadedRecordsOnce) {
        void this.loadMeetingRecords()
      }
    }).catch((_error: Error) => {
    })

    void SummaryService.init(ctx).catch((_error: Error) => {
    })
  }

  private userGreeting(): string {
    if (this.userName.length <= 0) {
      return '欢迎回来'
    }
    return `你好，${this.userName}`
  }

  private userSubline(): string {
    if (this.hasSelectedProfile()) {
      return `当前焦点：${this.selectedProfile.displayName}`
    }
    return '先选择一个角色，再开始你的第一场会议'
  }

  private selectedProfilePreview(): string {
    if (!this.selectedProfile.biography.length) {
      return '聚焦一个角色，把时间线、阶段人格和会议入口收拢到同一个首页。'
    }
    if (this.selectedProfile.biography.length <= 56) {
      return this.selectedProfile.biography
    }
    return `${this.selectedProfile.biography.slice(0, 56)}...`
  }

  private profileStatusLabel(): string {
    if (!this.hasSelectedProfile()) {
      return '等待选择'
    }
    if (this.hasReadyMeetingSelection()) {
      return '可以开会'
    }
    return '继续整理'
  }

  private statLabelThree(): string {
    return this.sourceDocument ? '原文已关联' : '待补充来源'
  }

  private welcomeTitle(): string {
    return this.userName.length > 0 ? this.userName : '时序人格'
  }

  private profileAvatarLetter(): string {
    const title = this.welcomeTitle().trim()
    if (title.length > 0) {
      return title.charAt(0)
    }
    return '时'
  }

  private welcomeEyebrow(): string {
    return 'HI, WELCOME'
  }

  private welcomeSubtitle(): string {
    if (this.hasSelectedProfile()) {
      return `和 ${this.selectedProfile.displayName} 继续聊聊。`
    }
    return '从一个问题开始。'
  }

  private profileBadgeLabel(): string {
    if (this.connectionLabel.length > 0) {
      return this.connectionLabel.replace('LIVE ', '')
    }
    return '在线'
  }

  private homeMoodTitle(): string {
    if (this.hasReadyMeetingSelection()) {
      return '现在开始刚好'
    }
    if (this.hasSelectedProfile()) {
      return '轻一点开始'
    }
    return '先挑一个角色'
  }

  private homeMoodSubtitle(): string {
    if (this.hasReadyMeetingSelection()) {
      return '已就绪'
    }
    if (this.hasSelectedProfile()) {
      return `${this.selectedProfile.displayName}`
    }
    return '先选角色'
  }

  private homeMoodBadge(): string {
    if (this.hasReadyMeetingSelection()) {
      return '可以开始'
    }
    if (this.hasSelectedProfile()) {
      return '慢热模式'
    }
    return '等待选择'
  }

  private homeRecommendationTitle(primary: boolean): string {
    if (primary) {
      return this.hasReadyMeetingSelection() ? '开始对话' : '从问题开始'
    }
    return this.hasSelectedProfile() ? '探索人设' : '看看角色'
  }

  private homeRecommendationSubtitle(primary: boolean): string {
    if (primary) {
      return this.hasReadyMeetingSelection()
        ? '直接开聊'
        : '一句话开始'
    }
    return this.hasSelectedProfile()
      ? `看看 ${this.selectedProfile.displayName}`
      : '看看喜欢的角色'
  }

  private meetingHeroSubtitle(): string {
    const selectedCount = this.effectiveSelectedAgentIds().length
    if (this.hasReadyMeetingSelection()) {
      return `${selectedCount} 个阶段人格已就绪，适合展开一场正式讨论。`
    }
    if (this.hasSelectedProfile()) {
      return `先从 ${this.selectedProfile.displayName} 的阶段人格里挑出两位参会者。`
    }
    return '先选择一个角色，再让不同阶段的人格围绕问题展开讨论。'
  }

  private meetingPrimaryActionLabel(): string {
    if (this.hasReadyMeetingSelection()) {
      return '继续发言'
    }
    if (this.hasSelectedProfile()) {
      return '选择参会人格'
    }
    return '开始第一场会议'
  }

  private meetingProfileLabel(): string {
    return this.hasSelectedProfile() ? this.selectedProfile.displayName : '待选择'
  }

  private meetingAgentCountLabel(): string {
    const selectedCount = this.effectiveSelectedAgentIds().length
    if (!this.hasSelectedProfile()) {
      return '0 / 2'
    }
    return `${selectedCount} / 2`
  }

  private meetingPersonaPrepLabel(): string {
    const selectedCount = this.effectiveSelectedAgentIds().length
    if (selectedCount <= 0) {
      return '待添加'
    }
    return `${selectedCount} 位人格`
  }

  private meetingPersonaPrepDetail(): string {
    if (this.hasReadyMeetingSelection()) {
      return '继续添加'
    }
    return '添加参会'
  }

  private reasoningEffortLabel(value: ReasoningEffort): string {
    const found = HOME_REASONING_EFFORT_OPTIONS.find((option: HomeReasoningEffortOption) => option.value === value)
    return found ? found.label : '均衡'
  }

  private meetingParameterPreview(): string {
    return `Agent 准度 · ${this.reasoningEffortLabel(this.meetingReasoningEffort)}`
  }

  private taskInfoPreview(): string {
    return '分类人物'
  }

  private lastMeetingTitle(): string {
    const record = this.latestRecord()
    if (!record) {
      return '暂无上一次会议'
    }
    return record.title && record.title.length > 0 ? record.title : '上一次会议'
  }

  private lastMeetingTopic(): string {
    const record = this.latestRecord()
    if (!record) {
      return '完成第一场会议后，就能从这里继续发言。'
    }
    if (record.topic && record.topic.length > 0) {
      return record.topic
    }
    return record.participantLine
  }

  private lastMeetingTopicPreview(): string {
    const topic = this.lastMeetingTopic()
    if (topic.length <= 44) {
      return topic
    }
    return `${topic.slice(0, 44)}...`
  }

  private lastMeetingPersonaCountLabel(): string {
    const record = this.latestRecord()
    if (!record) {
      return `${this.effectiveSelectedAgentIds().length}`
    }
    if (record.participants.length > 0) {
      return `${record.participants.length}`
    }
    return `${this.effectiveSelectedAgentIds().length}`
  }

  private lastMeetingStatusLabel(): string {
    const record = this.latestRecord()
    if (!record) {
      return '等待开始'
    }
    return record.timeAgo
  }

  private lastMeetingActionLabel(): string {
    if (this.latestRecord()) {
      return '继续发言'
    }
    return this.hasReadyMeetingSelection() ? '开始会议' : '先选择角色'
  }

  private homeCalendarDays(): HomeCalendarDay[] {
    const weekLabels: string[] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    const days: HomeCalendarDay[] = []
    const totalDays = new Date(this.selectedCalendarYear, this.selectedCalendarMonth, 0).getDate()
    const today = new Date()

    for (let day = 1; day <= totalDays; day++) {
      const nextDate = new Date(this.selectedCalendarYear, this.selectedCalendarMonth - 1, day)
      days.push({
        id: `${nextDate.getFullYear()}-${nextDate.getMonth() + 1}-${nextDate.getDate()}`,
        weekLabel: weekLabels[nextDate.getDay()],
        dayNumber: day,
        dayLabel: `${day}`.padStart(2, '0'),
        fullDateLabel: `${nextDate.getMonth() + 1}月${nextDate.getDate()}日`,
        isToday: nextDate.getFullYear() === today.getFullYear()
          && nextDate.getMonth() === today.getMonth()
          && nextDate.getDate() === today.getDate()
      })
    }

    return days
  }

  private syncCalendarSelection(): void {
    const totalDays = new Date(this.selectedCalendarYear, this.selectedCalendarMonth, 0).getDate()
    if (this.selectedCalendarDay > totalDays) {
      this.selectedCalendarDay = totalDays
    }
    if (this.selectedCalendarDay <= 0) {
      this.selectedCalendarDay = 1
    }
  }

  private resetCalendarToToday(): void {
    const today = new Date()
    this.selectedCalendarYear = today.getFullYear()
    this.selectedCalendarMonth = today.getMonth() + 1
    this.selectedCalendarDay = today.getDate()
    this.scrollCalendarToToday()
  }

  private scrollCalendarToToday(): void {
    const today = new Date()
    if (this.selectedCalendarYear !== today.getFullYear() || this.selectedCalendarMonth !== today.getMonth() + 1) {
      this.calendarScroller.scrollTo({ xOffset: 0, yOffset: 0, animation: true })
      return
    }

    const itemWidth = 72
    const itemGap = 10
    const sideInset = 4
    const targetOffset = Math.max(0, (today.getDate() - 2) * (itemWidth + itemGap) - sideInset)
    this.calendarScroller.scrollTo({ xOffset: targetOffset, yOffset: 0, animation: true })
  }

  private changeCalendarMonth(delta: number): void {
    const currentDate = new Date(this.selectedCalendarYear, this.selectedCalendarMonth - 1 + delta, 1)
    this.selectedCalendarYear = currentDate.getFullYear()
    this.selectedCalendarMonth = currentDate.getMonth() + 1

    const today = new Date()
    if (this.selectedCalendarYear === today.getFullYear() && this.selectedCalendarMonth === today.getMonth() + 1) {
      this.selectedCalendarDay = today.getDate()
    }
    this.syncCalendarSelection()
    this.scrollCalendarToToday()
  }

  private changeCalendarYear(delta: number): void {
    this.selectedCalendarYear += delta
    this.syncCalendarSelection()
    this.scrollCalendarToToday()
  }

  private refreshConnectionLabel(): void {
    this.connectionLabel = PersonaApi.getConnectionLabel()
  }

  private normalizeError(error: Object): string {
    const maybeMessage = error as Record<string, string>
    if (maybeMessage.message) {
      return maybeMessage.message
    }
    return '请求失败，请检查后端或网络设置'
  }

  private applyBundle(bundle: ProfileBundle): void {
    this.selectedProfile = bundle.profile
    this.nodes = bundle.nodes
    this.agents = bundle.agents
    const storedSelectedAgentIds = MeetingSessionStore.getSelectedAgents()
    this.selectedAgentIds = storedSelectedAgentIds.length > 0
      ? [...storedSelectedAgentIds]
      : []
    this.sourceDocument = bundle.sourceDocument || null
    this.syncMeetingWorkbenchFromSession()
  }

  private cacheCustomBundle(bundle: ProfileBundle): void {
    const nextCache = this.cachedCustomBundles.filter((item: ProfileBundle) => item.profile.id !== bundle.profile.id)
    this.cachedCustomBundles = [...nextCache, bundle]

    const nextProfiles = this.customProfiles.filter((item: PresetProfile) => item.id !== bundle.profile.id)
    this.customProfiles = [...nextProfiles, bundle.profile]
  }

  private consumeImportedBundle(): void {
    const bundle = ProfileImportStore.takePendingBundle()
    if (!bundle) {
      return
    }
    this.cacheCustomBundle(bundle)
    this.applyBundle(bundle)
    this.refreshConnectionLabel()
  }

  private findCachedCustomBundle(profileId: string): ProfileBundle | null {
    const found = this.cachedCustomBundles.find((bundle: ProfileBundle) => bundle.profile.id === profileId)
    return found ? found : null
  }

  private async hydratePresets(): Promise<void> {
    this.loading = '正在连接后端并加载角色库...'
    this.error = ''

    try {
      const profiles = await PersonaApi.getPresets()
      this.profiles = profiles
      this.refreshConnectionLabel()
    } catch (error) {
      this.error = this.normalizeError(error as Object)
      this.refreshConnectionLabel()
    } finally {
      this.loading = ''
    }
  }

  private async selectProfile(profile: PresetProfile): Promise<void> {
    const cachedCustomBundle = this.findCachedCustomBundle(profile.id)
    if (cachedCustomBundle) {
      this.applyBundle(cachedCustomBundle)
      this.refreshConnectionLabel()
      return
    }

    this.loading = `正在加载 ${profile.displayName} 的时间线与人格体...`
    this.error = ''

    try {
      const bundle = await PersonaApi.getProfileBundle(profile.id)
      this.applyBundle(bundle)
      this.refreshConnectionLabel()
    } catch (error) {
      this.error = this.normalizeError(error as Object)
      this.refreshConnectionLabel()
    } finally {
      this.loading = ''
    }
  }

  private async restoreSelectedProfileFromSession(): Promise<void> {
    const sessionProfileIds = MeetingSessionStore.getProfileIds()
    const profileId = sessionProfileIds.length > 0 ? sessionProfileIds[0] : MeetingSessionStore.getProfileId()
    if (profileId.length === 0 || this.selectedProfile.id === profileId) {
      return
    }

    const cachedCustomBundle = this.findCachedCustomBundle(profileId)
    if (cachedCustomBundle) {
      this.applyBundle(cachedCustomBundle)
      this.refreshConnectionLabel()
      return
    }

    try {
      const bundle = await PersonaApi.getProfileBundle(profileId)
      this.applyBundle(bundle)
      this.refreshConnectionLabel()
    } catch (_error) {
      this.refreshConnectionLabel()
    }
  }

  private mapHistoryItemToRecord(item: ArenaRunHistoryItem): RecordItem {
    const names = item.participantNames
    const avatarColors = names.map((_n: string, idx: number) => getParticipantColor(idx))
    const avatarTextColors = names.map((_n: string, idx: number) => getAvatarTextColor(idx))
    const title = item.title && item.title.length > 0
      ? item.title
      : (item.summaryTitle && item.summaryTitle.length > 0 ? item.summaryTitle : '历史会议')
    const content = item.consensusPreview && item.consensusPreview.length > 0
      ? item.consensusPreview
      : (item.consensus && item.consensus.length > 0 ? item.consensus : '')
    const participantLine = names.length > 0 ? names.join(' · ') : '暂无参会者'

    return {
      id: item.runId,
      sessionId: item.sessionId,
      title: title,
      topic: item.topic,
      participants: names,
      selectedAgentIds: item.participantAgentIds ? [...item.participantAgentIds] : [],
      profileIds: item.profileIds ? [...item.profileIds] : [],
      participantLine: participantLine,
      avatarColors: avatarColors,
      avatarTextColors: avatarTextColors,
      content: content,
      timeAgo: item.createdAt ? formatTimeAgo(item.createdAt) : '刚刚',
      accentColor: avatarColors.length > 0 ? avatarColors[0] : Colors.primary,
      messageCount: item.messageCount !== undefined ? item.messageCount : 0,
      highlightCount: 0,
      durationLabel: item.mode === 'debate' ? '辩论' : '对谈',
      isFavorite: false
    }
  }

  private async loadMeetingRecords(): Promise<void> {
    try {
      const history = await PersonaApi.getArenaHistory(50)
      const merged = MeetingSessionStore.mergeHistoryRecords(history.runs)
      this.records = merged.map((run: ArenaRunHistoryItem) => this.mapHistoryItemToRecord(run))
      this.refreshConnectionLabel()
    } catch (_error) {
      this.records = MeetingSessionStore.getHistoryRecords().map((run: ArenaRunHistoryItem) => this.mapHistoryItemToRecord(run))
      this.refreshConnectionLabel()
    }
  }

  private async handleGenerateShareCard(record: RecordItem): Promise<void> {
    if (record.id.length === 0) {
      this.error = '缺少会议 runId，无法生成卡片'
      return
    }

    const params: IndexNavigationParams = {
      arenaRunId: record.id,
      title: record.title
    }
    await this.pushPage('pages/PosterPreviewPage', params)
  }

  private async pushPage(url: string, params?: IndexNavigationParams): Promise<void> {
    try {
      await this.router().pushUrl({
        url: url,
        params: params
      })
    } catch (_error) {
      this.showToast('页面跳转失败，请稍后再试')
    }
  }

  private async goProfileDetail(): Promise<void> {
    if (!this.hasSelectedProfile()) {
      return
    }

    const params: IndexNavigationParams = {
      profileId: this.selectedProfile.id,
      selectedAgentIds: this.selectedAgentIds.join(',')
    }
    await this.pushPage('pages/ProfileDetail', params)
  }

  private async goCreateRole(): Promise<void> {
    await this.pushPage('pages/CreateRole')
  }

  private async goExplorePersonas(): Promise<void> {
    await this.pushPage('pages/ExplorePersonas')
  }

  private async goImportProfile(): Promise<void> {
    await this.pushPage('pages/ImportProfilePage')
  }

  private async goMeetingParticipant(): Promise<void> {
    await this.goMeetingParticipantWithFocus('')
  }

  private async goMeetingParticipantWithFocus(focus: string): Promise<void> {
    if (!this.hasSelectedProfile()) {
      const fallbackProfile = this.allProfiles()[0]
      if (!fallbackProfile) {
        this.showToast('当前没有可选角色')
        return
      }
      await this.selectProfile(fallbackProfile)
    }

    const reasoningEffort = MeetingSessionStore.getReasoningEffort()
    const selectedAgentIds = this.effectiveSelectedAgentIds()
    const params: IndexNavigationParams = {
      profileId: this.selectedProfile.id,
      profileIds: this.selectedProfile.id,
      selectedAgentIds: selectedAgentIds.join(','),
      focus: focus,
      reasoningEffort: reasoningEffort
    }
    await this.pushPage('pages/MeetingParticipantPage', params)
  }

  private async goMeetingChatDirect(): Promise<void> {
    const selectedAgentIds = this.effectiveSelectedAgentIds()
    if (this.hasSelectedProfile()) {
      MeetingSessionStore.setProfileId(this.selectedProfile.id)
      MeetingSessionStore.setProfileIds([this.selectedProfile.id])
    }
    MeetingSessionStore.setSelectedAgents(selectedAgentIds)
    MeetingSessionStore.setTopic('')
    MeetingSessionStore.setReasoningEffort(this.meetingReasoningEffort)
    MeetingSessionStore.clearContinueContext()

    const params: IndexNavigationParams = {
      profileId: this.hasSelectedProfile() ? this.selectedProfile.id : '',
      profileIds: this.hasSelectedProfile() ? this.selectedProfile.id : '',
      selectedAgentIds: selectedAgentIds.join(','),
      topic: '',
      reasoningEffort: this.meetingReasoningEffort
    }
    await this.pushPage('pages/MeetingChatPage', params)
  }

  private openMeetingParameterPanel(): void {
    this.parameterDraftReasoningEffort = this.meetingReasoningEffort
    this.meetingParameterPanelVisible = true
    this.showMeetingParameterPanel = true
    this.meetingParameterPanelOverlayOpacity = 0
    this.meetingParameterPanelOpacity = 0.94
    this.meetingParameterPanelTranslateY = 72

    setTimeout(() => {
      this.meetingParameterPanelOverlayOpacity = 1
      this.meetingParameterPanelOpacity = 1
      this.meetingParameterPanelTranslateY = 0
    }, 10)
  }

  private closeMeetingParameterPanel(): void {
    if (!this.meetingParameterPanelVisible) {
      return
    }
    this.meetingParameterPanelVisible = false
    this.meetingParameterPanelOverlayOpacity = 0
    this.meetingParameterPanelOpacity = 0.96
    this.meetingParameterPanelTranslateY = 84
    setTimeout(() => {
      this.showMeetingParameterPanel = false
    }, 280)
  }

  private saveMeetingParameters(): void {
    this.meetingReasoningEffort = this.parameterDraftReasoningEffort
    MeetingSessionStore.setReasoningEffort(this.meetingReasoningEffort)
    this.closeMeetingParameterPanel()
  }

  private async handleMeetingPrimaryAction(): Promise<void> {
    if (!this.hasSelectedProfile()) {
      await this.goExplorePersonas()
      return
    }
    await this.goMeetingParticipant()
  }

  private async handleLastMeetingAction(): Promise<void> {
    const record = this.latestRecord()
    if (!record) {
      if (this.effectiveSelectedAgentIds().length <= 0) {
        this.showToast('还未选择角色')
        return
      }
      if (!this.hasReadyMeetingSelection()) {
        this.showToast('请至少选择 2 位人格')
        return
      }
      await this.goMeetingChatDirect()
      return
    }
    await this.continueMeeting(record)
  }

  private async continueMeeting(record: RecordItem): Promise<void> {
    const recordProfileIds = record.profileIds && record.profileIds.length > 0
      ? [...record.profileIds]
      : (this.hasSelectedProfile() ? [this.selectedProfile.id] : [])
    const selectedAgentIds = record.selectedAgentIds && record.selectedAgentIds.length > 0
      ? [...record.selectedAgentIds]
      : this.effectiveSelectedAgentIds()

    if (recordProfileIds.length === 0 || selectedAgentIds.length < 2) {
      this.showToast('这场历史会议缺少参会人格信息，暂时无法继续发言')
      return
    }

    const primaryProfileId = recordProfileIds[0]
    MeetingSessionStore.setProfileId(primaryProfileId)
    MeetingSessionStore.setProfileIds(recordProfileIds)
    MeetingSessionStore.setSelectedAgents(selectedAgentIds)
    MeetingSessionStore.setTopic(record.topic && record.topic.length > 0 ? record.topic : this.topic)
    MeetingSessionStore.setReasoningEffort(this.meetingReasoningEffort)
    MeetingSessionStore.setContinueContext(record.id, record.sessionId ? record.sessionId : '')
    await this.pushPage('pages/MeetingChatPage', {
      profileId: primaryProfileId,
      profileIds: recordProfileIds.join(','),
      selectedAgentIds: selectedAgentIds.join(','),
      topic: record.topic && record.topic.length > 0 ? record.topic : this.topic,
      continueFromRunId: record.id,
      sessionId: record.sessionId ? record.sessionId : '',
      reasoningEffort: this.meetingReasoningEffort
    })
  }

  private async goSummaryDetail(arenaRunId: string): Promise<void> {
    const params: IndexNavigationParams = { arenaRunId: arenaRunId }
    await this.pushPage('pages/SummaryDetailPage', params)
  }

  private async openSummaryDetailFromLaunch(intent: LaunchIntent): Promise<void> {
    const params: IndexNavigationParams = {}
    if (intent.summaryId.length > 0) {
      params.summaryId = intent.summaryId
    }
    if (intent.arenaRunId.length > 0) {
      params.arenaRunId = intent.arenaRunId
    }

    if (!params.summaryId && !params.arenaRunId) {
      this.showToast('缺少纪要标识，无法打开详情')
      return
    }

    await this.pushPage('pages/SummaryDetailPage', params)
  }

  private async goSummaryList(): Promise<void> {
    await this.pushPage('pages/SummaryListPage')
  }

  private async goUserCenter(): Promise<void> {
    const params: IndexNavigationParams = {
      userName: this.userName,
      userAvatar: this.userAvatar,
      openId: this.userOpenId,
      unionId: this.userUnionId
    }
    await this.pushPage('pages/UserCenter', params)
  }

  private switchTab(index: number): void {
    if (this.activeTab === index) {
      return
    }
    this.tabContentOpacity = 0.66
    this.tabContentOffsetY = 10
    this.activeTab = index
    setTimeout(() => {
      this.tabContentOpacity = 1
      this.tabContentOffsetY = 0
    }, 70)
    if (index === 1) {
      void this.loadMeetingRecords()
    }
  }

  private handleRetry(): void {
    void this.hydratePresets()
  }

  private showToast(message: string): void {
    try {
      void promptAction.openToast({ message: message })
    } catch (_error) {
    }
  }

  private latestLaunchSnapshot() {
    return buildRecentMeetingSnapshot(MeetingSessionStore.getHistoryRecords(), this.meetingReasoningEffort)
  }

  private async consumePendingLaunchIntent(): Promise<void> {
    const intent = LaunchIntentStore.take()
    if (!intent || intent.action === 'none') {
      return
    }

    if (intent.action === 'open-recent-summaries') {
      await this.goSummaryList()
      return
    }

    if (intent.action === 'open-summary-detail') {
      await this.openSummaryDetailFromLaunch(intent)
      return
    }

    if (intent.action === 'new-meeting') {
      await this.handleLaunchNewMeeting()
      return
    }

    await this.handleLaunchContinueMeeting(intent)
  }

  private async handleLaunchNewMeeting(): Promise<void> {
    MeetingSessionStore.clearContinueContext()
    const effectiveProfileIds = this.effectiveProfileIdsForLaunch()
    if (effectiveProfileIds.length === 0) {
      return
    }

    const params: IndexNavigationParams = {
      profileId: effectiveProfileIds[0],
      profileIds: effectiveProfileIds.join(','),
      selectedAgentIds: this.effectiveSelectedAgentIds().join(','),
      topic: '',
      reasoningEffort: this.meetingReasoningEffort,
      focus: 'roles'
    }
    await this.pushPage('pages/MeetingParticipantPage', params)
  }

  private effectiveProfileIdsForLaunch(): string[] {
    if (this.selectedProfile.id.length > 0) {
      return [this.selectedProfile.id]
    }
    const sessionProfileIds = MeetingSessionStore.getProfileIds()
    if (sessionProfileIds.length > 0) {
      return sessionProfileIds
    }
    if (this.profiles.length > 0) {
      return [this.profiles[0].id]
    }
    return []
  }

  private async handleLaunchContinueMeeting(intent: LaunchIntent): Promise<void> {
    const fallbackIntent = buildLaunchIntentFromQuickAction('continue-meeting', this.latestLaunchSnapshot())
    const effectiveIntent: LaunchIntent = {
      action: 'continue-meeting',
      targetPage: 'pages/MeetingChatPage',
      continueFromRunId: intent.continueFromRunId.length > 0 ? intent.continueFromRunId : fallbackIntent.continueFromRunId,
      sessionId: intent.sessionId.length > 0 ? intent.sessionId : fallbackIntent.sessionId,
      summaryId: '',
      arenaRunId: '',
      topic: intent.topic.length > 0 ? intent.topic : fallbackIntent.topic,
      profileIds: intent.profileIds.length > 0 ? intent.profileIds : fallbackIntent.profileIds,
      selectedAgentIds: intent.selectedAgentIds.length > 0 ? intent.selectedAgentIds : fallbackIntent.selectedAgentIds,
      reasoningEffort: intent.reasoningEffort
    }

    if (effectiveIntent.profileIds.length === 0 || effectiveIntent.selectedAgentIds.length < 2) {
      this.showToast('还没有可继续的会议')
      return
    }

    MeetingSessionStore.setProfileId(effectiveIntent.profileIds[0])
    MeetingSessionStore.setProfileIds(effectiveIntent.profileIds)
    MeetingSessionStore.setSelectedAgents(effectiveIntent.selectedAgentIds)
    MeetingSessionStore.setTopic(effectiveIntent.topic)
    MeetingSessionStore.setReasoningEffort(effectiveIntent.reasoningEffort)
    MeetingSessionStore.setContinueContext(effectiveIntent.continueFromRunId, effectiveIntent.sessionId)

    const routeParams = buildRouteParamsFromLaunchIntent(effectiveIntent)
    const params: IndexNavigationParams = {
      profileId: effectiveIntent.profileIds[0],
      profileIds: routeParams.profileIds,
      selectedAgentIds: routeParams.selectedAgentIds,
      topic: routeParams.topic,
      continueFromRunId: routeParams.continueFromRunId,
      sessionId: routeParams.sessionId,
      reasoningEffort: routeParams.reasoningEffort
    }
    await this.pushPage('pages/MeetingChatPage', params)
  }

  @Builder
  private buildBackground() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.background)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['#F6F8FB', 0],
            [Colors.background, 0.44],
            ['#E8EDF3', 1]
          ]
        })

      Column()
        .width(560)
        .height(560)
        .borderRadius(280)
        .linearGradient({
          angle: 132,
          colors: [
            ['rgba(150, 170, 202, 0.20)', 0],
            ['rgba(232, 238, 245, 0.08)', 0.56],
            ['rgba(241, 245, 249, 0.00)', 1]
          ]
        })
        .blur(56)
        .opacity(0.42)
        .position({ x: '-36%', y: -120 })

      Column()
        .width(460)
        .height(460)
        .borderRadius(230)
        .linearGradient({
          angle: 32,
          colors: [
            ['rgba(241, 205, 181, 0.18)', 0],
            ['rgba(250, 238, 229, 0.06)', 0.62],
            ['rgba(248, 250, 252, 0.00)', 1]
          ]
        })
        .blur(44)
        .opacity(0.40)
        .position({ x: '54%', y: 24 })

      Column()
        .width(420)
        .height(420)
        .borderRadius(210)
        .linearGradient({
          angle: 120,
          colors: [
            ['rgba(160, 201, 191, 0.14)', 0],
            ['rgba(232, 245, 241, 0.05)', 0.52],
            ['rgba(247, 249, 251, 0.00)', 1]
          ]
        })
        .blur(36)
        .opacity(0.34)
        .position({ x: '-18%', y: '58%' })

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            [Colors.overlayMedium, 0],
            [Colors.overlaySoft, 0.26],
            ['rgba(255, 255, 255, 0.00)', 0.62],
            [Colors.backgroundTertiary, 1]
          ]
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildProfileCard() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width(52)
        .height(52)
        .borderRadius(26)
        .backgroundColor('rgba(210, 220, 232, 0.20)')
        .opacity(0.42)
        .translate({ x: 0, y: 3 })

      Column()
        .width(58)
        .height(58)
        .borderRadius(29)
        .linearGradient({
          angle: 135,
          colors: [
            ['rgba(255, 255, 255, 0.96)', 0],
            ['rgba(232, 239, 247, 0.96)', 1]
          ]
        })
        .border({
          width: 1,
          color: Colors.border,
          radius: 29
        })
        .shadow({
          radius: 10,
          color: 'rgba(124, 153, 195, 0.14)',
          offsetX: 0,
          offsetY: 4
        })

      if (this.userAvatar.length > 0) {
        Image(this.userAvatar)
          .width(48)
          .height(48)
          .borderRadius(24)
          .objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text(this.profileAvatarLetter())
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#304154')
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .linearGradient({
          angle: 135,
          colors: [
            ['rgba(240, 244, 249, 1)', 0],
            ['rgba(220, 229, 240, 1)', 1]
          ]
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      Column()
        .width(12)
        .height(12)
        .borderRadius(6)
        .backgroundColor(Colors.success)
        .border({
          width: 2,
          color: Colors.backgroundElevated,
          radius: 6
        })
        .position({ x: 39, y: 39 })
    }
    .width(56)
    .height(56)
    .scale({
      x: this.pressedProfileCard ? 0.96 : 1,
      y: this.pressedProfileCard ? 0.96 : 1
    })
    .translate({ x: 0, y: -10 })
    .animation({
      duration: 180,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedProfileCard = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedProfileCard = false
      }
    })
    .onClick(() => {
      void this.goUserCenter()
    })
  }

  @Builder
  private buildWelcomeSection() {
    Column({ space: 1 }) {
      Text(this.welcomeEyebrow())
        .fontSize(9)
        .fontWeight(FontWeight.Medium)
        .fontColor('rgba(107, 123, 150, 0.72)')
        .letterSpacing(1.8)
        .fontFamily('HarmonyOS Sans')
        .textCase(TextCase.UpperCase)
        .width('100%')

      Text(this.welcomeTitle())
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .fontFamily('HarmonyOS Sans SC')
        .letterSpacing(0.4)
        .width('100%')

      Text(this.welcomeSubtitle())
        .fontSize(10)
        .fontColor(Colors.textSecondary)
        .lineHeight(14)
        .width('100%')
        .maxLines(1)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildCalendarStrip() {
    Column({ space: 10 }) {
      Row() {
        Row({ space: 8 }) {
          Column()
            .width(4)
            .height(18)
            .borderRadius(2)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                ['rgba(91, 162, 255, 0.96)', 0],
                ['rgba(178, 210, 255, 0.88)', 1]
              ]
            })

          Column({ space: 2 }) {
            Text('日历')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)

            Text('默认定位到今天')
              .fontSize(10)
              .fontColor('rgba(98, 114, 138, 0.66)')
          }
          .alignItems(HorizontalAlign.Start)
        }

        Blank()

        Row({ space: 6 }) {
          this.buildCalendarStepper('year', `${this.selectedCalendarYear}年`, () => {
            this.changeCalendarYear(-1)
          }, () => {
            this.changeCalendarYear(1)
          })

          this.buildCalendarStepper('month', `${this.selectedCalendarMonth}月`, () => {
            this.changeCalendarMonth(-1)
          }, () => {
            this.changeCalendarMonth(1)
          })
        }
      }
      .width('100%')

      Scroll(this.calendarScroller) {
        Row({ space: 10 }) {
          ForEach(this.homeCalendarDays(), (day: HomeCalendarDay, index: number) => {
            this.buildCalendarDayItem(day, index)
          }, (day: HomeCalendarDay) => day.id)
        }
        .padding({ right: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .backgroundColor('rgba(252, 254, 255, 0.96)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 1)', 0],
        ['rgba(247, 251, 255, 0.98)', 0.62],
        ['rgba(243, 248, 255, 0.96)', 1]
      ]
    })
    .border({
      width: 1.1,
      color: 'rgba(191, 205, 227, 0.92)',
      radius: 26
    })
    .borderRadius(26)
    .shadow({
      radius: 14,
      color: 'rgba(140, 168, 208, 0.08)',
      offsetX: 0,
      offsetY: 7
    })
  }

  @Builder
  private buildCalendarStepper(key: string, label: string, onMinus: () => void, onPlus: () => void) {
    Row({ space: 6 }) {
      Button() {
        Icon({
          iconType: 'minus',
          iconSize: 11,
          iconColor: Colors.textPrimary,
          strokeWidth: 1.8
        })
      }
      .width(24)
      .height(24)
      .backgroundColor('rgba(255, 255, 255, 0.98)')
      .border({
        width: 1,
        color: 'rgba(214, 224, 240, 0.96)',
        radius: 12
      })
      .borderRadius(12)
      .scale({
        x: this.pressedCalendarControl === `${key}-minus` ? 0.92 : 1,
        y: this.pressedCalendarControl === `${key}-minus` ? 0.92 : 1
      })
      .animation({
        duration: 160,
        curve: Curve.FastOutSlowIn
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressedCalendarControl = `${key}-minus`
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressedCalendarControl = ''
        }
      })
      .onClick(() => {
        onMinus()
      })

      Text(label)
        .fontSize(11.5)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textSecondary)
        .padding({ left: 2, right: 2 })

      Button() {
        Icon({
          iconType: 'plus',
          iconSize: 11,
          iconColor: Colors.textPrimary,
          strokeWidth: 1.8
        })
      }
      .width(24)
      .height(24)
      .backgroundColor('rgba(255, 255, 255, 0.98)')
      .border({
        width: 1,
        color: 'rgba(214, 224, 240, 0.96)',
        radius: 12
      })
      .borderRadius(12)
      .scale({
        x: this.pressedCalendarControl === `${key}-plus` ? 0.92 : 1,
        y: this.pressedCalendarControl === `${key}-plus` ? 0.92 : 1
      })
      .animation({
        duration: 160,
        curve: Curve.FastOutSlowIn
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressedCalendarControl = `${key}-plus`
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressedCalendarControl = ''
        }
      })
      .onClick(() => {
        onPlus()
      })
    }
    .padding({ left: 8, right: 8, top: 6, bottom: 6 })
    .backgroundColor('rgba(246, 250, 255, 0.98)')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 0.98)', 0],
        ['rgba(244, 248, 255, 0.96)', 1]
      ]
    })
    .border({
      width: 1,
      color: 'rgba(206, 218, 238, 0.94)',
      radius: 17
    })
    .borderRadius(17)
    .shadow({
      radius: 8,
      color: 'rgba(147, 172, 207, 0.06)',
      offsetX: 0,
      offsetY: 3
    })
  }

  @Builder
  private buildCalendarDayItem(day: HomeCalendarDay, index: number) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(72)
        .height(88)
        .borderRadius(20)
        .backgroundColor(day.dayNumber === this.selectedCalendarDay ? 'rgba(109, 175, 255, 0.26)' : 'rgba(205, 222, 247, 0.14)')
        .translate({ x: 0, y: 9 })
        .opacity(day.dayNumber === this.selectedCalendarDay ? 0.88 : 0.42)

      Column()
        .width(72)
        .height(88)
        .borderRadius(20)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: day.dayNumber === this.selectedCalendarDay ? [
            ['rgba(102, 167, 255, 1)', 0],
            ['rgba(81, 146, 243, 0.98)', 0.54],
            ['rgba(71, 128, 226, 0.96)', 1]
          ] : [
            ['rgba(255, 255, 255, 0.99)', 0],
            ['rgba(247, 250, 255, 0.98)', 0.56],
            ['rgba(241, 246, 255, 0.96)', 1]
          ]
        })

      Column()
        .width(54)
        .height(14)
        .borderRadius(9)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(255, 255, 255, 0.58)', 0],
            ['rgba(255, 255, 255, 0)', 1]
          ]
        })
        .position({ x: 8, y: 8 })
        .opacity(day.dayNumber === this.selectedCalendarDay ? 0.92 : 0.62)

      Column({ space: 6 }) {
      Text(day.weekLabel)
        .fontSize(10)
        .fontWeight(day.isToday ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(day.dayNumber === this.selectedCalendarDay ? Colors.cardPrimary : (day.isToday ? Colors.accent : Colors.textMuted))

      Text(day.dayLabel)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(day.dayNumber === this.selectedCalendarDay ? '#FFFFFF' : Colors.textPrimary)

      Text(day.fullDateLabel)
        .fontSize(9)
        .fontColor(day.dayNumber === this.selectedCalendarDay ? 'rgba(255, 255, 255, 0.80)' : Colors.textMuted)
      }
    .width(72)
    .height(88)
    .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .border({
      width: day.dayNumber === this.selectedCalendarDay ? 1.1 : 1,
      color: day.dayNumber === this.selectedCalendarDay ? 'rgba(118, 183, 255, 0.96)' : 'rgba(208, 219, 237, 0.92)',
      radius: 20
    })
    .borderRadius(20)
    .shadow({
      radius: day.dayNumber === this.selectedCalendarDay ? 18 : 10,
      color: day.dayNumber === this.selectedCalendarDay ? 'rgba(75, 142, 255, 0.28)' : 'rgba(124, 150, 190, 0.08)',
      offsetX: 0,
      offsetY: day.dayNumber === this.selectedCalendarDay ? 8 : 4
    })
    .scale({
      x: this.pressedCalendarDayId === day.id ? 0.93 : 1,
      y: this.pressedCalendarDayId === day.id ? 0.93 : 1
    })
    .translate({
      x: 0,
      y: this.pressedCalendarDayId === day.id ? 3 : 0
    })
    .animation({
      duration: 160,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedCalendarDayId = day.id
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedCalendarDayId = ''
      }
    })
    .onClick(() => {
      this.selectedCalendarDay = day.dayNumber
    })
  }

  @Builder
  private buildHeader() {
    Row() {
      // 暂时隐藏左上角的四个点按钮
      /*
      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(Colors.textPrimary)

          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(Colors.textPrimary)
        }

        Row({ space: 4 }) {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(Colors.textPrimary)

          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(Colors.textPrimary)
        }
      }
      .width(38)
      .height(38)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(Colors.backgroundElevated)
      .border({
        width: 1,
        color: 'rgba(226, 232, 240, 0.86)',
        radius: 19
      })
      .borderRadius(19)
      */

      Blank()

      this.buildProfileCard()
    }
    .width('100%')
    .padding({
      left: this.responsiveLayout().pageHorizontalPadding,
      right: this.responsiveLayout().pageHorizontalPadding,
      top: this.safeTopVp - 2,
      bottom: 4
    })
    .zIndex(10) // 确保 Header 在滚动内容之上
  }

  @Builder
  private buildHomeFeatureCard(
    title: string,
    subtitle: string,
    tag: string,
    iconType: 'sparkles' | 'grid' | 'bookOpen' | 'chat',
    tintColor: ThemeColor,
    action: () => void
  ) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('86%')
        .height(138)
        .borderRadius(30)
        .backgroundColor(tintColor)
        .opacity(0.22)
        .translate({ x: 12, y: 20 })
        .rotate({ angle: tag === '01' || tag === '03' ? -5 : 4 })

      Column()
        .width(108)
        .height(108)
        .borderRadius(32)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            [Colors.overlayMedium, 0],
            [tintColor, 0.64],
            [Colors.overlaySoft, 1]
          ]
        })
        .opacity(0.20)
        .position({ x: '66%', y: 80 })
        .rotate({ angle: tag === '01' || tag === '04' ? 11 : -9 })

      Column()
        .width(82)
        .height(82)
        .borderRadius(24)
        .backgroundColor(Colors.overlaySoft)
        .opacity(0.62)
        .position({ x: '68%', y: 16 })
        .rotate({ angle: tag === '02' || tag === '04' ? 8 : -8 })

      Column({ space: 12 }) {
        Row() {
          Row({ space: 10 }) {
            Stack({ alignContent: Alignment.Center }) {
              Column()
                .width(52)
                .height(52)
                .borderRadius(16)
                .backgroundColor(LiquidGlass.surfaceStrong)
                .border({
                  width: 1,
                  color: LiquidGlass.border,
                  radius: 16
                })

              Icon({
                iconType: iconType,
                iconSize: 20,
                iconColor: Colors.textPrimary,
                strokeWidth: 1.8
              })
            }

            Column({ space: 3 }) {
              Text('FEATURE')
                .fontSize(9)
                .fontWeight(FontWeight.Medium)
                .fontColor(Colors.textMuted)
                .letterSpacing(1.3)

              Text(tag)
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.textPrimary)
            }
            .alignItems(HorizontalAlign.Start)
          }

          Blank()
        }
        .width('100%')

        Column({ space: 4 }) {
          Text(title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .width('100%')
            .maxLines(1)

          Text(subtitle)
            .fontSize(11)
            .fontColor(Colors.textSecondary)
            .lineHeight(17)
            .width('100%')
            .maxLines(2)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Blank()

        Row() {
          Text('ENTER')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .letterSpacing(1.0)

          Blank()

          Row({ space: 6 }) {
            Column()
              .width(26)
              .height(1)
              .backgroundColor(Colors.textMuted)
              .borderRadius(1)

            Text('>')
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
          }
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .height(182)
    .backgroundColor(Colors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [Colors.cardPrimary, 0],
        [Colors.cardSecondary, 0.58],
        [Colors.backgroundElevated, 1]
      ]
    })
    .border({
      width: 1.1,
      color: Colors.border,
      radius: 32
    })
    .borderRadius(32)
    .shadow({
      radius: this.pressedFeatureCardTag === tag ? 8 : 18,
      color: this.pressedFeatureCardTag === tag ? 'rgba(115, 131, 154, 0.05)' : 'rgba(115, 131, 154, 0.12)',
      offsetX: 0,
      offsetY: this.pressedFeatureCardTag === tag ? 3 : 10
    })
    .clip(true)
    .scale({
      x: this.pressedFeatureCardTag === tag ? 0.972 : 1,
      y: this.pressedFeatureCardTag === tag ? 0.972 : 1
    })
    .translate({
      x: 0,
      y: this.pressedFeatureCardTag === tag ? 2 : 0
    })
    .animation({
      duration: 180,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedFeatureCardTag = tag
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedFeatureCardTag = ''
      }
    })
    .onClick(() => {
      action()
    })
  }

  @Builder
  private buildHomeFunctionGrid() {
    Column({ space: 12 }) {
      Row() {
        Text('功能')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()

        Text('精选入口')
          .fontSize(12)
          .fontColor(Colors.textMuted)
      }
      .width('100%')

      Row({ space: 12 }) {
        this.buildHomeFeatureCard('创建角色', '一句灵感也能开始。', '01', 'sparkles', 'rgba(232, 194, 170, 0.86)', () => {
          void this.goCreateRole()
        })
        this.buildHomeFeatureCard('探索角色', '快速切换喜欢的人设。', '02', 'grid', 'rgba(174, 201, 225, 0.84)', () => {
          void this.goExplorePersonas()
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildHomeMoodPanel() {
    Row({ space: 10 }) {
      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text('今日状态')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.accent)

          Text(this.homeMoodBadge())
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textSecondary)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(Colors.overlaySoft)
            .borderRadius(10)
        }

        Text(this.homeMoodTitle())
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)
          .lineHeight(22)

        Text(this.homeMoodSubtitle())
          .fontSize(10)
          .fontColor(Colors.textSecondary)
          .lineHeight(13)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 4 }) {
        Text(this.hasReadyMeetingSelection() ? '顺' : '静')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Text(this.hasReadyMeetingSelection() ? '适合展开' : '适合梳理')
          .fontSize(10)
          .fontColor(Colors.textMuted)
      }
      .width(64)
      .height(72)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 8, right: 8 })
      .backgroundColor(Colors.overlaySoft)
      .borderRadius(18)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Colors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [Colors.cardPrimary, 0],
        [Colors.cardSecondary, 0.54],
        [Colors.backgroundElevated, 1]
      ]
    })
    .border({
      width: 1.1,
      color: Colors.border,
      radius: 28
    })
    .borderRadius(28)
    .shadow({
      radius: 16,
      color: 'rgba(118, 156, 204, 0.12)',
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  private buildMeetingHeroCard() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(34)
        .linearGradient({
          angle: 140,
          colors: [
            ['rgba(117, 135, 160, 0.10)', 0],
            ['rgba(255, 255, 255, 0.0)', 0.52],
            ['rgba(166, 181, 200, 0.08)', 1]
          ]
        })
        .blur(10)

      Column()
        .width('88%')
        .height('86%')
        .borderRadius(30)
        .backgroundColor(Colors.overlaySoft)
        .position({ x: 14, y: 18 })
        .rotate({ angle: -4 })

      Column()
        .width('100%')
        .height('100%')
        .borderRadius(34)
        .backgroundColor(Colors.cardPrimary)
        .backdropBlur(12)
        .linearGradient({
          angle: 145,
          colors: [
            [Colors.cardPrimary, 0],
            [Colors.cardSecondary, 0.58],
            [Colors.backgroundElevated, 1]
          ]
        })
        .border({
          width: 1.2,
          color: Colors.border,
          radius: 34
        })

      Column()
        .width(142)
        .height(142)
        .borderRadius(36)
        .linearGradient({
          angle: 132,
          colors: [
            [Colors.overlayMedium, 0],
            ['rgba(255, 255, 255, 0.00)', 1]
          ]
        })
        .opacity(0.42)
        .position({ x: '70%', y: 118 })

      Column({ space: 12 }) {
        Row() {
          this.buildMeetingStatusPill('上一次会议', this.lastMeetingStatusLabel())

          Blank()

          Text(`${this.lastMeetingPersonaCountLabel()} 位人格`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .backgroundColor(Colors.overlaySoft)
            .borderRadius(14)
            .border({
              width: 1,
              color: Colors.border,
              radius: 14
            })
        }
        .width('100%')

        Column({ space: 6 }) {
          Text('继续上一次会议')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .lineHeight(34)
            .width('100%')

          Text(this.lastMeetingTitle())
            .fontSize(13)
            .fontColor(Colors.textSecondary)
            .lineHeight(18)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Text(this.lastMeetingTopicPreview())
          .fontSize(12)
          .fontColor(Colors.textMuted)
          .lineHeight(18)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 12 }) {
          Column({ space: 2 }) {
            Text(this.lastMeetingPersonaCountLabel())
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)

            Text('参会人格')
              .fontSize(10)
              .fontColor(Colors.textMuted)
          }
          .width(82)
          .height(44)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(Colors.overlaySoft)
          .border({
            width: 1,
            color: Colors.border,
            radius: 22
          })
          .borderRadius(22)

          Button(this.lastMeetingActionLabel())
            .layoutWeight(1)
            .height(44)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textInverse)
            .linearGradient({
              angle: 135,
              colors: [
                ['#213245', 0],
                ['#36485D', 1]
              ]
            })
            .borderRadius(22)
            .border({
              width: 1,
              color: 'rgba(255, 255, 255, 0.24)',
              radius: 22
            })
            .shadow({
              radius: this.pressedActionBtn ? 6 : 12,
              color: 'rgba(33, 50, 69, 0.24)',
              offsetX: 0,
              offsetY: this.pressedActionBtn ? 2 : 5
            })
            .scale({
              x: this.pressedActionBtn ? 0.97 : 1,
              y: this.pressedActionBtn ? 0.97 : 1
            })
            .translate({ x: 0, y: this.pressedActionBtn ? 2 : 0 })
            .animation({
              duration: 160,
              curve: Curve.FastOutSlowIn
            })
            .onTouch((event: TouchEvent) => {
              // 阻止事件冒泡到外层的卡片
              if (event) {
                event.stopPropagation()
              }
              if (event.type === TouchType.Down) {
                this.pressedActionBtn = true
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.pressedActionBtn = false
              }
            })
            .onClick(() => {
              void this.handleLastMeetingAction()
            })
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 18 })
    }
    .width('100%')
    .height(226)
    .borderRadius(34)
    .clip(true)
    .opacity(1)
    .translate({ x: 0, y: this.pressedLastMeetingHero ? 2 : 0 })
    .scale({
      x: this.pressedLastMeetingHero ? 0.97 : 1,
      y: this.pressedLastMeetingHero ? 0.97 : 1
    })
    .animation({
      duration: 180,
      curve: Curve.FastOutSlowIn
    })
    .shadow({
      radius: this.pressedLastMeetingHero ? 10 : 24,
      color: this.pressedLastMeetingHero ? 'rgba(105, 122, 148, 0.10)' : 'rgba(111, 130, 158, 0.16)',
      offsetX: 0,
      offsetY: this.pressedLastMeetingHero ? 4 : 10
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedLastMeetingHero = true
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedLastMeetingHero = false
      }
    })
  }

  @Builder
  private buildMeetingStatusPill(label: string, value: string) {
    Row({ space: 6 }) {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textMuted)

      Text(value)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
    }
    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
    .backgroundColor(Colors.overlaySoft)
    .border({
      width: 1,
      color: Colors.border,
      radius: 14
    })
    .borderRadius(14)
    .shadow({
      radius: 10,
      color: Colors.shadowSoft,
      offsetX: 0,
      offsetY: 4
    })
  }

  @Builder
  private buildMeetingPrepSection() {
    Column({ space: 10 }) {
      Row() {
        Text('准备')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()

        Text(this.hasReadyMeetingSelection() ? '就绪' : '待完善')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.hasReadyMeetingSelection() ? Colors.success : Colors.warning)
          .padding({ left: 9, right: 9, top: 4, bottom: 4 })
          .backgroundColor(this.hasReadyMeetingSelection() ? 'rgba(49, 95, 102, 0.08)' : 'rgba(126, 106, 68, 0.08)')
          .borderRadius(12)
      }
      .width('100%')

      Row({ space: 9 }) {
        this.buildMeetingPrepCard('角色', this.meetingPersonaPrepLabel(), 'role', () => {
          void this.goMeetingParticipantWithFocus('roles')
        })

        this.buildMeetingPrepCard('参数', this.meetingParameterPreview(), 'params', () => {
          this.openMeetingParameterPanel()
        })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildMeetingPrepCard(title: string, value: string, tag: string, action: () => void) {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(11)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textSecondary)
        .width('100%')

      Text(value)
        .fontSize(tag === 'topic' ? 13 : 16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .lineHeight(tag === 'topic' ? 18 : 20)
        .maxLines(tag === 'topic' ? 2 : 1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .layoutWeight(1)
    .height(84)
    .padding({ left: 14, right: 14, top: 14, bottom: 14 })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(Colors.cardPrimary)
    .backdropBlur(10)
    .linearGradient({
      angle: 135,
      colors: [
        [Colors.cardPrimary, 0],
        [Colors.cardSecondary, 1]
      ]
    })
    .border({
      width: 1,
      color: Colors.border,
      radius: 24
    })
    .borderRadius(24)
    .shadow({
      radius: this.pressedMeetingCardTag === tag ? 8 : 16,
      color: 'rgba(109, 124, 148, 0.10)',
      offsetX: 0,
      offsetY: this.pressedMeetingCardTag === tag ? 4 : 7
    })
    .scale({
      x: this.pressedMeetingCardTag === tag ? 0.97 : 1,
      y: this.pressedMeetingCardTag === tag ? 0.97 : 1
    })
    .animation({
      duration: 160,
      curve: Curve.FastOutSlowIn
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedMeetingCardTag = tag
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedMeetingCardTag = ''
      }
    })
    .onClick(() => {
      action()
    })
  }

  @Builder
  private buildHomeRecommendationCard(
    title: string,
    subtitle: string,
    tag: string,
    mood: 'happy' | 'shy' | 'angry' | 'sleep',
    accentColor: ThemeColor,
    action: () => void
  ) {
    Column({ space: 6 }) {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(46)
            .height(46)
            .borderRadius(23)
            .backgroundColor(accentColor)
            .opacity(0.20)

          AnimatedCloudMascot({
            mascotSize: 42,
            mood,
            enableFloat: false,
            enableBlink: false,
            backgroundGlow: false,
            motionLevel: 'still'
          })
        }

        Blank()

        Text(tag)
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.textSecondary)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(Colors.overlaySoft)
          .borderRadius(10)
      }
      .width('100%')

      Column({ space: 3 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Text(subtitle)
          .fontSize(10)
          .fontColor(Colors.textSecondary)
          .lineHeight(13)
          .maxLines(1)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .layoutWeight(1)
    .height(108)
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(Colors.cardPrimary)
    .backdropBlur(10)
    .linearGradient({
      angle: 135,
      colors: [
        [Colors.cardPrimary, 0],
        [Colors.cardSecondary, 1]
      ]
    })
    .border({
      width: 1.5,
      color: Colors.border,
      radius: 28
    })
    .borderRadius(28)
    .shadow({
      radius: 12,
      color: 'rgba(92, 168, 255, 0.14)',
      offsetX: 0,
      offsetY: 5
    })
    .onClick(() => {
      action()
    })
  }

  @Builder
  private buildHomeRecommendationSection() {
    Column({ space: 12 }) {
      Row() {
        Text('今天做什么')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()
      }
      .width('100%')

      Row({ space: 10 }) {
        this.buildHomeRecommendationCard(
          this.homeRecommendationTitle(true),
          this.homeRecommendationSubtitle(true),
          '适合今天',
          'happy',
          'rgba(173, 218, 255, 0.92)',
          () => {
            if (this.hasReadyMeetingSelection()) {
              void this.goMeetingParticipant()
              return
            }
            void this.goCreateRole()
          }
        )

        this.buildHomeRecommendationCard(
          this.homeRecommendationTitle(false),
          this.homeRecommendationSubtitle(false),
          '轻探索',
          'shy',
          'rgba(188, 228, 216, 0.90)',
          () => {
            void this.goExplorePersonas()
          }
        )
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildSoftQuickAction(title: string, subtitle: string, mascotMood: 'happy' | 'shy' | 'angry' | 'sleep', action: () => void) {
    Row({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        Column()
          .width(38)
          .height(38)
          .borderRadius(19)
          .backgroundColor(Colors.overlaySoft)

        AnimatedCloudMascot({
          mascotSize: 34,
          mood: mascotMood,
          enableFloat: false,
          enableBlink: false,
          backgroundGlow: false,
          motionLevel: 'still'
        })
      }

      Column({ space: 3 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Text(subtitle)
          .fontSize(10)
          .fontColor(Colors.textMuted)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(Colors.cardPrimary)
    .backdropBlur(10)
    .linearGradient({
      angle: 135,
      colors: [
        [Colors.cardPrimary, 0],
        [Colors.cardSecondary, 1]
      ]
    })
    .border({
      width: 1.5,
      color: Colors.border,
      radius: 20
    })
    .borderRadius(20)
    .shadow({
      radius: 16,
      color: 'rgba(92, 168, 255, 0.12)',
      offsetX: 0,
      offsetY: 6
    })
    .onClick(() => {
      action()
    })
  }

  @Builder
  private buildHomeQuickActions() {
    Column({ space: 12 }) {
      Row() {
        Text('扩展')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()
      }
      .width('100%')

      Row({ space: 10 }) {
        this.buildSoftQuickAction('资料', this.taskInfoPreview(), 'shy', () => {
          void this.goExplorePersonas()
        })
        this.buildSoftQuickAction('创建', 'AI生成', 'happy', () => {
          void this.goCreateRole()
        })
      }
      .width('100%')

      Row({ space: 10 }) {
        this.buildSoftQuickAction('导入', '外部文件', 'angry', () => {
          void this.goImportProfile()
        })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildHomeHistorySection() {
    Column({ space: 12 }) {
      Row() {
        Text('历史会议')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textPrimary)

        Blank()

        if (this.records.length > 0) {
          Text('查看全部')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textSecondary)
            .onClick(() => {
              void this.goSummaryList()
            })
        }
      }
      .width('100%')

      if (this.records.length === 0) {
        Column({ space: 10 }) {
          Text('暂无记录')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)

          Text('从上方开始第一场会议。')
            .fontSize(12)
            .fontColor(Colors.textSecondary)
            .lineHeight(18)
            .width('100%')
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 18, bottom: 18 })
        .backgroundColor(Colors.cardPrimary)
        .backdropBlur(10)
        .linearGradient({
          angle: 135,
          colors: [
            [Colors.cardPrimary, 0],
            [Colors.cardSecondary, 1]
          ]
        })
        .border({
          width: 1,
          color: Colors.border,
          radius: 24
        })
        .borderRadius(24)
        .shadow({
          radius: 12,
          color: 'rgba(109, 124, 148, 0.10)',
          offsetX: 0,
          offsetY: 5
        })
      } else {
        Column({ space: 12 }) {
          ForEach(this.records.slice(0, 3), (record: RecordItem, index: number) => {
            HomeHistoryCard({
              record: record,
              index: index,
              onDetail: (id: string) => { void this.goSummaryDetail(id) },
              onContinue: (rec: RecordItem) => { void this.continueMeeting(rec) }
            })
          }, (record: RecordItem) => record.id)
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  private buildMeetingParameterPanel() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(16, 24, 40, 0.18)')
        .opacity(this.meetingParameterPanelOverlayOpacity)
        .animation({ duration: 260, curve: Curve.EaseOut })
        .onClick(() => {
          this.closeMeetingParameterPanel()
        })

      Column({ space: 14 }) {
        Row() {
          Blank()

          Column()
            .width(42)
            .height(5)
            .backgroundColor('rgba(123, 139, 162, 0.34)')
            .borderRadius(3)

          Blank()
        }
        .width('100%')

        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text('会议参数')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)

            Text('只保留 Agent 准度，议题进入对话页后再输入。')
              .fontSize(12)
              .fontColor(Colors.textMuted)
              .lineHeight(18)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('关闭')
            .height(34)
            .padding({ left: 14, right: 14 })
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .backgroundColor(Colors.cardSecondary)
            .borderRadius(17)
            .border({
              width: 1,
              color: Colors.border,
              radius: 17
            })
            .onClick(() => {
              this.closeMeetingParameterPanel()
            })
        }
        .width('100%')
        .padding({ right: 14 })

        Column({ space: 10 }) {
          Row() {
            Text('Agent 准度')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)

            Blank()

            Text(this.reasoningEffortLabel(this.parameterDraftReasoningEffort))
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.accent)
          }
          .width('100%')

          Text('只保存前端参数，后端接口暂时保持不动。')
            .fontSize(11)
            .fontColor(Colors.textMuted)
            .width('100%')

          Row({ space: 10 }) {
            ForEach(HOME_REASONING_EFFORT_OPTIONS, (option: HomeReasoningEffortOption) => {
              this.buildReasoningEffortOption(option)
            }, (option: HomeReasoningEffortOption) => `home_effort_${option.value}`)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .backgroundColor(Colors.cardPrimary)
        .linearGradient({
          angle: 140,
          colors: [
            [Colors.overlayMedium, 0],
            [Colors.cardSecondary, 0.58],
            [Colors.backgroundElevated, 1]
          ]
        })
        .border({
          width: 1,
          color: Colors.border,
          radius: 24
        })
        .borderRadius(24)
        .shadow({
          radius: 12,
          color: Colors.shadowMedium,
          offsetX: 0,
          offsetY: 5
        })

        Button('保存参数')
          .width('100%')
          .height(52)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.textInverse)
          .linearGradient({
            angle: 135,
            colors: [
              [Colors.primary, 0],
              [Colors.accent, 1]
            ]
          })
          .borderRadius(26)
          .shadow({
            radius: 18,
            color: 'rgba(8, 124, 197, 0.24)',
            offsetX: 0,
            offsetY: 8
          })
          .onClick(() => {
            this.saveMeetingParameters()
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 18,
        bottom: Math.max(this.safeBottomVp, 16) + 18
      })
      .backgroundColor(Colors.backgroundElevated)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          [Colors.cardPrimary, 0],
          [Colors.cardSecondary, 0.52],
          [Colors.backgroundElevated, 1]
        ]
      })
      .backdropBlur(16)
      .border({
        width: 1,
        color: Colors.border,
        radius: 28
      })
      .borderRadius(28)
      .shadow({
        radius: 18,
        color: Colors.shadowStrong,
        offsetX: 0,
        offsetY: -4
      })
      .opacity(this.meetingParameterPanelOpacity)
      .translate({ y: this.meetingParameterPanelTranslateY })
      .animation({
        duration: this.meetingParameterPanelVisible ? 360 : 280,
        curve: this.meetingParameterPanelVisible ? Curve.EaseOut : Curve.EaseIn
      })
    }
    .width('100%')
    .height('100%')
    .zIndex(30)
  }

  @Builder
  private buildReasoningEffortOption(option: HomeReasoningEffortOption) {
    Column({ space: 4 }) {
      Text(option.label)
        .fontSize(15)
        .fontWeight(this.parameterDraftReasoningEffort === option.value ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.parameterDraftReasoningEffort === option.value ? '#FFFFFF' : Colors.textPrimary)

      Text(option.description)
        .fontSize(10)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .fontColor(this.parameterDraftReasoningEffort === option.value ? Colors.cardPrimary : Colors.textMuted)
    }
    .layoutWeight(1)
    .height(74)
    .padding({ left: 8, right: 8, top: 10, bottom: 10 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.parameterDraftReasoningEffort === option.value ? Colors.accent : Colors.cardPrimary)
    .linearGradient({
      angle: 135,
      colors: this.parameterDraftReasoningEffort === option.value
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
      color: this.parameterDraftReasoningEffort === option.value ? Colors.primary : Colors.border,
      radius: 18
    })
    .borderRadius(18)
    .shadow({
      radius: this.parameterDraftReasoningEffort === option.value ? 12 : 0,
      color: this.parameterDraftReasoningEffort === option.value ? Colors.shadowMedium : 'rgba(255, 255, 255, 0.00)',
      offsetX: 0,
      offsetY: 4
    })
    .onClick(() => {
      this.parameterDraftReasoningEffort = option.value
    })
  }

  @Builder
  private buildHomeTab() {
    Column() {
      if (this.responsiveLayout().useSplitHomeLayout) {
        Row({ space: this.responsiveLayout().splitPanelGap }) {
          Column({ space: this.responsiveLayout().sectionGap }) {
            this.buildMeetingHeroCard()
            this.buildMeetingPrepSection()
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column({ space: this.responsiveLayout().sectionGap }) {
            this.buildHomeFunctionGrid()
            this.buildHomeHistorySection()
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      } else {
        Column({ space: this.responsiveLayout().sectionGap }) {
          this.buildMeetingHeroCard()
          this.buildMeetingPrepSection()
          this.buildHomeFunctionGrid()
          this.buildHomeHistorySection()
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildRecordsTab() {
    Column({ space: 16 }) {
      RecordsTab({
        records: this.records,
        onRecordClick: (record: RecordItem) => {
          void this.goSummaryDetail(record.id)
        },
        onGenerateCard: (record: RecordItem) => {
          void this.handleGenerateShareCard(record)
        },
        onGenerateVideo: (_record: RecordItem) => {
          this.showToast('会议视频入口开发中，可先使用生成卡片')
        },
        onShareRecord: (record: RecordItem) => {
          const params: IndexNavigationParams = {
            arenaRunId: record.id,
            openSheet: 'share'
          }
          void this.pushPage('pages/SummaryDetailPage', params)
        },
        onViewAll: () => {
          void this.goSummaryList()
        }
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      this.buildBackground()

      // 滚动区域（底层）
      Scroll() {
        Column({ space: this.responsiveLayout().sectionGap }) {
          Column({ space: this.responsiveLayout().sectionGap }) {
            // 顶部占位符，避免内容被绝对定位的 Header 遮挡
            Row()
              .width('100%')
              .height(56 + this.safeTopVp)

            LoadingOverlay({
              message: this.loading
            })

            ErrorToast({
              message: this.error,
              onRetry: () => {
                this.handleRetry()
              }
            })

            if (this.activeTab === 0) {
              this.buildHomeTab()
            } else {
              this.buildRecordsTab()
            }
          }
          .width('100%')
          .constraintSize({ maxWidth: this.responsiveLayout().contentMaxWidth })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .opacity(this.tabContentOpacity)
        .translate({ x: 0, y: this.tabContentOffsetY })
        .animation({
          duration: 220,
          curve: Curve.FastOutSlowIn
        })
        .padding({
          left: this.responsiveLayout().pageHorizontalPadding,
          right: this.responsiveLayout().pageHorizontalPadding,
          top: 0, // 顶部间距由上面的 Row 占位符控制
          bottom: 72 + this.safeBottomVp
        })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .position({ x: 0, y: 0 })
      .zIndex(1)

      // 顶部 Header (固定悬浮)
      Column() {
        this.buildHeader()
      }
      .width('100%')
      .position({ x: 0, y: 0 })
      .zIndex(10)

      if (this.showMeetingParameterPanel) {
        this.buildMeetingParameterPanel()
      }

      // 底部 TabBar
      TabBar({
        activeIndex: this.activeTab,
        safeBottomVp: this.safeBottomVp,
        onTabChange: (index: number) => {
          this.switchTab(index)
        },
        onPrimaryAction: () => {
          void this.goMeetingChatDirect()
        }
      })
      .zIndex(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('transparent')
  }
}

@Component
export struct HomeHistoryCard {
  @Prop record: RecordItem
  @Prop index: number
  onDetail: (id: string) => void = () => {}
  onContinue: (record: RecordItem) => void = () => {}

  @State private isPressed: boolean = false
  @State private isHovered: boolean = false

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height(126)
        .borderRadius(30)
        .linearGradient({
          angle: 135,
          colors: [
            [Colors.overlayMedium, 0],
            [Colors.overlaySoft, 1]
          ]
        })
        .translate({ x: 0, y: this.isHovered ? 8 : 12 })
        .opacity(this.isHovered ? 0.9 : 0.74)
        .animation({ duration: 200, curve: Curve.FastOutSlowIn })

      Column({ space: 12 }) {
      Row({ space: 14 }) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(44)
            .height(44)
            .borderRadius(22)
            .linearGradient({
              angle: 135,
              colors: [
                [Colors.overlayMedium, 0],
                [Colors.cardSecondary, 1]
              ]
            })
            .border({
              width: 1,
              color: Colors.border,
              radius: 22
            })
            .shadow({
              radius: this.isHovered ? 12 : 8,
              color: Colors.shadowMedium,
              offsetX: 0,
              offsetY: this.isHovered ? 4 : 2
            })

          Text(`${this.index + 1}`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
        }
        .width(44)
        .height(44)
        .shadow({
          radius: this.isHovered ? 14 : 10,
          color: 'rgba(148, 163, 184, 0.12)',
          offsetX: 0,
          offsetY: this.isHovered ? 5 : 3
        })
        .scale({ x: this.isHovered ? 1.03 : 1, y: this.isHovered ? 1.03 : 1 })
        .animation({ duration: 200, curve: Curve.FastOutSlowIn })

        Column({ space: 6 }) {
          Text(this.record.title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text(this.record.topic && this.record.topic.length > 0 ? this.record.topic : this.record.participantLine)
            .fontSize(12)
            .fontColor(Colors.textSecondary)
            .lineHeight(19)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row() {
        Row({ space: 5 }) {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor('rgba(102, 154, 219, 0.88)')

          Text(this.record.timeAgo)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textSecondary)
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(Colors.overlaySoft)
        .border({
          width: 1,
          color: Colors.border,
          radius: 12
        })
        .borderRadius(12)

        Blank()

        Row({ space: 10 }) {
          Button('查看纪要')
            .height(32)
            .padding({ left: 14, right: 14 })
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textTertiary)
            .backgroundColor(Colors.cardSecondary)
            .border({
              width: 1,
              color: Colors.border,
              radius: 16
            })
            .borderRadius(16)
            .shadow({
              radius: this.isHovered ? 6 : 4,
              color: Colors.shadowSoft,
              offsetX: 0,
              offsetY: this.isHovered ? 2 : 1
            })
            .scale({ x: this.isPressed ? 0.97 : 1, y: this.isPressed ? 0.97 : 1 })
            .animation({ duration: 150, curve: Curve.Sharp })
            .onClick(() => {
              this.onDetail(this.record.id)
            })

          Button('继续探讨')
            .height(32)
            .padding({ left: 14, right: 14 })
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textInverse)
            .linearGradient({
              angle: 135,
              colors: this.isHovered
                ? [
                    ['#6A9FE3', 0],
                    ['#4D83CF', 1]
                  ]
                : [
                    ['#7BADEB', 0],
                    ['#5C8FDB', 1]
                  ]
            })
            .borderRadius(16)
            .shadow({
              radius: this.isHovered ? 12 : 8,
              color: 'rgba(100, 145, 214, 0.28)',
              offsetX: 0,
              offsetY: this.isHovered ? 5 : 3
            })
            .scale({ x: this.isPressed ? 0.97 : 1, y: this.isPressed ? 0.97 : 1 })
            .animation({ duration: 150, curve: Curve.Sharp })
            .onClick(() => {
              this.onContinue(this.record)
            })
        }
      }
      .width('100%')
    }
    .width('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .backgroundColor(Colors.cardPrimary)
      .backdropBlur(12)
      .linearGradient({
        angle: 138,
        colors: [
          [Colors.overlayMedium, 0],
          [Colors.cardSecondary, 0.55],
          [Colors.backgroundElevated, 1]
        ]
      })
      .borderRadius(30)
      .clip(true)
    }
    .border({
      width: this.isHovered ? 1.5 : 1,
      color: this.isHovered ? Colors.accent : Colors.border,
      radius: 30
    })
    .borderRadius(30)
    .shadow({
      radius: this.isHovered ? 26 : 18,
      color: this.isHovered ? 'rgba(124, 153, 195, 0.22)' : 'rgba(124, 153, 195, 0.14)',
      offsetX: 0,
      offsetY: this.isHovered ? 12 : 7
    })
    .scale({ x: this.isPressed ? 0.98 : (this.isHovered ? 1.01 : 1), y: this.isPressed ? 0.98 : (this.isHovered ? 1.01 : 1) })
    .animation({ duration: this.isPressed ? 150 : 220, curve: this.isPressed ? Curve.Sharp : Curve.FastOutSlowIn })
    .onTouch((e: TouchEvent) => {
      if (e.type === TouchType.Down) {
        this.isPressed = true
        this.isHovered = true
      } else if (e.type === TouchType.Up || e.type === TouchType.Cancel) {
        this.isPressed = false
        setTimeout(() => {
          this.isHovered = false
        }, 200)
      }
    })
  }
}
