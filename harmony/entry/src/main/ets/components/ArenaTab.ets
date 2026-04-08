import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { PersonaSpec } from '../common/Models'

// ArenaTab 组件 - 共振页面（思维共振）
@Component
export struct ArenaTab {
  @Prop agents: PersonaSpec[] = []
  @Prop selectedAgentIds: string[] = []
  @Prop topic: string = ''
  @Prop isLoading: boolean = false
  @State private pressedStart: boolean = false
  onToggleAgent: (agentId: string) => void = () => {}
  onTopicChange: (topic: string) => void = () => {}
  onStartDiscussion: () => void = () => {}

  // 获取选中人格数量
  get selectedCount(): number {
    return this.selectedAgentIds.length
  }

  // 检查是否可以选择
  canSelect(): boolean {
    return this.selectedCount < 3
  }

  // 检查是否可以开始
  canStart(): boolean {
    return this.selectedCount >= 2 && !this.isLoading
  }

  // 获取人格显示名
  getAgentName(agentId: string): string {
    const agent = this.agents.find((a: PersonaSpec) => a.agentId === agentId)
    return agent ? agent.displayName.substring(0, 1) : '?'
  }

  build() {
    Column({ space: Spacing.card.xlarge }) {
      // 页面标题
      Column({ space: Spacing.sm }) {
        // 标题装饰线
        Row({ space: Spacing.sm }) {
          Column()
            .width(24)
            .height(3)
            .borderRadius(1.5)
            .backgroundColor('#6366F1')

          Text('思维共振')
            .fontSize(Typography.size.xxl)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text('重组思想切片，开启多维度的对话')
          .fontSize(Typography.size.bodyLg)
          .fontColor(Colors.textTertiary)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ top: Spacing.lg })

      // 人格编织区域
      Column({ space: Spacing.card.large }) {
        // 标题行
        Row() {
          Row({ space: 6 }) {
            Text('人格编织')
              .fontSize(Typography.size.subtitle)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)

            // 状态标签
            Text('编织中')
              .fontSize(Typography.size.xs)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.primary)
              .padding({
                left: Spacing.card.medium,
                right: Spacing.card.medium,
                top: 2,
                bottom: 2
              })
              .backgroundColor(Colors.accentPurple)
              .borderRadius(BorderRadius.pill)
          }
        }
        .width('100%')

        // 人格插槽区域
        Column({ space: Spacing.card.medium }) {
          Row({ space: Spacing.sm }) {
            // 已选人格
            ForEach(this.selectedAgentIds, (agentId: string) => {
              this.buildFilledSlot(agentId)
            }, (agentId: string) => agentId)

            // 空插槽
            if (this.canSelect()) {
              this.buildEmptySlot()
            }

            // 箭头
            Row({ space: 4 }) {
              Text('→')
                .fontSize(18)
                .fontColor(Colors.textMuted)
            }
            .margin({ left: Spacing.xs, right: Spacing.xs })

            // 结果人格
            this.buildResultSlot()
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding(Spacing.card.medium)
        .backgroundColor('rgba(99, 102, 241, 0.04)')
        .borderRadius(BorderRadius.xxl)

        // 提示文字
        Row({ space: 6 }) {
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor(Colors.textMuted)

          Text(`已加入 ${this.selectedCount} 个思维锚点，继续添加以合成新视界`)
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textMuted)
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.huge)
      .backgroundColor(Colors.cardPrimary)
      .borderRadius(BorderRadius.huge)
      .border({
        width: 1,
        color: 'rgba(99, 102, 241, 0.1)',
        radius: BorderRadius.huge
      })
      .backdropBlur(20)

      // 议题输入区域
      Column({ space: Spacing.card.large }) {
        Row({ space: Spacing.xs }) {
          Column()
            .width(3)
            .height(18)
            .borderRadius(1.5)
            .backgroundColor('#10B981')

          Text('抛出议题')
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textSecondary)
        }
        .width('100%')

        // 输入框
        TextArea({ placeholder: '例如：在面临极度不确定的未来时，该如何做出决策？' })
          .width('100%')
          .height(80)
          .fontSize(Typography.size.bodyLg)
          .fontColor(Colors.textPrimary)
          .placeholderColor(Colors.textPlaceholder)
          .placeholderFont({
            size: Typography.size.bodyLg,
            weight: FontWeight.Normal
          })
          .backgroundColor(Colors.background)
          .borderRadius(BorderRadius.xxl)
          .border({
            width: 1,
            color: Colors.borderLight,
            radius: BorderRadius.xxl
          })
          .padding(Spacing.card.large)
          .onChange((value: string) => {
            this.onTopicChange(value)
          })

        // 开始讨论按钮
        Button('开启跨时空会谈')
          .width('100%')
          .height(52)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor(this.canStart() ? '#6366F1' : Colors.textMuted)
          .borderRadius(BorderRadius.huge)
          .enabled(this.canStart())
          .shadow({
            radius: this.canStart() ? 20 : 10,
            color: this.canStart() ? 'rgba(99, 102, 241, 0.25)' : 'rgba(0, 0, 0, 0.05)',
            offsetX: 0,
            offsetY: this.canStart() ? 8 : 4
          })
          .scale({
            x: this.pressedStart ? 0.98 : 1,
            y: this.pressedStart ? 0.98 : 1
          })
          .animation({
            duration: 150,
            curve: Curve.EaseOut
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.pressedStart = true
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.pressedStart = false
            }
          })
          .onClick(() => {
            if (this.canStart()) {
              this.onStartDiscussion()
            }
          })
      }
      .width('100%')
      .padding({ bottom: Spacing.giant })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildFilledSlot(agentId: string) {
    // 找到对应的人格
    Column() {
      Text(this.getAgentName(agentId))
        .fontSize(Typography.size.subtitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.primary)
    }
    .width(52)
    .height(52)
    .borderRadius(26)
    .backgroundColor('#FFFFFF')
    .border({
      width: 2,
      color: '#6366F1',
      radius: 26
    })
    .shadow({
      radius: 12,
      color: 'rgba(99, 102, 241, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildEmptySlot() {
    Column() {
      Text('+')
        .fontSize(22)
        .fontColor(Colors.textMuted)
    }
    .width(52)
    .height(52)
    .borderRadius(26)
    .backgroundColor('rgba(241, 245, 249, 0.8)')
    .border({
      width: 1.5,
      color: Colors.textMuted,
      radius: 26,
      style: BorderStyle.Dashed
    })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildResultSlot() {
    Column({ space: 4 }) {
      Text('✨')
        .fontSize(20)

      Text('融合')
        .fontSize(Typography.size.xs)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.primary)
    }
    .width(64)
    .height(64)
    .borderRadius(20)
    .backgroundColor(Colors.accentPurple)
    .border({
      width: 1.5,
      color: 'rgba(99, 102, 241, 0.3)',
      radius: 20
    })
    .shadow({
      radius: 16,
      color: 'rgba(99, 102, 241, 0.15)',
      offsetX: 0,
      offsetY: 6
    })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
