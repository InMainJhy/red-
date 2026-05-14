# Harmony 端说明

最后更新：2026-05-12

## 当前主流程

Harmony 端当前实际使用的主链路如下：

1. `pages/SplashPage`
启动视频页，结束后进入首页。

2. `pages/Index`
首页工作台，负责：
- 角色入口
- 参数入口
- 资料入口
- 创建 / 导入入口
- 最近会议 / 纪要入口
- 底部 `+` 直接进入会议对话

3. `pages/MeetingParticipantPage`
只负责选择参会人格并保存回首页。

4. `pages/MeetingChatPage`
会议正式对话页。
当前逻辑是先进入会话，再由底部输入框发出议题开启讨论。

5. `pages/ExplorePersonas`
分类人物页。

6. `pages/ProfileDetail`
人物详细信息页。

7. `pages/SummaryListPage` / `pages/SummaryDetailPage`
纪要列表和纪要详情。

8. `pages/CreateRole` / `pages/AIDialogueCreateRole` / `pages/ImportProfilePage`
人物创建、AI 辅助创建、资料导入。

## 当前已移除的废弃分支

以下内容已不再作为当前主流程保留：

- `pages/IndexV2`
- `pages/Arena`
- `pages/FusionWorkbench`
- `pages/SmartQuestionPrep`
- `components/ArenaHeader`
- `components/ArenaTab`

这些页面对应的是早期首页 / 旧会议页 / 实验性工作台链路，当前已经被 `Index + MeetingParticipantPage + MeetingChatPage` 替代。

## API 现状

前端接口封装主要在：

- [entry/src/main/ets/service/PersonaApi.ets](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/harmony/entry/src/main/ets/service/PersonaApi.ets)
- [entry/src/main/ets/service/SummaryService.ets](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/harmony/entry/src/main/ets/service/SummaryService.ets)

当前前端已经定义了完整的接口调用路径，但有两个现实情况：

1. `PersonaApi.ets` 仍保留 mock 能力，默认并未彻底切成纯线上后端。
2. 前端期望的后端接口数量，已经明显多于 `backend/src/server.ts` 当前真正实现的接口数量。

后端待完善项请直接看：
[../backend/CURRENT_BACKEND_REQUIREMENTS.md](/Users/intmainjhy/Desktop/intmainjhy/idea/xiaohongshu_hackathon_2026.4-main/xiaohongshu_hackathon_2026.4-main/backend/CURRENT_BACKEND_REQUIREMENTS.md)

## 构建说明

- 命令行侧没有可靠的 `npm run build` 工作流。
- Harmony 端最终仍建议在 DevEco Studio 中完成：
  - 预览
  - 真机调试
  - hvigor 编译检查

## 当前收口重点

1. 完成真实后端联调。
2. 把纪要链路统一到一套稳定数据源。
3. 做一次完整真机走查：
启动页 -> 首页 -> 选角色 -> 进入会议 -> 发议题 -> 生成纪要 -> 查看详情 -> 导出分享
