import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { PresetProfile } from '../common/Models'
import {
  AnimationDuration,
  AnimationCurve
} from '../common/styles/Animation'

export interface RoleCardProps {
  profile: PresetProfile
  isActive: boolean
  index?: number
}

const AVATAR_COLORS: Record<string, string[]> = {
  'jobs': ['#DBEAFE', '#BFDBFE', '#93C5FD'],
  'steve-jobs': ['#DBEAFE', '#BFDBFE', '#93C5FD'],
  'qin': ['#FEE2E2', '#FECACA', '#FCA5A5'],
  'qin-shihuang': ['#FEE2E2', '#FECACA', '#FCA5A5'],
  'graduate': ['#DCFCE7', '#BBF7D0', '#86EFAC'],
  'zhang-yiming': ['#CFFAFE', '#A5F3FC', '#67E8F9'],
  'default': ['#F1F5F9', '#E2E8F0', '#CBD5E1']
}

@Component
export struct RoleCard {
  @Prop profile: PresetProfile
  @Prop isActive: boolean
  @Prop index: number = 0
  @State private isPressed: boolean = false
  @State private cardOpacity: number = 0
  @State private cardTranslateY: number = 30
  @State private avatarScale: number = 0.5
  @State private contentOpacity: number = 0
  onCardClick: (profile: PresetProfile) => void = () => {}
  onViewTimeline: () => void = () => {}

  aboutToAppear(): void {
    const delay = this.index * 60

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.bounce
      }, () => {
        this.avatarScale = 1
      })
    }, delay)

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.emphasized
      }, () => {
        this.cardOpacity = 1
        this.cardTranslateY = 0
      })
    }, delay + 90)

    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.emphasized
      }, () => {
        this.contentOpacity = 1
      })
    }, delay + 170)
  }

  private getAvatarGradient(): string[] {
    return AVATAR_COLORS[this.profile.id] || AVATAR_COLORS['default']
  }

  private getAvatarChar(): string {
    const name = this.profile.displayName
    return name.length > 0 ? name.charAt(0) : '?'
  }

  private getCategoryLabel(): string {
    const labels: Record<string, string> = {
      'self': '自我',
      'celebrity': '名人',
      'history': '历史',
      'fictional': '虚构'
    }
    return labels[this.profile.category] || this.profile.category
  }

  private getHighlightPreview(): string[] {
    return this.profile.highlights.slice(0, 2)
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column({ space: Spacing.md }) {
        Row({ space: Spacing.card.medium }) {
          Row({ space: Spacing.card.large }) {
            Column() {
              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(56)
                  .height(56)
                  .borderRadius(28)
                  .linearGradient({
                    direction: GradientDirection.Bottom,
                    colors: [
                      [this.getAvatarGradient()[0], 0],
                      [this.getAvatarGradient()[1], 0.55],
                      [this.getAvatarGradient()[2], 1]
                    ]
                  })

                Column()
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .backgroundColor(this.isActive ? 'rgba(99, 102, 241, 0.18)' : 'rgba(255, 255, 255, 0.55)')

                Text(this.getAvatarChar())
                  .fontSize(Typography.size.subtitle)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.isActive ? '#FFFFFF' : Colors.primary)
              }
            }
            .scale({
              x: this.avatarScale,
              y: this.avatarScale
            })
            .animation({
              duration: AnimationDuration.slow,
              curve: AnimationCurve.bounce
            })
            .shadow({
              radius: this.isActive ? 14 : 10,
              color: this.isActive ? 'rgba(99, 102, 241, 0.18)' : 'rgba(15, 23, 42, 0.08)',
              offsetX: 0,
              offsetY: this.isActive ? 5 : 3
            })

            Column({ space: 7 }) {
              Row({ space: Spacing.xs }) {
                Text(this.profile.displayName)
                  .fontSize(Typography.size.subtitle)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Colors.textPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)

                if (this.isActive) {
                  Text('已选')
                    .fontSize(Typography.size.xs)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Colors.primary)
                    .padding({
                      left: Spacing.sm,
                      right: Spacing.sm,
                      top: 3,
                      bottom: 3
                    })
                    .backgroundColor('rgba(99, 102, 241, 0.10)')
                    .borderRadius(BorderRadius.pill)
                }
              }
              .width('100%')
              .opacity(this.contentOpacity)
              .translate({ x: this.contentOpacity > 0 ? 0 : -10 })

              Text(this.profile.subtitle)
                .fontSize(Typography.size.caption)
                .fontColor(Colors.textTertiary)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .lineHeight(18)
                .opacity(this.contentOpacity)
                .translate({ x: this.contentOpacity > 0 ? 0 : -8 })

              Row({ space: 6 }) {
                Row({ space: 4 }) {
                  Column()
                    .width(4)
                    .height(4)
                    .borderRadius(2)
                    .backgroundColor(Colors.primary)

                  Text(this.getCategoryLabel())
                    .fontSize(Typography.size.xs)
                    .fontColor(Colors.textSecondary)
                }
                .padding({
                  left: Spacing.sm,
                  right: Spacing.sm,
                  top: 4,
                  bottom: 4
                })
                .backgroundColor('rgba(99, 102, 241, 0.08)')
                .borderRadius(BorderRadius.pill)

                if (this.profile.suggestedTopics.length > 0) {
                  Text('可发起讨论')
                    .fontSize(Typography.size.xs)
                    .fontColor(Colors.textMuted)
                    .padding({
                      left: Spacing.sm,
                      right: Spacing.sm,
                      top: 4,
                      bottom: 4
                    })
                    .backgroundColor('rgba(241, 245, 249, 0.85)')
                    .borderRadius(BorderRadius.pill)
                }
              }
              .opacity(this.contentOpacity)
              .translate({ x: this.contentOpacity > 0 ? 0 : -6 })
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

        if (this.getHighlightPreview().length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.getHighlightPreview(), (item: string) => {
              Text(item)
                .fontSize(Typography.size.xs)
                .fontColor(Colors.textSecondary)
                .padding({
                  left: Spacing.sm,
                  right: Spacing.sm,
                  top: 4,
                  bottom: 4
                })
                .backgroundColor('rgba(255, 255, 255, 0.78)')
                .borderRadius(BorderRadius.chip)
                .margin({ right: Spacing.xs, bottom: Spacing.xs })
            }, (item: string) => item)
          }
          .width('100%')
          .opacity(this.contentOpacity)
        }
      }
      .width('100%')
      .padding(Spacing.card.large)
      .backgroundColor(this.isActive ? 'rgba(255, 255, 255, 0.92)' : Colors.cardPrimary)
      .borderRadius(BorderRadius.huge)
      .border({
        width: this.isActive ? 1.5 : 1,
        color: this.isActive ? 'rgba(99, 102, 241, 0.26)' : 'rgba(255, 255, 255, 0.72)',
        radius: BorderRadius.huge
      })
      .shadow({
        radius: this.isActive ? 24 : (this.isPressed ? 8 : 12),
        color: this.isActive ? 'rgba(99, 102, 241, 0.14)' : (this.isPressed ? 'rgba(15, 23, 42, 0.06)' : 'rgba(15, 23, 42, 0.05)'),
        offsetX: 0,
        offsetY: this.isActive ? 8 : (this.isPressed ? 2 : 4)
      })
      .scale({
        x: this.isPressed ? 0.985 : 1,
        y: this.isPressed ? 0.985 : 1
      })
      .animation({
        duration: AnimationDuration.fast,
        curve: AnimationCurve.emphasized
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.isPressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false
        }
      })

      Row() {
        Text('⋯')
          .fontSize(20)
          .fontColor(Colors.textMuted)
          .fontWeight(FontWeight.Bold)
      }
      .width(30)
      .height(30)
      .backgroundColor('rgba(255, 255, 255, 0.70)')
      .borderRadius(15)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: Spacing.sm, right: Spacing.sm })
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
    .opacity(this.cardOpacity)
    .translate({ x: 0, y: this.cardTranslateY })
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.emphasized
    })
  }
}
