import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { common } from '@kit.AbilityKit'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { PersonaApi } from '../service/PersonaApi'
import { ProfileImportStore } from '../utils/ProfileImportStore'
import { Colors, LiquidGlass } from '../common/styles/Colors'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { ImportForm, BackButton, AnimatedCloudMascot, DynamicGlassBackground } from '../components'

@Entry
@Component
struct ImportProfilePage {
  @State private safeTopVp: number = 0
  @State private safeBottomVp: number = 0
  @State private importFormExpanded: boolean = true
  @State private importName: string = ''
  @State private importBio: string = ''
  @State private loading: string = ''
  @State private pressedSubmitHint: boolean = false
  @State private pressedGuideTag: string = ''

  aboutToAppear(): void {
    this.loadSafeInsets()
  }

  private getHostContext(): common.UIAbilityContext | null {
    const hostContext = this.getUIContext().getHostContext()
    if (hostContext) {
      return hostContext as common.UIAbilityContext
    }
    return null
  }

  private loadSafeInsets(): void {
    const ctx = this.getHostContext()
    if (!ctx) {
      return
    }
    fetchSafeAreaInsets(ctx).then((insets) => {
      this.safeTopVp = insets.topVp
      this.safeBottomVp = insets.bottomVp
    }).catch((_error: Error) => {
    })
  }

  private showToast(message: string): void {
    try {
      void promptAction.openToast({ message })
    } catch (_error) {
    }
  }

  private normalizeError(error: Object): string {
    const maybeError = error as Record<string, string>
    if (maybeError.message) {
      return maybeError.message
    }
    return '导入失败，请稍后再试'
  }

  private back(): void {
    router.back()
  }

  private helperTags(): Array<string> {
    return ['人物经历', '关键阶段', '关系变化', '长期目标']
  }

  private async submitImport(): Promise<void> {
    if (!this.importName.trim() || this.importBio.trim().length < 10) {
      this.showToast('请输入人物名称，并填写至少 10 个字的传记内容')
      return
    }

    this.loading = `正在解析 ${this.importName} 的时间线并构建人格体...`
    try {
      const bundle = await PersonaApi.importCustomProfile(this.importName.trim(), this.importBio.trim())
      ProfileImportStore.setPendingBundle(bundle)
      this.loading = ''
      this.showToast('导入完成')
      this.back()
    } catch (error) {
      this.loading = ''
      this.showToast(this.normalizeError(error as Object))
    }
  }

  @Builder
  private buildHeader() {
    Row() {
      BackButton({
        buttonSize: 40,
        iconSize: 18,
        iconColor: Colors.textPrimary,
        bgColor: '#FFFFFF',
        customBorderColor: 'rgba(226, 232, 240, 0.92)',
        customOnClick: () => {
          this.back()
        }
      })

      Blank()
    }
    .width('100%')
    .padding({
      left: Spacing.page.horizontal,
      right: Spacing.page.horizontal,
      top: this.safeTopVp + 6,
      bottom: 8
    })
  }

  @Builder
  private buildHero() {
    Column({ space: 16 }) {
      Row({ space: 14 }) {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(86)
            .height(86)
            .borderRadius(43)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                ['rgba(233, 242, 255, 0.96)', 0],
                ['rgba(205, 226, 255, 0.90)', 1]
              ]
            })
            .shadow({
              radius: 18,
              color: 'rgba(161, 190, 232, 0.20)',
              offsetX: 0,
              offsetY: 10
            })

          Column()
            .width(64)
            .height(18)
            .borderRadius(10)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                ['rgba(255, 255, 255, 0.92)', 0],
                ['rgba(255, 255, 255, 0.12)', 1]
              ]
            })
            .translate({ x: -5, y: -26 })

          AnimatedCloudMascot({
            mascotSize: 82,
            mood: 'happy',
            enableFloat: false,
            enableBlink: false,
            backgroundGlow: false,
            motionLevel: 'still'
          })
        }
        .width(94)
        .height(94)

        Column({ space: 7 }) {
          Text('导入资料')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .fontFamily('HarmonyOS Sans SC')

          Text('把人物素材整理成可立即使用的角色。')
            .fontSize(13)
            .fontColor(Colors.textSecondary)
            .lineHeight(19)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.helperTags(), (item: string) => {
          Text(item)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textSecondary)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(LiquidGlass.surfaceStrong)
            .borderRadius(18)
            .border({
              width: 1,
              color: this.pressedGuideTag === item ? LiquidGlass.borderStrong : LiquidGlass.border,
              radius: 18
            })
            .margin({ right: 8, bottom: 8 })
            .scale({
              x: this.pressedGuideTag === item ? 0.97 : 1,
              y: this.pressedGuideTag === item ? 0.97 : 1
            })
            .animation({
              duration: 160,
              curve: Curve.FastOutSlowIn
            })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.pressedGuideTag = item
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.pressedGuideTag = ''
              }
            })
        }, (item: string) => item)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 18 })
    .backgroundColor(Colors.cardPrimary)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        ['rgba(255, 255, 255, 0.99)', 0],
        ['rgba(247, 251, 255, 0.98)', 0.58],
        ['rgba(241, 247, 255, 0.95)', 1]
      ]
    })
    .border({
      width: 1.2,
      color: Colors.border,
      radius: 30
    })
    .borderRadius(30)
    .shadow({
      radius: 18,
      color: 'rgba(155, 184, 224, 0.10)',
      offsetX: 0,
      offsetY: 10
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      DynamicGlassBackground()

      Column() {
        this.buildHeader()

        Scroll() {
          Column({ space: 16 }) {
            this.buildHero()

            Column({ space: 14 }) {
              ImportForm({
                isExpanded: this.importFormExpanded,
                name: this.importName,
                bio: this.importBio,
                isLoading: this.loading.length > 0,
                importMode: 'import',
                showCloseButton: false,
                onNameChange: (value: string) => {
                  this.importName = value
                },
                onBioChange: (value: string) => {
                  this.importBio = value
                },
                onSubmit: () => {
                  void this.submitImport()
                },
                onToggle: () => {
                  this.importFormExpanded = !this.importFormExpanded
                },
                onClose: () => {
                }
              })

              Text('完成后会自动回到首页，并把新角色加入当前工作区。')
                .fontSize(12)
                .fontColor(Colors.textMuted)
                .lineHeight(18)
                .width('100%')
                .scale({
                  x: this.pressedSubmitHint ? 0.985 : 1,
                  y: this.pressedSubmitHint ? 0.985 : 1
                })
                .animation({
                  duration: 180,
                  curve: Curve.FastOutSlowIn
                })
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.pressedSubmitHint = true
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.pressedSubmitHint = false
                  }
                })
            }
            .width('100%')
            .padding({ left: 18, right: 18, top: 18, bottom: 18 })
            .backgroundColor(Colors.cardSecondary)
            .border({
              width: 1,
              color: Colors.borderLight,
              radius: BorderRadius.xxl3
            })
            .borderRadius(BorderRadius.xxl3)
            .shadow({
              radius: 14,
              color: 'rgba(151, 178, 218, 0.08)',
              offsetX: 0,
              offsetY: 8
            })
          }
          .width('100%')
          .padding({
            left: Spacing.page.horizontal,
            right: Spacing.page.horizontal,
            top: 2,
            bottom: 36 + this.safeBottomVp
          })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
    }
  }
}
