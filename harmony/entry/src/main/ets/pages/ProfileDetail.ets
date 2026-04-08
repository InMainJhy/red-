import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { PersonaSpec, PresetProfile, ProfileBundle, RouteParams, TimelineNode, EMPTY_PROFILE } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
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
  @State agents: PersonaSpec[] = []
  @State selectedAgentIds: string[] = []
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0

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

  topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

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

  getStageColor(stageType: string): string {
    const colors: Record<string, string> = {
      'early': MintColors.stage.early,
      'turning-point': MintColors.stage.turningPoint,
      'crisis': MintColors.stage.crisis,
      'rebuild': MintColors.stage.rebuild,
      'peak': MintColors.stage.peak
    }
    return colors[stageType] || MintColors.stage.default
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景
      Column() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(MintColors.background)

        Column()
          .width(300)
          .height(200)
          .borderRadius(150)
          .backgroundColor('rgba(78, 205, 196, 0.06)')
          .blur(80)
          .position({ x: -100, y: -60 })

        Column()
          .width(260)
          .height(170)
          .borderRadius(130)
          .backgroundColor('rgba(184, 169, 217, 0.06)')
          .blur(60)
          .position({ right: -80, y: -40 })
      }
      .width('100%')
      .height('100%')

      // 左上返回
      Button() {
        Text('<')
          .fontSize(20)
          .fontColor(MintColors.mintDark)
      }
      .width(38)
      .height(38)
      .backgroundColor(MintColors.surfaceGlass)
      .borderRadius(19)
      .shadow({
        radius: 10,
        color: 'rgba(78, 205, 196, 0.1)',
        offsetX: 0,
        offsetY: 3
      })
      .position({ x: Spacing.page.horizontal, y: this.topInsetVp() + 12 })
      .onClick(() => {
        router.back()
      })

      Scroll() {
        Column({ space: Spacing.lg }) {
          // 头部人物卡片
          Column({ space: Spacing.md }) {
            Text(this.profile.displayName)
              .fontSize(Typography.size.hero)
              .fontWeight(Typography.weight.bold)
              .fontColor(MintColors.textPrimary)

            Text(this.profile.biography)
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textSecondary)
              .lineHeight(Typography.lineHeight.relaxed)

            Divider()
              .color(MintColors.divider)
              .margin({ top: Spacing.sm, bottom: Spacing.sm })

            // 底部操作行
            Row() {
              Column() {
                Text(`${this.selectedAgentIds.length}`)
                  .fontSize(Typography.size.xl)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MintColors.mint)
                Text('已选节点')
                  .fontSize(Typography.size.xs)
                  .fontColor(MintColors.textMuted)
              }

              Blank()

              Button('带入议会')
                .height(40)
                .fontSize(Typography.size.bodyLg)
                .fontColor(this.selectedAgentIds.length >= 2 ? '#FFFFFF' : MintColors.textMuted)
                .backgroundColor(this.selectedAgentIds.length >= 2 ? MintColors.mint : MintColors.backgroundSecondary)
                .borderRadius(BorderRadius.xxl)
                .enabled(this.selectedAgentIds.length >= 2)
                .onClick(() => {
                  this.goArena()
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(Spacing.lg)
          .backgroundColor(MintColors.cardPrimary)
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 0.5,
            color: MintColors.border,
            radius: BorderRadius.xxl
          })
          .shadow({
            radius: 20,
            color: 'rgba(78, 205, 196, 0.08)',
            offsetX: 0,
            offsetY: 6
          })

          // 时间线标签
          Row() {
            Text('人生时间线')
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Medium)
              .fontColor(MintColors.textPrimary)
          }
          .width('100%')
          .padding({ top: Spacing.sm })

          // 时间线节点
          ForEach(this.nodes, (node: TimelineNode, index: number) => {
            this.buildTimelineNode(node, index)
          }, (node: TimelineNode) => node.nodeId)
        }
        .padding({
          left: Spacing.page.horizontal,
          right: Spacing.page.horizontal,
          top: this.topInsetVp() + 60,
          bottom: this.safeBottomVp + Spacing.xl
        })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MintColors.background)
  }

  @Builder
  buildTimelineNode(node: TimelineNode, index: number) {
    Column({ space: Spacing.md }) {
      // 节点头部
      Row() {
        // 阶段圆点
        Column()
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor(this.getStageColor(node.stageType))

        Text(`${index + 1}`)
          .fontSize(Typography.size.sm)
          .fontColor('#FFFFFF')
          .width(28)
          .height(28)
          .textAlign(TextAlign.Center)
          .position({ y: 0 })

        Text(node.stageLabel)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.textPrimary)
          .margin({ left: Spacing.sm })

        Blank()

        Text(node.timeLabel)
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textMuted)
      }
      .width('100%')

      // 摘要
      Text(node.summary)
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textSecondary)
        .lineHeight(Typography.lineHeight.relaxed)

      // 关键事件（右侧占满剩余宽度并自动换行，避免单行溢出）
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

      // 特质标签
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

      // 价值观
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

      // 证据引用
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

      // 加入按钮
      Button(
        this.selectedAgentIds.includes(this.agents[index]?.agentId) ? '✓ 已加入议会' : '+ 加入议会'
      )
        .width('100%')
        .height(42)
        .fontSize(Typography.size.body)
        .fontColor(
          this.selectedAgentIds.includes(this.agents[index]?.agentId)
            ? '#FFFFFF'
            : MintColors.mintDark
        )
        .backgroundColor(
          this.selectedAgentIds.includes(this.agents[index]?.agentId)
            ? MintColors.mint
            : MintColors.surfaceGlass
        )
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 1,
          color: this.selectedAgentIds.includes(this.agents[index]?.agentId) ? MintColors.mint : MintColors.border,
          radius: BorderRadius.xxl
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