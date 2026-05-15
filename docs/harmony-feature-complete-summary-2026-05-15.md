# 时序人格局 HarmonyOS 特性完整说明

> 项目：时序人格局  
> 平台：HarmonyOS NEXT / ArkTS  
> 日期：2026-05-15  
> 用途：比赛答辩、项目介绍、特性盘点、技术说明

## 1. 项目概述

“时序人格局”围绕“人格会议”这一核心场景，提供从人物选择、会议讨论、纪要沉淀、海报导出到跨设备传播的一整套体验。  
在 HarmonyOS 端，我们没有只做一个普通应用，而是把主流程深度接入到了系统级能力中，形成了完整的 `入口 -> 讨论 -> 纪要 -> 分享 -> 协同 -> 展示` 闭环。

当前 Harmony 主链路为：

1. `SplashPage` 启动页
2. `Index` 首页工作台
3. `MeetingParticipantPage` 角色选择
4. `MeetingChatPage` 人格会议
5. `SummaryListPage / SummaryDetailPage` 纪要回看
6. `PosterPreviewPage` 海报生成与分享

## 2. 一句话总结

本项目当前已经接入并落地了一套 HarmonyOS 全场景能力组合，覆盖：

- 深链直达
- 桌面服务卡片
- 原生分享
- 碰一碰与隔空传送
- 二维码直达
- 应用接续
- 纪要提醒
- 快捷意图
- 跨设备协同
- 大屏投播
- 统一拖拽
- 图像增强

## 3. 特性总览

| 分类 | 特性 | 当前状态 | 主要场景 |
| --- | --- | --- | --- |
| 入口能力 | App Linking Kit | 已完成 | 继续会议、打开纪要 |
| 入口能力 | Form Kit | 已完成 | 桌面快速恢复会议 |
| 入口能力 | Scan Kit | 已完成 | 扫码进入会议或纪要 |
| 入口能力 | Intents Kit | 已完成 | 快捷触发高频操作 |
| 传播能力 | Share Kit | 已完成 | 海报分享、系统分享 |
| 传播能力 | NFC / 碰一碰 | 已完成 | 纪要与海报近场分享 |
| 传播能力 | ArkData / UDMF | 已完成 | 海报拖拽跨应用流转 |
| 图像能力 | Media Kit / Image Kit | 已完成 | 海报清晰度增强 |
| 协同能力 | Ability Kit | 已完成 | 应用接续 |
| 协同能力 | Service Collaboration Kit | 已完成 | 平板 / 智慧屏流转 |
| 展示能力 | AV Session Kit | 已完成 | 大屏投播 |
| 结果沉淀 | Calendar Kit | 已完成 | 纪要复盘提醒 |

## 4. 已用 HarmonyOS 特性详解

### 4.1 App Linking Kit

#### 特性说明

将业务场景转换为可直达的深链入口，支持通过链接直接恢复会议或打开纪要页面。

#### 当前落地

- 支持 `继续会议`
- 支持 `开始新会议`
- 支持 `查看最近纪要`
- 支持 `打开指定纪要详情`

#### 用户价值

用户收到链接后，不是停留在“看一段文本”，而是可以直接回到对应业务上下文。

#### 代码落点

- [harmony/entry/src/main/ets/common/LaunchIntent.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/common/LaunchIntent.ets)
- [harmony/entry/src/main/ets/common/LaunchIntentStore.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/common/LaunchIntentStore.ets)
- [harmony/entry/src/main/ets/entryability/EntryAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryability/EntryAbility.ets)
- [harmony/entry/src/main/module.json5](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/module.json5)

#### 演示方式

- 打开 `timepersona://meeting/continue`
- 打开 `timepersona://meeting/new`
- 打开 `timepersona://summaries/recent`
- 打开 `timepersona://summary/detail`

---

### 4.2 Form Kit

#### 特性说明

通过桌面服务卡片把高频操作直接前置到系统桌面。

#### 当前落地

- 继续上次会议
- 开始新会议
- 查看最近纪要
- 多种卡片视觉样式

#### 用户价值

减少用户操作路径，让会议恢复不必经过首页层层点击。

#### 代码落点

- [harmony/entry/src/main/ets/entryformability/MeetingQuickActionsFormAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryformability/MeetingQuickActionsFormAbility.ets)
- [harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsFocusCard.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsFocusCard.ets)
- [harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsEditorialCard.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsEditorialCard.ets)
- [harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsGlassCard.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/widget/pages/MeetingQuickActionsGlassCard.ets)
- [harmony/entry/src/main/resources/base/profile/form_config.json](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/resources/base/profile/form_config.json)

#### 演示方式

在桌面添加卡片并点击主操作，展示不进首页也能继续会议。

---

### 4.3 Scan Kit

#### 特性说明

将会议和纪要转成二维码，支持扫码直达。

#### 当前落地

- 继续会议二维码
- 纪要详情二维码
- 扫码后回到深链目标页

#### 用户价值

适合线下分享、答辩演示和多设备快速进入。

#### 代码落点

- [harmony/entry/src/main/ets/pages/QrLinkPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/QrLinkPage.ets)
- [harmony/entry/src/main/ets/common/QrCodeService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/common/QrCodeService.ets)
- [harmony/entry/src/main/ets/pages/MeetingChatPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/MeetingChatPage.ets)
- [harmony/entry/src/main/ets/pages/SummaryDetailPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/SummaryDetailPage.ets)

#### 演示方式

展示二维码，用另一台设备扫码进入会议或纪要详情。

---

### 4.4 Intents Kit

#### 特性说明

将项目核心动作封装为系统可识别的快捷意图。

#### 当前落地

- 继续上次会议
- 开始新会议
- 打开最近纪要

#### 用户价值

提升系统理解能力，让高频操作更容易被 HarmonyOS 调起。

#### 代码落点

- [harmony/entry/src/main/ets/intents/MeetingInsightIntentExecutor.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/intents/MeetingInsightIntentExecutor.ets)
- [harmony/entry/src/main/resources/base/profile/insight_intent.json](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/resources/base/profile/insight_intent.json)

#### 演示方式

展示 3 个快捷意图及其对应页面跳转关系。

---

### 4.5 Share Kit

#### 特性说明

使用 HarmonyOS 原生分享通道完成会议海报与内容传播。

#### 当前落地

- 系统分享面板
- 隔空传送
- 抓一抓
- 链接复制
- 海报文件分享

#### 用户价值

从“生成内容”延展到“高质量传播”，强化作品的演示感和社交传播能力。

#### 代码落点

- [harmony/entry/src/main/ets/pages/PosterPreviewPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/PosterPreviewPage.ets)

#### 演示方式

在海报页演示系统分享、隔空传送与抓一抓。

---

### 4.6 NFC / 碰一碰

#### 特性说明

通过 NFC 与碰一碰能力实现近场分享和接收。

#### 当前落地

- 支持发送端写入分享数据
- 支持接收端解析 NFC tag
- 支持接收后自动跳转纪要详情

#### 用户价值

让分享更具 HarmonyOS 场景感，也更适合现场互动式答辩展示。

#### 代码落点

- [harmony/entry/src/main/ets/service/NfcShareService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/NfcShareService.ets)
- [harmony/entry/src/main/ets/nfcshareability/NfcShareAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/nfcshareability/NfcShareAbility.ets)
- [harmony/entry/src/main/ets/entryability/EntryAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryability/EntryAbility.ets)

#### 演示方式

两台设备靠近，触发 NFC / 碰一碰，目标设备自动进入纪要内容。

---

### 4.7 ArkData / UDMF 统一拖拽

#### 特性说明

利用 ArkData 的统一数据模型，在海报页支持拖拽跨应用、跨设备传递内容。

#### 当前落地

- 海报图片拖拽
- 降级为纯文本链接拖拽
- 支持统一数据写入

#### 用户价值

把海报从静态页面升级成可直接流转的内容对象。

#### 代码落点

- [harmony/entry/src/main/ets/pages/PosterPreviewPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/PosterPreviewPage.ets)

#### 演示方式

长按拖拽海报，展示跨应用 / 跨设备流转能力。

---

### 4.8 Media Kit / Image Kit

#### 特性说明

为会议海报提供图像增强能力，提高分享前的视觉质量。

#### 当前落地

- 海报超分辨率增强
- 文件和网络图像均可增强
- 支持增强结果反馈

#### 用户价值

提升生成内容的精致感，更适合社交传播和大屏展示。

#### 代码落点

- [harmony/entry/src/main/ets/service/ImageSuperResolutionService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/ImageSuperResolutionService.ets)
- [harmony/entry/src/main/ets/pages/PosterPreviewPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/PosterPreviewPage.ets)

#### 演示方式

点击 `AI 超分`，展示增强前后的清晰度提升。

---

### 4.9 Ability Kit

#### 特性说明

通过应用接续能力在不同设备之间传递会议上下文。

#### 当前落地

- 支持会议上下文接续
- 支持继续会议恢复
- 支持新会议上下文传递

#### 用户价值

让用户从手机切到平板、从一个设备切到另一个设备时，会议状态不丢失。

#### 代码落点

- [harmony/entry/src/main/ets/entryability/EntryAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryability/EntryAbility.ets)
- [harmony/entry/src/main/ets/common/LaunchIntent.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/common/LaunchIntent.ets)

#### 演示方式

设备 A 开会，设备 B 接续恢复到同一会议场景。

---

### 4.10 Calendar Kit

#### 特性说明

从纪要详情直接创建系统复盘提醒。

#### 当前落地

- 纪要一键转提醒
- 默认下一轮复盘时间
- 提醒关联回纪要详情

#### 用户价值

帮助用户把一次会议结果真正沉淀成后续行动。

#### 代码落点

- [harmony/entry/src/main/ets/service/CalendarReminderService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/CalendarReminderService.ets)
- [harmony/entry/src/main/ets/pages/SummaryDetailPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/SummaryDetailPage.ets)

#### 演示方式

在纪要详情页点击 `复盘提醒`，展示提醒创建与系统回跳能力。

---

### 4.11 Service Collaboration Kit

#### 特性说明

通过跨设备协同，把纪要从手机直接流转到平板或智慧屏。

#### 当前落地

- 流转到平板
- 流转到智慧屏
- 目标设备按统一启动协议恢复详情页

#### 用户价值

强化 HarmonyOS 多设备一体协同的体验，适合“手机生成，平板查看，大屏展示”的演示路径。

#### 代码落点

- [harmony/entry/src/main/ets/service/ServiceCollaborationService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/ServiceCollaborationService.ets)
- [harmony/entry/src/main/ets/pages/SummaryDetailPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/SummaryDetailPage.ets)
- [harmony/entry/src/main/ets/entryability/EntryAbility.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/entryability/EntryAbility.ets)

#### 演示方式

在纪要详情页点击 `平板` 或 `智慧屏`，展示内容跨设备继续打开。

---

### 4.12 AV Session Kit

#### 特性说明

通过系统投播设备选择器，把会议海报带到大屏进行展示。

#### 当前落地

- 海报页一键投播
- 调起系统投播面板
- 面向智慧屏的大屏展示

#### 用户价值

将会议成果从手机小屏提升到大屏复盘，增强沉浸感和答辩观感。

#### 代码落点

- [harmony/entry/src/main/ets/service/AVCastService.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/service/AVCastService.ets)
- [harmony/entry/src/main/ets/pages/PosterPreviewPage.ets](/Users/intmainjhy/Desktop/red--main/harmony/entry/src/main/ets/pages/PosterPreviewPage.ets)

#### 演示方式

点击 `大屏投播`，调起系统设备列表，展示投播到智慧屏的能力。

## 5. 推荐答辩结构

建议从 4 组来讲：

### 第一组：入口能力

- App Linking
- 桌面卡片
- 二维码
- 快捷意图

这组强调：用户如何更快进入会议和纪要场景。

### 第二组：传播能力

- 系统分享
- 碰一碰
- 隔空传送
- 统一拖拽
- 海报超分

这组强调：会议结果如何高质量传播。

### 第三组：协同能力

- 应用接续
- 跨设备流转
- 平板查看
- 智慧屏查看

这组强调：HarmonyOS 一体协同体验。

### 第四组：结果沉淀能力

- 纪要详情
- 复盘提醒
- 大屏投播

这组强调：讨论结果如何真正落地。

## 6. 推荐答辩话术

### 开场一句话

“我们不是只做了一个 HarmonyOS 应用，而是围绕人格会议这条主链路，把项目做成了一套 HarmonyOS 全场景体验。”

### 中段总结

“从入口直达、桌面恢复、二维码进入，到原生分享、碰一碰、跨设备协同和大屏投播，我们把会议的生成、传播、恢复和复盘都接进了 HarmonyOS 的系统能力里。”

### 收束句

“所以这个项目的亮点不仅是 AI 会议本身，更是 AI 能力与 HarmonyOS 全场景特性的深度结合。”

## 7. 当前状态说明

当前这些 HarmonyOS 特性的代码已经落地，并通过了 Harmony 工程的 `CompileArkTS` 编译阶段验证。  
当前打包阶段仍受本机缺少 Java Runtime 影响，卡在 `PackageHap`，属于本地环境问题，不是本次特性代码本身的编译错误。
