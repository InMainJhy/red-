@Entry
@Component
struct MeetingQuickActionsFocusCard {
  @Builder
  private buildTag(label: string) {
    Row() {
      Text(label)
        .fontSize(9)
        .fontColor('rgba(255, 255, 255, 0.76)')
    }
    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    .backgroundColor('rgba(255, 255, 255, 0.14)')
    .borderRadius(999)
  }

  @Builder
  private buildPrimaryAction() {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        launchAction: 'continue-meeting'
      }
    }) {
      Row({ space: 6 }) {
        Text('继续会议')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0F172A')
        Text('回到对话')
          .fontSize(10)
          .maxLines(1)
          .fontColor('rgba(15, 23, 42, 0.68)')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .backgroundColor('#F8FAFC')
      .borderRadius(22)
    }
  }

  @Builder
  private buildMiniAction(label: string, action: string) {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        launchAction: action
      }
    }) {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(12)
          .maxLines(1)
          .fontWeight(FontWeight.Medium)
          .fontColor('#E2E8F0')
      }
      .height(54)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('rgba(255, 255, 255, 0.12)')
      .borderRadius(18)
    }
  }

  build() {
    Column({ space: 9 }) {
      Row({ space: 6 }) {
        this.buildTag('最近会话')
        this.buildTag('桌面续聊')
      }

      Column({ space: 2 }) {
        Text('继续上次会议')
          .fontSize(18)
          .maxLines(1)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('直接续聊、开新会，或查看纪要。')
          .fontSize(9)
          .maxLines(1)
          .fontColor('rgba(255, 255, 255, 0.74)')
      }
      .alignItems(HorizontalAlign.Start)

      this.buildPrimaryAction()

      Row({ space: 8 }) {
        this.buildMiniAction('开始新会议', 'new-meeting')
        this.buildMiniAction('最近纪要', 'open-recent-summaries')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .linearGradient({
      angle: 135,
      colors: [['#0F172A', 0], ['#164E63', 0.52], ['#2563EB', 1]]
    })
    .borderRadius(26)
  }
}
