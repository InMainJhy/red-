import { common } from '@kit.AbilityKit'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { MintColors } from '../common/styles/MintColors'
import { Typography } from '../common/styles/Typography'
import { BorderRadius } from '../common/styles/BorderRadius'
import { Spacing } from '../common/styles/Spacing'
import { AnimationDuration, AnimationCurve } from '../common/styles/Animation'
import { Icon, IconType } from '../components/CustomIcon'
import { PersonaApi } from '../service/PersonaApi'

const FALLBACK_SAFE_TOP_VP: number = 52

interface TabItem {
  title: string
  iconType: IconType
}

interface MockWeChatRecord {
  id: string
  contactName: string
  title: string
  preview: string
  biography: string
}

interface AIDialogMessage {
  id: string
  sender: string
  text: string
}

const MOCK_WECHAT_RECORDS: MockWeChatRecord[] = [
  {
    id: 'dad',
    contactName: '爸爸',
    title: '爸爸（家庭群）.txt',
    preview: '“别太拼，注意按时吃饭。工作是做不完的，人要先顾好自己。”',
    biography: '爸爸的聊天记录显示他是典型务实型长辈，表达克制但非常关心家人。常提醒作息、饮食和财务规划，价值观偏稳定与责任，遇事先考虑风险和长期后果。说话简短直接，但会在细节处给支持。'
  },
  {
    id: 'mom',
    contactName: '妈妈',
    title: '妈妈（私聊）.txt',
    preview: '“今天降温了，多穿一件。你忙的时候也要记得回我一句平安。”',
    biography: '妈妈的聊天记录体现出高情绪敏感与照料倾向，擅长通过日常问候建立安全感。沟通温柔细腻，关注身体状态和情绪波动，处理冲突时更倾向安抚与协商。人物特征偏共情、耐心、重家庭联结。'
  },
  {
    id: 'boyfriend',
    contactName: '男朋友',
    title: '男朋友（置顶聊天）.txt',
    preview: '“你想冲就冲，我在。要是累了我们就先停一下，慢慢来。”',
    biography: '男朋友的聊天记录呈现出陪伴型与鼓励型特征，表达风格轻松直接，注重“同频沟通”和及时反馈。面对压力议题时偏支持探索，强调尊重个人选择，同时具备一定行动导向和问题拆解能力。'
  }
]

const AI_PERSONALITY_QUESTIONS: string[] = [
  '当计划被临时打乱时，你通常会怎么做？',
  '在团队讨论中，你更常扮演推动决策的人，还是倾听协调的人？',
  '面对长期压力时，你一般靠什么方式恢复状态？'
]

@Entry
@Component
export struct CreateRole {
  @State private currentTab: number = 0
  @State private roleName: string = ''
  @State private biography: string = ''
  @State private isLoading: boolean = false
  @State private pageEntered: boolean = false
  @State private safeTopVp: number = 0
  @State private safeBottomVp: number = 0

  @State private contentOpacity: number = 0
  @State private contentTranslateY: number = 30
  @State private showWeChatPicker: boolean = false
  @State private selectedWeChatRecordId: string = ''
  @State private showAIDialogueModal: boolean = false
  @State private aiInputText: string = ''
  @State private aiMessages: AIDialogMessage[] = []
  @State private aiStep: number = 0
  @State private aiQuestionIndex: number = 0
  @State private aiNameAnswer: string = ''
  @State private aiBackgroundAnswer: string = ''
  @State private aiPersonalityAnswers: string[] = []
  @State private aiConversationDone: boolean = false

  aboutToAppear(): void {
    this.loadSafeInsets()
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.emphasized
      }, () => {
        this.pageEntered = true
        this.contentOpacity = 1
        this.contentTranslateY = 0
      })
    }, 100)
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

  goBack(): void {
    animateTo({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.decelerated
    }, () => {
      router.back()
    })
  }

  switchTab(index: number): void {
    animateTo({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.emphasized
    }, () => {
      this.currentTab = index
    })
  }

  createRole(): void {
    if (!this.roleName.trim()) {
      promptAction.showToast({ message: '请输入人物名称' })
      return
    }

    if (!this.biography.trim() || this.biography.length < 10) {
      promptAction.showToast({ message: '请输入至少10个字符的人物描述' })
      return
    }

    this.isLoading = true

    PersonaApi.importCustomProfile(this.roleName.trim(), this.biography.trim())
      .then((bundle) => {
        promptAction.showToast({ message: '角色创建成功！' })
        router.pushUrl({
          url: 'pages/ProfileDetail',
          params: {
            profileId: bundle.profile.id
          }
        })
      })
      .catch((error: Error) => {
        promptAction.showToast({ message: `创建失败: ${error.message}` })
      })
      .finally(() => {
        this.isLoading = false
      })
  }

  uploadWeChat(): void {
    this.showWeChatPicker = true
  }

  closeWeChatPicker(): void {
    this.showWeChatPicker = false
  }

  selectMockWeChatRecord(record: MockWeChatRecord): void {
    this.selectedWeChatRecordId = record.id
    this.roleName = record.contactName
    this.biography = record.biography
    this.currentTab = 0
    this.showWeChatPicker = false
    promptAction.showToast({ message: `已选择 ${record.title}` })
  }

  getSelectedWeChatRecord(): MockWeChatRecord | null {
    const found = MOCK_WECHAT_RECORDS.find((item: MockWeChatRecord) => item.id === this.selectedWeChatRecordId)
    return found ? found : null
  }

  getSelectedWeChatRecordTitle(): string {
    const selected = this.getSelectedWeChatRecord()
    return selected ? selected.title : ''
  }

  startAIDialogue(): void {
    this.showAIDialogueModal = true
    this.aiInputText = ''
    this.aiMessages = []
    this.aiStep = 0
    this.aiQuestionIndex = 0
    this.aiNameAnswer = ''
    this.aiBackgroundAnswer = ''
    this.aiPersonalityAnswers = []
    this.aiConversationDone = false
    this.appendAIMessage('你好，我会帮你生成角色画像。我们先从姓名开始，请告诉我这个角色的姓名。')
  }

  closeAIDialogueModal(): void {
    this.showAIDialogueModal = false
  }

  appendAIMessage(text: string): void {
    const next: AIDialogMessage = {
      id: `ai-${this.aiMessages.length + 1}`,
      sender: 'ai',
      text
    }
    this.aiMessages = [...this.aiMessages, next]
  }

  appendUserMessage(text: string): void {
    const next: AIDialogMessage = {
      id: `user-${this.aiMessages.length + 1}`,
      sender: 'user',
      text
    }
    this.aiMessages = [...this.aiMessages, next]
  }

  submitAIDialogueInput(): void {
    const text = this.aiInputText.trim()
    if (!text) {
      promptAction.showToast({ message: '请输入内容后再发送' })
      return
    }

    this.appendUserMessage(text)
    this.aiInputText = ''

    if (this.aiStep === 0) {
      this.aiNameAnswer = text
      this.roleName = text
      this.aiStep = 1
      this.appendAIMessage(`好的，${text}。接下来请介绍一下 Ta 的背景经历（成长环境、关键事件、关系状态等）。`)
      return
    }

    if (this.aiStep === 1) {
      this.aiBackgroundAnswer = text
      this.aiStep = 2
      this.aiQuestionIndex = 0
      this.appendAIMessage('收到。最后我会通过 3 个简短性格测试题来补全人格。')
      this.appendAIMessage(`1/3 ${AI_PERSONALITY_QUESTIONS[0]}`)
      return
    }

    if (this.aiStep === 2) {
      this.aiPersonalityAnswers = [...this.aiPersonalityAnswers, text]
      if (this.aiQuestionIndex < AI_PERSONALITY_QUESTIONS.length - 1) {
        this.aiQuestionIndex = this.aiQuestionIndex + 1
        const nextIndex = this.aiQuestionIndex + 1
        this.appendAIMessage(`${nextIndex}/3 ${AI_PERSONALITY_QUESTIONS[this.aiQuestionIndex]}`)
        return
      }

      this.aiStep = 3
      this.aiConversationDone = true
      this.biography = this.buildAIBiography()
      this.currentTab = 0
      promptAction.showToast({ message: 'AI对话已完成，信息已回填' })
      this.closeAIDialogueModal()
    }
  }

  buildAIBiography(): string {
    const personalitySummary = this.buildPersonalitySummary()
    const answerSummary = this.aiPersonalityAnswers.map((item: string, index: number) => {
      return `Q${index + 1}: ${item}`
    }).join('；')

    const composed = `${this.aiBackgroundAnswer}\n\n【性格画像】${personalitySummary}\n【测试回答】${answerSummary}`
    if (composed.length > 500) {
      return `${composed.slice(0, 496)}...`
    }
    return composed
  }

  buildPersonalitySummary(): string {
    const answers = this.aiPersonalityAnswers.join('；')
    if (answers.includes('计划') || answers.includes('安排') || answers.includes('清单')) {
      return '偏理性规划型，重视秩序与执行。'
    }
    if (answers.includes('沟通') || answers.includes('协调') || answers.includes('倾听')) {
      return '偏共情协调型，重视关系和氛围。'
    }
    if (answers.includes('行动') || answers.includes('尝试') || answers.includes('直接')) {
      return '偏行动探索型，倾向快速试错与推进。'
    }
    return '性格较均衡，兼具思考、共情与行动能力。'
  }

  getNameInitial(): string {
    return this.roleName.length > 0 ? this.roleName.charAt(0) : '?'
  }

  getTabIconColor(index: number, isActive: boolean): string {
    if (!isActive) {
      return MintColors.textMuted
    }
    if (index === 1) {
      return MintColors.lavender
    }
    if (index === 2) {
      return MintColors.mintDark
    }
    return MintColors.mint
  }

  getIllustrationBgColor(): string {
    if (this.currentTab === 1) {
      return MintColors.lavenderPale
    }
    return MintColors.mintBg
  }

  getIllustrationOrbColor(): string {
    if (this.currentTab === 1) {
      return MintColors.lavenderBg
    }
    if (this.currentTab === 2) {
      return MintColors.lavenderPale
    }
    return MintColors.mintPale
  }

  getIllustrationIconColor(): string {
    return this.getTabIconColor(this.currentTab, true)
  }

  getIllustrationAccentIcon(offset: number): IconType {
    const tabItems = this.getTabItems()
    return tabItems[(this.currentTab + offset) % tabItems.length].iconType
  }

  @Builder
  buildHeroIllustration() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(130)
          .height(130)
          .fill(this.getIllustrationBgColor())

        Circle()
          .width(90)
          .height(90)
          .fill(this.getIllustrationOrbColor())

        Column() {
          Icon({
            iconType: this.getTabItems()[this.currentTab].iconType,
            iconSize: 34,
            iconColor: this.getIllustrationIconColor()
          })
        }
        .width(58)
        .height(58)
        .backgroundColor('rgba(255, 255, 255, 0.68)')
        .borderRadius(29)
        .border({
          width: 0.5,
          color: 'rgba(255, 255, 255, 0.88)',
          radius: 29
        })
        .backdropBlur(18)
        .shadow({
          radius: 18,
          color: 'rgba(78, 205, 196, 0.12)',
          offsetX: 0,
          offsetY: 6
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Icon({
            iconType: this.getIllustrationAccentIcon(1),
            iconSize: 16,
            iconColor: MintColors.lavenderDark
          })
        }
        .width(28)
        .height(28)
        .backgroundColor('rgba(255, 255, 255, 0.72)')
        .borderRadius(14)
        .shadow({
          radius: 10,
          color: 'rgba(184, 169, 217, 0.14)',
          offsetX: 0,
          offsetY: 4
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .position({ x: 86, y: 18 })

        Column() {
          Icon({
            iconType: this.getIllustrationAccentIcon(2),
            iconSize: 14,
            iconColor: MintColors.mintDark
          })
        }
        .width(24)
        .height(24)
        .backgroundColor('rgba(255, 255, 255, 0.72)')
        .borderRadius(12)
        .shadow({
          radius: 10,
          color: 'rgba(78, 205, 196, 0.10)',
          offsetX: 0,
          offsetY: 4
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .position({ x: 18, y: 78 })
      }
      .margin({ top: Spacing.lg })

      Text('创建专属角色')
        .fontSize(Typography.size.xxl)
        .fontWeight(Typography.weight.bold)
        .fontColor(MintColors.textPrimary)
        .margin({ top: Spacing.md })

      Text('通过文字描绘、聊天记录或 AI 对话，让角色设定更完整也更有质感。')
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textMuted)
        .textAlign(TextAlign.Center)
        .margin({ top: Spacing.xs })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEnhancedTabIcon(item: TabItem, index: number, isActive: boolean) {
    Icon({
      iconType: item.iconType,
      iconSize: 18,
      iconColor: this.getTabIconColor(index, isActive)
    })
      .margin({ bottom: 4 })
  }

  @Builder
  buildWeChatUploadCard() {
    Column({ space: Spacing.md }) {
      Column({ space: Spacing.md }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(100)
            .height(100)
            .fill(MintColors.lavenderPale)

          Column() {
            Icon({
              iconType: 'chat',
              iconSize: 38,
              iconColor: MintColors.lavender
            })
          }
          .width(56)
          .height(56)
          .backgroundColor('rgba(255, 255, 255, 0.68)')
          .borderRadius(28)
          .border({
            width: 0.5,
            color: 'rgba(255, 255, 255, 0.88)',
            radius: 28
          })
          .shadow({
            radius: 14,
            color: 'rgba(184, 169, 217, 0.14)',
            offsetX: 0,
            offsetY: 4
          })
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: Spacing.sm }) {
          Text('上传微信聊天记录')
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Text('系统会分析对话内容，提取人物特征，帮助你快速生成更真实的角色画像。')
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .padding({ left: Spacing.lg, right: Spacing.lg })
      }
      .width('100%')
      .padding({ top: Spacing.xl, bottom: Spacing.xl })
      .backgroundColor(MintColors.cardPrimary)
      .borderRadius(BorderRadius.xxl)
      .border({
        width: 0.5,
        color: MintColors.border,
        radius: BorderRadius.xxl
      })

      Button('选择聊天记录文件')
        .width('100%')
        .height(50)
        .fontSize(Typography.size.bodyLg)
        .fontColor(MintColors.lavender)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(MintColors.lavenderBg)
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 0.5,
          color: MintColors.border,
          radius: BorderRadius.xxl
        })
        .onClick(() => this.uploadWeChat())

      if (this.selectedWeChatRecordId.length > 0) {
        Row({ space: Spacing.xs }) {
          Icon({
            iconType: 'check',
            iconSize: 14,
            iconColor: MintColors.mintDark
          })
          Text(`已选择：${this.getSelectedWeChatRecordTitle()}`)
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.mintDark)
        }
        .padding({
          left: Spacing.sm,
          right: Spacing.sm,
          top: 6,
          bottom: 6
        })
        .backgroundColor(MintColors.mintPale)
        .borderRadius(BorderRadius.pill)
      }

      Row() {
        Text('支持格式：')
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textMuted)

        Text('.txt')
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.lavender)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: Spacing.xs })
    }
  }

  @Builder
  buildAIDialogueCard() {
    Column({ space: Spacing.md }) {
      Column({ space: Spacing.md }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(100)
            .height(100)
            .fill(MintColors.mintBg)

          Column() {
            Icon({
              iconType: 'ai',
              iconSize: 38,
              iconColor: MintColors.mintDark
            })
          }
          .width(56)
          .height(56)
          .backgroundColor('rgba(255, 255, 255, 0.68)')
          .borderRadius(28)
          .border({
            width: 0.5,
            color: 'rgba(255, 255, 255, 0.88)',
            radius: 28
          })
          .shadow({
            radius: 14,
            color: 'rgba(78, 205, 196, 0.14)',
            offsetX: 0,
            offsetY: 4
          })
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: Spacing.sm }) {
          Text('AI 智能对话创建')
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Text('通过 AI 对话逐步补全背景、性格和表达方式，让角色设定更自然也更完整。')
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .padding({ left: Spacing.lg, right: Spacing.lg })
      }
      .width('100%')
      .padding({ top: Spacing.xl, bottom: Spacing.xl })
      .backgroundColor(MintColors.cardPrimary)
      .borderRadius(BorderRadius.xxl)
      .border({
        width: 0.5,
        color: MintColors.border,
        radius: BorderRadius.xxl
      })

      Button('开始 AI 对话')
        .width('100%')
        .height(50)
        .fontSize(Typography.size.bodyLg)
        .fontColor(MintColors.mintDark)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(MintColors.mintBg)
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 0.5,
          color: MintColors.border,
          radius: BorderRadius.xxl
        })
        .onClick(() => this.startAIDialogue())
    }
  }

  getTabItems(): TabItem[] {
    return [
      { title: '手动输入', iconType: 'edit' },
      { title: '微信记录', iconType: 'chat' },
      { title: 'AI对话', iconType: 'ai' }
    ]
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景
      Column() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(MintColors.background)

        // 右上薄荷光晕
        Column()
          .width(260)
          .height(180)
          .borderRadius(130)
          .backgroundColor('rgba(78, 205, 196, 0.1)')
          .blur(70)
          .position({ x: '55%', y: -60 })

        // 左下淡紫光晕
        Column()
          .width(220)
          .height(160)
          .borderRadius(110)
          .backgroundColor('rgba(184, 169, 217, 0.1)')
          .blur(60)
          .position({ x: -60, y: '65%' })

        // 底部装饰线
        Column()
          .width('100%')
          .height(2)
          .linearGradient({
            direction: GradientDirection.Left,
            colors: [
              [MintColors.lavenderPale, 0.0],
              [MintColors.mintPale, 0.5],
              [MintColors.lavenderPale, 1.0]
            ]
          })
          .position({ y: '100%' })
      }
      .width('100%')
      .height('100%')

      // 返回按钮
      Button() {
        Icon({
          iconType: 'arrowLeft',
          iconSize: 16,
          iconColor: MintColors.mintDark
        })
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
      .onClick(() => this.goBack())

      Scroll() {
        Column({ space: Spacing.md }) {
          this.buildHeroIllustration()
          this.buildTabSelector()
          this.buildContentArea()
          this.buildCreateButton()
        }
        .padding({
          left: Spacing.page.horizontal,
          right: Spacing.page.horizontal,
          top: this.topInsetVp() + 60,
          bottom: Spacing.page.bottom + 100 + this.safeBottomVp
        })
      }
      .width('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      if (this.showWeChatPicker) {
        this.buildMockWeChatPicker()
      }

      if (this.showAIDialogueModal) {
        this.buildAIDialogueModal()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MintColors.background)
    .opacity(this.contentOpacity)
    .translate({ x: 0, y: this.contentTranslateY })
  }

  @Builder
  buildMockWeChatPicker() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(15, 23, 42, 0.36)')
        .onClick(() => this.closeWeChatPicker())

      Column({ space: Spacing.md }) {
        Row() {
          Text('选择微信聊天记录')
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)
          Blank()
          Text('模拟数据')
            .fontSize(Typography.size.xs)
            .fontColor(MintColors.lavenderDark)
            .padding({
              left: Spacing.sm,
              right: Spacing.sm,
              top: 4,
              bottom: 4
            })
            .backgroundColor(MintColors.lavenderPale)
            .borderRadius(BorderRadius.pill)
        }
        .width('100%')

        Text('请选择要导入的聊天对象，系统会自动提取人物画像用于创建角色。')
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textSecondary)
          .width('100%')

        Column({ space: Spacing.sm }) {
          ForEach(MOCK_WECHAT_RECORDS, (item: MockWeChatRecord) => {
            Column({ space: 6 }) {
              Row() {
                Text(item.contactName)
                  .fontSize(Typography.size.bodyLg)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(MintColors.textPrimary)
                Blank()
                Text(item.title)
                  .fontSize(Typography.size.xs)
                  .fontColor(MintColors.textMuted)
              }
              .width('100%')

              Text(item.preview)
                .fontSize(Typography.size.caption)
                .fontColor(MintColors.textSecondary)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding(Spacing.md)
            .backgroundColor(MintColors.surface)
            .borderRadius(BorderRadius.xl)
            .border({
              width: 0.5,
              color: MintColors.border,
              radius: BorderRadius.xl
            })
            .onClick(() => this.selectMockWeChatRecord(item))
          }, (item: MockWeChatRecord) => item.id)
        }
        .width('100%')

        Button('取消')
          .width('100%')
          .height(44)
          .fontSize(Typography.size.body)
          .fontColor(MintColors.textSecondary)
          .backgroundColor(MintColors.backgroundSecondary)
          .borderRadius(BorderRadius.xxl)
          .onClick(() => this.closeWeChatPicker())
      }
      .width('88%')
      .padding(Spacing.card.large)
      .backgroundColor(MintColors.cardPrimary)
      .borderRadius(BorderRadius.xxl)
      .border({
        width: 0.5,
        color: MintColors.border,
        radius: BorderRadius.xxl
      })
      .shadow({
        radius: 26,
        color: 'rgba(15, 23, 42, 0.12)',
        offsetX: 0,
        offsetY: 10
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildAIDialogueModal() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(15, 23, 42, 0.36)')
        .onClick(() => this.closeAIDialogueModal())

      Column({ space: Spacing.md }) {
        Row() {
          Text('AI 角色访谈')
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)
          Blank()
          Button('关闭')
            .height(30)
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.textSecondary)
            .backgroundColor(MintColors.backgroundSecondary)
            .borderRadius(BorderRadius.pill)
            .onClick(() => this.closeAIDialogueModal())
        }
        .width('100%')

        Scroll() {
          Column({ space: Spacing.sm }) {
            ForEach(this.aiMessages, (item: AIDialogMessage) => {
              Row() {
                if (item.sender === 'ai') {
                  Row() {
                    Text(item.text)
                      .fontSize(Typography.size.body)
                      .fontColor(MintColors.textPrimary)
                  }
                  .padding(Spacing.sm)
                  .backgroundColor(MintColors.background)
                  .borderRadius(BorderRadius.xl)
                  Blank()
                } else {
                  Blank()
                  Row() {
                    Text(item.text)
                      .fontSize(Typography.size.body)
                      .fontColor('#FFFFFF')
                  }
                  .padding(Spacing.sm)
                  .backgroundColor(MintColors.mintDark)
                  .borderRadius(BorderRadius.xl)
                }
              }
              .width('100%')
            }, (item: AIDialogMessage) => item.id)
          }
          .width('100%')
        }
        .width('100%')
        .height(300)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)

        Row({ space: Spacing.xs }) {
          TextInput({
            text: this.aiInputText,
            placeholder: this.aiConversationDone ? '对话已完成' : '输入你的回答...'
          })
            .layoutWeight(1)
            .height(42)
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textPrimary)
            .placeholderColor(MintColors.textPlaceholder)
            .backgroundColor(MintColors.surface)
            .borderRadius(BorderRadius.xxl)
            .padding({ left: Spacing.md, right: Spacing.md })
            .onChange((value: string) => {
              this.aiInputText = value
            })

          Button(this.aiConversationDone ? '完成' : '发送')
            .height(42)
            .fontSize(Typography.size.caption)
            .fontColor('#FFFFFF')
            .backgroundColor(this.aiConversationDone ? MintColors.textMuted : MintColors.mint)
            .borderRadius(BorderRadius.xxl)
            .onClick(() => {
              if (this.aiConversationDone) {
                this.closeAIDialogueModal()
              } else {
                this.submitAIDialogueInput()
              }
            })
        }
        .width('100%')
      }
      .width('90%')
      .padding(Spacing.card.large)
      .backgroundColor(MintColors.cardPrimary)
      .borderRadius(BorderRadius.xxl)
      .border({
        width: 0.5,
        color: MintColors.border,
        radius: BorderRadius.xxl
      })
      .shadow({
        radius: 26,
        color: 'rgba(15, 23, 42, 0.12)',
        offsetX: 0,
        offsetY: 10
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildIllustration() {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(130)
          .height(130)
          .fill(MintColors.mintBg)

        Circle()
          .width(90)
          .height(90)
          .fill(MintColors.lavenderPale)

        // 装饰星星
        Column() {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(MintColors.mint)
        }
        .position({ x: 46, y: 12 })

        Column() {
          Column()
            .width(5)
            .height(5)
            .borderRadius(2.5)
            .backgroundColor(MintColors.lavender)
        }
        .position({ x: 16, y: 55 })

        Column() {
          Column()
            .width(5)
            .height(5)
            .borderRadius(2.5)
            .backgroundColor(MintColors.mintDark)
        }
        .position({ x: 90, y: 65 })

        Column() {
          Column()
            .width(4)
            .height(4)
            .borderRadius(2)
            .backgroundColor(MintColors.lavenderDark)
        }
        .position({ x: 54, y: 92 })
      }
      .margin({ top: Spacing.lg })

      Text('创建专属角色')
        .fontSize(Typography.size.xxl)
        .fontWeight(Typography.weight.bold)
        .fontColor(MintColors.textPrimary)
        .margin({ top: Spacing.md })

      Text('通过文字描绘、AI对话或聊天记录')
        .fontSize(Typography.size.body)
        .fontColor(MintColors.textMuted)
        .margin({ top: Spacing.xs })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildTabSelector() {
    Row() {
      ForEach(this.getTabItems(), (item: TabItem, index: number) => {
        Column() {
          this.buildEnhancedTabIcon(item, index, this.currentTab === index)

          Text(item.title)
            .fontSize(Typography.size.caption)
            .fontColor(this.currentTab === index ? MintColors.mintDark : MintColors.textMuted)
        }
        .padding({
          left: Spacing.md,
          right: Spacing.md,
          top: Spacing.sm,
          bottom: Spacing.sm
        })
        .backgroundColor(this.currentTab === index ? MintColors.mintBg : 'transparent')
        .borderRadius(BorderRadius.xxl)
        .onClick(() => this.switchTab(index))
        .animation({
          duration: AnimationDuration.fast,
          curve: AnimationCurve.emphasized
        })
      }, (item: TabItem) => item.title)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .backgroundColor(MintColors.surfaceGlass)
    .borderRadius(BorderRadius.xxl)
    .padding({ top: Spacing.xs, bottom: Spacing.xs })
  }

  @Builder
  buildTabIcon(iconType: string, isActive: boolean) {
    if (iconType === 'edit') {
      Column() {
        Column()
          .width(16)
          .height(2)
          .backgroundColor(isActive ? MintColors.mint : MintColors.textMuted)
          .borderRadius(1)
        Column()
          .width(2)
          .height(14)
          .backgroundColor(isActive ? MintColors.mint : MintColors.textMuted)
          .borderRadius(1)
          .position({ x: 6, y: -8 })
      }
      .width(20)
      .height(20)
      .margin({ bottom: 4 })
      .rotate({ angle: -45 })
    } else if (iconType === 'chat') {
      Column() {
        Column()
          .width(18)
          .height(12)
          .backgroundColor(isActive ? MintColors.lavender : MintColors.textMuted)
          .borderRadius(3)
        Column()
          .width(0)
          .height(0)
          .borderWidth({
            top: 4,
            left: 3,
            right: 5
          })
          .borderColor({
            top: isActive ? MintColors.lavender : MintColors.textMuted,
            left: isActive ? MintColors.lavender : MintColors.textMuted,
            right: Color.Transparent
          })
          .position({ x: -3, y: 8 })
      }
      .width(20)
      .height(20)
      .margin({ bottom: 4 })
    } else if (iconType === 'ai') {
      Column() {
        Column()
          .width(14)
          .height(10)
          .backgroundColor(isActive ? MintColors.mintDark : MintColors.textMuted)
          .borderRadius(3)
        Column()
          .width(10)
          .height(6)
          .backgroundColor(isActive ? MintColors.mintDark : MintColors.textMuted)
          .borderRadius(3)
          .position({ y: -2 })
      }
      .width(20)
      .height(20)
      .margin({ bottom: 4 })
    }
  }

  @Builder
  buildContentArea() {
    Column({ space: Spacing.md }) {
      if (this.currentTab === 0) {
        this.buildManualForm()
      } else if (this.currentTab === 1) {
        this.buildWeChatUploadCard()
      } else {
        this.buildAIDialogueCard()
      }
    }
  }

  @Builder
  buildManualForm() {
    Column({ space: Spacing.md }) {
      Column({ space: Spacing.xs }) {
        Text('人物名称')
          .fontSize(Typography.size.bodyLg)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.textPrimary)

        TextInput({ placeholder: '请输入角色名称', text: this.roleName })
          .width('100%')
          .height(50)
          .fontSize(Typography.size.bodyLg)
          .fontColor(MintColors.textPrimary)
          .placeholderFont({ size: Typography.size.body })
          .placeholderColor(MintColors.textPlaceholder)
          .backgroundColor(MintColors.surface)
          .borderRadius(BorderRadius.xxl)
          .border({ width: 0.5, color: MintColors.border })
          .padding({ left: Spacing.md, right: Spacing.md })
          .onChange((value: string) => {
            this.roleName = value
          })
      }

      Column({ space: Spacing.xs }) {
        Row() {
          Text('人物传记')
            .fontSize(Typography.size.bodyLg)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.textPrimary)

          Blank()

          Text(`${this.biography.length}/500`)
            .fontSize(Typography.size.caption)
            .fontColor(MintColors.textMuted)
        }
        .width('100%')

        TextArea({ placeholder: '请描述角色的背景、性格、特点...', text: this.biography })
          .width('100%')
          .height(140)
          .fontSize(Typography.size.bodyLg)
          .fontColor(MintColors.textPrimary)
          .placeholderFont({ size: Typography.size.body })
          .placeholderColor(MintColors.textPlaceholder)
          .backgroundColor(MintColors.surface)
          .borderRadius(BorderRadius.xxl)
          .border({ width: 0.5, color: MintColors.border })
          .padding(Spacing.md)
          .maxLength(500)
          .onChange((value: string) => {
            this.biography = value
          })
      }
    }
  }

  @Builder
  buildWeChatUpload() {
    Column({ space: Spacing.md }) {
      Column({ space: Spacing.md }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(100)
            .height(100)
            .fill(MintColors.lavenderPale)

          Column() {
            Column()
              .width(36)
              .height(28)
              .backgroundColor(MintColors.lavender)
              .borderRadius(8)
            Column()
              .width(0)
              .height(0)
              .borderWidth({
                top: 8,
                left: 6,
                right: 10
              })
              .borderColor({
                top: MintColors.lavender,
                left: MintColors.lavender,
                right: Color.Transparent
              })
              .position({ x: -6, y: 22 })
          }
          .width(50)
          .height(50)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: Spacing.sm }) {
          Text('上传微信聊天记录')
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Text('系统将分析聊天内容，提取对方特征，生成角色画像')
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .padding({ left: Spacing.lg, right: Spacing.lg })
      }
      .width('100%')
      .padding({ top: Spacing.xl, bottom: Spacing.xl })
      .backgroundColor(MintColors.cardPrimary)
      .borderRadius(BorderRadius.xxl)
      .border({
        width: 0.5,
        color: MintColors.border,
        radius: BorderRadius.xxl
      })

      Button('选择聊天记录文件')
        .width('100%')
        .height(50)
        .fontSize(Typography.size.bodyLg)
        .fontColor(MintColors.lavender)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(MintColors.lavenderBg)
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 0.5,
          color: MintColors.border,
          radius: BorderRadius.xxl
        })
        .onClick(() => this.uploadWeChat())

      Row() {
        Text('支持格式：')
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.textMuted)

        Text('.txt')
          .fontSize(Typography.size.caption)
          .fontColor(MintColors.lavender)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: Spacing.xs })
    }
  }

  @Builder
  buildAIDialogue() {
    Column({ space: Spacing.md }) {
      Column({ space: Spacing.md }) {
        Stack({ alignContent: Alignment.Center }) {
          Circle()
            .width(100)
            .height(100)
            .fill(MintColors.mintBg)

          Column() {
            Column()
              .width(32)
              .height(22)
              .backgroundColor(MintColors.mint)
              .borderRadius(6)
            Column()
              .width(18)
              .height(14)
              .backgroundColor(MintColors.mint)
              .borderRadius(7)
              .position({ y: -4 })
          }
          .width(50)
          .height(50)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: Spacing.sm }) {
          Text('AI智能对话创建')
            .fontSize(Typography.size.subtitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(MintColors.textPrimary)

          Text('通过与AI对话交流，逐步塑造角色形象，系统将根据对话内容生成角色')
            .fontSize(Typography.size.body)
            .fontColor(MintColors.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .padding({ left: Spacing.lg, right: Spacing.lg })
      }
      .width('100%')
      .padding({ top: Spacing.xl, bottom: Spacing.xl })
      .backgroundColor(MintColors.cardPrimary)
      .borderRadius(BorderRadius.xxl)
      .border({
        width: 0.5,
        color: MintColors.border,
        radius: BorderRadius.xxl
      })

      Button('开始AI对话')
        .width('100%')
        .height(50)
        .fontSize(Typography.size.bodyLg)
        .fontColor(MintColors.mintDark)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(MintColors.mintBg)
        .borderRadius(BorderRadius.xxl)
        .border({
          width: 0.5,
          color: MintColors.border,
          radius: BorderRadius.xxl
        })
        .onClick(() => this.startAIDialogue())
    }
  }

  @Builder
  buildCreateButton() {
    Button() {
      Row() {
        if (this.isLoading) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#FFFFFF')
          Text('创建中...')
            .fontSize(Typography.size.bodyLg)
            .fontColor('#FFFFFF')
            .margin({ left: Spacing.sm })
        } else {
          Text('创建角色')
            .fontSize(Typography.size.bodyLg)
            .fontColor('#FFFFFF')
        }
      }
    }
    .width('100%')
    .height(52)
    .backgroundColor(this.roleName.trim() ? MintColors.mint : MintColors.backgroundSecondary)
    .borderRadius(BorderRadius.xxl)
    .shadow({
      radius: 16,
      color: 'rgba(78, 205, 196, 0.2)',
      offsetX: 0,
      offsetY: 6
    })
    .enabled(this.roleName.trim().length > 0 && !this.isLoading)
    .onClick(() => this.createRole())
  }
}
