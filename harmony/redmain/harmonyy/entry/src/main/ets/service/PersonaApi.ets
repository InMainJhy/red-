import { http } from '@kit.NetworkKit'
import {
  ArenaMode,
  ArenaRun,
  ArenaRunRequest,
  ArenaRunResponse,
  ArenaStreamEvent,
  ArenaStreamEventType,
  BuildAgentsRequest,
  BuildAgentsResponse,
  HealthCheckResponse,
  ParseTimelineRequest,
  ParseTimelineResponse,
  PersonaSpec,
  PresetProfile,
  PresetsResponse,
  ProfileBundle,
  SelectedAgentsBundle,
  TimelineNode
} from '../common/Models'
import {
  buildAgents,
  buildArenaRun,
  getPresetProfiles,
  getProfileById,
  getTimelineByProfileId
} from '../data/MockData'

// 线上服务 Base URL
const API_BASE_URL = 'https://hackhathon.69d5c46af2ab61f5dd649c62.servers.onzeabur.com'

// 本地开发环境备用地址
const LOCAL_BASE_URLS: string[] = [
  'http://192.168.51.148:3030',
  'http://10.0.2.2:3030',
  'http://127.0.0.1:3030',
  'http://localhost:3030'
]

const PROFILE_TIMEOUT_MS: number = 20_000
const GENERATION_TIMEOUT_MS: number = 300_000

let activeBaseUrl: string = API_BASE_URL
let lastConnectionLabel: string = 'LIVE · 线上服务'

function normalizePayload(result: Object | string): string {
  if (typeof result === 'string') {
    return result
  }
  return JSON.stringify(result)
}

function parseJson<T>(result: Object | string): T {
  return JSON.parse(normalizePayload(result)) as T
}

function parseErrorMessage(result: Object | string, statusCode: number): string {
  try {
    const payload = parseJson<Record<string, Object | string>>(result)
    const errorValue = payload.error

    if (typeof errorValue === 'string') {
      return errorValue
    }

    if (errorValue) {
      const flatError = errorValue as Record<string, Object>
      const fieldErrors = flatError.fieldErrors as Record<string, string[]> | undefined
      if (fieldErrors) {
        let messages: string[] = []
        Object.keys(fieldErrors).forEach((key: string) => {
          const values = fieldErrors[key]
          if (values && values.length > 0) {
            messages.push(`${key}: ${values[0]}`)
          }
        })
        if (messages.length > 0) {
          return messages.join('；')
        }
      }
    }
  } catch (_error) {
  }

  return `请求失败 ${statusCode}`
}

function formatThrownError(error: Object): string {
  if (typeof error === 'string') {
    return error
  }

  const maybeMessage = error as Record<string, string>
  if (maybeMessage.message) {
    return maybeMessage.message
  }

  return JSON.stringify(error)
}

function buildMockBundle(profileId: string): ProfileBundle | null {
  const profile = getProfileById(profileId)
  if (!profile.id.length) {
    return null
  }

  const nodes = getTimelineByProfileId(profileId)
  return {
    profile,
    nodes,
    agents: buildAgents(profile.id, profile.displayName, nodes)
  }
}

function buildCustomProfile(profileId: string, displayName: string, biography: string, nodes: TimelineNode[]): PresetProfile {
  return {
    id: profileId,
    displayName,
    subtitle: '自定义导入角色',
    category: 'self',
    coverSeed: profileId,
    biography,
    highlights: nodes.slice(0, 4).map((node: TimelineNode) => node.stageLabel),
    suggestedTopics: [
      '现在最该坚持的到底是什么？',
      '应该继续投入还是及时止损？',
      '边界、野心和现实怎么重新排序？'
    ]
  }
}

function buildParseTimelineRequest(displayName: string, biography: string): ParseTimelineRequest {
  return {
    displayName,
    biography
  }
}

function buildAgentsRequest(parsed: ParseTimelineResponse, biography: string): BuildAgentsRequest {
  return {
    personId: parsed.personId,
    displayName: parsed.displayName,
    biography,
    nodes: parsed.nodes
  }
}

function buildArenaRunRequest(topic: string, mode: ArenaMode, selectedAgents: PersonaSpec[]): ArenaRunRequest {
  return {
    topic,
    mode,
    selectedAgentIds: selectedAgents.map((agent: PersonaSpec) => agent.agentId),
    agents: selectedAgents
  }
}

async function requestJson<T>(path: string, method: http.RequestMethod, body?: Object, timeoutMs: number = PROFILE_TIMEOUT_MS): Promise<T> {
  try {
    const client = http.createHttp()

    try {
      let response = await client.request(`${activeBaseUrl}${path}`, {
        method,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: body ? JSON.stringify(body) : '',
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs
      })

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return parseJson<T>(response.result)
      }

      throw new Error(parseErrorMessage(response.result, response.responseCode))
    } finally {
      client.destroy()
    }
  } catch (error) {
    throw new Error(formatThrownError(error as Object))
  }
}

// SSE 流式解析器
function parseSSELine(line: string): SSELineResult | null {
  if (!line || line.startsWith(':')) {
    return null
  }
  const colonIndex = line.indexOf(':')
  if (colonIndex === -1) {
    return { field: line.trim(), value: '' }
  }
  const field = line.substring(0, colonIndex).trim()
  let value = line.substring(colonIndex + 1).trim()
  if (value.startsWith(' ')) {
    value = value.substring(1)
  }
  return { field, value }
}

// SSE 事件解析器类型
export type SSEEventHandler = (event: ArenaStreamEvent) => void
export type SSEErrorHandler = (error: string) => void
export type SSECompleteHandler = () => void

// SSE 行解析结果接口
export interface SSELineResult {
  field: string
  value: string
}

// SSE 解析后的数据接口
interface SSEParsedData {
  type?: string
  runId?: string
  mode?: string
  topic?: string
  sequence?: number
  timestamp?: string
  message?: string
  message_?: string
}

// 定义有效的事件类型数组（避免索引访问类型）
const VALID_STREAM_EVENT_TYPES: ArenaStreamEventType[] = [
  'run_started', 'phase_started', 'message', 'phase_completed',
  'summary_started', 'summary', 'done', 'error'
]

// 辅助函数：解析事件类型
function parseStreamEventType(type: string): ArenaStreamEventType {
  const validIndex: number = VALID_STREAM_EVENT_TYPES.indexOf(type as ArenaStreamEventType)
  if (validIndex >= 0) {
    return VALID_STREAM_EVENT_TYPES[validIndex]
  }
  return 'message'
}

// 辅助函数：解析 Arena 模式
function parseStreamArenaMode(mode?: string): ArenaMode {
  if (mode === 'debate') {
    return 'debate'
  }
  return 'chat'
}

export class PersonaApi {
  static getConnectionLabel(): string {
    return lastConnectionLabel
  }

  static async checkHealth(): Promise<HealthCheckResponse | null> {
    try {
      return await requestJson<HealthCheckResponse>('/health', http.RequestMethod.GET, undefined, 10_000)
    } catch (_error) {
      return null
    }
  }

  static async getPresets(): Promise<PresetProfile[]> {
    try {
      const result = await requestJson<PresetsResponse>('/api/presets', http.RequestMethod.GET)
      return result.presets
    } catch (_error) {
      lastConnectionLabel = 'MOCK FALLBACK'
      return Promise.resolve(getPresetProfiles())
    }
  }

  static async getProfileBundle(profileId: string): Promise<ProfileBundle> {
    try {
      return await requestJson<ProfileBundle>(`/api/profiles/${encodeURIComponent(profileId)}`, http.RequestMethod.GET)
    } catch (error) {
      const mockBundle = buildMockBundle(profileId)
      if (mockBundle) {
        lastConnectionLabel = 'MOCK FALLBACK'
        return Promise.resolve(mockBundle)
      }
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async getSelectedAgents(profileId: string, selectedAgentIds: string[]): Promise<SelectedAgentsBundle> {
    const bundle = await PersonaApi.getProfileBundle(profileId)
    const selectedAgents = bundle.agents.filter((agent: PersonaSpec) => selectedAgentIds.includes(agent.agentId))
    let selectedBundle: SelectedAgentsBundle = { profile: bundle.profile, selectedAgents }
    return Promise.resolve(selectedBundle)
  }

  static async importCustomProfile(displayName: string, biography: string): Promise<ProfileBundle> {
    const parseRequest: ParseTimelineRequest = buildParseTimelineRequest(displayName, biography)
    const parsed = await requestJson<ParseTimelineResponse>('/api/timeline/parse', http.RequestMethod.POST, parseRequest, GENERATION_TIMEOUT_MS)

    const agentsRequest: BuildAgentsRequest = buildAgentsRequest(parsed, biography)
    const built = await requestJson<BuildAgentsResponse>('/api/agents/build', http.RequestMethod.POST, agentsRequest, GENERATION_TIMEOUT_MS)

    try {
      const storedBundle = await requestJson<ProfileBundle>(`/api/profiles/${encodeURIComponent(parsed.personId)}`, http.RequestMethod.GET)
      if (storedBundle.agents.length === 0) {
        storedBundle.agents = built.agents
      }
      return storedBundle
    } catch (_error) {
      const fallbackBundle: ProfileBundle = {
        profile: buildCustomProfile(parsed.personId, parsed.displayName, biography, parsed.nodes),
        nodes: parsed.nodes,
        agents: built.agents
      }
      return Promise.resolve(fallbackBundle)
    }
  }

  static async runArena(topic: string, selectedAgents: PersonaSpec[], mode: ArenaMode = 'chat'): Promise<ArenaRun> {
    try {
      const arenaRequest: ArenaRunRequest = buildArenaRunRequest(topic, mode, selectedAgents)
      const result = await requestJson<ArenaRunResponse>('/api/arena/run', http.RequestMethod.POST, arenaRequest, GENERATION_TIMEOUT_MS)
      return result.result
    } catch (_error) {
      lastConnectionLabel = 'MOCK FALLBACK'
      return Promise.resolve(buildArenaRun(topic, selectedAgents, mode))
    }
  }

  static async streamArena(
    topic: string,
    selectedAgents: PersonaSpec[],
    mode: ArenaMode = 'chat',
    onEvent?: SSEEventHandler,
    onError?: SSEErrorHandler,
    onComplete?: SSECompleteHandler
  ): Promise<void> {
    const client = http.createHttp()

    try {
      const arenaRequest: ArenaRunRequest = buildArenaRunRequest(topic, mode, selectedAgents)

      // SSE 流式请求
      const response = await client.request(`${activeBaseUrl}/api/arena/stream`, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(arenaRequest),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: GENERATION_TIMEOUT_MS,
        readTimeout: GENERATION_TIMEOUT_MS
      })

      if (response.responseCode !== 200) {
        throw new Error(`流式请求失败: ${response.responseCode}`)
      }

      const content = response.result as string
      const lines = content.split('\n')

      let eventData: Record<string, string> = {}
      let eventType: string = ''

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i]

        if (!line.trim()) {
          if (eventType && Object.keys(eventData).length > 0) {
            const dataStr = eventData['data']
            if (dataStr) {
              try {
                const parsedData: SSEParsedData = JSON.parse(dataStr)
                const event: ArenaStreamEvent = {
                  type: parseStreamEventType(eventType),
                  runId: parsedData.runId ?? '',
                  mode: parseStreamArenaMode(parsedData.mode),
                  topic: parsedData.topic ?? '',
                  sequence: parsedData.sequence ?? 0,
                  timestamp: parsedData.timestamp ?? ''
                }
                onEvent?.(event)

                if (eventType === 'done' || eventType === 'error') {
                  if (eventType === 'done') {
                    onComplete?.()
                  }
                  if (eventType === 'error') {
                    const errorMsg: string = parsedData.message ?? parsedData.message_ ?? '流式传输错误'
                    onError?.(errorMsg)
                  }
                  break
                }
              } catch (parseError) {
                // 忽略解析错误
              }
            }
          }
          eventData = {}
          eventType = ''
          continue
        }

        const parsed = parseSSELine(line)
        if (!parsed) {
          continue
        }

        if (parsed.field === 'event') {
          eventType = parsed.value
        } else if (parsed.field === 'data') {
          eventData['data'] = parsed.value
        } else {
          eventData[parsed.field] = parsed.value
        }
      }
    } catch (error) {
      onError?.(formatThrownError(error as Object))
    } finally {
      client.destroy()
    }
  }
}
