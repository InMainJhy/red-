import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import { getConfig } from './config.js';
import { BackendRepository } from './repository.js';
import type { ArenaRunRequest, BuildAgentsRequest, CreateSummaryRequest, ParseTimelineRequest, UpdateSummaryRequest, SummaryFilter, SummarySortBy, SummarySortOrder } from './domain.js';
import { arenaRunRequestSchema, buildAgentsRequestSchema, createSummaryRequestSchema, parseTimelineRequestSchema, updateSummaryRequestSchema } from './schemas.js';

const config = getConfig();
const repository = new BackendRepository(config.databaseUrl);

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

function parseSummaryFilter(query: Record<string, unknown>): SummaryFilter {
  const category = typeof query.category === 'string' ? query.category : undefined;
  const sortBy = typeof query.sortBy === 'string' ? query.sortBy : undefined;
  const sortOrder = typeof query.sortOrder === 'string' ? query.sortOrder : undefined;
  return {
    category: category === 'all' || category === 'favorite' || category === 'tag' ? category : undefined,
    tag: typeof query.tag === 'string' ? query.tag : undefined,
    keyword: typeof query.keyword === 'string' ? query.keyword : undefined,
    sortBy: sortBy === 'createdAt' || sortBy === 'updatedAt' || sortBy === 'viewCount' ? (sortBy as SummarySortBy) : undefined,
    sortOrder: sortOrder === 'asc' || sortOrder === 'desc' ? (sortOrder as SummarySortOrder) : undefined,
  };
}

app.get('/health', async (_req, res) => {
  try {
    await repository.ping();
    res.json({ ok: true, timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ ok: false, error: error instanceof Error ? error.message : String(error) });
  }
});

app.get('/api/presets', async (_req, res) => {
  try {
    res.json({ presets: await repository.listDefaultPresets() });
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.get('/api/profiles/:profileId', async (req, res) => {
  try {
    const bundle = await repository.getProfileBundle(req.params.profileId);
    if (!bundle) { res.status(404).json({ error: 'profile not found' }); return; }
    res.json(bundle);
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/timeline/parse', async (req, res) => {
  const parsed = parseTimelineRequestSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  try {
    const result = await repository.parseTimeline(parsed.data as ParseTimelineRequest);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/agents/build', async (req, res) => {
  const parsed = buildAgentsRequestSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  try {
    const result = await repository.buildAgents(parsed.data as BuildAgentsRequest);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/arena/run', async (req, res) => {
  const parsed = arenaRunRequestSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  try {
    const result = await repository.runArena(parsed.data as ArenaRunRequest);
    res.json({ result });
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.get('/api/arena/history', async (_req, res) => {
  try {
    const runs = await repository.listArenaRuns();
    res.json({ runs });
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/arena/stream', async (req, res) => {
  const parsed = arenaRunRequestSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.flushHeaders();
  try {
    await repository.streamArena(parsed.data as ArenaRunRequest, (event) => {
      res.write(`data: ${JSON.stringify(event)}\n\n`);
    });
    res.write('data: [DONE]\n\n');
    res.end();
  } catch (error) {
    res.write(`data: ${JSON.stringify({ type: 'error', error: String(error) })}\n\n`);
    res.end();
  }
});

app.get('/api/summaries', async (req, res) => {
  try {
    res.json(await repository.listSummaries(parseSummaryFilter(req.query as Record<string, unknown>)));
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.get('/api/summaries/:summaryId', async (req, res) => {
  try {
    const record = await repository.getSummary(req.params.summaryId, true);
    if (!record) { res.status(404).json({ error: 'summary not found' }); return; }
    res.json({ record });
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.post('/api/summaries', async (req, res) => {
  const parsed = createSummaryRequestSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  try {
    const record = await repository.createSummary(parsed.data as CreateSummaryRequest);
    res.status(201).json({ record });
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.put('/api/summaries/:summaryId', async (req, res) => {
  const parsed = updateSummaryRequestSchema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.flatten() }); return; }
  try {
    const record = await repository.updateSummary(req.params.summaryId, parsed.data as UpdateSummaryRequest);
    if (!record) { res.status(404).json({ error: 'summary not found' }); return; }
    res.json({ record });
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

app.delete('/api/summaries/:summaryId', async (req, res) => {
  try {
    const deleted = await repository.deleteSummary(req.params.summaryId);
    if (!deleted) { res.status(404).json({ error: 'summary not found' }); return; }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : String(error) });
  }
});

async function bootstrap(): Promise<void> {
  await repository.init();
  app.listen(config.port, () => {
    console.log(`time-persona backend listening on http://localhost:${config.port}`);
  });
}

bootstrap().catch((error) => {
  console.error('backend bootstrap failed', error);
  process.exitCode = 1;
});
