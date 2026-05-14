import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import {
  AnimationDuration,
  AnimationCurve
} from '../common/styles/Animation'

export interface ImportFormProps {
  isExpanded: boolean
  name: string
  bio: string
  isLoading: boolean
  importMode: string
  showCloseButton: boolean
}

@Component
export struct ImportForm {
  @Prop isExpanded: boolean = false
  @Prop name: string = ''
  @Prop bio: string = ''
  @Prop isLoading: boolean = false
  @Prop importMode: string = 'import'
  @Prop showCloseButton: boolean = false
  @State private isPressed: boolean = false
  @State private formOpacity: number = 0
  @State private formTranslateY: number = 20
  @State private inputFocus1: boolean = false
  @State private inputFocus2: boolean = false
  onNameChange: (value: string) => void = () => {}
  onBioChange: (value: string) => void = () => {}
  onSubmit: () => void = () => {}
  onToggle: () => void = () => {}
  onClose: () => void = () => {}

  private getPanelTitle(): string {
    return this.importMode === 'create' ? '创造新识' : '探访前人'
  }

  private getPanelSubtitle(): string {
    return this.importMode === 'create' ? '定义一个全新的人格' : '导入已有的人物传记'
  }

  private getToggleLabel(): string {
    if (this.isExpanded) {
      return '收起'
    }
    return this.importMode === 'create' ? '填写信息' : '导入传记'
  }

  private canSubmit(): boolean {
    return this.name.trim().length > 0 && this.bio.trim().length >= 10 && !this.isLoading
  }

  private getAssistTags(): string[] {
    if (this.importMode === 'create') {
      return ['成长片段', '关键转折', '价值冲突']
    }
    return ['传记内容', '人物经历', '真实细节']
  }

  private getProgressWidth(): string {
    const ratio = Math.min(this.bio.trim().length / 140, 1)
    const width = Math.max(10, Math.round(ratio * 100))
    return `${width}%`
  }

  private getProgressLabel(): string {
    const length = this.bio.trim().length
    if (length < 10) {
      return '信息还不够完整'
    }
    if (length < 60) {
      return '已经可以生成阶段人格'
    }
    return '人物轮廓已经比较清晰'
  }

  aboutToAppear(): void {
    if (this.isExpanded) {
      setTimeout(() => {
        animateTo({
          duration: AnimationDuration.slow,
          curve: AnimationCurve.emphasized
        }, () => {
          this.formOpacity = 1
          this.formTranslateY = 0
        })
      }, 50)
    }
  }

  build() {
    Column({ space: Spacing.card.large }) {
      Row() {
        Row({ space: Spacing.sm }) {
          Column()
            .width(3)
            .height(32)
            .borderRadius(1.5)
            .backgroundColor(this.importMode === 'create' ? Colors.textPrimary : Colors.textPrimary)
            .scale({
              x: 1,
              y: this.isExpanded ? 1 : 0
            })
            .animation({
              duration: AnimationDuration.normal,
              curve: AnimationCurve.emphasized
            })

          Column({ space: 4 }) {
            Row({ space: Spacing.xs }) {
              Text(this.getPanelTitle())
                .fontSize(Typography.size.subtitle)
                .fontWeight(FontWeight.Bold)
                .fontColor(Colors.textPrimary)

              Text(this.importMode === 'create' ? 'NEW' : 'BIO')
                .fontSize(Typography.size.xs)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.importMode === 'create' ? Colors.accent : Colors.accent)
                .padding({
                  left: Spacing.sm,
                  right: Spacing.sm,
                  top: 3,
                  bottom: 3
                })
                .backgroundColor('rgba(225, 237, 255, 0.82)')
                .borderRadius(BorderRadius.pill)
            }

            Text(this.getPanelSubtitle())
              .fontSize(Typography.size.caption)
              .fontColor(Colors.textTertiary)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Row({ space: Spacing.xs }) {
          if (this.showCloseButton) {
            Text('关闭')
              .fontSize(Typography.size.caption)
              .fontColor(Colors.textMuted)
              .padding({
                left: Spacing.sm,
                right: Spacing.sm,
                top: Spacing.xs,
                bottom: Spacing.xs
              })
              .backgroundColor('rgba(247, 247, 243, 0.75)')
              .borderRadius(BorderRadius.pill)
              .onClick(() => {
                this.onClose()
              })
          }

          Button(this.getToggleLabel())
            .height(34)
            .fontSize(Typography.size.xs)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isExpanded ? '#FFFFFF' : Colors.textSecondary)
            .backgroundColor(this.isExpanded ? Colors.accent : Colors.tagBg)
            .borderRadius(BorderRadius.pill)
            .shadow({
              radius: this.isExpanded ? 12 : 8,
              color: this.isExpanded ? 'rgba(82, 117, 170, 0.22)' : 'rgba(159, 181, 218, 0.08)',
              offsetX: 0,
              offsetY: 4
            })
            .onClick(() => {
              this.onToggle()
            })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.isExpanded) {
        Column({ space: Spacing.card.large }) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.getAssistTags(), (item: string) => {
              Text(item)
                .fontSize(Typography.size.xs)
                .fontColor(Colors.textSecondary)
                .padding({
                  left: Spacing.sm,
                  right: Spacing.sm,
                  top: 4,
                  bottom: 4
                })
                .backgroundColor('rgba(250, 252, 255, 0.95)')
                .border({
                  width: 1,
                  color: 'rgba(220, 233, 251, 0.88)',
                  radius: BorderRadius.chip
                })
                .borderRadius(BorderRadius.chip)
                .margin({ right: Spacing.xs, bottom: Spacing.xs })
            }, (item: string) => item)
          }
          .width('100%')

          Column({ space: Spacing.sm }) {
            Text('人物名称')
              .fontSize(Typography.size.caption)
              .fontColor(Colors.textMuted)

            TextInput({ text: this.name, placeholder: '人物名称' })
              .width('100%')
              .height(48)
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
                width: this.inputFocus1 ? 2 : 1,
                color: this.inputFocus1 ? Colors.accent : Colors.borderLight,
                radius: BorderRadius.xxl
              })
              .shadow({
                radius: this.inputFocus1 ? 14 : 8,
                color: this.inputFocus1 ? 'rgba(121, 155, 211, 0.18)' : 'rgba(160, 181, 216, 0.06)',
                offsetX: 0,
                offsetY: 4
              })
              .padding({ left: Spacing.card.medium, right: Spacing.card.medium })
              .animation({
                duration: AnimationDuration.fast,
                curve: AnimationCurve.emphasized
              })
              .onFocus(() => {
                this.inputFocus1 = true
              })
              .onBlur(() => {
                this.inputFocus1 = false
              })
              .onChange((value: string) => {
                this.onNameChange(value)
              })
          }
          .width('100%')

          Column({ space: Spacing.sm }) {
            Row() {
              Text('人物传记 / 背景')
                .fontSize(Typography.size.caption)
                .fontColor(Colors.textMuted)

              Blank()

              Text(`${this.bio.length} / 2000`)
                .fontSize(Typography.size.xs)
                .fontColor(this.bio.length >= 10 ? Colors.success : Colors.textMuted)
            }
            .width('100%')

            TextArea({ text: this.bio, placeholder: '粘贴人物传记、背景描述或关键经历，至少 10 个字' })
              .width('100%')
              .height(118)
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
                width: this.inputFocus2 ? 2 : 1,
                color: this.inputFocus2 ? Colors.accent : Colors.borderLight,
                radius: BorderRadius.xxl
              })
              .shadow({
                radius: this.inputFocus2 ? 14 : 8,
                color: this.inputFocus2 ? 'rgba(121, 155, 211, 0.18)' : 'rgba(160, 181, 216, 0.06)',
                offsetX: 0,
                offsetY: 4
              })
              .padding(Spacing.card.medium)
              .animation({
                duration: AnimationDuration.fast,
                curve: AnimationCurve.emphasized
              })
              .onFocus(() => {
                this.inputFocus2 = true
              })
              .onBlur(() => {
                this.inputFocus2 = false
              })
              .onChange((value: string) => {
                this.onBioChange(value)
              })
          }
          .width('100%')

          Column({ space: Spacing.sm }) {
            Row() {
              Text(this.getProgressLabel())
                .fontSize(Typography.size.xs)
                .fontColor(this.bio.trim().length >= 10 ? Colors.success : Colors.textMuted)

              Blank()

              Text('越具体，切片越稳定')
                .fontSize(Typography.size.xs)
                .fontColor(Colors.textMuted)
            }
            .width('100%')

            Stack({ alignContent: Alignment.Start }) {
              Column()
                .width('100%')
                .height(6)
                .borderRadius(3)
                .backgroundColor('rgba(226, 232, 240, 0.65)')

              Column()
                .width(this.getProgressWidth())
                .height(6)
                .borderRadius(3)
                .linearGradient({
                  direction: GradientDirection.Right,
                  colors: [
                    ['rgba(116, 160, 228, 1)', 0],
                    ['rgba(46, 92, 167, 1)', 1]
                  ]
                })
            }
            .width('100%')
          }
          .width('100%')

          Row() {
            Text('建议写入关键事件、关系变化和长期目标')
              .fontSize(Typography.size.xs)
              .fontColor(Colors.textMuted)
              .layoutWeight(1)

            Button(this.isLoading ? '生成中...' : '解析传记并生成阶段人格')
              .width('auto')
              .height(42)
              .fontSize(Typography.size.sm)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textInverse)
              .backgroundColor(this.canSubmit() ? Colors.accent : Colors.textMuted)
              .borderRadius(BorderRadius.pill)
              .linearGradient(this.canSubmit() ? {
                direction: GradientDirection.Bottom,
                colors: [
                  ['rgba(62, 103, 177, 1)', 0],
                  ['rgba(26, 44, 73, 1)', 1]
                ]
              } : {
                direction: GradientDirection.Bottom,
                colors: [
                  ['rgba(132, 145, 163, 1)', 0],
                  ['rgba(103, 116, 134, 1)', 1]
                ]
              })
              .shadow({
                radius: this.canSubmit() ? 18 : 8,
                color: this.canSubmit() ? 'rgba(88, 125, 183, 0.26)' : 'rgba(0, 0, 0, 0.03)',
                offsetX: 0,
                offsetY: 6
              })
              .scale({
                x: this.isPressed ? 0.98 : 1,
                y: this.isPressed ? 0.98 : 1
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
              .enabled(this.canSubmit())
              .opacity(this.canSubmit() ? 1 : 0.6)
              .onClick(() => {
                this.onSubmit()
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding(Spacing.card.large)
        .backgroundColor(Colors.cardPrimary)
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['rgba(255, 255, 255, 0.99)', 0],
            ['rgba(247, 250, 255, 0.98)', 0.56],
            ['rgba(241, 247, 255, 0.95)', 1]
          ]
        })
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 1.1,
          color: Colors.border,
          radius: BorderRadius.xxl
        })
        .shadow({
          radius: 12,
          color: 'rgba(150, 178, 218, 0.08)',
          offsetX: 0,
          offsetY: 7
        })
        .opacity(this.formOpacity)
        .translate({ x: 0, y: this.formTranslateY })
        .animation({
          duration: AnimationDuration.slow,
          curve: AnimationCurve.emphasized
        })
        .transition(TransitionEffect.asymmetric(
          TransitionEffect.OPACITY
            .combine(TransitionEffect.translate({ y: -15 }))
            .animation({
              duration: AnimationDuration.normal,
              curve: AnimationCurve.decelerated
            }),
          TransitionEffect.OPACITY
            .combine(TransitionEffect.translate({ y: -15 }))
            .animation({
              duration: AnimationDuration.fast,
              curve: AnimationCurve.decelerated
            })
        ))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
