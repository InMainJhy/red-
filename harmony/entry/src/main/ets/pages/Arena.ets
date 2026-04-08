import { common } from '@kit.AbilityKit'
import { router } from '@kit.ArkUI'
import { ArenaMessage, PersonaSpec, PresetProfile, RouteParams, SelectedAgentsBundle, EMPTY_PROFILE } from '../common/Models'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { Spacing } from '../common/styles/Spacing'
import { BorderRadius } from '../common/styles/BorderRadius'
import {
  Icon
} from '../components/CustomIcon'

const FALLBACK_SAFE_TOP_VP: number = 52

@Entry
@Component
struct Arena {
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

  topInsetVp(): number {
    return this.safeTopVp > 0 ? this.safeTopVp : FALLBACK_SAFE_TOP_VP
  }

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

  getStanceColor(stance: string): string {
    const colors: Record<string, string> = {
      'support': MintColors.stance.support,
      'oppose': MintColors.stance.oppose,
      'reflective': MintColors.stance.reflective
    }
    return colors[stance] || MintColors.stance.default
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
          .width(280)
          .height(180)
          .borderRadius(140)
          .backgroundColor('rgba(78, 205, 196, 0.06)')
          .blur(80)
          .position({ x: -80, y: -50 })

        Column()
          .width(240)
          .height(160)
          .borderRadius(120)
          .backgroundColor('rgba(184, 169, 217, 0.07)')
          .blur(60)
          .position({ right: -60, y: -30 })
      }
      .width('100%')
      .height('100%')

      // 返回按钮
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
          // 头部信息卡片
          Column({ space: Spacing.md }) {
            Text('阶段人格议会')
              .fontSize(Typography.size.hero)
              .fontWeight(Typography.weight.bold)
              .fontColor(MintColors.textPrimary)

            Text(`${this.profile.displayName} 的多面人生`)
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textSecondary)

            // 议题输入
            TextArea({ text: this.topic, placeholder: '输入讨论议题，例如：现在该不该创业？' })
              .width('100%')
              .height(80)
              .fontSize(Typography.size.body)
              .fontColor(MintColors.textPrimary)
              .placeholderColor(MintColors.textPlaceholder)
              .backgroundColor(MintColors.backgroundSecondary)
              .borderRadius(BorderRadius.lg)
              .padding(Spacing.md)
              .onChange((value: string) => {
                this.topic = value
              })

            // 开始讨论按钮
            Button(this.isLoading ? '讨论中...' : '✨ 开始讨论')
              .width('100%')
              .height(46)
              .fontSize(Typography.size.bodyLg)
              .fontColor('#FFFFFF')
              .backgroundColor(this.selectedAgents.length >= 2 ? MintColors.mint : MintColors.backgroundSecondary)
              .borderRadius(BorderRadius.xxl)
              .enabled(!this.isLoading && this.selectedAgents.length >= 2)
              .onClick(() => {
                this.runDiscussion()
              })
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

          // 参会角色
          Column({ space: Spacing.sm }) {
            Text('参会角色')
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Medium)
              .fontColor(MintColors.textPrimary)

            ForEach(this.selectedAgents, (agent: PersonaSpec) => {
              Column({ space: 4 }) {
                Text(agent.stageLabel)
                  .fontSize(Typography.size.bodyLg)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(MintColors.textPrimary)

                Text(`${agent.timeLabel} · ${agent.voiceStyle}`)
                  .fontSize(Typography.size.caption)
                  .fontColor(MintColors.textMuted)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(Spacing.md)
              .backgroundColor(MintColors.surface)
              .borderRadius(BorderRadius.lg)
              .border({
                width: 0.5,
                color: MintColors.border,
                radius: BorderRadius.lg
              })
            }, (agent: PersonaSpec) => agent.agentId)
          }
          .width('100%')

          // 对话流
          Column({ space: Spacing.sm }) {
            Text('对话流')
              .fontSize(Typography.size.bodyLg)
              .fontWeight(FontWeight.Medium)
              .fontColor(MintColors.textPrimary)

            if (this.messages.length > 0) {
              ForEach(this.messages, (message: ArenaMessage) => {
                Column({ space: Spacing.xs }) {
                  // 消息头
                  Row({ space: Spacing.xs }) {
                    Text(message.stance.toUpperCase())
                      .fontSize(Typography.size.xs)
                      .fontColor(this.getStanceColor(message.stance))
                      .padding({
                        left: Spacing.sm,
                        right: Spacing.sm,
                        top: 3,
                        bottom: 3
                      })
                      .backgroundColor(this.getStanceColor(message.stance) + '20')
                      .borderRadius(BorderRadius.chip)

                    Text(`${message.stageLabel} · ${message.displayName}`)
                      .fontSize(Typography.size.caption)
                      .fontColor(MintColors.lavender)
                  }
                  .width('100%')

                  // 内容
                  Text(message.content)
                    .fontSize(Typography.size.body)
                    .fontColor(MintColors.textPrimary)
                    .lineHeight(Typography.lineHeight.relaxed)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding(Spacing.md)
                .backgroundColor(MintColors.surface)
                .borderRadius(BorderRadius.xxl)
                .border({
                  width: 0.5,
                  color: MintColors.border,
                  radius: BorderRadius.xxl
                })
              }, (message: ArenaMessage) => message.id)
            } else {
              Column({ space: Spacing.sm }) {
                Text('等待开始')
                  .fontSize(Typography.size.bodyLg)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(MintColors.textPrimary)

                Text('点击"开始讨论"后，这里会生成阶段人格之间的对话。')
                  .fontSize(Typography.size.caption)
                  .fontColor(MintColors.textMuted)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding(Spacing.lg)
              .backgroundColor(MintColors.surface)
              .borderRadius(BorderRadius.xxl)
            }
          }
          .width('100%')

          // 会议纪要
          if (this.summaryTitle.length > 0) {
            Column({ space: Spacing.md }) {
              Text(this.summaryTitle)
                .fontSize(Typography.size.xl)
                .fontWeight(FontWeight.Bold)
                .fontColor(MintColors.textPrimary)

              // 共识
              if (this.consensus.length > 0) {
                Column({ space: 4 }) {
                  Text('共识')
                    .fontSize(Typography.size.caption)
                    .fontColor(MintColors.mintDark)
                  Text(this.consensus)
                    .fontSize(Typography.size.body)
                    .fontColor(MintColors.textPrimary)
                    .lineHeight(Typography.lineHeight.relaxed)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding(Spacing.md)
                .backgroundColor(MintColors.mintBg)
                .borderRadius(BorderRadius.lg)
              }

              // 分歧
              if (this.disagreements.length > 0) {
                Column({ space: Spacing.xs }) {
                  Text('主要分歧')
                    .fontSize(Typography.size.caption)
                    .fontColor(MintColors.error)

                  ForEach(this.disagreements, (item: string) => {
                    Row({ space: Spacing.xs }) {
                      Text('•')
                        .fontSize(Typography.size.body)
                        .fontColor(MintColors.error)
                      Text(item)
                        .fontSize(Typography.size.body)
                        .fontColor(MintColors.textPrimary)
                        .lineHeight(Typography.lineHeight.relaxed)
                    }
                    .width('100%')
                  }, (item: string) => item)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding(Spacing.md)
                .backgroundColor('rgba(224, 120, 128, 0.06)')
                .borderRadius(BorderRadius.lg)
              }

              // 行动建议
              if (this.actionableAdvice.length > 0) {
                Column({ space: Spacing.xs }) {
                  Text('行动建议')
                    .fontSize(Typography.size.caption)
                    .fontColor(MintColors.mintDark)

                  ForEach(this.actionableAdvice, (item: string) => {
                    Row({ space: Spacing.xs }) {
                      Text('✓')
                        .fontSize(Typography.size.body)
                        .fontColor(MintColors.mint)
                      Text(item)
                        .fontSize(Typography.size.body)
                        .fontColor(MintColors.textPrimary)
                        .lineHeight(Typography.lineHeight.relaxed)
                    }
                    .width('100%')
                  }, (item: string) => item)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding(Spacing.md)
                .backgroundColor(MintColors.mintBg)
                .borderRadius(BorderRadius.lg)
              }

              // 叙事钩子
              if (this.narrativeHook.length > 0) {
                Text(`"${this.narrativeHook}"`)
                  .fontSize(Typography.size.body)
                  .fontColor(MintColors.lavenderDark)
                  .lineHeight(Typography.lineHeight.relaxed)
                  .fontStyle(FontStyle.Italic)
                  .padding(Spacing.md)
                  .backgroundColor(MintColors.lavenderPale)
                  .borderRadius(BorderRadius.lg)
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
}
