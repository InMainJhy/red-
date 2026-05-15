# HarmonyOS 特性接入总结

> 项目：时序人格局  
> 日期：2026-05-15  
> 说明：本文档用于汇总当前项目已完成的 HarmonyOS 特性接入情况，可直接用于比赛答辩、项目说明或阶段汇报。

## 一句话概括

“时序人格局”已经从普通应用流程，扩展为一套覆盖 `深链直达`、`桌面服务卡片`、`原生分享`、`跨设备接续`、`二维码直达`、`系统提醒`、`快捷意图`、`设备协同`、`大屏投播` 的 HarmonyOS 全场景体验。

## 当前已完成的 HarmonyOS 特性

### 1. App Linking Kit

#### 用户价值

将会议、纪要和继续讨论能力转化为可直达入口，用户收到链接后不是只查看内容，而是可以直接回到对应业务场景。

#### 当前能力

- 支持 `继续会议`
- 支持 `开始新会议`
- 支持 `查看最近纪要`
- 支持 `打开指定纪要详情`

#### 项目落点

- [harmony/entry/src/main/ets/common/LaunchIntent.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/common/LaunchIntent.ets)
- [harmony/entry/src/main/ets/entryability/EntryAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryability/EntryAbility.ets)
- [harmony/entry/src/main/module.json5](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/module.json5)

#### 演示方式

打开或触发以下链接：

- `timepersona://meeting/continue`
- `timepersona://meeting/new`
- `timepersona://summaries/recent`
- `timepersona://summary/detail`

应用会直接进入对应页面。

---

### 2. Form Kit

#### 用户价值

把高频能力前置到桌面，让用户不进入应用也能快速恢复工作流。

#### 当前能力

- 桌面服务卡片已接入
- 支持多种卡片样式
- 支持 `继续上次会议`
- 支持 `开始新会议`
- 支持 `查看最近纪要`

#### 项目落点

- [harmony/entry/src/main/ets/entryformability/MeetingQuickActionsFormAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryformability/MeetingQuickActionsFormAbility.ets)
- [harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsFocusCard.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsFocusCard.ets)
- [harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsEditorialCard.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsEditorialCard.ets)
- [harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsGlassCard.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsGlassCard.ets)
- [harmony/entry/src/main/resources/base/profile/form_config.json](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/resources/base/profile/form_config.json)

#### 演示方式

在桌面添加卡片，直接点击三个主操作，展示无需进入应用主页面也能继续会议和查看纪要。

---

### 3. Share Kit

#### 用户价值

会议结果和海报可以通过 HarmonyOS 原生分享能力快速扩散，既支持应用间传播，也支持设备间流转。

#### 当前能力

- 支持系统分享
- 支持隔空传送
- 支持碰一碰分享
- 支持链接复制

#### 项目落点

- [harmony/entry/src/main/ets/pages/PosterPreviewPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/PosterPreviewPage.ets)

#### 演示方式

打开海报预览页，展示 `碰一碰`、`抓一抓`、`系统分享` 和 `复制链接`。

---

### 4. Media Kit / Image Kit

#### 用户价值

提升生成海报的清晰度，让会议内容更适合保存、传播和大屏展示。

#### 当前能力

- 已接入 AI 超分辨率增强
- 海报可在分享前先增强清晰度

#### 项目落点

- [harmony/entry/src/main/ets/pages/PosterPreviewPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/PosterPreviewPage.ets)
- [harmony/entry/src/main/ets/service/ImageSuperResolutionService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/ImageSuperResolutionService.ets)

#### 演示方式

在海报页点击 `AI 超分`，展示增强前后的视觉效果和分辨率提升提示。

---

### 5. Ability Kit

#### 用户价值

支持应用接续，让会议上下文可以从一台设备平滑切换到另一台设备。

#### 当前能力

- 支持会议上下文接续
- 支持继续会议场景恢复
- 支持从当前设备把会议状态带到目标设备

#### 项目落点

- [harmony/entry/src/main/ets/entryability/EntryAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryability/EntryAbility.ets)
- [harmony/entry/src/main/ets/common/LaunchIntent.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/common/LaunchIntent.ets)

#### 演示方式

在设备 A 发起会议，再在设备 B 展示“继续同一场会议”的恢复效果。

---

### 6. Scan Kit

#### 用户价值

把会议和纪要变成“扫一下即可进入”的场景入口，适合线下传播、答辩展示和多人协作。

#### 当前能力

- 支持生成继续会议二维码
- 支持生成纪要详情二维码
- 支持扫码后基于深链跳转

#### 项目落点

- [harmony/entry/src/main/ets/pages/QrLinkPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/QrLinkPage.ets)
- [harmony/entry/src/main/ets/common/QrCodeService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/common/QrCodeService.ets)
- [harmony/entry/src/main/ets/pages/MeetingChatPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/MeetingChatPage.ets)
- [harmony/entry/src/main/ets/pages/SummaryDetailPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/SummaryDetailPage.ets)

#### 演示方式

展示“继续会议二维码”或“纪要二维码”，再用另一台设备扫码直达对应页面。

---

### 7. Calendar Kit

#### 用户价值

把会议结论延展到系统提醒和日程管理，让“讨论结果”变成“后续行动”。

#### 当前能力

- 支持从纪要详情创建复盘提醒
- 默认生成下一次回顾时间
- 点击提醒后可回到对应纪要

#### 项目落点

- [harmony/entry/src/main/ets/service/CalendarReminderService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/CalendarReminderService.ets)
- [harmony/entry/src/main/ets/pages/SummaryDetailPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/SummaryDetailPage.ets)

#### 演示方式

在纪要详情页点击 `复盘提醒`，展示提醒创建成功和后续回到纪要的能力。

---

### 8. Intents Kit

#### 用户价值

把核心功能接入 HarmonyOS 智能入口，让高频操作更容易被系统理解和触发。

#### 当前能力

- 支持 `继续上次会议`
- 支持 `开始新会议`
- 支持 `打开最近纪要`

#### 项目落点

- [harmony/entry/src/main/ets/intents/MeetingInsightIntentExecutor.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/intents/MeetingInsightIntentExecutor.ets)
- [harmony/entry/src/main/resources/base/profile/insight_intent.json](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/resources/base/profile/insight_intent.json)

#### 演示方式

展示项目已注册的 3 个快捷意图，并说明其与会议主链路的对应关系。

---

### 9. Service Collaboration Kit

#### 用户价值

支持跨设备流转，把纪要从手机继续带到平板或智慧屏查看，强化 HarmonyOS 的协同体验。

#### 当前能力

- 支持纪要流转到平板
- 支持纪要流转到智慧屏
- 目标设备接收后按统一启动协议打开对应详情

#### 项目落点

- [harmony/entry/src/main/ets/service/ServiceCollaborationService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/ServiceCollaborationService.ets)
- [harmony/entry/src/main/ets/pages/SummaryDetailPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/SummaryDetailPage.ets)
- [harmony/entry/src/main/ets/entryability/EntryAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryability/EntryAbility.ets)

#### 演示方式

在纪要详情页选择 `平板` 或 `智慧屏`，将当前纪要流转到目标设备继续展示。

---

### 10. AV Session Kit

#### 用户价值

将会议海报和复盘内容带到大屏设备，增强展示感、沉浸感和比赛现场表现力。

#### 当前能力

- 已接入系统投播设备选择器
- 海报页支持一键调起大屏投播

#### 项目落点

- [harmony/entry/src/main/ets/service/AVCastService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/AVCastService.ets)
- [harmony/entry/src/main/ets/pages/PosterPreviewPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/PosterPreviewPage.ets)

#### 演示方式

在海报页点击 `大屏投播`，展示系统投播面板，并说明可将复盘海报投到智慧屏进行展示。

## 答辩建议讲法

### 推荐开场

“我们不是只做了一个 HarmonyOS 端应用，而是围绕会议、纪要和分享这条主链路，把项目做成了一套 HarmonyOS 全场景体验。”

### 推荐中段结构

可以按下面 4 组来讲：

1. `入口能力`
App Linking、二维码直达、快捷意图、桌面卡片。

2. `内容传播能力`
系统分享、碰一碰、隔空传送、海报超分。

3. `多设备协同能力`
应用接续、服务协同、平板流转、智慧屏流转。

4. `结果沉淀能力`
纪要详情、复盘提醒、大屏展示。

### 推荐收束句

“因此，这个项目的亮点不只是 AI 会议本身，而是我们把会议生成、会议恢复、会议传播和会议复盘，完整接入到了 HarmonyOS 的系统能力里。”

## 当前状态说明

当前这些功能的代码已经接入项目，并通过了 Harmony 工程的 `CompileArkTS` 编译阶段验证。  
当前打包阶段仍受本机缺少 Java Runtime 影响，卡在 `PackageHap`，属于本地环境问题，不是本次 Harmony 特性代码本身的编译错误。
