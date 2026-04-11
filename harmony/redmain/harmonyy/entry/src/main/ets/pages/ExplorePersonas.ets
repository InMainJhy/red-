import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PresetProfile, RouteParams } from '../common/Models'
import { buildMeetingRouteParams, MAX_MEETING_PARTICIPANTS, parseMeetingSelection } from '../common/MeetingSelection'
import { PersonaApi } from '../service/PersonaApi'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'

const FALLBACK_SAFE_TOP_VP: number = 52

type ExploreFilter = 'all' | 'self' | 'celebrity' | 'history' | 'fictional'
interface FilterOption { id: ExploreFilter; label: string }
const FILTERS: FilterOption[] = [
  { id: 'all', label: '全部' },
  { id: 'self', label: '自我' },
  { id: 'celebrity', label: '名人' },
  { id: 'history', label: '历史' },
  { id: 'fictional', label: '虚构' }
]

@Entry
@Component
struct ExplorePersonas {
  @State profiles: PresetProfile[] = []
  @State searchText: string = ''
  @State activeFilter: ExploreFilter = 'all'
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State meetingProfileIds: string[] = []
  @State meetingAgentIds: string[] = []
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0

  aboutToAppear(): void {
    this.loadSafeInsets()
    const params = router.getParams() as RouteParams
    const selection = parseMeetingSelection(params)
    this.meetingProfileIds = selection.profileIds
    this.meetingAgentIds = selection.selectedAgentIds
    void this.loadProfiles()
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

  async loadProfiles(): Promise<void> {
    this.isLoading = true
    this.errorMessage = ''
    try {
      this.profiles = await PersonaApi.getPresets()
    } catch (_error) {
      this.errorMessage = '角色库加载失败，请稍后重试。'
    } finally {
      this.isLoading = false
    }
  }

  filteredProfiles(): PresetProfile[] {
    const keyword = this.searchText.trim().toLowerCase()
    return this.profiles.filter((profile: PresetProfile) => {
      if (this.activeFilter !== 'all' && profile.category !== this.activeFilter) { return false }
      if (keyword.length === 0) { return true }
      const haystack = [profile.displayName, profile.subtitle, profile.biography, ...profile.highlights, ...profile.suggestedTopics].join(' ').toLowerCase()
      return haystack.includes(keyword)
    })
  }

  isInMeeting(profileId: string): boolean { return this.meetingProfileIds.includes(profileId) }
  categoryBadge(profile: PresetProfile): string {
    const labels: Record<string, string> = { 'self': '自我', 'celebrity': '名人', 'history': '历史', 'fictional': '虚构' }
    return labels[profile.category] || profile.category
  }
  initial(profile: PresetProfile): string { return profile.displayName.length > 0 ? profile.displayName.charAt(0) : '?' }
  profileById(profileId: string): PresetProfile | null {
    const profile = this.profiles.find((item: PresetProfile) => item.id === profileId)
    return profile ? profile : null
  }
  displayNameById(profileId: string): string {
    const profile = this.profileById(profileId)
    return profile ? profile.displayName : profileId
  }
  selectionSubtitle(): string {
    if (this.meetingProfileIds.length === 0) { return '先挑选 2 到 3 位角色进入阵容，再去会议编排页锁定发言人格。' }
    if (this.meetingProfileIds.length < 2) { return '再补充至少 1 位角色，会议讨论会更有对照和张力。' }
    return '阵容已具备开会条件，你可以直接开始，或先去自定义发言人格。'
  }
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

  openProfile(profile: PresetProfile): void {
    this.safePush('pages/ProfileDetail', buildMeetingRouteParams({ profileIds: this.meetingProfileIds, selectedAgentIds: this.meetingAgentIds }, { profileId: profile.id }))
  }

  quickAddToMeeting(profile: PresetProfile): void {
    if (this.isInMeeting(profile.id)) {
      this.safePush('pages/MeetingComposer', buildMeetingRouteParams({ profileIds: this.meetingProfileIds, selectedAgentIds: this.meetingAgentIds }))
      return
    }
    if (this.meetingProfileIds.length >= MAX_MEETING_PARTICIPANTS) {
      this.errorMessage = `会议最多容纳 ${MAX_MEETING_PARTICIPANTS} 位角色，请先去编排页替换现有角色。`
      return
    }
    this.safePush('pages/MeetingComposer', buildMeetingRouteParams({ profileIds: [...this.meetingProfileIds, profile.id], selectedAgentIds: this.meetingAgentIds }))
  }

  removeFromMeeting(profileId: string): void { this.meetingProfileIds = this.meetingProfileIds.filter((id: string) => id !== profileId) }

  async startMeetingDirectly(): Promise<void> {
    if (this.meetingProfileIds.length < 2) {
      this.errorMessage = '至少需要选择 2 位角色才能开始会议。'
      return
    }
    this.isLoading = true
    this.errorMessage = ''
    try {
      let defaultAgentIds: string[] = []
      for (let index = 0; index < this.meetingProfileIds.length; index++) {
        const bundle = await PersonaApi.getProfileBundle(this.meetingProfileIds[index])
        if (bundle.agents.length > 0) { defaultAgentIds.push(bundle.agents[0].agentId) }
      }
      if (defaultAgentIds.length < 2) {
        this.errorMessage = '部分角色暂时无法加载，请稍后重试。'
        return
      }
      this.safePush('pages/Arena', buildMeetingRouteParams({ profileIds: this.meetingProfileIds, selectedAgentIds: defaultAgentIds }))
    } catch (_error) {
      this.errorMessage = '加载角色数据失败，请稍后重试。'
    } finally {
      this.isLoading = false
    }
  }

  @Builder
  headerPanel() {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.md }) {
        Button() { Text('<').fontSize(20).fontColor(MintColors.mintDark) }.width(40).height(40).backgroundColor('rgba(255, 255, 255, 0.92)').borderRadius(20).border({ width: 0.5, color: MintColors.border, radius: 20 }).onClick(() => this.safeBack())
        Column({ space: 4 }) {
          Text('会议角色库').fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
          Text(this.selectionSubtitle()).fontSize(Typography.size.xs).fontColor(MintColors.textSecondary).lineHeight(18)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Column({ space: 2 }) {
          Text(`${this.meetingProfileIds.length}/${MAX_MEETING_PARTICIPANTS}`).fontSize(Typography.size.body).fontWeight(FontWeight.Bold).fontColor(this.meetingProfileIds.length >= 2 ? MintColors.mintDark : MintColors.textPrimary)
          Text(this.meetingProfileIds.length >= 2 ? '可开会' : '待补齐').fontSize(Typography.size.xs).fontColor(MintColors.textMuted)
        }.padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm }).backgroundColor('rgba(255, 255, 255, 0.78)').borderRadius(BorderRadius.xxl)
      }.width('100%')
      Text('选择角色加入会议').fontSize(Typography.size.hero).fontWeight(FontWeight.Bold).fontColor(MintColors.textPrimary)
      Text('从角色库里挑出最适合坐上同一张桌子的角色，进入下一步后再为每个人锁定发言人格。').fontSize(Typography.size.body).fontColor(MintColors.textSecondary).lineHeight(Typography.lineHeight.relaxed)
    }.width('100%')
  }

  @Builder
  selectionPanel() {
    Column({ space: Spacing.md }) {
      Text(`已选角色 (${this.meetingProfileIds.length}/${MAX_MEETING_PARTICIPANTS})`).fontSize(Typography.size.body).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary)
      Text(this.selectionSubtitle()).fontSize(Typography.size.xs).fontColor(MintColors.textSecondary).lineHeight(18).width('100%')
      if (this.meetingProfileIds.length > 0) {
        Scroll() {
          Row({ space: Spacing.sm }) {
            ForEach(this.meetingProfileIds, (profileId: string) => {
              Row({ space: Spacing.xs }) {
                Stack({ alignContent: Alignment.Center }) {
                  Column().width(34).height(34).borderRadius(17).linearGradient({ direction: GradientDirection.Bottom, colors: [['rgba(78, 205, 196, 0.88)', 0], ['rgba(184, 169, 217, 0.86)', 1]] })
                  Text(this.displayNameById(profileId).charAt(0)).fontSize(Typography.size.caption).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                }
                Text(this.displayNameById(profileId)).fontSize(Typography.size.xs).fontColor(MintColors.textPrimary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('×').fontSize(Typography.size.body).fontColor(MintColors.textMuted).onClick(() => this.removeFromMeeting(profileId))
              }.padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs, bottom: Spacing.xs }).backgroundColor('rgba(255, 255, 255, 0.90)').borderRadius(BorderRadius.xxl).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl })
            }, (profileId: string) => profileId)
          }.width('100%')
        }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      }
      if (this.meetingProfileIds.length >= 2) {
        Row({ space: Spacing.sm }) {
          Button('直接开始会议').layoutWeight(1).height(42).fontSize(Typography.size.body).fontColor('#FFFFFF').backgroundColor(MintColors.mint).borderRadius(BorderRadius.xxl).onClick(() => { void this.startMeetingDirectly() })
          Button('自定义发言人格').layoutWeight(1).height(42).fontSize(Typography.size.body).fontColor(MintColors.mintDark).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl }).onClick(() => this.safePush('pages/MeetingComposer', buildMeetingRouteParams({ profileIds: this.meetingProfileIds, selectedAgentIds: this.meetingAgentIds })))
        }.width('100%')
      }
    }.width('100%').alignItems(HorizontalAlign.Start).padding(Spacing.lg).backgroundColor('rgba(255, 255, 255, 0.78)').borderRadius(BorderRadius.xxl3).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl3 })
  }

  @Builder
  filterPanel() {
    Column({ space: Spacing.md }) {
      TextInput({ placeholder: '搜索角色、经历或关键事件', text: this.searchText }).width('100%').height(50).fontSize(Typography.size.body).fontColor(MintColors.textPrimary).placeholderColor(MintColors.textPlaceholder).backgroundColor(MintColors.backgroundSecondary).borderRadius(BorderRadius.xxl).padding({ left: Spacing.lg, right: Spacing.lg }).onChange((value: string) => { this.searchText = value })
      Scroll() {
        Row({ space: Spacing.xs }) {
          ForEach(FILTERS, (filter: FilterOption) => {
            Text(filter.label).fontSize(Typography.size.caption).fontColor(this.activeFilter === filter.id ? '#FFFFFF' : MintColors.textSecondary).padding({ left: Spacing.md, right: Spacing.md, top: Spacing.sm, bottom: Spacing.sm }).backgroundColor(this.activeFilter === filter.id ? MintColors.mint : 'rgba(255, 255, 255, 0.78)').borderRadius(BorderRadius.pill).border({ width: this.activeFilter === filter.id ? 0 : 0.5, color: MintColors.borderLight, radius: BorderRadius.pill }).onClick(() => { this.activeFilter = filter.id })
          }, (filter: FilterOption) => filter.id)
        }.width('100%')
      }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
    }.width('100%').padding(Spacing.lg).backgroundColor('rgba(255, 255, 255, 0.78)').borderRadius(BorderRadius.xxl3).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl3 })
  }

  @Builder
  profileCard(profile: PresetProfile) {
    Column({ space: Spacing.md }) {
      Row({ space: Spacing.md }) {
        Stack({ alignContent: Alignment.Center }) {
          Column().width(58).height(58).borderRadius(29).linearGradient({ direction: GradientDirection.Bottom, colors: [['rgba(78, 205, 196, 0.90)', 0], ['rgba(184, 169, 217, 0.86)', 1]] })
          Text(this.initial(profile)).fontSize(Typography.size.subtitle).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        }
        Column({ space: Spacing.xs }) {
          Row({ space: Spacing.xs }) {
            Text(profile.displayName).layoutWeight(1).fontSize(Typography.size.bodyLg).fontWeight(FontWeight.Medium).fontColor(MintColors.textPrimary).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.categoryBadge(profile)).fontSize(Typography.size.xs).fontColor(MintColors.mintDark).padding({ left: Spacing.sm, right: Spacing.sm, top: 4, bottom: 4 }).backgroundColor(MintColors.mintBg).borderRadius(BorderRadius.pill)
          }.width('100%')
          Text(profile.subtitle).fontSize(Typography.size.caption).fontColor(MintColors.textSecondary).maxLines(2).lineHeight(Typography.lineHeight.relaxed).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%')
      if (profile.highlights.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(profile.highlights.slice(0, 3), (highlight: string) => {
            Text(highlight).fontSize(Typography.size.xs).fontColor(MintColors.textMuted).padding({ left: Spacing.sm, right: Spacing.sm, top: 4, bottom: 4 }).backgroundColor('rgba(255, 255, 255, 0.76)').borderRadius(BorderRadius.chip).margin({ right: Spacing.xs, bottom: Spacing.xs })
          }, (highlight: string) => highlight)
        }.width('100%')
      }
      Row({ space: Spacing.sm }) {
        Button('查看完整经历').layoutWeight(1).height(38).fontSize(Typography.size.caption).fontColor(MintColors.mintDark).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl).border({ width: 0.5, color: MintColors.border, radius: BorderRadius.xxl }).onClick(() => this.openProfile(profile))
        Button(this.isInMeeting(profile.id) ? '已在会议中' : '一键加入会议').layoutWeight(1).height(38).fontSize(Typography.size.caption).fontColor(this.isInMeeting(profile.id) ? MintColors.lavenderDark : '#FFFFFF').backgroundColor(this.isInMeeting(profile.id) ? MintColors.lavenderPale : MintColors.mint).borderRadius(BorderRadius.xxl).onClick(() => this.quickAddToMeeting(profile))
      }.width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start).padding(Spacing.lg).backgroundColor('rgba(255, 255, 255, 0.82)').borderRadius(BorderRadius.xxl3).border({ width: 0.5, color: this.isInMeeting(profile.id) ? MintColors.lavender : MintColors.border, radius: BorderRadius.xxl3 })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Column().width('100%').height('100%').backgroundColor(MintColors.background)
        Column().width(280).height(180).borderRadius(140).backgroundColor('rgba(78, 205, 196, 0.08)').blur(90).position({ x: -90, y: -40 })
        Column().width(250).height(170).borderRadius(125).backgroundColor('rgba(184, 169, 217, 0.08)').blur(70).position({ right: -70, y: 12 })
      }.width('100%').height('100%')
      Scroll() {
        Column({ space: Spacing.md }) {
          this.headerPanel()
          this.selectionPanel()
          this.filterPanel()
          if (this.errorMessage.length > 0) { Text(this.errorMessage).width('100%').fontSize(Typography.size.caption).fontColor(MintColors.error).padding(Spacing.md).backgroundColor('rgba(224, 120, 128, 0.08)').borderRadius(BorderRadius.lg) }
          if (this.isLoading) {
            Text('正在整理角色库...').fontSize(Typography.size.body).fontColor(MintColors.textMuted).padding(Spacing.xl)
          } else if (this.filteredProfiles().length === 0) {
            Text('没有找到匹配的角色').fontSize(Typography.size.bodyLg).fontColor(MintColors.textPrimary).padding(Spacing.xl)
          } else {
            ForEach(this.filteredProfiles(), (profile: PresetProfile) => { this.profileCard(profile) }, (profile: PresetProfile) => profile.id)
          }
        }.padding({ left: Spacing.page.horizontal, right: Spacing.page.horizontal, top: this.topInsetVp() + 12, bottom: this.safeBottomVp + Spacing.xl })
      }.width('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }.width('100%').height('100%').backgroundColor(MintColors.background)
  }
}
