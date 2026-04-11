/**
 * AI对话创建角色页面
 * 自由对话模式：用户可以随意对话，最后一键生成角色
 * 流程：开场问候 → 自由对话收集信息 → 随时结束 → 生成角色
 */
import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import promptAction from '@ohos.promptAction'
import { fetchSafeAreaInsets } from '../common/WindowSafeArea'
import { MintColors } from '../common/styles/MintColors'
import { BorderRadius } from '../common/styles/BorderRadius'
import { AnimationDuration, AnimationCurve } from '../common/styles/Animation'

const FALLBACK_SAFE_TOP_VP: number = 52

// 对话消息类型
interface ChatMessage {
  id: string
  role: 'user' | 'ai'
  content: string
  timestamp: number
  isTyping?: boolean
}

// AI回复模板（根据对话内容动态生成）
const AI_RESPONSES_NAME: string[] = [
  '很好！这个名字很有特点。继续告诉我更多关于这个角色的信息吧~',
  '明白了。还有什么其他信息可以帮助我更好地了解这个角色吗？',
]

const AI_RESPONSES_AGE: string[] = [
  '这个阶段正是人生观形成的关键时期。这个角色的性格大概是什么样的？',
  '正值壮年啊！这个角色在事业上有什么追求或目标吗？',
]

const AI_RESPONSES_JOB: string[] = [
  '职业选择往往反映一个人的价值观。这个角色在工作中最看重什么？',
  '这个领域很有趣。这个角色有没有经历过什么重大转折？',
]

const AI_RESPONSES_EXPERIENCE: string[] = [
  '这些经历塑造了独特的人格。你觉得这个角色内心深处最在乎什么？',
  '听起来是一段丰富的旅程。这个角色有什么一直坚持的信念吗？',
]

const AI_RESPONSES_VALUE: string[] = [
  '价值观决定了选择。这个角色在面临重大决定时会怎么思考？',
  '这些特质很有意思。这个角色有没有什么内心的恐惧或担忧？',
]

const AI_RESPONSES_FEAR: string[] = [
  '每个人都有软肋。这种恐惧会影响他/她的决策方式吗？',
  '理解了。这个角色在什么时候会感到最焦虑？',
]

const AI_RESPONSES_TOPIC: string[] = [
  '在这些话题上，这个角色通常会站在什么立场上？',
  '很好！现在我对这个角色有了比较清晰的了解。',
]

const AI_RESPONSES_DEFAULT: string[] = [
  '好的，还有什么补充的吗？或者我们可以开始创建角色了~',
  '明白了！你可以继续补充，或者点击下方「结束对话，创建角色」~',
  '继续说说吧，你描述得越详细，生成的角色就越立体~',
  '还有吗？如果信息足够了，可以直接结束对话~',
]

// 对话开场白
const WELCOME_MESSAGE = '你好！我是时间人格的AI助手。\n\n你可以随意描述你想创建的角色，我来帮你整理和提炼。\n\n比如：\n• 他/她叫什么名字？\n• 年龄、职业、性格？\n• 经历过什么重要的事情？\n• 有什么价值观或信念？\n\n想聊什么就聊什么，说完就可以创建角色~'

@Entry
@Component
export struct AIDialogueCreateRole {
  @State private messages: ChatMessage[] = []
  @State private userInput: string = ''
  @State private isAITyping: boolean = false
  @State private isGenerating: boolean = false
  @State private collectedKeywords: string[] = []
  @State private collectedSummary: string = ''
  @State private hasGeneratedResult: boolean = false

  @State private safeTopVp: number = 0
  @State private safeBottomVp: number = 0
  @State private pageEntered: boolean = false
  @State private contentOpacity: number = 0
  @State private inputAreaOpacity: number = 0
  @State private inputAreaTranslateY: number = 20
  @State private showEndButton: boolean = false
  @State private messageCount: number = 0

  private scrollController: Scroller = new Scroller()
  private typingTimer: number = -1

  aboutToAppear(): void {
    this.loadSafeInsets()
    setTimeout(() => {
      animateTo({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.emphasized
      }, () => {
        this.pageEntered = true
        this.contentOpacity = 1
      })
    }, 100)

    setTimeout(() => {
      this.startAIDialogue()
    }, 500)
  }

  aboutToDisappear(): void {
    if (this.typingTimer !== -1) {
      clearTimeout(this.typingTimer)
    }
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

  goBack(): void {
    animateTo({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.decelerated
    }, () => {
      router.back()
    })
  }

  startAIDialogue(): void {
    this.simulateAITyping(WELCOME_MESSAGE)
  }

  simulateAITyping(fullText: string): void {
    this.isAITyping = true

    const msgId = `msg_${Date.now()}`
    this.messages.push({
      id: msgId,
      role: 'ai',
      content: '',
      timestamp: Date.now(),
      isTyping: true
    })

    setTimeout(() => {
      this.scrollToBottom()
    }, 100)

    let currentIndex = 0
    const typeChar = () => {
      if (currentIndex < fullText.length) {
        const currentMsg = this.messages.find(m => m.id === msgId)
        if (currentMsg) {
          currentMsg.content = fullText.substring(0, currentIndex + 1)
          this.messages = [...this.messages]
        }
        currentIndex++
        const delay = this.getTypingDelay(fullText.charAt(currentIndex - 1))
        this.typingTimer = setTimeout(typeChar, delay)
      } else {
        const currentMsg = this.messages.find(m => m.id === msgId)
        if (currentMsg) {
          currentMsg.isTyping = false
          this.messages = [...this.messages]
        }
        this.isAITyping = false

        setTimeout(() => {
          animateTo({
            duration: AnimationDuration.normal,
            curve: AnimationCurve.emphasized
          }, () => {
            this.inputAreaOpacity = 1
            this.inputAreaTranslateY = 0
          })
        }, 200)

        this.scrollToBottom()
      }
    }

    setTimeout(typeChar, 300)
  }

  getTypingDelay(char: string): number {
    if (char === '\n') return 120
    if ('。！？!?'.includes(char)) return 100
    if (',，、:：;；'.includes(char)) return 60
    return 20 + Math.random() * 15
  }

  scrollToBottom(): void {
    try {
      this.scrollController.scrollToIndex(this.messages.length - 1, true)
    } catch (_e) {
      // 忽略滚动错误
    }
  }

  sendMessage(): void {
    if (!this.userInput.trim() || this.isAITyping) {
      return
    }

    const userText = this.userInput.trim()

    // 添加用户消息
    this.messages.push({
      id: `msg_${Date.now()}`,
      role: 'user',
      content: userText,
      timestamp: Date.now()
    })

    this.messageCount++
    this.collectedSummary += userText + '\n'
    this.extractKeywords(userText)

    this.userInput = ''

    // 隐藏输入区域
    animateTo({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.decelerated
    }, () => {
      this.inputAreaOpacity = 0
      this.inputAreaTranslateY = 20
    })

    // 显示结束按钮
    if (this.messageCount >= 2) {
      this.showEndButton = true
    }

    this.scrollToBottom()

    // AI回复
    setTimeout(() => {
      this.generateAIResponse(userText)
    }, 600)
  }

  generateAIResponse(userText: string): void {
    // 根据用户输入内容选择回复
    let responses: string[] = AI_RESPONSES_DEFAULT
    const lowerText = userText.toLowerCase()

    if (this.containsKeywords(lowerText, ['名字', '叫', '姓名', '名称'])) {
      responses = AI_RESPONSES_NAME
    } else if (this.containsKeywords(lowerText, ['岁', '年龄', '年'])) {
      responses = AI_RESPONSES_AGE
    } else if (this.containsKeywords(lowerText, ['工作', '职业', '职位', '岗位', '事业'])) {
      responses = AI_RESPONSES_JOB
    } else if (this.containsKeywords(lowerText, ['经历', '故事', '过去', '曾经', '毕业', '入职', '创业'])) {
      responses = AI_RESPONSES_EXPERIENCE
    } else if (this.containsKeywords(lowerText, ['相信', '认为', '坚持', '追求', '价值'])) {
      responses = AI_RESPONSES_VALUE
    } else if (this.containsKeywords(lowerText, ['害怕', '恐惧', '担心', '焦虑'])) {
      responses = AI_RESPONSES_FEAR
    } else if (this.containsKeywords(lowerText, ['话题', '关心', '关注', '讨论', '话题'])) {
      responses = AI_RESPONSES_TOPIC
    }

    // 随机选择一条回复
    const idx = Math.floor(Math.random() * responses.length)
    const response = responses[idx]
    this.simulateAITyping(response)
  }

  containsKeywords(text: string, keywords: string[]): boolean {
    return keywords.some(keyword => text.includes(keyword))
  }

  extractKeywords(text: string): void {
    const keywords = [
      '奋斗', '坚持', '创新', '责任', '成长', '突破', '努力', '上进',
      '稳健', '保守', '冒险', '激进', '平衡', '反思', '勇气', '智慧',
      '耐心', '果断', '诚信', '感恩', '自律', '独立', '自由',
      '家庭', '事业', '健康', '财富', '成功', '失败', '成长',
      '迷茫', '焦虑', '坚定', '困惑', '期待', '失望', '希望'
    ]

    for (const keyword of keywords) {
      if (text.includes(keyword) && !this.collectedKeywords.includes(keyword)) {
        this.collectedKeywords.push(keyword)
      }
    }
  }

  // 结束对话，创建角色
  endAndCreate(): void {
    if (this.isAITyping) {
      return
    }

    animateTo({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.decelerated
    }, () => {
      this.inputAreaOpacity = 0
      this.inputAreaTranslateY = 20
    })

    // 添加结束消息
    this.messages.push({
      id: `msg_${Date.now()}`,
      role: 'user',
      content: '好的，差不多了，帮我创建角色吧！',
      timestamp: Date.now()
    })

    this.scrollToBottom()

    // 模拟生成过程
    setTimeout(() => {
      const generatingText = '好的！让我根据我们的对话，整理角色的完整档案...\n\n🎭 正在分析对话内容...\n📝 正在提取关键特征...\n✨ 正在构建人格模型...'
      this.simulateAITyping(generatingText)

      setTimeout(() => {
        this.showGeneratedResult()
      }, 2500)
    }, 500)
  }

  showGeneratedResult(): void {
    this.hasGeneratedResult = true

    // 移除正在生成的消息
    if (this.messages.length > 0) {
      this.messages.pop()
    }

    const roleName = this.extractRoleName()
    const resultText = `✅ 角色档案已生成！\n\n【${roleName}】\n\n📋 角色特征：${this.collectedKeywords.slice(0, 6).join('、') || '独特性格'}\n\n💡 已根据对话整理了完整的角色信息，你可以在角色详情页查看~`

    this.simulateAITyping(resultText)

    // 显示操作按钮
    setTimeout(() => {
      this.messages.push({
        id: `msg_action_${Date.now()}`,
        role: 'ai',
        content: '点击下方「查看角色」进入详情，或「继续补充」完善角色信息~',
        timestamp: Date.now()
      })
      this.scrollToBottom()
    }, resultText.length * 25 + 500)
  }

  extractRoleName(): string {
    // 尝试从对话中提取角色名
    const patterns = [
      /名字[是叫]*(.+?)[，,。\n]/,
      /叫(.+?)[，,。\n]/,
      /(.+?)是.*[人角色家伙]/
    ]

    for (const pattern of patterns) {
      const match = this.collectedSummary.match(pattern)
      if (match && match[1]) {
        return match[1].trim().substring(0, 10)
      }
    }

    return '我的角色'
  }

  viewProfile(): void {
    promptAction.showToast({ message: '正在跳转至角色详情页...' })

    setTimeout(() => {
      router.pushUrl({
        url: 'pages/ProfileDetail',
        params: {
          profileId: 'ai-custom-' + Date.now()
        }
      })
    }, 500)
  }

  // 继续补充
  continueChat(): void {
    const responses = [
      '好的，继续说说吧~你还想补充什么？',
      '好的！继续描述这个角色吧~',
      '明白了，继续补充信息，越详细越好~'
    ]
    const response = responses[Math.floor(Math.random() * responses.length)]
    this.simulateAITyping(response)
  }

  // 重新开始
  restart(): void {
    animateTo({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.decelerated
    }, () => {
      this.messages = []
      this.collectedKeywords = []
      this.collectedSummary = ''
      this.userInput = ''
      this.showEndButton = false
      this.messageCount = 0
      this.inputAreaOpacity = 0
      this.inputAreaTranslateY = 20
    })

    setTimeout(() => {
      this.startAIDialogue()
    }, 300)
  }

  build(): void {
    Stack() {
      Column() {
        this.buildHeader()
        this.buildMessageCount()
        this.buildChatArea()
        this.buildInputArea()
        this.buildEndButton()
        this.buildActionButtons()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(MintColors.background)
      .opacity(this.contentOpacity)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildHeader(): void {
    Column() {
      Row() {
        Button() {
          Text('←')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(MintColors.textPrimary)
        }
        .width(44)
        .height(44)
        .backgroundColor(MintColors.surfaceGlass)
        .borderRadius(BorderRadius.lg)
        .onClick(() => this.goBack())

        Blank()

        Text('AI创建角色')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(MintColors.textPrimary)

        Blank()

        Row().width(44).height(44)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ top: this.safeTopVp, left: 16, right: 16, bottom: 8 })
    .backgroundColor(MintColors.background)
  }

  @Builder
  buildMessageCount(): void {
    if (this.messageCount > 0) {
      Row() {
        Text(`已对话 ${this.messageCount} 轮`)
          .fontSize(12)
          .fontColor(MintColors.textMuted)
        Blank()
        if (this.showEndButton && !this.isAITyping) {
          Text('随时可以结束')
            .fontSize(12)
            .fontColor(MintColors.mint)
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 4 })
    } else {
      Column().height(20)
    }
  }

  @Builder
  buildChatArea(): void {
    Scroll(this.scrollController) {
      Column() {
        ForEach(this.messages, (message: ChatMessage) => {
          this.buildMessageBubble(message)
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  buildMessageBubble(message: ChatMessage): void {
    if (message.role === 'user') {
      Row() {
        Blank()
        Column() {
          Text(message.content)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .lineHeight(22)
            .padding(12)
        }
        .constraintSize({ maxWidth: '75%' })
        .backgroundColor(MintColors.mint)
        .borderRadius({
          topLeft: BorderRadius.lg,
          topRight: BorderRadius.lg,
          bottomLeft: BorderRadius.lg,
          bottomRight: 4
        })
      }
      .width('100%')
      .margin({ top: 8, bottom: 8 })
    } else {
      Row() {
        // AI头像 - 使用SVG图标
        Image($r('app.media.ai_avatar_robot'))
          .width(36)
          .height(36)
          .borderRadius(18)
          .border({
            width: 1.5,
            color: MintColors.mintPale
          })
          .shadow({
            radius: 6,
            color: MintColors.mint,
            offsetX: 0,
            offsetY: 2
          })

        Column() {
          Text(message.content)
            .fontSize(15)
            .fontColor(MintColors.textPrimary)
            .lineHeight(22)
            .padding(12)
            .backgroundColor(MintColors.surface)
            .borderRadius({
              topLeft: 4,
              topRight: BorderRadius.lg,
              bottomLeft: BorderRadius.lg,
              bottomRight: BorderRadius.lg
            })

          // 打字指示器
          if (message.isTyping) {
            Row() {
              Row()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(MintColors.mint)
                .margin({ right: 3 })
              Row()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(MintColors.mint)
                .opacity(0.6)
                .margin({ right: 3 })
              Row()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(MintColors.mint)
                .opacity(0.3)
            }
            .margin({ top: 8 })
          }
        }
        .constraintSize({ maxWidth: '75%' })
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Top)
    }
  }

  @Builder
  buildInputArea(): void {
    Column() {
      Row() {
        TextInput({
          placeholder: '随便说说，比如：名字叫张三，35岁产品经理...',
          text: this.userInput
        })
          .placeholderColor(MintColors.textPlaceholder)
          .caretColor(MintColors.mint)
          .fontSize(15)
          .fontColor(MintColors.textPrimary)
          .backgroundColor(MintColors.surface)
          .borderRadius(BorderRadius.lg)
          .height(44)
          .layoutWeight(1)
          .padding({ left: 16, right: 12 })
          .onChange((value: string) => {
            this.userInput = value
          })
          .onSubmit(() => {
            this.sendMessage()
          })

        Button() {
          Text('发送')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.userInput.trim() ? '#FFFFFF' : MintColors.textMuted)
        }
        .height(44)
        .padding({ left: 20, right: 20 })
        .backgroundColor(this.userInput.trim() ? MintColors.mint : MintColors.backgroundSecondary)
        .borderRadius(BorderRadius.lg)
        .enabled(this.userInput.trim().length > 0)
        .onClick(() => {
          this.sendMessage()
        })
      }
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .backgroundColor(MintColors.background)
    .opacity(this.inputAreaOpacity)
    .translate({ y: this.inputAreaTranslateY })
    .padding({ bottom: 8 })
  }

  // 结束对话按钮
  @Builder
  buildEndButton(): void {
    if (this.showEndButton && !this.isAITyping && this.messageCount >= 2) {
      Column() {
        Button() {
          Row() {
            Text('✨')
              .fontSize(16)
              .margin({ right: 6 })
            Text('结束对话，创建角色')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
          }
        }
        .height(48)
        .width('100%')
        .backgroundColor(MintColors.mint)
        .borderRadius(BorderRadius.lg)
        .onClick(() => this.endAndCreate())
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })
    } else {
      Column().height(8)
    }
  }

  // 操作按钮区域
  @Builder
  buildActionButtons(): void {
    if (this.hasGeneratedResult && !this.isAITyping) {
      Column() {
        Row() {
          Button() {
            Row() {
              Text('📋')
                .fontSize(16)
                .margin({ right: 6 })
              Text('查看角色')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
            }
          }
          .height(48)
          .layoutWeight(1)
          .backgroundColor(MintColors.mint)
          .borderRadius(BorderRadius.lg)
          .margin({ right: 8 })
          .onClick(() => this.viewProfile())

          Button() {
            Row() {
              Text('💬')
                .fontSize(16)
                .margin({ right: 6 })
              Text('继续补充')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(MintColors.mint)
            }
          }
          .height(48)
          .layoutWeight(1)
          .backgroundColor(MintColors.surface)
          .borderRadius(BorderRadius.lg)
          .border({
            width: 1.5,
            color: MintColors.mint
          })
          .onClick(() => this.continueChat())
        }
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .backgroundColor(MintColors.background)
    } else {
      Column().height(this.safeBottomVp > 0 ? this.safeBottomVp : 16).backgroundColor(MintColors.background)
    }
  }
}
