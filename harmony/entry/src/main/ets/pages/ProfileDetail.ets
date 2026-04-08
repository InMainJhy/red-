import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { PersonaSpec, PresetProfile, ProfileBundle, RouteParams, TimelineNode, EMPTY_PROFILE } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
import { ColorsLight } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'

@Entry
@Component
struct ProfileDetail {
  // 状态
  @State profile: PresetProfile = EMPTY_PROFILE
  @State nodes: TimelineNode[] = []
  @State agents: PersonaSpec[] = []
  @State selectedAgentIds: string[] = []
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0

  // 生命周期
  aboutToAppear(): void {
    this.loadSafeInsets()
    const params = router.getParams() as RouteParams
    const profileId = params.profileId ? params.profileId : 'graduate'

    PersonaApi.getProfileBundle(profileId).then((bundle: ProfileBundle) => {
      this.profile = bundle.profile
      this.nodes = bundle.nodes
      this.agents = bundle.agents
      this.selectedAgentIds = bundle.agents.slice(0, 2).map((agent: PersonaSpec) => agent.agentId)
    })
  }

  loadSafeInsets(): void {
    try {
      const ctx = getContext(this) as common.UIAbilityContext
      fetchSafeAreaInsets(ctx).then((insets) => {
        this.safeTopVp = insets.topVp
        this.safeBottomVp = insets.bottomVp
      })
    } catch (_e) {
      // 忽略错误
    }
  }

  // 业务方法
  toggleAgent(agentId: string): void {
    if (this.selectedAgentIds.includes(agentId)) {
      this.selectedAgentIds = this.selectedAgentIds.filter((item: string) => item !== agentId)
      return
    }

    if (this.selectedAgentIds.length >= 3) {
      this.selectedAgentIds = [...this.selectedAgentIds.slice(1), agentId]
      return
    }

    this.selectedAgentIds = [...this.selectedAgentIds, agentId]
  }

  goArena(): void {
    router.pushUrl({
      url: 'pages/Arena',
      params: {
        profileId: this.profile.id,
        selectedAgentIds: this.selectedAgentIds.join(',')
      }
    })
  }

  // 获取阶段颜色
  getStageColor(stageType: string): string {
    const colors: Record<string, string> = {
      'early': '#0D7A72',
      'turning-point': '#4A7C59',
      'crisis': '#7A3C35',
      'rebuild': '#6B5B95',
      'peak': '#B8860B'
    }
    return colors[stageType] || ColorsLight.accent
  }

  build() {
    Scroll() {
      Column({ space: Spacing.giant }) {
        // 头部信息卡片
        Column({ space: Spacing.card.large }) {
          // 返回按钮
          Button('← 返回角色库')
            .fontSize(Typography.size.body)
            .fontColor(ColorsLight.accent)
            .backgroundColor('#00000000')
            .padding(0)
            .onClick(() => {
              router.back()
            })

          // 标签
          Text('角色详情子页')
            .fontSize(Typography.size.caption)
            .fontColor(ColorsLight.accent)
            .letterSpacing(Typography.letterSpacing.wide)

          // 人物名称
          Text(this.profile.displayName)
            .fontSize(Typography.size.hero)
            .fontWeight(Typography.weight.bold)
            .fontColor(ColorsLight.textPrimary)

          // 传记
          Text(this.profile.biography)
            .fontSize(Typography.size.subtitle)
            .fontColor(ColorsLight.textSecondary)
            .lineHeight(Typography.lineHeight.relaxed)

          // 底部操作栏
          Row() {
            Text(`已选节点 ${this.selectedAgentIds.length} / 3`)
              .fontSize(Typography.size.body)
              .fontColor(ColorsLight.textTertiary)

            Blank()

            Button('带入议会')
              .height(40)
              .fontSize(Typography.size.bodyLg)
              .fontColor(ColorsLight.background)
              .backgroundColor(ColorsLight.textPrimary)
              .borderRadius(BorderRadius.pill)
              .enabled(this.selectedAgentIds.length >= 2)
              .opacity(this.selectedAgentIds.length >= 2 ? 1 : 0.5)
              .onClick(() => {
                this.goArena()
              })
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .padding(Spacing.huge)
        .width('100%')
        .backgroundColor(ColorsLight.backgroundSecondary)
        .borderRadius(BorderRadius.card.large)

        // 时间线节点列表
        ForEach(this.nodes, (node: TimelineNode, index: number) => {
          this.buildTimelineNode(node, index)
        }, (node: TimelineNode) => node.nodeId)
      }
      .padding({
        left: Spacing.page.horizontal,
        right: Spacing.page.horizontal,
        top: Spacing.page.vertical + this.safeTopVp,
        bottom: Spacing.page.vertical + this.safeBottomVp
      })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .scrollBar(BarState.Off)
    .backgroundColor(ColorsLight.background)
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTimelineNode(node: TimelineNode, index: number) {
    Column({ space: Spacing.card.medium }) {
      // 节点头部
      Row() {
        // 序号圆圈
        Text(`${index + 1}`)
          .fontSize(Typography.size.body)
          .fontColor(ColorsLight.background)
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getStageColor(node.stageType))
          .borderRadius(14)

        // 时间标签
        Text(`${node.timeLabel}${node.ageLabel ? ' / ' + node.ageLabel : ''}`)
          .fontSize(Typography.size.caption)
          .fontColor(ColorsLight.accent)
          .margin({ left: Spacing.sm })
      }
      .width('100%')

      // 阶段标题
      Text(node.stageLabel)
        .fontSize(Typography.size.xl)
        .fontWeight(Typography.weight.bold)
        .fontColor(ColorsLight.textPrimary)

      // 摘要
      Text(node.summary)
        .fontSize(Typography.size.bodyLg)
        .fontColor(ColorsLight.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)

      // 关键事件
      Row({ space: Spacing.xs }) {
        Text('关键事件：')
          .fontSize(Typography.size.body)
          .fontColor(ColorsLight.textTertiary)
        Text(node.keyEvent)
          .fontSize(Typography.size.body)
          .fontColor(ColorsLight.textPrimary)
      }
      .width('100%')

      // 特质标签
      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
        ForEach(node.traits, (trait: string) => {
          Text(trait)
            .fontSize(Typography.size.sm)
            .fontColor(ColorsLight.accent)
            .padding({
              left: Spacing.sm,
              right: Spacing.sm,
              top: Spacing.xs,
              bottom: Spacing.xs
            })
            .backgroundColor(ColorsLight.accentLight)
            .borderRadius(BorderRadius.sm)
            .margin({ right: Spacing.xs, bottom: Spacing.xs })
        }, (trait: string) => trait)
      }
      .width('100%')

      // 价值观
      if (node.values.length > 0) {
        Row({ space: Spacing.xs }) {
          Text('价值观：')
            .fontSize(Typography.size.body)
            .fontColor(ColorsLight.textTertiary)
          Text(node.values.join(' / '))
            .fontSize(Typography.size.body)
            .fontColor(ColorsLight.textPrimary)
        }
        .width('100%')
      }

      // 证据引用
      if (node.sourceEvidence.length > 0) {
        Column({ space: Spacing.xs }) {
          Text('证据引用：')
            .fontSize(Typography.size.sm)
            .fontColor(ColorsLight.textTertiary)

          Text(`"${node.sourceEvidence[0].quote}"`)
            .fontSize(Typography.size.body)
            .fontColor(ColorsLight.error)
            .lineHeight(Typography.lineHeight.relaxed)
            .fontStyle(FontStyle.Italic)
        }
        .width('100%')
        .padding(Spacing.card.medium)
        .backgroundColor(ColorsLight.cardMuted)
        .borderRadius(BorderRadius.card.small)
      }

      // 加入/移出按钮
      Button(this.selectedAgentIds.includes(this.agents[index]?.agentId) ? '✓ 已加入议会' : '+ 加入议会')
        .width('100%')
        .height(44)
        .fontSize(Typography.size.bodyLg)
        .fontColor(this.selectedAgentIds.includes(this.agents[index]?.agentId) ? ColorsLight.accent : ColorsLight.error)
        .backgroundColor(this.selectedAgentIds.includes(this.agents[index]?.agentId) ? ColorsLight.accentLight : ColorsLight.cardMuted)
        .borderRadius(BorderRadius.pill)
        .border({
          width: 1,
          color: this.selectedAgentIds.includes(this.agents[index]?.agentId) ? ColorsLight.accent : ColorsLight.error,
          radius: BorderRadius.pill
        })
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })
        .onClick(() => {
          if (this.agents[index]) {
            this.toggleAgent(this.agents[index].agentId)
          }
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(Spacing.card.xlarge)
    .backgroundColor(ColorsLight.cardPrimary)
    .borderRadius(BorderRadius.card.xlarge)
    .transition(TransitionEffect.OPACITY.animation({
      duration: 300,
      curve: Curve.EaseOut
    }))
  }
}
