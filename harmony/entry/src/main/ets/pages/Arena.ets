import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { ArenaMessage, PersonaSpec, PresetProfile, RouteParams, SelectedAgentsBundle, EMPTY_PROFILE } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
import { ColorsLight } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'

@Entry
@Component
struct Arena {
  // 状态
  @State profile: PresetProfile = EMPTY_PROFILE
  @State selectedAgents: PersonaSpec[] = []
  @State topic: string = '现在该不该离开这份长期消耗我的工作？'
  @State messages: ArenaMessage[] = []
  @State summaryTitle: string = ''
  @State consensus: string = ''
  @State disagreements: string[] = []
  @State actionableAdvice: string[] = []
  @State narrativeHook: string = ''
  @State isLoading: boolean = false
  @State safeTopVp: number = 0
  @State safeBottomVp: number = 0

  // 生命周期
  aboutToAppear(): void {
    this.loadSafeInsets()
    const params = router.getParams() as RouteParams
    const profileId = params.profileId ? params.profileId : 'graduate'
    const selectedAgentIds = params.selectedAgentIds ? params.selectedAgentIds.split(',') : []

    PersonaApi.getSelectedAgents(profileId, selectedAgentIds).then((bundle: SelectedAgentsBundle) => {
      this.profile = bundle.profile
      this.selectedAgents = bundle.selectedAgents
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
  runDiscussion(): void {
    if (this.selectedAgents.length < 2) {
      return
    }

    this.isLoading = true

    PersonaApi.runArena(this.topic, this.selectedAgents).then((result) => {
      this.messages = result.messages
      this.summaryTitle = result.summary.title
      this.consensus = result.summary.consensus
      this.disagreements = result.summary.disagreements
      this.actionableAdvice = result.summary.actionableAdvice
      this.narrativeHook = result.summary.narrativeHook
    }).finally(() => {
      this.isLoading = false
    })
  }

  // 获取立场颜色
  getStanceColor(stance: string): string {
    const colors: Record<string, string> = {
      'support': '#0D7A72',
      'oppose': '#7A3C35',
      'reflective': '#6B5B95'
    }
    return colors[stance] || ColorsLight.accent
  }

  build() {
    Scroll() {
      Column({ space: Spacing.giant }) {
        // 头部信息卡片
        Column({ space: Spacing.card.large }) {
          // 返回按钮
          Button('← 返回角色详情')
            .fontSize(Typography.size.body)
            .fontColor(ColorsLight.accent)
            .backgroundColor('#00000000')
            .padding(0)
            .onClick(() => {
              router.back()
            })

          // 标签
          Text('ARENA / 阶段人格议会')
            .fontSize(Typography.size.caption)
            .fontColor(ColorsLight.accent)
            .letterSpacing(Typography.letterSpacing.wide)

          // 标题
          Text(`${this.profile.displayName} 的阶段人格议会`)
            .fontSize(Typography.size.xxl)
            .fontWeight(Typography.weight.bold)
            .fontColor(ColorsLight.textPrimary)

          // 议题输入
          TextArea({ text: this.topic, placeholder: '输入讨论议题，例如：现在该不该创业？' })
            .width('100%')
            .height(100)
            .fontSize(Typography.size.bodyLg)
            .fontColor(ColorsLight.textPrimary)
            .placeholderColor(ColorsLight.textTertiary)
            .backgroundColor(ColorsLight.cardPrimary)
            .borderRadius(BorderRadius.card.medium)
            .padding(Spacing.card.medium)
            .onChange((value: string) => {
              this.topic = value
            })

          // 开始讨论按钮
          Button(this.isLoading ? '讨论中...' : '开始讨论')
            .width('100%')
            .height(48)
            .fontSize(Typography.size.subtitle)
            .fontColor(ColorsLight.background)
            .backgroundColor(ColorsLight.textPrimary)
            .borderRadius(BorderRadius.pill)
            .enabled(!this.isLoading && this.selectedAgents.length >= 2)
            .opacity(!this.isLoading && this.selectedAgents.length >= 2 ? 1 : 0.5)
            .onClick(() => {
              this.runDiscussion()
            })
        }
        .alignItems(HorizontalAlign.Start)
        .padding(Spacing.huge)
        .width('100%')
        .backgroundColor(ColorsLight.backgroundSecondary)
        .borderRadius(BorderRadius.card.large)

        // 参会角色列表
        Column({ space: Spacing.card.medium }) {
          Text('参会角色')
            .fontSize(Typography.size.bodyLg)
            .fontColor(ColorsLight.textTertiary)

          ForEach(this.selectedAgents, (agent: PersonaSpec) => {
            Column({ space: Spacing.xs }) {
              Text(agent.stageLabel)
                .fontSize(Typography.size.lg)
                .fontWeight(Typography.weight.bold)
                .fontColor(ColorsLight.textPrimary)

              Text(`${agent.timeLabel} · ${agent.voiceStyle}`)
                .fontSize(Typography.size.body)
                .fontColor(ColorsLight.textTertiary)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(Spacing.card.large)
            .backgroundColor(ColorsLight.cardPrimary)
            .borderRadius(BorderRadius.card.medium)
          }, (agent: PersonaSpec) => agent.agentId)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 对话流
        Column({ space: Spacing.card.medium }) {
          Text('对话流')
            .fontSize(Typography.size.bodyLg)
            .fontColor(ColorsLight.textTertiary)

          if (this.messages.length > 0) {
            ForEach(this.messages, (message: ArenaMessage) => {
              Column({ space: Spacing.sm }) {
                // 消息头
                Row({ space: Spacing.sm }) {
                  // 立场标签
                  Text(message.stance.toUpperCase())
                    .fontSize(Typography.size.xs)
                    .fontColor(this.getStanceColor(message.stance))
                    .padding({
                      left: Spacing.xs,
                      right: Spacing.xs,
                      top: 2,
                      bottom: 2
                    })
                    .backgroundColor(this.getStanceColor(message.stance) + '20')
                    .borderRadius(BorderRadius.xs)

                  Text(`${message.stageLabel} · ${message.displayName}`)
                    .fontSize(Typography.size.body)
                    .fontColor(ColorsLight.accent)
                }
                .width('100%')

                // 消息内容
                Text(message.content)
                  .fontSize(Typography.size.bodyLg)
                  .fontColor(ColorsLight.textPrimary)
                  .lineHeight(Typography.lineHeight.relaxed)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(Spacing.card.large)
              .backgroundColor(ColorsLight.cardPrimary)
              .borderRadius(BorderRadius.card.xlarge)
            }, (message: ArenaMessage) => message.id)
          } else {
            Column({ space: Spacing.sm }) {
              Text('等待开始')
                .fontSize(Typography.size.lg)
                .fontWeight(Typography.weight.bold)
                .fontColor(ColorsLight.textPrimary)

              Text('点击"开始讨论"后，这里会生成阶段人格之间的对话。')
                .fontSize(Typography.size.body)
                .fontColor(ColorsLight.textTertiary)
                .lineHeight(Typography.lineHeight.relaxed)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding(Spacing.huge)
            .backgroundColor(ColorsLight.cardPrimary)
            .borderRadius(BorderRadius.card.xlarge)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 会议纪要
        if (this.summaryTitle.length > 0) {
          Column({ space: Spacing.card.medium }) {
            // 标题
            Text(this.summaryTitle)
              .fontSize(Typography.size.xl)
              .fontWeight(Typography.weight.bold)
              .fontColor(ColorsLight.textPrimary)

            // 共识
            Text(this.consensus)
              .fontSize(Typography.size.bodyLg)
              .fontColor(ColorsLight.textSecondary)
              .lineHeight(Typography.lineHeight.relaxed)

            Divider()
              .color(ColorsLight.border)
              .margin({ top: Spacing.sm, bottom: Spacing.sm })

            // 主要分歧
            Text('主要分歧')
              .fontSize(Typography.size.bodyLg)
              .fontColor(ColorsLight.textTertiary)

            ForEach(this.disagreements, (item: string) => {
              Row({ space: Spacing.sm }) {
                Text('•')
                  .fontSize(Typography.size.body)
                  .fontColor(ColorsLight.error)
                Text(item)
                  .fontSize(Typography.size.body)
                  .fontColor(ColorsLight.textPrimary)
                  .lineHeight(Typography.lineHeight.relaxed)
              }
              .width('100%')
            }, (item: string) => item)

            Divider()
              .color(ColorsLight.border)
              .margin({ top: Spacing.sm, bottom: Spacing.sm })

            // 行动建议
            Text('行动建议')
              .fontSize(Typography.size.bodyLg)
              .fontColor(ColorsLight.textTertiary)

            ForEach(this.actionableAdvice, (item: string) => {
              Row({ space: Spacing.sm }) {
                Text('•')
                  .fontSize(Typography.size.body)
                  .fontColor(ColorsLight.accent)
                Text(item)
                  .fontSize(Typography.size.body)
                  .fontColor(ColorsLight.textPrimary)
                  .lineHeight(Typography.lineHeight.relaxed)
              }
              .width('100%')
            }, (item: string) => item)

            // 叙事钩子
            if (this.narrativeHook.length > 0) {
              Text(`"${this.narrativeHook}"`)
                .fontSize(Typography.size.body)
                .fontColor(ColorsLight.error)
                .lineHeight(Typography.lineHeight.relaxed)
                .padding(Spacing.card.large)
                .backgroundColor(ColorsLight.cardMuted)
                .borderRadius(BorderRadius.card.medium)
            }
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
}
