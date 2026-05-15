@Entry
@Component
struct MeetingQuickActionsEditorialCard {
  @Builder
  private buildAccentChip(label: string) {
    Row() {
      Text(label)
        .fontSize(9)
        .fontColor('rgba(17, 24, 39, 0.58)')
    }
    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    .backgroundColor('rgba(255, 255, 255, 0.72)')
    .borderRadius(999)
  }

  @Builder
  private buildAction(label: string, action: string, inverse: boolean = false) {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        launchAction: action
      }
    }) {
      Row() {
        Text(label)
          .fontSize(inverse ? 13 : 11)
          .maxLines(1)
          .fontWeight(inverse ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(inverse ? '#F8FAFC' : '#111827')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(inverse ? '#111827' : '#FFFFFF')
      .borderRadius(20)
    }
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        this.buildAccentChip('MEETING')
        this.buildAccentChip('EDITORIAL')
      }

      Text('继续会议')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')
        .maxLines(1)

      Row()
        .width('100%')
        .height(1)
        .backgroundColor('rgba(17, 24, 39, 0.08)')

      Column({ space: 6 }) {
        this.buildAction('继续会议', 'continue-meeting', true)
        this.buildAction('开始新会议', 'new-meeting')
        this.buildAction('查看纪要', 'open-recent-summaries')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding(11)
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#F3F0EA')
    .borderRadius(26)
    .border({
      width: 1,
      color: 'rgba(17, 24, 39, 0.08)'
    })
  }
}
