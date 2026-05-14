import 'dotenv/config';

import cors from 'cors';
import express from 'express';

import { getConfig } from './config.js';
import type { ArenaRunRequest, BuildAgentsRequest, LlmChatRequest, ParseTimelineRequest } from './domain.js';
import { MemoryRepository } from './memory-repository.js';
import { arenaRunRequestSchema, buildAgentsRequestSchema, parseTimelineRequestSchema } from './schemas.js';
import { runArena } from './services/arena.js';
import { DefaultLibraryImporter } from './services/importer.js';
import { chatWithLlm, getLlmEnvStatus, testLlmConnection } from './services/llm.js';
import { buildAgents } from './services/persona.js';
import { parseTimeline } from './services/timeline.js';
import { generatePoster, getImageEnvStatus } from './services/image.js';

const config = getConfig();
const repository = new MemoryRepository();
const importer = new DefaultLibraryImporter(repository);

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', async (_request, response) => {
  try {
    await repository.ping();
    const overview = await importer.getOverview();
    const llmStatus = getLlmEnvStatus();
    response.json({
      ok: true,
      runtime: {
        mode: 'deepseek-api',
        model: llmStatus.model,
        hasApiKey: llmStatus.hasApiKey,
      },
      import: {
        ...importer.getState(),
        ...overview,
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    response.status(500).json({
      ok: false,
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    });
  }
});

app.get('/api/presets', async (_request, response) => {
  try {
    response.json({
      presets: await repository.listDefaultPresets(),
    });
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.get('/api/profiles/:profileId', async (request, response) => {
  try {
    const bundle = await repository.getProfileBundle(request.params.profileId);
    if (!bundle) {
      response.status(404).json({ error: 'profile not found' });
      return;
    }
    response.json(bundle);
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/timeline/parse', async (request, response) => {
  const parsed = parseTimelineRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    response.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  try {
    const result = await parseTimeline(repository, parsed.data as ParseTimelineRequest);
    response.json(result);
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/agents/build', async (request, response) => {
  const parsed = buildAgentsRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    response.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  try {
    const result = await buildAgents(repository, parsed.data as BuildAgentsRequest);
    response.json(result);
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/arena/run', async (request, response) => {
  const parsed = arenaRunRequestSchema.safeParse(request.body);
  if (!parsed.success) {
    response.status(400).json({ error: parsed.error.flatten() });
    return;
  }

  try {
    const result = await runArena(repository, parsed.data as ArenaRunRequest);
    response.json(result);
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/admin/import-defaults', async (_request, response) => {
  try {
    const result = await importer.importDefaults(true);
    const overview = await importer.getOverview();
    response.json({ state: result, overview });
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.get('/api/admin/import-status', async (_request, response) => {
  try {
    response.json({
      state: importer.getState(),
      overview: await importer.getOverview(),
    });
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

// LLM Chat API
app.post('/api/llm/chat', async (request, response) => {
  try {
    const result = await chatWithLlm(request.body as LlmChatRequest);
    if (!result.ok) {
      response.status(500).json(result);
    } else {
      response.json(result);
    }
  } catch (error) {
    response.status(500).json({
      ok: false,
      text: '',
      model: '',
      baseUrl: '',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

app.post('/api/llm/test', async (_request, response) => {
  try {
    const result = await testLlmConnection();
    response.json(result);
  } catch (error) {
    response.status(500).json({
      ok: false,
      text: '',
      model: '',
      baseUrl: '',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

app.get('/api/debug/env', async (_request, response) => {
  try {
    response.json({
      llm: getLlmEnvStatus(),
      image: getImageEnvStatus(),
    });
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

// 图片生成 API - 生成对话海报
app.post('/api/image/poster', async (request, response) => {
  try {
    const { topic, mode, participants, summary, stylePrompt, imageSize } = request.body;

    if (!topic || !participants || !Array.isArray(participants)) {
      response.status(400).json({ ok: false, error: 'topic 和 participants 是必填项' });
      return;
    }

    const result = await generatePoster({ topic, mode, participants, summary, stylePrompt, imageSize });

    if (!result.ok) {
      response.status(500).json(result);
    } else {
      response.json(result);
    }
  } catch (error) {
    response.status(500).json({
      ok: false,
      model: '',
      prompt: '',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

// 获取会议详情 - 支持纪要页面通过 arenaRunId 加载
app.get('/api/arena/runs/:runId', async (request, response) => {
  try {
    const runId = request.params.runId;
    const run = await repository.getArenaRun(runId);
    if (!run) {
      response.status(404).json({ error: 'run not found' });
      return;
    }
    response.json({
      result: run,
      links: {
        runId: run.runId,
        shareApiPath: `/api/arena/${run.runId}/share`,
        shareApiUrl: `/api/arena/${run.runId}/share`,
        suggestedSharePath: `/api/arena/${run.runId}/poster`,
        suggestedShareUrl: `/api/arena/${run.runId}/poster`,
      },
    });
  } catch (error) {
    response.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

// 海报生成 API - 兼容前端 /api/arena/poster 调用路径
// 前端 PersonaApi.generateArenaPoster() 调用此路径
app.post('/api/arena/poster', async (request, response) => {
  try {
    const { runId, run, stylePreset, aspectRatio } = request.body;

    // 优先使用传入的 run 对象，否则根据 runId 从 repository 获取
    let effectiveRun = run;
    if (!effectiveRun && runId) {
      effectiveRun = await repository.getArenaRun(runId);
    }

    // 从 run 对象中提取生成海报所需的信息
    const topic = effectiveRun?.topic || '';
    const mode = effectiveRun?.mode || 'chat';
    const participants = effectiveRun?.participants
      ? effectiveRun.participants.map((p: { displayName: string; stageLabel: string }) => ({
          displayName: p.displayName,
          stageLabel: p.stageLabel,
        }))
      : [];
    const summary = effectiveRun?.summary || undefined;

    if (!topic || participants.length === 0) {
      response.status(400).json({
        ok: false,
        error: '缺少会议主题或参与角色信息，请确保 runId 有效或传入完整的 run 对象',
      });
      return;
    }

    const imageSize = aspectRatio === '16:9' ? '1024x576'
      : aspectRatio === '3:4' ? '768x1024'
      : '1024x1024';

    const result = await generatePoster({ topic, mode, participants, summary, imageSize });

    const effectiveRunId = runId || run?.runId || `poster-${Date.now()}`;
    const title = summary?.title || topic;

    if (!result.ok) {
      response.status(500).json({
        runId: effectiveRunId,
        links: {
          runId: effectiveRunId,
          shareApiPath: `/api/arena/${effectiveRunId}/share`,
          shareApiUrl: `/api/arena/${effectiveRunId}/share`,
          suggestedSharePath: `/api/arena/${effectiveRunId}/poster`,
          suggestedShareUrl: `/api/arena/${effectiveRunId}/poster`,
        },
        poster: {
          runId: effectiveRunId,
          title,
          summary: summary?.consensus || '',
          stylePreset: stylePreset || 'editorial',
          aspectRatio: aspectRatio || '3:4',
          outputDir: 'generated',
          imagePath: '',
          imageUrl: '',
          promptPath: '',
          promptUrl: '',
          sourcePath: '',
          sourceUrl: '',
          generatedAt: new Date().toISOString(),
        },
        error: result.error,
      });
    } else {
      response.json({
        runId: effectiveRunId,
        links: {
          runId: effectiveRunId,
          shareApiPath: `/api/arena/${effectiveRunId}/share`,
          shareApiUrl: `/api/arena/${effectiveRunId}/share`,
          suggestedSharePath: `/api/arena/${effectiveRunId}/poster`,
          suggestedShareUrl: `/api/arena/${effectiveRunId}/poster`,
        },
        poster: {
          runId: effectiveRunId,
          title,
          summary: summary?.consensus || '',
          stylePreset: stylePreset || 'editorial',
          aspectRatio: aspectRatio || '3:4',
          outputDir: 'generated',
          imagePath: result.imageUrl || '',
          imageUrl: result.imageUrl || result.imageBase64 || '',
          promptPath: `/api/arena/${effectiveRunId}/prompt`,
          promptUrl: `/api/arena/${effectiveRunId}/prompt`,
          sourcePath: result.imageUrl || '',
          sourceUrl: result.imageUrl || result.imageBase64 || '',
          generatedAt: new Date().toISOString(),
        },
      });
    }
  } catch (error) {
    response.status(500).json({
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

async function bootstrap(): Promise<void> {
  await repository.init();

  app.listen(config.port, () => {
    const llm = getLlmEnvStatus();
    console.log(`
╔══════════════════════════════════════════════════╗
║  时序人格后端服务器 (DeepSeek API)                ║
║  http://localhost:${config.port}                      ║
║  模型: ${llm.model.padEnd(42)}║
║  API Key: ${(llm.hasApiKey ? '已配置 ✓' : '未配置 ✗').padEnd(37)}║
╚══════════════════════════════════════════════════╝
    `);
  });

  if (config.importOnBoot) {
    void importer.importDefaults().catch((error) => {
      console.error('default import failed', error);
    });
  }
}

bootstrap().catch((error) => {
  console.error('backend bootstrap failed', error);
  process.exitCode = 1;
});
