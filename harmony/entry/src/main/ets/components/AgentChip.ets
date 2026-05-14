import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { PersonaSpec } from '../common/Models'

type ThemeColor = ResourceColor | string

// AgentChip 组件属性
export interface AgentChipProps {
  agent: PersonaSpec
  isSelected: boolean
}

// AgentChip 组件 - 清新风格人格标签
@Component
export struct AgentChip {
  @Prop agent: PersonaSpec
  @Prop isSelected: boolean
  onChipClick: (agentId: string) => void = () => {}

  getStageColor(stageType: string): ThemeColor {
    switch (stageType) {
      case 'early':
        return Colors.stage.early
      case 'turning-point':
        return Colors.stage.turningPoint
      case 'crisis':
        return Colors.stage.crisis
      case 'rebuild':
        return Colors.stage.rebuild
      case 'peak':
        return Colors.stage.peak
      default:
        return Colors.stage.default
    }
  }

  build() {
    Column() {
      Column({ space: 4 }) {
        Text(this.agent.stageLabel)
          .fontSize(Typography.size.bodyLg)
          .fontWeight(this.isSelected ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.isSelected ? Colors.textPrimary : Colors.textMuted)

        Text(this.agent.timeLabel)
          .fontSize(Typography.size.caption)
          .fontColor(Colors.textMuted)
      }
      .width('100%')
      .padding({
        left: Spacing.card.large,
        right: Spacing.card.large,
        top: Spacing.card.medium,
        bottom: Spacing.card.medium
      })
      .backgroundColor(this.isSelected ? Colors.cardSecondary : Colors.cardPrimary)
      .border({
        width: 1,
        color: this.isSelected ? LiquidGlass.borderStrong : LiquidGlass.border,
        radius: BorderRadius.huge
      })
      .backdropBlur(8)
      .borderRadius(BorderRadius.huge)
      .shadow({
        radius: this.isSelected ? 22 : 14,
        color: this.isSelected ? 'rgba(0, 0, 0, 0.36)' : 'rgba(0, 0, 0, 0.24)',
        offsetX: 0,
        offsetY: this.isSelected ? 10 : 6
      })
    }
    .width('auto')
    .backgroundColor(Color.Transparent)
    .borderRadius(BorderRadius.huge)
    .scale({
      x: this.isSelected ? 1.05 : 1,
      y: this.isSelected ? 1.05 : 1
    })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      this.onChipClick(this.agent.agentId)
    })
  }
}

// AgentChipList 组件属性
export interface AgentChipListProps {
  agents: PersonaSpec[]
  selectedAgentIds: string[]
}

// AgentChipList 组件 - 清新风格人格标签列表
@Component
export struct AgentChipList {
  @Prop agents: PersonaSpec[] = []
  @Prop selectedAgentIds: string[] = []
  onToggleAgent: (agentId: string) => void = () => {}

  build() {
    if (this.agents.length > 0) {
      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
        ForEach(this.agents, (agent: PersonaSpec) => {
          AgentChip({
            agent: agent,
            isSelected: this.selectedAgentIds.includes(agent.agentId),
            onChipClick: (agentId: string) => {
              this.onToggleAgent(agentId)
            }
          })
          .margin({ right: Spacing.sm, bottom: Spacing.sm })
        }, (agent: PersonaSpec) => agent.agentId)
      }
      .width('100%')
    } else {
      Text('去角色页选择至少 2 个阶段人格后，这里会显示参会阵容。')
        .fontSize(Typography.size.bodyLg)
        .fontColor(Colors.textTertiary)
        .lineHeight(Typography.lineHeight.relaxed)
        .padding(Spacing.card.large)
        .backgroundColor(Colors.cardPrimary)
        .borderRadius(BorderRadius.huge)
        .border({
          width: 1,
          color: LiquidGlass.border,
          radius: BorderRadius.huge
        })
    }
  }
}
