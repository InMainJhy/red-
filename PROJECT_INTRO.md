# 时序人格局

> 小红书黑客松项目，当前以 HarmonyOS 端为主要演示载体。

## 一句话介绍

“时序人格局”通过人物时间线拆解出不同人生阶段的人格切片，让这些人格围绕同一议题展开会议式对话，并把结果沉淀为会议纪要、海报和分享内容。

## 当前项目现状

当前仓库已经进入“主流程收口”阶段，不再是纯概念验证。

Harmony 端当前真实主链路是：

1. 启动页 `SplashPage`
2. 首页工作台 `Index`
3. 角色选择 `MeetingParticipantPage`
4. 直接进入会议 `MeetingChatPage`
5. 纪要列表 / 纪要详情 `SummaryListPage` / `SummaryDetailPage`

更完整的现状说明见：
[docs/project-current-status-2026-05-12.md](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/docs/project-current-status-2026-05-12.md)

## 仓库结构

```text
backend/           Node.js + Express 后端
harmony/           HarmonyOS ArkTS 前端
shared/            共享模型与语义基线
web/               Web 前端
time-persona-web/  另一套 Web 实验目录
docs/              设计文档、计划文档、当前项目说明
```

## 当前核心能力

### 人物与资料

- 预设人物列表
- 人物详情与时间线展示
- 自定义人物创建
- 资料导入入口

### 会议

- 选择参会人格
- 配置对话轮数与准度
- 直接进入会议对话
- 流式展示会议过程

### 纪要

- 最近会议回看
- 纪要列表与详情
- 收藏 / 删除
- 海报导出与分享入口

## 当前技术状态

### 前端

- Harmony 主流程已基本成型
- UI 风格和动效方向已建立
- 旧实验页已清理一轮

### 后端

- 基础人物与非流式 arena 已实现
- 但仍缺少多项前端已经依赖的接口

后端待完善清单见：
[backend/CURRENT_BACKEND_REQUIREMENTS.md](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/backend/CURRENT_BACKEND_REQUIREMENTS.md)

## 当前最重要的下一步

1. 补齐后端缺失接口
2. 关闭 Harmony 主流程 mock
3. 完成一次 DevEco 真机全链路验收
