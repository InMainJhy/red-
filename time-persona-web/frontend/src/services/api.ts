import {
  ArenaMode, ArenaRun, ArenaRunHistoryItem, ArenaStreamEvent,
  BuildAgentsRequest, BuildAgentsResponse, CreateSummaryRequest, ParseTimelineRequest,
  ParseTimelineResponse, PersonaSpec, PresetProfile, ProfileBundle,
  SummaryRecord, SummaryListResponse,
} from '../types';

const API_BASE = '/api';

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: `HTTP ${res.status}` }));
    throw new Error(err.error || `HTTP ${res.status}`);
  }
  if (res.status === 204) return {} as T;
  return res.json();
}

async function streamPost(
  url: string,
  body: unknown,
  onEvent: (event: ArenaStreamEvent) => void,
  onError: (error: string) => void,
  onComplete: () => void,
): Promise<void> {
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok || !res.body) {
      onError(`HTTP ${res.status}`);
      return;
    }
    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6).trim();
          if (data === '[DONE]') { onComplete(); return; }
          try {
            const parsed = JSON.parse(data);
            if (parsed.type === 'error') { onError(parsed.error || 'Unknown error'); return; }
            onEvent(parsed as ArenaStreamEvent);
          } catch { /* ignore parse errors */ }
        }
      }
    }
    onComplete();
  } catch (err) {
    onError(err instanceof Error ? err.message : 'Connection lost');
  }
}

export const PersonaApi = {
  getPresets: () => request<{ presets: PresetProfile[] }>('/presets').then(r => r.presets),

  getProfileBundle: (profileId: string) =>
    request<ProfileBundle>(`/profiles/${profileId}`),

  parseTimeline: (data: ParseTimelineRequest) =>
    request<ParseTimelineResponse>('/timeline/parse', { method: 'POST', body: JSON.stringify(data) }),

  buildAgents: (data: BuildAgentsRequest) =>
    request<BuildAgentsResponse>('/agents/build', { method: 'POST', body: JSON.stringify(data) }),

  runArena: (topic: string, agents: PersonaSpec[], mode: ArenaMode) =>
    request<{ result: ArenaRun }>('/arena/run', {
      method: 'POST',
      body: JSON.stringify({ topic, mode, selectedAgentIds: agents.map(a => a.agentId), agents }),
    }).then(r => r.result),

  getArenaHistory: () =>
    request<{ runs: ArenaRunHistoryItem[] }>('/arena/history').then(r => r.runs),

  streamArena(
    topic: string,
    agents: PersonaSpec[],
    mode: ArenaMode,
    onEvent: (event: ArenaStreamEvent) => void,
    onError: (error: string) => void,
    onComplete: () => void,
    roundCount?: number,
  ) {
    return streamPost(
      `${API_BASE}/arena/stream`,
      { topic, mode, selectedAgentIds: agents.map(a => a.agentId), agents, roundCount },
      onEvent, onError, onComplete,
    );
  },

  getSummaries: (params?: Record<string, string>) => {
    const qs = params ? '?' + new URLSearchParams(params).toString() : '';
    return request<SummaryListResponse>(`/summaries${qs}`);
  },

  getSummary: (id: string) =>
    request<{ record: SummaryRecord }>(`/summaries/${id}`).then(r => r.record),

  createSummary: (data: CreateSummaryRequest) =>
    request<{ record: SummaryRecord }>('/summaries', { method: 'POST', body: JSON.stringify(data) }).then(r => r.record),

  updateSummary: (id: string, data: { isFavorite?: boolean; tags?: string[]; title?: string }) =>
    request<{ record: SummaryRecord }>(`/summaries/${id}`, { method: 'PUT', body: JSON.stringify(data) }).then(r => r.record),

  deleteSummary: (id: string) => request<void>(`/summaries/${id}`, { method: 'DELETE' }),

  health: () => request<{ ok: boolean; timestamp: string }>('/health'),
};
