# 时序人格局

小红书黑客松 HarmonyOS 主端项目工作区。

当前仓库以 Harmony 端为主，主流程已经收敛到：

1. 启动页 `SplashPage`
2. 首页工作台 `Index`
3. 选择参会人格 `MeetingParticipantPage`
4. 直接进入会议对话 `MeetingChatPage`
5. 查看纪要列表 / 纪要详情 `SummaryListPage` / `SummaryDetailPage`

## 目录

```text
backend/   Node.js + TypeScript API
harmony/   HarmonyOS ArkTS 前端
shared/    共享领域模型与预设语义
web/       Web 端实验区
docs/      当前整理后的项目说明与设计文档
```

## 当前重点文档

- 项目现状梳理：
  [docs/project-current-status-2026-05-12.md](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/docs/project-current-status-2026-05-12.md)
- 后端待完善清单：
  [backend/CURRENT_BACKEND_REQUIREMENTS.md](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/backend/CURRENT_BACKEND_REQUIREMENTS.md)
- Harmony 当前说明：
  [harmony/README.md](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/harmony/README.md)

## 当前代码状态

- Harmony 主流程页面仍在持续优化，但已不是从零开发阶段。
- 旧的实验页和废弃入口已做过一轮清理。
- 前端 API 层接口定义较完整，但真实后端能力还没有完全对齐。
- `PersonaApi.ets` 目前默认仍可走 mock 逻辑，联调前需要进一步收口。

## 建议下一步

1. 完成后端缺失接口。
2. 关闭 Harmony 端 mock 并做完整联调。
3. 在 DevEco Studio 做一轮真机验收。
