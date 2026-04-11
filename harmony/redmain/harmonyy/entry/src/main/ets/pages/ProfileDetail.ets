import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { PresetProfile, ProfileBundle, RouteParams, TimelineNode, EMPTY_PROFILE } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
import { buildMeetingRouteParams, MAX_MEETING_PARTICIPANTS, mergeUniqueStrings, parseMeetingSelection } from '../common/MeetingSelection'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'

const FALLBACK_SAFE_TOP_VP: number = 52

@Entry
@Component
struct ProfileDetail {
  @State profile: PresetProfile = EMPTY_PROFILE
  @State nodes: TimelineNode[] = []
  @State focusedNodeId: string = ''
  @State meetingProfileIds: string[] = []
  @State meetingAgentIds: string[] = []
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0
  @State isLoading: boolean = false
  @State noticeMessage: string = ''
  @State errorMessage: string = ''

  aboutToAppear(): void {
    this.loadSafeInsets()
    const params = router.getParams() as RouteParams
    const selection = parseMeetingSelection(params)
    this.meetingProfileIds = selection.profileIds
    this.meetingAgentIds = selection.selectedAgentIds
    const profileId = params.profileId ? params.profileId : 'graduate'
    void this.loadProfile(profileId)
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

  topInsetVp(): number { return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP }

  async loadProfile(profileId: string): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    try {
      const bundle = await PersonaApi.getProfileBundle(profileId)
      this.profile = bundle.profile
      this.nodes = bundle.nodes
      this.focusedNodeId = bundle.nodes.length > 0 ? bundle.nodes[0].nodeId : ''
    } catch (_error) {
      this.errorMessage = '角色详情加载失败，请稍后重试。'
    } finally {
      this.isLoading = false
    }
  }

  isFocused(nodeId: string): boolean { return this.focusedNodeId === nodeId }
  isInMeeting(): boolean { return this.meetingProfileIds.includes(this.profile.id) }
  safeBack(): void {
    try { router.back() } catch (_error) { this.errorMessage = '返回上一页失败，请稍后重试。' }
  }
  safePush(url: string, params?: RouteParams): void {
    try {
      if (params) { router.pushUrl({ url, params }) } else { router.pushUrl({ url }) }
    } catch (_error) {
      this.errorMessage = '页面跳转失败，请稍后重试。'
    }
  }
  goExploreMore(): void {
    this.safePush('pages/ExplorePersonas', buildMeetingRouteParams({ profileIds: this.meetingProfileIds, selectedAgentIds: this.meetingAgentIds }))
  }
  goMeetingComposer(): void {
    const mergedProfileIds = mergeUniqueStrings(this.meetingProfileIds, [this.profile.id])
    if (mergedProfileIds.length > MAX_MEETING_PARTICIPANTS) {
      this.noticeMessage = `会议最多邀请 ${MAX_MEETING_PARTICIPANTS} 位角色，请先回去替换现有阵容。`
      return
    }
    this.safePush('pages/MeetingComposer', buildMeetingRouteParams({ profileIds: mergedProfileIds, selectedAgentIds: this.meetingAgentIds }))
  }
  getStageColor(stageType: string): string {
    const colors: Record<string, string> = { 'early': MintColors.stage.early, 'turning-point': MintColors.stage.turningPoint, 'stable': MintColors.mintDark, 'crisis': MintColors.stage.crisis, 'rebuild': MintColors.stage.rebuild, 'peak': MintColors.stage.peak }
    return colors[stageType] || MintColors.stage.default
  }
  stageHint(node: TimelineNode): string {
    const parts: string[] = []
    if (node.timeLabel.length > 0) { parts.push(node.timeLabel) }
    if (node.ageLabel && node.ageLabel.length > 0) { parts.push(node.ageLabel) }
    return parts.join(' / ')
  }

  @Builder
  heroPanel() {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.md }) {
        Button() { Text('<').fontSize(20).fontColor(MintColors.mintDark) }.width(40).height(40).backgroundColor('rgba(255, 255, 255, 0.92)').borderRadius(20).border({ width: 0.5, color: MintColors.border, radius: 20 }).onClick(() => this.safeBack())
        Column({ space: 4 }) {
          Text('角色详情').fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
          Text(this.isInMeeting() ? '当前角色已在会议阵容中' : '可以加入会议继续编排').fontSize(Typography.size.xs).fontColor(MintColors.textSecondary)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%')
      Text(this.profile.displayName).fontSize(Typography.size.hero).fontWeight(FontWeight.Bold).fontColor(MintColors.textPrimary)
      Text(this.profile.subtitle).fontSize(Typography.size.bodyLg).fontColor(MintColors.mintDark)
      Text(this.profile.biography).fontSize(Typography.size.body).fontColor(MintColors.textSecondary).lineHeight(Typography.lineHeight.relaxed)
      if (this.profile.highlights.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.profile.highlights.slice(0, 4), (item: string) => {
            Text(item).fontSize(Typography.size.xs).fontColor(MintColors.textSecondary).padding({ left: Spacing.sm, right: Spacing.sm, top: 4, bottom: 4 }).backgroundColor('rgba(255, 255, 255, 0.76)').borderRadius(BorderRadius.chip).margin({ right: Spacing.xs, bottom: Spacing.xs })
          }, (item: string) => item)
        }.width('100%')
      }
      Row({ space: Spacing.sm }) {
        Column({ space: 4 }) {
          Text(`${this.meetingProfileIds.length}${this.isInMeeting() ? ' + 当前角色' : ''}`).fontSize(Typography.size.xl).fontWeight(FontWeight.Bold).fontColor(MintColors.mint)
          Text('会议筹备中的角色数').fontSize(Typography.size.xs).fontColor(MintColors.textMuted)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Column({ space: Spacing.sm }) {
          Button(this.isInMeeting() ? '查看会议编排' : '加入会议编排').height(42).fontSize(Typography.size.body).fontColor('#FFFFFF').backgroundColor(MintColors.mint).borderRadius(BorderRadius.xxl).onClick(() => this.goMeetingComposer())
          Button('继续新增角色').height(38).fontSize(Typography.size.caption).fontColor(MintColors.mintDark).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl }).onClick(() => this.goExploreMore())
        }.alignItems(HorizontalAlign.End)
      }.width('100%')
      if (this.noticeMessage.length > 0) { Text(this.noticeMessage).width('100%').fontSize(Typography.size.caption).fontColor(MintColors.error).padding(Spacing.md).backgroundColor('rgba(224, 120, 128, 0.08)').borderRadius(BorderRadius.lg) }
    }.width('100%').alignItems(HorizontalAlign.Start).padding(Spacing.lg).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl3).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl3 })
  }

  @Builder
  timelineNode(node: TimelineNode, index: number) {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.md }) {
        Stack({ alignContent: Alignment.Center }) {
          Column().width(30).height(30).borderRadius(15).backgroundColor(this.getStageColor(node.stageType))
          Text(`${index + 1}`).fontSize(Typography.size.sm).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        }
        Column({ space: 4 }) {
          Row({ space: Spacing.xs }) {
            Text(node.stageLabel).fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
            if (this.stageHint(node).length > 0) {
              Text(this.stageHint(node)).fontSize(Typography.size.xs).fontColor(MintColors.textMuted).padding({ left: Spacing.sm, right: Spacing.sm, top: 3, bottom: 3 }).backgroundColor(MintColors.surfaceGlass).borderRadius(BorderRadius.pill)
            }
          }
          Text(node.keyEvent).fontSize(Typography.size.body).fontColor(MintColors.mintDark).lineHeight(Typography.lineHeight.relaxed)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text(this.isFocused(node.nodeId) ? '收起' : '展开').fontSize(Typography.size.xs).fontColor(MintColors.textMuted)
      }.width('100%').alignItems(VerticalAlign.Top)
      Text(node.summary).fontSize(Typography.size.body).fontColor(MintColors.textSecondary).lineHeight(Typography.lineHeight.relaxed)
      if (this.isFocused(node.nodeId)) {
        if (node.traits.length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(node.traits, (trait: string) => {
              Text(trait).fontSize(Typography.size.xs).fontColor(MintColors.mintDark).padding({ left: Spacing.sm, right: Spacing.sm, top: 4, bottom: 4 }).backgroundColor(MintColors.mintBg).borderRadius(BorderRadius.chip).margin({ right: Spacing.xs, bottom: Spacing.xs })
            }, (trait: string) => trait)
          }.width('100%')
        }
        if (node.values.length > 0) { Text(`此时最看重：${node.values.join(' / ')}`).fontSize(Typography.size.caption).fontColor(MintColors.textSecondary) }
        if (node.tensions.length > 0) { Text(`内在拉扯：${node.tensions.join(' / ')}`).fontSize(Typography.size.caption).fontColor(MintColors.textMuted).lineHeight(Typography.lineHeight.relaxed) }
        if (node.sourceEvidence.length > 0) { Text(`“${node.sourceEvidence[0].quote}”`).fontSize(Typography.size.body).fontColor(MintColors.lavenderDark).lineHeight(Typography.lineHeight.relaxed).fontStyle(FontStyle.Italic).padding(Spacing.md).backgroundColor(MintColors.lavenderPale).borderRadius(BorderRadius.lg) }
        Text('加入会议后，你可以在下一页把这个关键阶段对应的人格设为发言者。').fontSize(Typography.size.caption).fontColor(MintColors.textMuted).lineHeight(Typography.lineHeight.relaxed)
      }
    }.width('100%').alignItems(HorizontalAlign.Start).padding(Spacing.lg).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl3).border({ width: this.isFocused(node.nodeId) ? 1 : 0.5, color: this.isFocused(node.nodeId) ? this.getStageColor(node.stageType) : MintColors.border, radius: BorderRadius.xxl3 }).onClick(() => { this.focusedNodeId = this.isFocused(node.nodeId) ? '' : node.nodeId })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Column().width('100%').height('100%').backgroundColor(MintColors.background)
        Column().width(300).height(200).borderRadius(150).backgroundColor('rgba(78, 205, 196, 0.07)').blur(90).position({ x: -100, y: -60 })
        Column().width(260).height(170).borderRadius(130).backgroundColor('rgba(184, 169, 217, 0.08)').blur(70).position({ right: -80, y: -30 })
      }.width('100%').height('100%')
      Scroll() {
        Column({ space: Spacing.lg }) {
          this.heroPanel()
          if (this.errorMessage.length > 0) { Text(this.errorMessage).width('100%').fontSize(Typography.size.caption).fontColor(MintColors.error).padding(Spacing.md).backgroundColor('rgba(224, 120, 128, 0.08)').borderRadius(BorderRadius.lg) }
          if (this.isLoading) {
            Text('正在整理这个角色的完整人生轨迹...').fontSize(Typography.size.body).fontColor(MintColors.textMuted).padding(Spacing.xl)
          } else {
            Column({ space: Spacing.sm }) {
              Text('完整人生轨迹').fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
              Text('这些阶段节点会在会议编排页继续展开，帮助你挑出最适合上桌发言的人格版本。').fontSize(Typography.size.caption).fontColor(MintColors.textMuted).lineHeight(Typography.lineHeight.relaxed)
            }.width('100%').alignItems(HorizontalAlign.Start)
            ForEach(this.nodes, (node: TimelineNode, index: number) => { this.timelineNode(node, index) }, (node: TimelineNode) => node.nodeId)
          }
        }.padding({ left: Spacing.page.horizontal, right: Spacing.page.horizontal, top: this.topInsetVp() + 12, bottom: this.safeBottomVp + Spacing.xl })
      }.width('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }.width('100%').height('100%').backgroundColor(MintColors.background)
  }
}
