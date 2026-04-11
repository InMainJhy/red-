import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { ARENA_USER_TOPIC_AGENT_ID, ArenaMessage, ArenaSummary, DebateJudgeScorecard, PersonaSpec, PresetProfile, ProfileBundle, RouteParams } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { MAX_MEETING_PARTICIPANTS, parseMeetingSelection, parseRouteStringArray } from '../common/MeetingSelection'
import { PersonaApi } from '../service/PersonaApi'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'

const FALLBACK_SAFE_TOP_VP: number = 52
const DEFAULT_TOPIC: string = '这个选择现在该坚持，还是该及时转向？'

@Entry
@Component
struct Arena {
  @State bundles: ProfileBundle[] = []
  @State participants: PersonaSpec[] = []
  @State profileIds: string[] = []
  @State selectedAgentIds: string[] = []
  @State topic: string = DEFAULT_TOPIC
  @State messages: ArenaMessage[] = []
  @State summaryTitle: string = ''
  @State consensus: string = ''
  @State disagreements: string[] = []
  @State actionableAdvice: string[] = []
  @State narrativeHook: string = ''
  @State winnerDisplayName: string = ''
  @State verdictRationale: string = ''
  @State scorecards: DebateJudgeScorecard[] = []
  @State activeSpeakerAgentId: string = ''
  @State currentPhaseLabel: string = '待命'
  @State chatInputText: string = ''
  @State isLoadingSelection: boolean = false
  @State isGenerating: boolean = false
  @State isPlaying: boolean = false
  @State noticeMessage: string = ''
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0
  @State showRosterSheet: boolean = false
  @State pickerPresets: PresetProfile[] = []
  @State pickerExpandedProfileId: string = ''
  @State pickerExpandedBundle: ProfileBundle | null = null
  @State pickerLoadingProfileId: string = ''
  @State pickerNotice: string = ''
  private playbackHandle: number = -1

  aboutToAppear(): void {
    this.loadSafeInsets()
    void this.loadArenaSelection()
  }

  aboutToDisappear(): void {
    this.clearPlayback()
  }

  loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
        this.safeBottomVp = insets.bottomVp
      })
    } catch (_error) {
    }
  }

  topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

  safeBack(): void {
    try {
      router.back()
    } catch (_error) {
      this.noticeMessage = '返回上一页失败，请稍后重试。'
    }
  }

  safePush(url: string, params?: RouteParams): void {
    try {
      if (params) {
        router.pushUrl({ url, params })
      } else {
        router.pushUrl({ url })
      }
    } catch (_error) {
      this.noticeMessage = '页面跳转失败，请稍后重试。'
    }
  }

  async loadArenaSelection(): Promise<void> {
    const params = router.getParams() as RouteParams
    const selection = parseMeetingSelection(params)
    let profileIds = selection.profileIds
    let selectedAgentIds = selection.selectedAgentIds
    if (profileIds.length === 0 && params.profileId) {
      profileIds = [params.profileId]
      selectedAgentIds = parseRouteStringArray(params.selectedAgentIds)
    }
    this.profileIds = profileIds
    this.selectedAgentIds = selectedAgentIds
    this.isLoadingSelection = true
    this.noticeMessage = ''
    let loadedBundles: ProfileBundle[] = []
    for (let index = 0; index < profileIds.length; index++) {
      try {
        const bundle = await PersonaApi.getProfileBundle(profileIds[index])
        loadedBundles = [...loadedBundles, bundle]
      } catch (_error) {
        this.noticeMessage = '部分角色暂时无法加载，会议阵容已自动跳过。'
      }
    }
    this.bundles = loadedBundles
    this.profileIds = loadedBundles.map((bundle: ProfileBundle) => bundle.profile.id)
    if (params.debateTopic !== undefined && params.debateTopic.length > 0) {
      try {
        const decoded = decodeURIComponent(params.debateTopic)
        if (decoded.length > 0) {
          this.topic = decoded
        }
      } catch (_error) {
      }
    }
    if (this.selectedAgentIds.length === 0) {
      let nextIds: string[] = []
      loadedBundles.forEach((bundle: ProfileBundle) => {
        if (bundle.agents.length > 0) {
          nextIds = [...nextIds, bundle.agents[0].agentId]
        }
      })
      this.selectedAgentIds = nextIds
    }
    this.syncParticipants()
    this.isLoadingSelection = false
  }

  syncParticipants(): void {
    let nextParticipants: PersonaSpec[] = []
    this.selectedAgentIds.forEach((agentId: string) => {
      const agent = this.findAgentById(agentId)
      if (agent) {
        nextParticipants = [...nextParticipants, agent]
      }
    })
    this.participants = nextParticipants
  }

  findAgentById(agentId: string): PersonaSpec | null {
    for (let bundleIndex = 0; bundleIndex < this.bundles.length; bundleIndex++) {
      const bundle = this.bundles[bundleIndex]
      for (let agentIndex = 0; agentIndex < bundle.agents.length; agentIndex++) {
        const agent = bundle.agents[agentIndex]
        if (agent.agentId === agentId) {
          return agent
        }
      }
    }
    return null
  }

  findProfileName(personId: string): string {
    for (let index = 0; index < this.bundles.length; index++) {
      const bundle = this.bundles[index]
      if (bundle.profile.id === personId) {
        return bundle.profile.displayName
      }
    }
    return personId
  }

  clearPlayback(): void {
    if (this.playbackHandle >= 0) {
      clearTimeout(this.playbackHandle)
      this.playbackHandle = -1
    }
  }

  resetDebateOutput(): void {
    this.clearPlayback()
    this.messages = []
    this.summaryTitle = ''
    this.consensus = ''
    this.disagreements = []
    this.actionableAdvice = []
    this.narrativeHook = ''
    this.winnerDisplayName = ''
    this.verdictRationale = ''
    this.scorecards = []
    this.activeSpeakerAgentId = ''
    this.currentPhaseLabel = '待命'
  }

  canStart(): boolean {
    return this.participants.length >= 2 && !this.isGenerating && !this.isPlaying
  }

  sendChatMessage(): void {
    const text = this.chatInputText.trim()
    if (text.length === 0 || this.isGenerating) {
      return
    }
    this.messages = [...this.messages, {
      id: `user-${Date.now()}`,
      agentId: ARENA_USER_TOPIC_AGENT_ID,
      displayName: '我',
      stageLabel: '提问',
      content: text,
      stance: 'neutral',
      phase: 'manual',
      timestamp: new Date().toISOString()
    }]
    this.chatInputText = ''
  }

  openRosterPicker(): void {
    this.pickerNotice = ''
    this.showRosterSheet = true
    if (this.pickerPresets.length === 0) {
      void this.loadPickerPresets()
    }
  }

  closeRosterPicker(): void {
    this.showRosterSheet = false
    this.pickerExpandedProfileId = ''
    this.pickerExpandedBundle = null
    this.pickerLoadingProfileId = ''
    this.pickerNotice = ''
  }

  async loadPickerPresets(): Promise<void> {
    try {
      this.pickerPresets = await PersonaApi.getPresets()
    } catch (_error) {
      this.pickerNotice = '角色列表加载失败。'
    }
  }

  async expandPickerProfile(profile: PresetProfile): Promise<void> {
    this.pickerNotice = ''
    if (this.pickerExpandedProfileId === profile.id) {
      this.pickerExpandedProfileId = ''
      this.pickerExpandedBundle = null
      return
    }
    this.pickerExpandedProfileId = profile.id
    this.pickerExpandedBundle = null
    const cached = this.bundles.find((bundle: ProfileBundle) => bundle.profile.id === profile.id)
    if (cached) {
      this.pickerExpandedBundle = cached
      return
    }
    this.pickerLoadingProfileId = profile.id
    try {
      this.pickerExpandedBundle = await PersonaApi.getProfileBundle(profile.id)
    } catch (_error) {
      this.pickerNotice = '该角色暂时无法加载。'
      this.pickerExpandedProfileId = ''
    } finally {
      this.pickerLoadingProfileId = ''
    }
  }

  applyPickerAgent(bundle: ProfileBundle, agent: PersonaSpec): void {
    const hadProfile = this.bundles.some((item: ProfileBundle) => item.profile.id === bundle.profile.id)
    if (!hadProfile && this.bundles.length >= MAX_MEETING_PARTICIPANTS) {
      this.pickerNotice = `最多同时加入 ${MAX_MEETING_PARTICIPANTS} 位角色。`
      return
    }
    let nextBundles = hadProfile
      ? this.bundles.map((item: ProfileBundle) => item.profile.id === bundle.profile.id ? bundle : item)
      : [...this.bundles, bundle]
    let nextAgentIds = this.selectedAgentIds.filter((agentId: string) => {
      const current = this.findAgentById(agentId)
      return !current || current.personId !== agent.personId
    })
    this.bundles = nextBundles
    this.profileIds = nextBundles.map((item: ProfileBundle) => item.profile.id)
    this.selectedAgentIds = [...nextAgentIds, agent.agentId]
    this.syncParticipants()
    this.closeRosterPicker()
  }

  removeProfileFromMeeting(personId: string): void {
    this.bundles = this.bundles.filter((bundle: ProfileBundle) => bundle.profile.id !== personId)
    this.profileIds = this.bundles.map((bundle: ProfileBundle) => bundle.profile.id)
    this.selectedAgentIds = this.selectedAgentIds.filter((agentId: string) => this.findAgentById(agentId) !== null)
    this.syncParticipants()
  }

  async startDebate(): Promise<void> {
    if (this.participants.length < 2) {
      this.noticeMessage = '请先补齐至少 2 位角色，并为每位角色锁定发言人格。'
      return
    }
    this.noticeMessage = ''
    this.isGenerating = true
    this.resetDebateOutput()
    const normalizedTopic = this.topic.trim().length > 0 ? this.topic.trim() : DEFAULT_TOPIC
    this.topic = normalizedTopic
    try {
      const result = await PersonaApi.runArena(normalizedTopic, this.participants, 'debate')
      this.participants = result.participants
      this.selectedAgentIds = result.participants.map((agent: PersonaSpec) => agent.agentId)
      this.playMessages(result.messages, result.summary)
    } catch (_error) {
      this.noticeMessage = '会议生成失败，请稍后再试。'
      this.isGenerating = false
    }
  }

  playMessages(messages: ArenaMessage[], summary: ArenaSummary): void {
    this.isGenerating = false
    this.isPlaying = true
    this.currentPhaseLabel = '开场陈述'
    this.playNextMessage(messages, summary, 0)
  }

  playNextMessage(messages: ArenaMessage[], summary: ArenaSummary, index: number): void {
    if (index >= messages.length) {
      this.isPlaying = false
      this.activeSpeakerAgentId = ''
      this.applySummary(summary)
      this.currentPhaseLabel = '会议完成'
      return
    }
    const nextMessage = messages[index]
    this.messages = [...this.messages, nextMessage]
    this.activeSpeakerAgentId = nextMessage.agentId
    this.currentPhaseLabel = this.phaseLabel(nextMessage.phase, index)
    const delay = 520 + Math.min(nextMessage.content.length * 9, 850)
    this.playbackHandle = setTimeout(() => this.playNextMessage(messages, summary, index + 1), delay) as number
  }

  applySummary(summary: ArenaSummary): void {
    this.summaryTitle = summary.title
    this.consensus = summary.consensus
    this.disagreements = summary.disagreements
    this.actionableAdvice = summary.actionableAdvice
    this.narrativeHook = summary.narrativeHook
    if (summary.debateVerdict) {
      this.winnerDisplayName = summary.debateVerdict.winnerDisplayName ? summary.debateVerdict.winnerDisplayName : ''
      this.verdictRationale = summary.debateVerdict.rationale
      this.scorecards = summary.debateVerdict.scorecards
    } else {
      this.winnerDisplayName = ''
      this.verdictRationale = ''
      this.scorecards = []
    }
  }

  phaseLabel(phase?: string, index?: number): string {
    const textMap: Record<string, string> = { 'opening': '开场陈述', 'reflection': '互相理解', 'rebuttal': '正面交锋', 'synthesis': '综合回应', 'closing': '收束陈词', 'manual': '手动提问' }
    if (phase && textMap[phase]) { return textMap[phase] }
    if (index !== undefined && index < this.participants.length) { return '开场陈述' }
    return '收束陈词'
  }

  stanceColor(stance: string): string {
    const colors: Record<string, string> = { 'support': MintColors.stance.support, 'oppose': MintColors.stance.oppose, 'reflective': MintColors.stance.reflective, 'neutral': MintColors.textMuted }
    return colors[stance] || MintColors.textMuted
  }

  participantIndex(agentId: string): number {
    for (let index = 0; index < this.participants.length; index++) {
      if (this.participants[index].agentId === agentId) { return index }
    }
    return 0
  }

  isRightAligned(agentId: string): boolean {
    return this.participantIndex(agentId) % 2 === 1
  }

  arenaStatusTitle(): string {
    if (this.isLoadingSelection) { return '正在布置会议现场' }
    if (this.isGenerating) { return '角色正在组织观点' }
    if (this.isPlaying) { return this.currentPhaseLabel }
    if (this.messages.length > 0) { return '会议已完成' }
    return '阵容待命'
  }

  messageProfileName(agentId: string, fallback: string): string {
    const agent = this.findAgentById(agentId)
    return agent ? this.findProfileName(agent.personId) : fallback
  }

  formatMessageTime(iso: string | undefined): string {
    if (iso === undefined || iso.length < 16) { return '' }
    const pivot = iso.indexOf('T')
    return pivot >= 0 ? iso.substring(pivot + 1, pivot + 6) : ''
  }

  hasSummary(): boolean {
    return this.summaryTitle.length > 0
      || this.consensus.length > 0
      || this.disagreements.length > 0
      || this.actionableAdvice.length > 0
      || this.narrativeHook.length > 0
  }

  @Builder
  pill(label: string, color: string, bg: string, border: string) {
    Text(label).fontSize(Typography.size.xs).fontColor(color).padding({ left: Spacing.sm, right: Spacing.sm, top: 5, bottom: 5 }).backgroundColor(bg).borderRadius(BorderRadius.pill).border({ width: 0.5, color: border, radius: BorderRadius.pill })
  }

  @Builder
  topBar() {
    Row({ space: Spacing.md }) {
      Button() { Text('<').fontSize(20).fontColor(MintColors.mintDark) }.width(40).height(40).backgroundColor('rgba(255, 255, 255, 0.92)').borderRadius(20).border({ width: 0.5, color: MintColors.border, radius: 20 }).onClick(() => this.safeBack())
      Column({ space: 4 }) {
        Text('会议现场').fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
        Text(this.arenaStatusTitle()).fontSize(Typography.size.xs).fontColor(MintColors.textSecondary)
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Text(`${this.participants.length} 人`)
        .fontSize(Typography.size.caption)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.participants.length >= 2 ? MintColors.mintDark : MintColors.textPrimary)
        .padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm })
        .backgroundColor('rgba(255, 255, 255, 0.78)')
        .borderRadius(BorderRadius.xxl)
        .border({ width: 0.5, color: MintColors.borderLight, radius: BorderRadius.xxl })
    }.width('100%')
  }

  @Builder
  hero() {
    Column({ space: Spacing.sm }) {
      Row({ space: Spacing.sm }) {
        this.pill(this.isGenerating ? '生成中' : this.isPlaying ? this.currentPhaseLabel : this.messages.length > 0 ? '继续讨论' : '待开始', MintColors.mintDark, MintColors.mintBg, MintColors.mint)
        this.pill(`消息 ${this.messages.length}`, MintColors.lavenderDark, MintColors.lavenderPale, MintColors.lavender)
        if (this.activeSpeakerAgentId.length > 0) {
          this.pill(`当前 ${this.messageProfileName(this.activeSpeakerAgentId, '发言')}`, '#B88632', 'rgba(232, 184, 109, 0.14)', 'rgba(232, 184, 109, 0.24)')
        }
      }.width('100%')
      TextArea({ text: this.topic, placeholder: '输入会议议题，角色会围绕这句话展开讨论。' })
        .width('100%')
        .height(72)
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textPrimary)
        .placeholderColor(MintColors.textPlaceholder)
        .backgroundColor(MintColors.backgroundSecondary)
        .borderRadius(BorderRadius.xxl)
        .padding(Spacing.md)
        .enabled(!this.isGenerating && !this.isPlaying)
        .onChange((value: string) => { this.topic = value })
      if (this.participants.length > 0) {
        Scroll() {
          Row({ space: Spacing.sm }) {
            ForEach(this.participants, (participant: PersonaSpec) => {
              Row({ space: 8 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Column()
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .backgroundColor(this.activeSpeakerAgentId === participant.agentId ? MintColors.mint : 'rgba(255, 255, 255, 0.90)')
                    .border({ width: 0.5, color: this.activeSpeakerAgentId === participant.agentId ? MintColors.mint : MintColors.borderLight, radius: 14 })
                  Text(this.findProfileName(participant.personId).charAt(0))
                    .fontSize(Typography.size.xs)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.activeSpeakerAgentId === participant.agentId ? '#FFFFFF' : MintColors.textPrimary)
                }
                Column({ space: 2 }) {
                  Text(this.findProfileName(participant.personId))
                    .fontSize(Typography.size.xs)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(MintColors.textPrimary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(participant.stageLabel)
                    .fontSize(10)
                    .fontColor(MintColors.textMuted)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }.alignItems(HorizontalAlign.Start)
              }
                .padding({ left: Spacing.sm, right: Spacing.sm, top: 9, bottom: 9 })
                .backgroundColor('rgba(255, 255, 255, 0.78)')
                .borderRadius(BorderRadius.xxl)
                .border({ width: 0.5, color: MintColors.borderLight, radius: BorderRadius.xxl })
            }, (participant: PersonaSpec) => participant.agentId)
          }.width('100%')
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      } else {
        Text('先加入至少 2 位角色，聊天框里才会开始碰撞观点。')
          .width('100%')
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textSecondary)
      }
      Row({ space: Spacing.sm }) {
        Button('角色').height(40).padding({ left: Spacing.md, right: Spacing.md }).fontSize(Typography.size.caption).fontColor(MintColors.mintDark).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl }).onClick(() => this.openRosterPicker())
        Button('提问台').height(40).padding({ left: Spacing.md, right: Spacing.md }).fontSize(Typography.size.caption).fontColor(MintColors.mintDark).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl }).onClick(() => this.safePush('pages/FusionWorkbench'))
        Button(this.canStart() ? '开始会议' : '至少 2 人开始').layoutWeight(1).height(40).fontSize(Typography.size.caption).fontColor('#FFFFFF').backgroundColor(this.canStart() ? MintColors.mint : MintColors.textMuted).borderRadius(BorderRadius.xxl).enabled(this.canStart()).onClick(() => { void this.startDebate() })
      }.width('100%')
      if (this.noticeMessage.length > 0) {
        Text(this.noticeMessage).width('100%').fontSize(Typography.size.caption).fontColor(MintColors.error).padding(Spacing.md).backgroundColor('rgba(224, 120, 128, 0.08)').borderRadius(BorderRadius.lg)
      }
    }.width('100%').alignItems(HorizontalAlign.Start).padding(Spacing.lg).backgroundColor('rgba(255, 255, 255, 0.80)').borderRadius(BorderRadius.xxl3).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl3 })
  }

  @Builder
  conversation() {
    Column({ space: Spacing.md }) {
      Row() {
        Column({ space: 4 }) {
          Text('聊天框').fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
          Text(this.messages.length > 0 ? '角色发言、你的追问和会议结论都集中在这里。' : '从这里开始，让会议像聊天一样自然展开。').fontSize(Typography.size.xs).fontColor(MintColors.textSecondary)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        if (this.hasSummary()) {
          this.pill('已生成结论', MintColors.mintDark, MintColors.mintBg, MintColors.mint)
        }
      }.width('100%')
      Scroll() {
        Column({ space: Spacing.md }) {
          if (this.messages.length === 0 && !this.isGenerating) {
            Column({ space: Spacing.sm }) {
              Text('聊天还没开始').fontSize(Typography.size.body).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
              Text('先确认议题和角色，再点击“开始会议”。后面的补充追问也都会留在这里。').fontSize(Typography.size.caption).fontColor(MintColors.textSecondary).lineHeight(18).textAlign(TextAlign.Center)
            }
              .width('100%')
              .padding({ left: Spacing.lg, right: Spacing.lg, top: 44, bottom: 44 })
              .backgroundColor('rgba(78, 205, 196, 0.05)')
              .borderRadius(BorderRadius.xxl)
              .alignItems(HorizontalAlign.Center)
          }
          ForEach(this.messages, (message: ArenaMessage, index: number) => {
            if (message.agentId === ARENA_USER_TOPIC_AGENT_ID) {
              Row() {
                Blank().layoutWeight(1)
                Column({ space: 6 }) {
                  Text('我').fontSize(Typography.size.xs).fontColor(MintColors.mintDark).width('100%').textAlign(TextAlign.End)
                  Column({ space: 6 }) {
                    Text(message.content).fontSize(Typography.size.body).fontColor(MintColors.textPrimary).lineHeight(Typography.lineHeight.relaxed)
                    Text(this.formatMessageTime(message.timestamp)).fontSize(10).fontColor(MintColors.textMuted).width('100%').textAlign(TextAlign.End)
                  }.padding(Spacing.md).backgroundColor('rgba(78, 205, 196, 0.16)').borderRadius({ topLeft: 18, topRight: 8, bottomRight: 18, bottomLeft: 18 })
                }.constraintSize({ maxWidth: '84%' }).alignItems(HorizontalAlign.End)
              }.width('100%')
            } else {
              Row({ space: Spacing.sm }) {
                Stack({ alignContent: Alignment.Center }) {
                  Column()
                    .width(32)
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor(this.activeSpeakerAgentId === message.agentId ? MintColors.mint : 'rgba(255, 255, 255, 0.92)')
                    .border({ width: 0.5, color: this.activeSpeakerAgentId === message.agentId ? MintColors.mint : MintColors.borderLight, radius: 16 })
                  Text(this.messageProfileName(message.agentId, message.displayName).charAt(0))
                    .fontSize(Typography.size.xs)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.activeSpeakerAgentId === message.agentId ? '#FFFFFF' : MintColors.textPrimary)
                }.margin({ top: 18 })
                Column({ space: 6 }) {
                  Text(`${this.messageProfileName(message.agentId, message.displayName)} · ${this.phaseLabel(message.phase, index)}`).fontSize(Typography.size.xs).fontColor(this.stanceColor(message.stance))
                  Column({ space: 6 }) {
                    Text(message.content).fontSize(Typography.size.body).fontColor(MintColors.textPrimary).lineHeight(Typography.lineHeight.relaxed)
                    Text(this.formatMessageTime(message.timestamp)).fontSize(10).fontColor(MintColors.textMuted)
                  }
                    .constraintSize({ maxWidth: '100%' })
                    .padding(Spacing.md)
                    .backgroundColor(this.isRightAligned(message.agentId) ? 'rgba(78, 205, 196, 0.16)' : '#FFFFFF')
                    .borderRadius(this.isRightAligned(message.agentId)
                      ? { topLeft: 18, topRight: 6, bottomRight: 18, bottomLeft: 18 }
                      : { topLeft: 6, topRight: 18, bottomRight: 18, bottomLeft: 18 })
                    .border({ width: this.activeSpeakerAgentId === message.agentId ? 1.2 : 0.5, color: this.activeSpeakerAgentId === message.agentId ? MintColors.mint : MintColors.borderLight, radius: BorderRadius.xl })
                }.constraintSize({ maxWidth: '78%' }).alignItems(HorizontalAlign.Start)
                Blank().layoutWeight(1)
              }.width('100%')
            }
          }, (message: ArenaMessage) => message.id)
          if (this.isGenerating) {
            Row({ space: Spacing.sm }) {
              LoadingProgress().width(20).height(20)
              Text('角色正在围绕议题组织观点，请稍候...').fontSize(Typography.size.caption).fontColor(MintColors.textMuted)
            }.padding(Spacing.md).backgroundColor('rgba(255, 255, 255, 0.90)').borderRadius(BorderRadius.xxl)
          }
          this.summary()
        }.width('100%')
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }.width('100%').height('100%').alignItems(HorizontalAlign.Start).padding(Spacing.lg).backgroundColor('rgba(255, 255, 255, 0.78)').borderRadius(BorderRadius.xxl3).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl3 })
  }

  @Builder
  summary() {
    if (this.hasSummary()) {
      Column({ space: Spacing.md }) {
        Row({ space: Spacing.sm }) {
          this.pill('会议结论', MintColors.mintDark, MintColors.mintBg, MintColors.mint)
          if (this.winnerDisplayName.length > 0) {
            this.pill(`当前领先：${this.winnerDisplayName}`, MintColors.lavenderDark, MintColors.lavenderPale, MintColors.lavender)
          }
        }
        Text(this.summaryTitle.length > 0 ? this.summaryTitle : '会议已收束').fontSize(Typography.size.body).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
        if (this.consensus.length > 0) { Text(this.consensus).fontSize(Typography.size.caption).fontColor(MintColors.textSecondary).lineHeight(18) }
        if (this.verdictRationale.length > 0) { Text(this.verdictRationale).fontSize(Typography.size.caption).fontColor(MintColors.textSecondary).lineHeight(18) }
        ForEach(this.disagreements, (item: string) => { Text(`• ${item}`).fontSize(Typography.size.caption).fontColor(MintColors.textPrimary).lineHeight(18) }, (item: string) => item)
        ForEach(this.actionableAdvice, (item: string) => { Text(`• ${item}`).fontSize(Typography.size.caption).fontColor('#B88632').lineHeight(18) }, (item: string) => item)
        if (this.narrativeHook.length > 0) { Text(this.narrativeHook).fontSize(Typography.size.caption).fontColor(MintColors.textSecondary).lineHeight(18).padding(Spacing.md).backgroundColor('rgba(255, 255, 255, 0.72)').borderRadius(BorderRadius.xxl) }
      }.width('100%').alignItems(HorizontalAlign.Start).padding(Spacing.lg).backgroundColor('rgba(78, 205, 196, 0.08)').borderRadius(BorderRadius.xxl).border({ width: 0.5, color: MintColors.borderLight, radius: BorderRadius.xxl })
    }
  }

  @Builder
  inputDock() {
    Column({ space: 8 }) {
      Text(this.messages.length > 0 ? '继续追问、纠偏或换话题' : '也可以先发一句话，稍后继续推进会议').fontSize(Typography.size.xs).fontColor(MintColors.mintDark)
      Row({ space: Spacing.sm }) {
        TextArea({ text: this.chatInputText, placeholder: '输入你的追问或补充，这里会作为主聊天框保留全部上下文。' }).layoutWeight(1).height(54).fontSize(Typography.size.body).fontColor(MintColors.textPrimary).placeholderColor(MintColors.textPlaceholder).backgroundColor(MintColors.backgroundSecondary).borderRadius(BorderRadius.xxl).padding(Spacing.md).enabled(!this.isGenerating).onChange((value: string) => { this.chatInputText = value }).onSubmit((enterKey: EnterKeyType) => { if (enterKey === EnterKeyType.Send) { this.sendChatMessage() } })
        Button('发送').height(54).padding({ left: Spacing.lg, right: Spacing.lg }).fontSize(Typography.size.body).fontColor('#FFFFFF').backgroundColor(MintColors.mint).borderRadius(BorderRadius.xxl).enabled(this.chatInputText.trim().length > 0 && !this.isGenerating).onClick(() => this.sendChatMessage())
      }.width('100%')
    }.width('100%').padding(Spacing.md).backgroundColor('rgba(255, 255, 255, 0.92)').borderRadius(BorderRadius.xxl).border({ width: 1, color: MintColors.borderLight, radius: BorderRadius.xxl })
  }

  @Builder
  buildRosterOverlay() {
    Column() {
      Column().width('100%').layoutWeight(1).backgroundColor('rgba(0, 0, 0, 0.48)').onClick(() => this.closeRosterPicker())
      Column({ space: Spacing.md }) {
        Row() {
          Text('选择角色与发言人格').fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Bold).fontColor(MintColors.textPrimary).layoutWeight(1)
          Button('关闭').height(36).fontSize(Typography.size.caption).fontColor(MintColors.mintDark).backgroundColor(MintColors.mintBg).borderRadius(BorderRadius.xxl).onClick(() => this.closeRosterPicker())
        }.width('100%')
        if (this.pickerNotice.length > 0) { Text(this.pickerNotice).fontSize(Typography.size.caption).fontColor(MintColors.error).width('100%') }
        Scroll() {
          Column({ space: Spacing.sm }) {
            ForEach(this.bundles, (bundle: ProfileBundle) => {
              Row({ space: Spacing.sm }) {
                Text(bundle.profile.displayName).layoutWeight(1).fontSize(Typography.size.body).fontColor(MintColors.textPrimary)
                Button('移除').height(32).fontSize(Typography.size.xs).fontColor(MintColors.error).backgroundColor('rgba(224, 120, 128, 0.10)').borderRadius(BorderRadius.lg).onClick(() => this.removeProfileFromMeeting(bundle.profile.id))
              }.width('100%').padding(Spacing.sm).backgroundColor('rgba(255, 255, 255, 0.78)').borderRadius(BorderRadius.lg)
            }, (bundle: ProfileBundle) => bundle.profile.id)
            ForEach(this.pickerPresets, (profile: PresetProfile) => {
              Column({ space: Spacing.xs }) {
                Row({ space: Spacing.sm }) {
                  Stack({ alignContent: Alignment.Center }) {
                    Column().width(40).height(40).borderRadius(20).backgroundColor(MintColors.mint)
                    Text(profile.displayName.length > 0 ? profile.displayName.charAt(0) : '?').fontSize(Typography.size.body).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  }
                  Column({ space: 4 }) {
                    Text(profile.displayName).fontSize(Typography.size.body).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
                    Text(profile.subtitle).fontSize(Typography.size.xs).fontColor(MintColors.textSecondary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  if (this.pickerLoadingProfileId === profile.id) {
                    LoadingProgress().width(24).height(24)
                  } else {
                    Text(this.pickerExpandedProfileId === profile.id ? '收起' : '展开').fontSize(Typography.size.xs).fontColor(MintColors.mintDark)
                  }
                }.width('100%').padding(Spacing.sm).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.lg).onClick(() => { void this.expandPickerProfile(profile) })
                if (this.pickerExpandedProfileId === profile.id && this.pickerExpandedBundle) {
                  Column({ space: Spacing.xs }) {
                    ForEach(this.pickerExpandedBundle.agents, (agent: PersonaSpec) => {
                      Row({ space: Spacing.sm }) {
                        Column({ space: 4 }) {
                          Text(agent.stageLabel).fontSize(Typography.size.body).fontColor(MintColors.textPrimary)
                          Text(agent.knowledgeBoundary.length > 36 ? `${agent.knowledgeBoundary.substring(0, 36)}...` : agent.knowledgeBoundary).fontSize(Typography.size.xs).fontColor(MintColors.textMuted).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                        Button('上场').height(32).fontSize(Typography.size.xs).fontColor('#FFFFFF').backgroundColor(MintColors.mint).borderRadius(BorderRadius.lg).onClick(() => { if (this.pickerExpandedBundle) { this.applyPickerAgent(this.pickerExpandedBundle, agent) } })
                      }.width('100%').padding(Spacing.sm).backgroundColor('rgba(78, 205, 196, 0.06)').borderRadius(BorderRadius.lg)
                    }, (agent: PersonaSpec) => agent.agentId)
                  }.width('100%').padding({ left: Spacing.lg, right: Spacing.sm, bottom: Spacing.sm })
                }
              }.width('100%')
            }, (profile: PresetProfile) => profile.id)
          }
        }.width('100%').constraintSize({ maxHeight: 420 }).scrollBar(BarState.Auto)
      }.width('100%').padding(Spacing.lg).backgroundColor(MintColors.cardPrimary).borderRadius({ topLeft: BorderRadius.xxl3, topRight: BorderRadius.xxl3, bottomRight: 0, bottomLeft: 0 })
    }.width('100%').height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Column().width('100%').height('100%').backgroundColor(MintColors.background)
        Column().width(320).height(220).borderRadius(160).backgroundColor('rgba(78, 205, 196, 0.10)').blur(100).position({ x: -120, y: -50 })
        Column().width(280).height(200).borderRadius(140).backgroundColor('rgba(184, 169, 217, 0.10)').blur(80).position({ right: -80, y: 80 })
      }.width('100%').height('100%')
      if (!this.showRosterSheet) {
        Column({ space: Spacing.sm }) {
          this.topBar()
          this.hero()
          Column() {
            this.conversation()
          }.width('100%').layoutWeight(1)
          this.inputDock()
        }.width('100%').height('100%').padding({ left: Spacing.page.horizontal, right: Spacing.page.horizontal, top: this.topInsetVp() + 12, bottom: this.safeBottomVp + Spacing.sm })
      }
      if (this.showRosterSheet) { this.buildRosterOverlay() }
    }.width('100%').height('100%').backgroundColor(MintColors.background)
  }
}
