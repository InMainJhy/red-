import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { PresetProfile } from '../common/Models'

// RoleCard 组件属性
export interface RoleCardProps {
  profile: PresetProfile
  isActive: boolean
}

// 角色头像颜色映射
const AVATAR_COLORS: Record<string, string[]> = {
  'steve-jobs': ['#DBEAFE', '#BFDBFE', '#93C5FD'],
  'qin-shihuang': ['#FEE2E2', '#FECACA', '#FCA5A5'],
  'zhang-fei': ['#DCFCE7', '#BBF7D0', '#86EFAC'],
  'lu-bufeng': ['#F3E8FF', '#E9D5FF', '#DDD6FE'],
  'luo-yonghao': ['#FEF3C7', '#FDE68A', '#FCD34D'],
  'zhang-yiming': ['#CFFAFE', '#A5F3FC', '#67E8F9'],
  'default': ['#F1F5F9', '#E2E8F0', '#CBD5E1']
}

// RoleCard 组件 - 清新风格角色列表卡片（设计稿：头像 + 文案 + 更多菜单）
@Component
export struct RoleCard {
  @Prop profile: PresetProfile
  @Prop isActive: boolean
  @State private isPressed: boolean = false
  onCardClick: (profile: PresetProfile) => void = () => {}
  onViewTimeline: () => void = () => {}

  // 获取角色头像颜色
  getAvatarGradient(): string[] {
    return AVATAR_COLORS[this.profile.id] || AVATAR_COLORS['default']
  }

  // 获取角色姓氏
  getAvatarChar(): string {
    const name = this.profile.displayName
    return name.length > 0 ? name.charAt(0) : '?'
  }

  build() {
    Stack({ alignContent: Alignment.End }) {
      // 卡片主体
      Row({ space: Spacing.card.medium }) {
        Row({ space: Spacing.card.large }) {
          // 头像 - 带渐变背景
          Column() {
            Stack({ alignContent: Alignment.Center }) {
              // 背景渐变圆
              Column()
                .width(50)
                .height(50)
                .borderRadius(25)
                .linearGradient({
                  direction: GradientDirection.Bottom,
                  colors: [[this.getAvatarGradient()[0], 0], [this.getAvatarGradient()[1], 1]]
                })

              // 头像文字
              Text(this.getAvatarChar())
                .fontSize(Typography.size.subtitle)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isActive ? '#FFFFFF' : Colors.primary)
            }
          }
          .shadow({
            radius: 8,
            color: 'rgba(0, 0, 0, 0.08)',
            offsetX: 0,
            offsetY: 3
          })

          // 角色信息
          Column({ space: 6 }) {
            Text(this.profile.displayName)
              .fontSize(Typography.size.subtitle)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.profile.subtitle)
              .fontSize(Typography.size.caption)
              .fontColor(Colors.textTertiary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            // 分类标签
            Row({ space: 4 }) {
              Column()
                .width(4)
                .height(4)
                .borderRadius(2)
                .backgroundColor(Colors.primary)

              Text(this.profile.category)
                .fontSize(Typography.size.xs)
                .fontColor(Colors.textMuted)
            }
            .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .layoutWeight(1)
        .onClick(() => {
          this.onCardClick(this.profile)
        })
      }
      .width('100%')
      .padding(Spacing.card.large)
      .backgroundColor(this.isActive ? Colors.cardSecondary : Colors.cardPrimary)
      .borderRadius(BorderRadius.huge)
      .border({
        width: this.isActive ? 1.5 : 0.5,
        color: this.isActive ? 'rgba(99, 102, 241, 0.3)' : 'rgba(255, 255, 255, 0.6)',
        radius: BorderRadius.huge
      })
      .shadow({
        radius: this.isActive ? 24 : 10,
        color: this.isActive ? 'rgba(99, 102, 241, 0.12)' : 'rgba(0, 0, 0, 0.04)',
        offsetX: 0,
        offsetY: this.isActive ? 6 : 3
      })
      .scale({
        x: this.isPressed ? 0.98 : 1,
        y: this.isPressed ? 0.98 : 1
      })
      .animation({
        duration: 200,
        curve: Curve.EaseOut
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.isPressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false
        }
      })

      // 更多菜单（设计稿右侧三点）
      Column() {
        Text('⋮')
          .fontSize(22)
          .fontColor(Colors.textMuted)
          .fontWeight(FontWeight.Bold)
      }
      .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.md, bottom: Spacing.md })
      .hitTestBehavior(HitTestMode.Block)
      .bindMenu([
        {
          value: '查看时间线',
          action: (): void => {
            this.onViewTimeline()
          }
        }
      ])
    }
    .width('100%')
  }
}
