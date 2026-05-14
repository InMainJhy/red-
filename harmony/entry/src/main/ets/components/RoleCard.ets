import { Colors, LiquidGlass } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing, MobileSpacing } from '../common/styles/Spacing'
import { PresetProfile } from '../common/Models'
import {
  AnimationDuration,
  AnimationCurve
} from '../common/styles/Animation'
import { PersonaAvatar } from './PersonaAvatar'

export interface RoleCardProps {
  profile: PresetProfile
  isActive: boolean
  index?: number
}

const AVATAR_COLORS: Record<string, string[]> = {
  'jobs': ['#E6E4DE', '#C6C3BC', '#8A8983'],
  'steve-jobs': ['#E6E4DE', '#C6C3BC', '#8A8983'],
  'qin': ['#D9D4CC', '#B9B3AA', '#77736B'],
  'qin-shihuang': ['#D9D4CC', '#B9B3AA', '#77736B'],
  'graduate': ['#EAE8E1', '#C9C6BE', '#94918A'],
  'zhang-yiming': ['#F2F1ED', '#D8D4CB', '#A19D95'],
  'default': ['#E4E2DB', '#BDBAB3', '#73716C']
}

@Component
export struct RoleCard {
  @Prop public profile: PresetProfile
  @Prop public isActive: boolean
  @Prop public index: number = 0
  @State private isPressed: boolean = false
  @State private isHovered: boolean = false
  @State private cardOpacity: number = 0
  @State private cardTranslateY: number = 30
  @State private avatarScale: number = 0.5
  @State private contentOpacity: number = 0
  @State private avatarRotate: number = -15
  @State private highlightOpacity: number = 0
  public onCardClick: (profile: PresetProfile) => void = () => {}
  public onViewTimeline: () => void = () => {}

  aboutToAppear(): void {
    const delay = this.index * 60

    // 头像弹性入场
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slower,
        curve: Curve.FastOutSlowIn,
      }, () => {
        this.avatarScale = 1
        this.avatarRotate = 0
      })
    }, delay)

    // 卡片滑入
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: Curve.FastOutSlowIn
      }, () => {
        this.cardOpacity = 1
        this.cardTranslateY = 0
      })
    }, delay + 80)

    // 内容淡入
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.emphasized
      }, () => {
        this.contentOpacity = 1
      })
    }, delay + 150)

    // 高亮标签延迟出现
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.fast,
        curve: AnimationCurve.emphasized
      }, () => {
        this.highlightOpacity = 1
      })
    }, delay + 220)
  }

  private getAvatarGradient(): string[] {
    return AVATAR_COLORS[this.profile.id] || AVATAR_COLORS['default']
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
      Column({ space: MobileSpacing.md }) {
        Row({ space: MobileSpacing.card.medium }) {
          Row({ space: MobileSpacing.card.large }) {
            Column() {
              PersonaAvatar({
                personaId: this.profile.id,
                displayName: this.profile.displayName,
                coverSeed: this.profile.coverSeed,
                avatarSize: 40,
                highlighted: this.isActive,
                fallbackColors: this.getAvatarGradient()
              })
            }
            .scale({
              x: this.avatarScale,
              y: this.avatarScale
            })
            .rotate({
              angle: this.avatarRotate,
              centerX: '50%',
              centerY: '50%'
            })
            .shadow({
              radius: this.isActive ? 12 : (this.isHovered ? 8 : 6),
              color: this.isActive ? 'rgba(0, 0, 0, 0.16)' : 'rgba(0, 0, 0, 0.06)',
              offsetX: 0,
              offsetY: this.isActive ? 4 : (this.isHovered ? 3 : 2)
            })
            .animation({
              duration: AnimationDuration.normal,
              curve: Curve.FastOutSlowIn
            })

            Column({ space: 5 }) {
              Row({ space: MobileSpacing.xs }) {
                Text(this.profile.displayName)
                  .fontSize(Typography.size.bodyLg)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Colors.textPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)

                if (this.isActive) {
                  Text('已选')
                    .fontSize(Typography.size.xs)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Colors.accentAlt)
                    .padding({
                      left: MobileSpacing.xs,
                      right: MobileSpacing.xs,
                      top: 2,
                      bottom: 2
                    })
                    .backgroundColor(Colors.accent)
                    .borderRadius(BorderRadius.pill)
                }
              }
              .width('100%')
              .opacity(this.contentOpacity)
              .translate({ x: this.contentOpacity > 0 ? 0 : -10 })

              Text(this.profile.subtitle)
                .fontSize(Typography.size.xs)
                .fontColor(Colors.textSecondary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .lineHeight(14)
                .opacity(this.contentOpacity)
                .translate({ x: this.contentOpacity > 0 ? 0 : -8 })

              Row({ space: 5 }) {
                Row({ space: 3 }) {
                  Column()
                    .width(4)
                    .height(4)
                    .borderRadius(2)
                    .backgroundColor(Colors.accent)

                  Text(this.getCategoryLabel())
                    .fontSize(Typography.size.xs)
                    .fontColor(Colors.accentAlt)
                }
                .padding({
                  left: MobileSpacing.xs,
                  right: MobileSpacing.xs,
                  top: 3,
                  bottom: 3
                })
                .backgroundColor(Colors.accent)
                .borderRadius(BorderRadius.pill)
                .border({
                  width: 1,
                  color: Colors.accent,
                  radius: BorderRadius.pill
                })

                if (this.profile.suggestedTopics.length > 0) {
                  Text('可发起讨论')
                    .fontSize(Typography.size.xs)
                    .fontColor(Colors.textMuted)
                    .padding({
                      left: MobileSpacing.xs,
                      right: MobileSpacing.xs,
                      top: 3,
                      bottom: 3
                    })
                    .backgroundColor(LiquidGlass.surfaceMuted)
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
            ForEach(this.getHighlightPreview(), (item: string, idx: number) => {
              Text(item)
                .fontSize(Typography.size.xs)
                .fontColor(Colors.textSecondary)
                .padding({
                  left: MobileSpacing.xs,
                  right: MobileSpacing.xs,
                  top: 3,
                  bottom: 3
                })
                .backgroundColor(LiquidGlass.surfaceMuted)
                .borderRadius(BorderRadius.chip)
                .border({
                  width: 1,
                  color: LiquidGlass.border,
                  radius: BorderRadius.chip
                })
                .margin({ right: MobileSpacing.xs, bottom: MobileSpacing.xs })
                .opacity(this.highlightOpacity)
                .scale({
                  x: this.highlightOpacity,
                  y: this.highlightOpacity
                })
                .animation({
                  duration: AnimationDuration.normal,
                  curve: Curve.FastOutSlowIn,
                  delay: idx * 40
                })
            }, (item: string) => item)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding(MobileSpacing.card.medium)
      .backgroundColor(this.isActive ? 'rgba(255, 255, 255, 0.96)' : Colors.cardPrimary)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [
          [this.isActive ? 'rgba(255, 255, 255, 0.98)' : 'rgba(255, 255, 255, 0.96)', 0],
          [this.isActive ? 'rgba(239, 245, 253, 0.96)' : 'rgba(244, 248, 253, 0.92)', 0.64],
          [this.isActive ? 'rgba(232, 239, 249, 0.92)' : 'rgba(238, 244, 252, 0.88)', 1]
        ]
      })
      .borderRadius(BorderRadius.xxl2)
      .border({
        width: 1,
        color: this.isActive ? 'rgba(255, 255, 255, 0.76)' : 'rgba(255, 255, 255, 0.62)',
        radius: BorderRadius.xxl2
      })
      .shadow({
        radius: this.isActive ? 24 : (this.isPressed ? 10 : 18),
        color: this.isActive ? 'rgba(112, 134, 168, 0.18)' : (this.isPressed ? 'rgba(112, 134, 168, 0.10)' : 'rgba(112, 134, 168, 0.14)'),
        offsetX: 0,
        offsetY: this.isActive ? 8 : (this.isPressed ? 3 : 6)
      })
      .scale({
        x: this.isPressed ? 0.98 : 1,
        y: this.isPressed ? 0.98 : 1
      })
      .translate({
        x: 0,
        y: this.isPressed ? 2 : (this.isActive ? -2 : 0)
      })
      .animation({
        duration: AnimationDuration.fast,
        curve: Curve.Sharp
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          animateTo({
            duration: AnimationDuration.instant,
            curve: Curve.Sharp
          }, () => {
            this.isPressed = true
          })
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          animateTo({
            duration: AnimationDuration.fast,
            curve: Curve.FastOutSlowIn
          }, () => {
            this.isPressed = false
          })
        }
      })

      Row() {
        Text('⋯')
          .fontSize(16)
          .fontColor(Colors.textMuted)
          .fontWeight(FontWeight.Bold)
      }
      .width(24)
      .height(24)
      .backgroundColor('rgba(255, 255, 255, 0.54)')
      .border({
        width: 1,
        color: 'rgba(255, 255, 255, 0.68)',
        radius: 12
      })
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: MobileSpacing.xs, right: MobileSpacing.xs })
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
