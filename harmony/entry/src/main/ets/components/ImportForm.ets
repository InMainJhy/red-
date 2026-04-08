import { Colors } from '../common/styles/Colors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'

// ImportForm 组件属性
export interface ImportFormProps {
  isExpanded: boolean
  name: string
  bio: string
  isLoading: boolean
  importMode: string
  showCloseButton: boolean
}

// ImportForm 组件 - 清新风格导入表单（创造新识 / 寻访前人）
@Component
export struct ImportForm {
  @Prop isExpanded: boolean = false
  @Prop name: string = ''
  @Prop bio: string = ''
  @Prop isLoading: boolean = false
  /** create：创造新识；import：寻访前人 */
  @Prop importMode: string = 'import'
  @Prop showCloseButton: boolean = false
  @State private isPressed: boolean = false
  onNameChange: (value: string) => void = () => {}
  onBioChange: (value: string) => void = () => {}
  onSubmit: () => void = () => {}
  onToggle: () => void = () => {}
  onClose: () => void = () => {}

  private getPanelTitle(): string {
    return this.importMode === 'create' ? '创造新识' : '寻访前人'
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

  build() {
    Column({ space: Spacing.card.large }) {
      // 头部
      Row() {
        // 标题装饰
        Column()
          .width(3)
          .height(32)
          .borderRadius(1.5)
          .backgroundColor(this.importMode === 'create' ? '#6366F1' : '#10B981')

        Column({ space: 4 }) {
          Text(this.getPanelTitle())
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textSecondary)
          Text(this.getPanelSubtitle())
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textTertiary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ left: Spacing.sm })

        if (this.showCloseButton) {
          Text('关闭')
            .fontSize(Typography.size.caption)
            .fontColor(Colors.textMuted)
            .padding({ left: Spacing.sm, right: Spacing.sm, top: Spacing.xs, bottom: Spacing.xs })
            .onClick(() => {
              this.onClose()
            })
        }

        Button(this.getToggleLabel())
          .height(32)
          .fontSize(Typography.size.xs)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isExpanded ? '#FFFFFF' : Colors.textSecondary)
          .backgroundColor(this.isExpanded ? '#6366F1' : Colors.tagBg)
          .borderRadius(BorderRadius.pill)
          .shadow({
            radius: this.isExpanded ? 10 : 6,
            color: this.isExpanded ? 'rgba(99, 102, 241, 0.15)' : 'rgba(0, 0, 0, 0.03)',
            offsetX: 0,
            offsetY: 2
          })
          .onClick(() => {
            this.onToggle()
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 展开表单
      if (this.isExpanded) {
        Column({ space: Spacing.card.large }) {
          // 名称输入
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
              width: 1,
              color: Colors.borderLight,
              radius: BorderRadius.xxl
            })
            .padding({ left: Spacing.card.medium, right: Spacing.card.medium })
            .onChange((value: string) => {
              this.onNameChange(value)
            })

          // 传记输入
          TextArea({ text: this.bio, placeholder: '粘贴人物传记或背景描述（至少10个字）' })
            .width('100%')
            .height(100)
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
            .padding(Spacing.card.medium)
            .onChange((value: string) => {
              this.onBioChange(value)
            })

          // 底部操作
          Row() {
            Text(`${this.bio.length} / 2000 字`)
              .fontSize(Typography.size.xs)
              .fontColor(this.bio.length >= 10 ? Colors.success : Colors.textMuted)

            Blank()

            Button('解析传记并生成阶段人格')
              .width('auto')
              .height(40)
              .fontSize(Typography.size.sm)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor(this.canSubmit() ? '#6366F1' : Colors.textMuted)
              .borderRadius(BorderRadius.pill)
              .shadow({
                radius: this.canSubmit() ? 15 : 8,
                color: this.canSubmit() ? 'rgba(99, 102, 241, 0.2)' : 'rgba(0, 0, 0, 0.03)',
                offsetX: 0,
                offsetY: 4
              })
              .scale({
                x: this.isPressed ? 0.98 : 1,
                y: this.isPressed ? 0.98 : 1
              })
              .animation({
                duration: 150,
                curve: Curve.EaseOut
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
        }
        .width('100%')
        .padding(Spacing.card.large)
        .backgroundColor(Colors.cardPrimary)
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 1,
          color: Colors.borderLight,
          radius: BorderRadius.xxl
        })
        .transition(TransitionEffect.asymmetric(
          TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: -10 })),
          TransitionEffect.OPACITY.combine(TransitionEffect.translate({ y: -10 }))
        ).animation({
          duration: 250,
          curve: Curve.EaseOut
        }))
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
