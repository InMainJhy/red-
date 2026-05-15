@Entry
@Component
struct MeetingQuickActionsGlassCard {
  @Builder
  private buildTopPill(label: string) {
    Row() {
      Text(label)
        .fontSize(8)
        .fontColor('rgba(248, 250, 252, 0.78)')
    }
    .padding({ left: 7, right: 7, top: 3, bottom: 3 })
    .backgroundColor('rgba(255, 255, 255, 0.12)')
    .borderRadius(999)
  }

  @Builder
  private buildActionBlock(title: string, note: string, action: string) {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        launchAction: action
      }
    }) {
      Row({ space: 6 }) {
        Text(title)
          .fontSize(12)
          .maxLines(1)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F8FAFC')
        Text(note)
          .fontSize(8)
          .maxLines(1)
          .fontColor('rgba(248, 250, 252, 0.68)')
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 8, bottom: 8 })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('rgba(255, 255, 255, 0.12)')
      .borderRadius(18)
      .backdropBlur(18)
    }
  }

  build() {
    Column({ space: 7 }) {
      Row({ space: 6 }) {
        this.buildTopPill('LIVE')
        this.buildTopPill('GLASS')
      }

      Column({ space: 3 }) {
        Row({ space: 8 }) {
          Text('继续会议')
            .fontSize(17)
            .maxLines(1)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        Text('桌面上的会议快捷台。')
          .fontSize(9)
          .maxLines(1)
          .fontColor('rgba(255, 255, 255, 0.72)')
      }
      .alignItems(HorizontalAlign.Start)

      this.buildActionBlock('继续上次会议', '恢复', 'continue-meeting')
      this.buildActionBlock('开始新会议', '新建', 'new-meeting')
      this.buildActionBlock('查看最近纪要', '回看', 'open-recent-summaries')
    }
    .width('100%')
    .height('100%')
    .padding(11)
    .backgroundColor('#0F172A')
    .linearGradient({
      angle: 145,
      colors: [['#111827', 0], ['#312E81', 0.46], ['#0F766E', 1]]
    })
    .borderRadius(26)
  }
}
