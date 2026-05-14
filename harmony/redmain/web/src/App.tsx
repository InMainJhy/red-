import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type KeyboardEvent,
  type PointerEvent as ReactPointerEvent,
} from 'react'

import './App.css'
import {
  buildAgents,
  loadPresets,
  loadProfile,
  parseTimeline,
  runArena,
} from './lib/api'
import type {
  ArenaMessage,
  ArenaMode,
  ArenaRun,
  PersonaSpec,
  PresetProfile,
  TimelineNode,
} from './types'

interface CharacterBundle {
  profile: PresetProfile
  nodes: TimelineNode[]
  agents: PersonaSpec[]
}

interface ChatLine {
  id: string
  agentId: string
  displayName: string
  stageLabel: string
  content: string
  stance: ArenaMessage['stance']
  source: 'user' | 'arena'
}

const LAYOUT_BREAKPOINT = 1100

function shortLabel(name: string) {
  const trimmed = name.trim()
  if (!trimmed) return '人'
  const first = [...trimmed][0]
  return first ?? '人'
}

function hashValue(input: string) {
  let hash = 0
  for (let index = 0; index < input.length; index += 1) {
    hash = (hash << 5) - hash + input.charCodeAt(index)
    hash |= 0
  }
  return Math.abs(hash)
}

function initialMarkStyle(seed: string): CSSProperties {
  const h = hashValue(seed) % 360
  return { color: `hsl(${h} 52% 34%)` }
}

function avatarStyle(seed: string): CSSProperties {
  const baseHue = hashValue(seed) % 360
  const accentHue = (baseHue + 48) % 360

  return {
    background: `linear-gradient(145deg, hsl(${baseHue} 76% 80%), hsl(${accentHue} 68% 56%))`,
    boxShadow: `0 18px 36px hsla(${baseHue}, 62%, 40%, 0.2)`,
  }
}

function createAvatarUrl(seed: string) {
  const paletteIndex = hashValue(`${seed}-${shortLabel(seed)}-palette`) % 5
  const skinTones = ['#f9d7b5', '#efc39e', '#d9a67e', '#f4c7a1', '#e6b88d']
  const hairTones = ['#2d1b12', '#4d3225', '#6f432a', '#1d2733', '#693d2f']
  const shirtTones = ['#4ea798', '#6689d3', '#9b75d4', '#dc8f58', '#4b7aa8']
  const backdrops = ['#dff4ec', '#e6eefb', '#f4e8fb', '#f7eadf', '#e4f1f9']
  const accentTones = ['#9fe2ca', '#b8cdf7', '#d8bdf4', '#f6c59a', '#add8ec']

  const skin = skinTones[paletteIndex]
  const hair = hairTones[(paletteIndex + 2) % hairTones.length]
  const shirt = shirtTones[(paletteIndex + 1) % shirtTones.length]
  const background = backdrops[paletteIndex]
  const halo = accentTones[paletteIndex]

  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">
      <rect width="120" height="120" rx="34" fill="${background}"/>
      <circle cx="60" cy="42" r="30" fill="${halo}" opacity="0.45"/>
      <path d="M25 106c5-19 18-31 35-31s30 12 35 31H25Z" fill="${shirt}"/>
      <circle cx="60" cy="49" r="22" fill="${skin}"/>
      <path d="M38 49c0-18 11-29 22-29 14 0 24 10 24 28 0 2 0 4-1 6-4-7-12-13-22-13-10 0-18 4-23 12-1-1 0-3 0-4Z" fill="${hair}"/>
      <circle cx="52" cy="49" r="2.8" fill="#263342"/>
      <circle cx="68" cy="49" r="2.8" fill="#263342"/>
      <path d="M53 60c4 4 10 4 14 0" stroke="#9b5c56" stroke-width="3" stroke-linecap="round"/>
      <path d="M43 42c2-4 6-7 11-8" stroke="${hair}" stroke-width="4" stroke-linecap="round"/>
      <path d="M77 42c-2-4-6-7-11-8" stroke="${hair}" stroke-width="4" stroke-linecap="round"/>
    </svg>
  `.trim()

  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

function App() {
  const [presets, setPresets] = useState<PresetProfile[]>([])
  const [customProfiles, setCustomProfiles] = useState<PresetProfile[]>([])
  const [loadedCharacters, setLoadedCharacters] = useState<Record<string, CharacterBundle>>({})
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set())
  const [selectedAgentIds, setSelectedAgentIds] = useState<string[]>([])

  const [topic, setTopic] = useState('现在应该继续坚持，还是及时换一条更稳的路？')
  const [arenaMode, setArenaMode] = useState<ArenaMode>('chat')
  const [arenaResult, setArenaResult] = useState<ArenaRun | null>(null)
  const [lastRunKey, setLastRunKey] = useState('')

  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [profileLoadingId, setProfileLoadingId] = useState<string | null>(null)
  const [importLoading, setImportLoading] = useState(false)
  const [arenaLoading, setArenaLoading] = useState(false)

  const [leftWidth, setLeftWidth] = useState(288)
  const [leftCollapsed, setLeftCollapsed] = useState(false)
  const [isCompactLayout, setIsCompactLayout] = useState(() => {
    if (typeof window === 'undefined') return false
    return window.innerWidth <= LAYOUT_BREAKPOINT
  })

  const [showImportForm, setShowImportForm] = useState(false)
  const [importName, setImportName] = useState('')
  const [importBio, setImportBio] = useState('')

  const allProfiles = [...presets, ...customProfiles]
  const allLoadedAgents = Object.values(loadedCharacters).flatMap((character) => character.agents)
  const selectedAgents = selectedAgentIds
    .map((agentId) => allLoadedAgents.find((agent) => agent.agentId === agentId))
    .filter((agent): agent is PersonaSpec => Boolean(agent))
  const currentRunKey = `${arenaMode}::${topic.trim()}::${[...selectedAgentIds].sort().join(',')}`
  const hasFreshArenaResult = Boolean(arenaResult) && currentRunKey === lastRunKey
  const effectiveLeftCollapsed = !isCompactLayout && leftCollapsed
  const sourceBusyText = importLoading
    ? '正在解析自定义角色，请稍候...'
    : profileLoadingId
      ? '正在整理人物时间线，请稍候...'
      : ''

  useEffect(() => {
    if (typeof window === 'undefined') return undefined

    const updateLayout = () => {
      setIsCompactLayout(window.innerWidth <= LAYOUT_BREAKPOINT)
    }

    updateLayout()
    window.addEventListener('resize', updateLayout)
    return () => window.removeEventListener('resize', updateLayout)
  }, [])

  useEffect(() => {
    if (isCompactLayout && leftCollapsed) {
      setLeftCollapsed(false)
    }
  }, [isCompactLayout, leftCollapsed])

  useEffect(() => {
    let alive = true

    const hydrate = async () => {
      try {
        const data = await loadPresets()
        if (alive) setPresets(data)
      } catch {
        if (alive) setError('加载预设角色失败')
      }
    }

    void hydrate()

    return () => {
      alive = false
    }
  }, [])

  const handleSelectProfile = useCallback(async (profile: PresetProfile) => {
    const profileId = profile.id

    setError('')
    setNotice('')

    if (loadedCharacters[profileId]) {
      setExpandedIds((previous) => {
        const next = new Set(previous)
        if (next.has(profileId)) next.delete(profileId)
        else next.add(profileId)
        return next
      })
      return
    }

    setProfileLoadingId(profileId)

    try {
      let nodes: TimelineNode[]
      let agents: PersonaSpec[]
      let resolvedProfile = profile

      if (!profileId.startsWith('custom-')) {
        try {
          const bundle = await loadProfile(profileId)
          nodes = bundle.nodes
          agents = bundle.agents
          resolvedProfile = bundle.profile ?? profile
          setLoadedCharacters((previous) => ({
            ...previous,
            [profileId]: { profile: resolvedProfile, nodes, agents },
          }))
          setExpandedIds((previous) => new Set(previous).add(profileId))
          setNotice(`${resolvedProfile.displayName} 已展开，可以直接挑选阶段人格。`)
          return
        } catch {
          // Fallback to parse + build when bundle endpoint is unavailable.
        }
      }

      const timeline = await parseTimeline({
        profileId,
        displayName: profile.displayName,
        biography: profile.biography,
      })
      const built = await buildAgents({
        personId: timeline.personId,
        displayName: timeline.displayName,
        biography: profile.biography,
        nodes: timeline.nodes,
      })
      nodes = timeline.nodes
      agents = built

      setLoadedCharacters((previous) => ({
        ...previous,
        [profileId]: { profile: resolvedProfile, nodes, agents },
      }))
      setExpandedIds((previous) => new Set(previous).add(profileId))
      setNotice(`${resolvedProfile.displayName} 已展开，可以直接挑选阶段人格。`)
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : '角色解析失败')
    } finally {
      setProfileLoadingId((current) => (current === profileId ? null : current))
    }
  }, [loadedCharacters])

  const toggleAgent = useCallback((agentId: string) => {
    setError('')
    setNotice('')
    setLastRunKey('')
    setSelectedAgentIds((current) => {
      if (current.includes(agentId)) {
        return current.filter((item) => item !== agentId)
      }

      if (current.length >= 3) {
        setNotice('最多同时选择 3 位阶段人格，请先取消一个再添加。')
        return current
      }

      return [...current, agentId]
    })
  }, [])

  const handleTopicChange = useCallback((value: string) => {
    setTopic(value)
    setLastRunKey('')
  }, [])

  const handleArenaModeChange = useCallback((value: ArenaMode) => {
    setArenaMode(value)
    setLastRunKey('')
  }, [])

  const handleRunArena = useCallback(async () => {
    if (selectedAgents.length < 2) {
      setError('至少选择 2 位阶段人格，会议才会开始。')
      return
    }

    if (!topic.trim()) {
      setError('请先输入一个具体的会议议题。')
      return
    }

    setError('')
    setNotice('')
    setArenaLoading(true)

    const runKey = `${arenaMode}::${topic.trim()}::${[...selectedAgentIds].sort().join(',')}`

    try {
      const result = await runArena({
        topic: topic.trim(),
        mode: arenaMode,
        selectedAgentIds,
        agents: allLoadedAgents,
      })
      setArenaResult(result)
      setLastRunKey(runKey)
      setNotice('本轮会议已生成，下面可以直接查看发言和纪要。')
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : '议会运行失败')
    } finally {
      setArenaLoading(false)
    }
  }, [allLoadedAgents, arenaMode, selectedAgentIds, selectedAgents.length, topic])

  const handleImport = useCallback(async () => {
    const trimmedName = importName.trim()
    const trimmedBio = importBio.trim()

    if (!trimmedName || !trimmedBio) {
      setError('请填写人物名称和传记文本。')
      return
    }

    setError('')
    setNotice('')
    setImportLoading(true)

    try {
      const timeline = await parseTimeline({
        displayName: trimmedName,
        biography: trimmedBio,
      })
      const built = await buildAgents({
        personId: timeline.personId,
        displayName: timeline.displayName,
        biography: trimmedBio,
        nodes: timeline.nodes,
      })

      const customProfile: PresetProfile = {
        id: `custom-${Date.now()}`,
        displayName: trimmedName,
        subtitle: '自定义导入角色',
        category: 'self',
        coverSeed: 'custom',
        biography: trimmedBio,
        highlights: [],
        suggestedTopics: [],
      }

      const profileId = customProfile.id
      setCustomProfiles((previous) => [...previous, customProfile])
      setLoadedCharacters((previous) => ({
        ...previous,
        [profileId]: { profile: customProfile, nodes: timeline.nodes, agents: built },
      }))
      setExpandedIds((previous) => new Set(previous).add(profileId))
      setArenaResult(null)
      setLastRunKey('')
      setImportName('')
      setImportBio('')
      setShowImportForm(false)
      setNotice(`${trimmedName} 已导入并展开，现在可以选择 TA 的阶段人格。`)
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : '导入解析失败')
    } finally {
      setImportLoading(false)
    }
  }, [importBio, importName])

  const handleClearSelection = useCallback(() => {
    setSelectedAgentIds([])
    setLastRunKey('')
    setError('')
    setNotice('已清空本轮会议阵容，请重新选择阶段人格。')
  }, [])

  const appShellStyle = {
    '--left-width': effectiveLeftCollapsed ? '72px' : `${leftWidth}px`,
  } as CSSProperties

  return (
    <div className={`app-shell ${isCompactLayout ? 'compact-layout' : ''}`} style={appShellStyle}>
      <div className={`col col-left ${effectiveLeftCollapsed ? 'collapsed' : ''}`}>
        <div className="col-header">
          {!isCompactLayout && (
            <button
              className="collapse-btn"
              onClick={() => setLeftCollapsed((current) => !current)}
              title={effectiveLeftCollapsed ? '展开角色栏' : '折叠角色栏'}
            >
              {effectiveLeftCollapsed ? '▶' : '◀'}
            </button>
          )}
          {!effectiveLeftCollapsed && (
            <>
              <span className="section-label">角色面板</span>
              <button
                className="add-btn"
                onClick={() => setShowImportForm((visible) => !visible)}
                title="导入自定义角色"
              >
                {showImportForm ? '×' : '+'}
              </button>
            </>
          )}
        </div>

        {!effectiveLeftCollapsed && (
          <SourcePanel
            showImportForm={showImportForm}
            allProfiles={allProfiles}
            loadedCharacters={loadedCharacters}
            expandedIds={expandedIds}
            selectedAgentIds={selectedAgentIds}
            onSelectProfile={handleSelectProfile}
            onToggleAgent={toggleAgent}
            importName={importName}
            importBio={importBio}
            setImportName={setImportName}
            setImportBio={setImportBio}
            onImport={handleImport}
            sourceBusyText={sourceBusyText}
            loadingProfileId={profileLoadingId}
            importLoading={importLoading}
          />
        )}
      </div>

      {!isCompactLayout && (
        <Divider
          side="left"
          onDrag={(delta) => setLeftWidth((width) => Math.max(240, Math.min(420, width + delta)))}
        />
      )}

      <div className="col col-center">
        <CouncilStage
          selectedAgents={selectedAgents}
          topic={topic}
          setTopic={handleTopicChange}
          arenaMode={arenaMode}
          setArenaMode={handleArenaModeChange}
          arenaResult={arenaResult}
          hasFreshArenaResult={hasFreshArenaResult}
          arenaLoading={arenaLoading}
          error={error}
          notice={notice}
          onRun={handleRunArena}
          onToggleAgent={toggleAgent}
          onClearSelection={handleClearSelection}
        />
      </div>
    </div>
  )
}

function Divider({
  side,
  onDrag,
}: {
  side: 'left' | 'right'
  onDrag: (delta: number) => void
}) {
  const dragging = useRef(false)
  const lastX = useRef(0)

  const onPointerDown = useCallback((event: ReactPointerEvent<HTMLDivElement>) => {
    event.preventDefault()
    dragging.current = true
    lastX.current = event.clientX
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'

    const onMove = (moveEvent: PointerEvent) => {
      if (!dragging.current) return
      const delta = moveEvent.clientX - lastX.current
      lastX.current = moveEvent.clientX
      onDrag(delta)
    }

    const onUp = () => {
      dragging.current = false
      document.body.style.cursor = ''
      document.body.style.userSelect = ''
      document.removeEventListener('pointermove', onMove)
      document.removeEventListener('pointerup', onUp)
      document.removeEventListener('pointercancel', onUp)
    }

    document.addEventListener('pointermove', onMove)
    document.addEventListener('pointerup', onUp)
    document.addEventListener('pointercancel', onUp)
  }, [onDrag])

  return <div className={`divider-handle divider-${side}`} onPointerDown={onPointerDown} />
}

function SourcePanel({
  showImportForm,
  allProfiles,
  loadedCharacters,
  expandedIds,
  selectedAgentIds,
  onSelectProfile,
  onToggleAgent,
  importName,
  importBio,
  setImportName,
  setImportBio,
  onImport,
  sourceBusyText,
  loadingProfileId,
  importLoading,
}: {
  showImportForm: boolean
  allProfiles: PresetProfile[]
  loadedCharacters: Record<string, CharacterBundle>
  expandedIds: Set<string>
  selectedAgentIds: string[]
  onSelectProfile: (profile: PresetProfile) => void
  onToggleAgent: (agentId: string) => void
  importName: string
  importBio: string
  setImportName: (value: string) => void
  setImportBio: (value: string) => void
  onImport: () => void
  sourceBusyText: string
  loadingProfileId: string | null
  importLoading: boolean
}) {
  return (
    <>
      <div className="source-overview">
        <div className="source-copy">
          <span className="source-eyebrow">会议筹备</span>
          <h2 className="source-title">先展开角色，再选上桌人格</h2>
          <p className="source-description">
            推荐选择 2 到 3 位阶段人格，这样讨论既有张力，也不会信息过载。
          </p>
        </div>
        <div className="source-stats">
          <div className="source-stat">
            <span className="source-stat-value">{Object.keys(loadedCharacters).length}</span>
            <span className="source-stat-label">已展开角色</span>
          </div>
          <div className="source-stat">
            <span className="source-stat-value">{selectedAgentIds.length}</span>
            <span className="source-stat-label">已选人格</span>
          </div>
        </div>
      </div>

      {sourceBusyText && <div className="panel-notice">{sourceBusyText}</div>}

      {showImportForm && (
        <div className="import-view">
          <p className="import-hint">
            粘贴任意人物传记后，系统会自动拆分成关键时间线，并生成可上桌的阶段人格。
          </p>
          <input
            className="import-name-input"
            placeholder="人物名称"
            value={importName}
            onChange={(event) => setImportName(event.target.value)}
          />
          <textarea
            className="import-textarea"
            placeholder="粘贴人物传记文本..."
            value={importBio}
            onChange={(event) => setImportBio(event.target.value)}
          />
          <button
            className="btn-import"
            disabled={importLoading || !importName.trim() || !importBio.trim()}
            onClick={onImport}
          >
            {importLoading ? '正在解析...' : '解析传记并生成时间线'}
          </button>
          <hr className="divider" />
        </div>
      )}

      <div className="role-list">
        {allProfiles.map((profile) => {
          const loaded = loadedCharacters[profile.id]
          const expanded = expandedIds.has(profile.id)
          const loading = loadingProfileId === profile.id

          return (
            <div key={profile.id} className="role-group">
              <button
                className={`role-item ${loaded ? 'loaded' : ''} ${expanded ? 'expanded' : ''} ${loading ? 'loading' : ''}`}
                disabled={loading}
                onClick={() => onSelectProfile(profile)}
              >
                <span className={`role-dot ${profile.id.startsWith('custom-') ? 'custom' : ''} ${loaded ? 'loaded' : ''}`} />
                <div className="role-copy">
                  <span className="role-name">{profile.displayName}</span>
                  <span className="role-sub">{profile.subtitle}</span>
                </div>
                {loading && <span className="role-status">加载中</span>}
                {!loading && loaded && <span className="expand-arrow">{expanded ? '▾' : '▸'}</span>}
              </button>

              {loaded && expanded && (
                <div className="timeline-spine nested">
                  {loaded.nodes.map((node, index) => {
                    const agent = loaded.agents[index]
                    const selected = agent ? selectedAgentIds.includes(agent.agentId) : false

                    return (
                      <button
                        key={node.nodeId}
                        className={`tl-node ${selected ? 'selected' : ''}`}
                        onClick={() => agent && onToggleAgent(agent.agentId)}
                        title={node.keyEvent}
                      >
                        <div className="tl-copy">
                          <span className="tl-label">{node.stageLabel}</span>
                          <span className="tl-detail">{node.keyEvent}</span>
                        </div>
                        <span className="tl-badge">{node.timeLabel}</span>
                      </button>
                    )
                  })}
                </div>
              )}
            </div>
          )
        })}
      </div>
    </>
  )
}

function CouncilStage({
  selectedAgents,
  topic,
  setTopic,
  arenaMode,
  setArenaMode,
  arenaResult,
  hasFreshArenaResult,
  arenaLoading,
  error,
  notice,
  onRun,
  onToggleAgent,
  onClearSelection,
}: {
  selectedAgents: PersonaSpec[]
  topic: string
  setTopic: (value: string) => void
  arenaMode: ArenaMode
  setArenaMode: (value: ArenaMode) => void
  arenaResult: ArenaRun | null
  hasFreshArenaResult: boolean
  arenaLoading: boolean
  error: string
  notice: string
  onRun: () => void
  onToggleAgent: (agentId: string) => void
  onClearSelection: () => void
}) {
  const messagesRef = useRef<HTMLDivElement | null>(null)
  const prevArenaLoading = useRef(false)
  const [chatLines, setChatLines] = useState<ChatLine[]>([])
  const [messageCount, setMessageCount] = useState(0)
  const [speakingAgentId, setSpeakingAgentId] = useState<string | null>(null)
  const [draft, setDraft] = useState('')

  const isArenaStreaming =
    Boolean(arenaResult && hasFreshArenaResult) &&
    arenaResult != null &&
    messageCount < arenaResult.messages.length

  useEffect(() => {
    if (selectedAgents.length === 0) {
      setSpeakingAgentId(null)
      return
    }
    setSpeakingAgentId((current) =>
      current && selectedAgents.some((a) => a.agentId === current)
        ? current
        : selectedAgents[0].agentId,
    )
  }, [selectedAgents])

  useEffect(() => {
    if (arenaLoading && !prevArenaLoading.current) {
      setChatLines([])
    }
    prevArenaLoading.current = arenaLoading
  }, [arenaLoading])

  useEffect(() => {
    if (!arenaResult || !hasFreshArenaResult) return
    setChatLines(
      arenaResult.messages.slice(0, messageCount).map((m) => ({
        id: m.id,
        agentId: m.agentId,
        displayName: m.displayName,
        stageLabel: m.stageLabel,
        content: m.content,
        stance: m.stance,
        source: 'arena' as const,
      })),
    )
  }, [arenaResult, hasFreshArenaResult, messageCount])

  useEffect(() => {
    if (!arenaResult || !hasFreshArenaResult) {
      const resetTimer = window.setTimeout(() => {
        setMessageCount(0)
      }, 0)
      return () => window.clearTimeout(resetTimer)
    }

    const resetTimer = window.setTimeout(() => {
      setMessageCount(0)
    }, 0)

    let index = 0

    const timer = window.setInterval(() => {
      index += 1
      setMessageCount(index)
      if (index >= arenaResult.messages.length) window.clearInterval(timer)
    }, 650)

    return () => {
      window.clearTimeout(resetTimer)
      window.clearInterval(timer)
    }
  }, [arenaResult, hasFreshArenaResult])

  useEffect(() => {
    const el = messagesRef.current
    if (!el) return
    el.scrollTop = el.scrollHeight
  }, [chatLines, arenaLoading, isArenaStreaming])

  const activeLineId = chatLines.at(-1)?.id ?? null
  const toneSeedForAgent = (agent: PersonaSpec) => `${agent.agentId}-${agent.stageLabel}`

  const sendDraft = useCallback(() => {
    const text = draft.trim()
    const agent = selectedAgents.find((a) => a.agentId === speakingAgentId)
    if (!text || !agent || arenaLoading || isArenaStreaming) return
    setChatLines((prev) => [
      ...prev,
      {
        id: `local-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
        agentId: agent.agentId,
        displayName: agent.displayName,
        stageLabel: agent.stageLabel,
        content: text,
        stance: 'neutral',
        source: 'user',
      },
    ])
    setDraft('')
  }, [draft, speakingAgentId, selectedAgents, arenaLoading, isArenaStreaming])

  const onDraftKeyDown = useCallback(
    (event: KeyboardEvent<HTMLTextAreaElement>) => {
      if (event.key === 'Enter' && !event.shiftKey) {
        event.preventDefault()
        sendDraft()
      }
    },
    [sendDraft],
  )

  const canCompose =
    selectedAgents.length >= 1 && !arenaLoading && !isArenaStreaming
  const showTypingTail =
    arenaResult &&
    hasFreshArenaResult &&
    messageCount < arenaResult.messages.length

  return (
    <>
      <div className="workspace-hero">
        <div className="hero-copy">
          <span className="source-eyebrow">会议工作台</span>
          <h1 className="center-title">人格就位</h1>
          <p className="center-subtitle">
            从左侧挑出 2 到 3 位阶段人格，在聊天区以头像区分身份发言，或由议会自动生成讨论。
          </p>
        </div>
        <div className="workspace-card">
          <span className="workspace-card-value">{selectedAgents.length}</span>
          <span className="workspace-card-label">已上桌人格 / 3</span>
        </div>
      </div>

      <div className="selection-strip">
        {selectedAgents.length > 0 ? (
          <>
            <div className="selection-scroll">
              {selectedAgents.map((agent) => (
                <div key={agent.agentId} className="selection-chip">
                  <div className="selection-chip-avatar" style={avatarStyle(agent.agentId)}>
                    <img
                      src={createAvatarUrl(`${agent.avatarSeed}-${agent.stageLabel}`)}
                      alt={agent.displayName}
                    />
                  </div>
                  <div className="selection-chip-copy">
                    <span className="selection-chip-title">{agent.displayName}</span>
                    <span className="selection-chip-meta">
                      {agent.stageLabel} · {agent.timeLabel}
                    </span>
                  </div>
                  <button
                    className="selection-chip-remove"
                    onClick={() => onToggleAgent(agent.agentId)}
                    title="移出本轮会议"
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
            <div className="selection-actions">
              <p>推荐 2 到 3 人，能兼顾观点多样性和讨论清晰度。</p>
              <button className="selection-clear" onClick={onClearSelection}>
                清空阵容
              </button>
            </div>
          </>
        ) : (
          <div className="selection-empty">
            还没有选中人格。先在左侧展开角色，再点击对应阶段卡片加入会议。
          </div>
        )}
      </div>

      <section className="debate-chat-panel">
        <header className="debate-chat-toolbar">
          <div className="debate-chat-toolbar-main">
            <span className="topic-tag">{arenaMode === 'chat' ? '圆桌对话' : '观点辩论'}</span>
            <h2 className="debate-chat-topic-title">{topic.trim() || '请输入会议议题'}</h2>
            <p className="debate-chat-toolbar-meta">
              {selectedAgents.length === 0
                ? '请先在左侧选择上桌人格'
                : selectedAgents.length < 2
                  ? `已选 ${selectedAgents.length} 位，至少 2 位可启动议会`
                  : `${selectedAgents.length} 位人格在讨论区就位 · 点头像切换发言身份`}
            </p>
          </div>
          {arenaResult && hasFreshArenaResult ? (
            <span className="debate-chat-count">
              {chatLines.length}
              {' / '}
              {arenaResult.messages.length}
              {' 条'}
            </span>
          ) : (
            <span className="debate-chat-count">{chatLines.length} 条消息</span>
          )}
        </header>

        <div className="debate-chat-participants" role="tablist" aria-label="选择发言人格">
          {selectedAgents.map((agent) => {
            const seed = toneSeedForAgent(agent)
            const active = speakingAgentId === agent.agentId
            return (
              <button
                key={agent.agentId}
                type="button"
                role="tab"
                aria-selected={active}
                className={`debate-chat-participant ${active ? 'active' : ''}`}
                onClick={() => setSpeakingAgentId(agent.agentId)}
                title={`以 ${agent.displayName} 身份发言`}
              >
                <div className="debate-chat-participant-avatar">
                  <span className="debate-chat-participant-initial" style={initialMarkStyle(seed)}>
                    {shortLabel(agent.displayName)}
                  </span>
                </div>
                <span className="debate-chat-participant-name">{agent.displayName}</span>
                <span className="debate-chat-participant-stage">{agent.stageLabel}</span>
              </button>
            )
          })}
        </div>

        <div className="debate-chat-messages" ref={messagesRef}>
          {chatLines.length === 0 && !arenaLoading && (
            <div className="debate-chat-empty">
              <p>
                {selectedAgents.length < 1
                  ? '从左侧展开角色并选择阶段人格后，他们会显示在上方。'
                  : '在下方输入并发送消息，或点击「启动议会」由系统按议题生成讨论，发言会逐条出现在这里。'}
              </p>
            </div>
          )}

          {chatLines.map((line) => (
            <article
              key={line.id}
              className={`chat-message debate-chat-msg ${line.stance} ${activeLineId === line.id ? 'active' : ''}`}
            >
              <div className="debate-chat-msg-avatar" aria-hidden>
                <span
                  className="debate-chat-msg-initial"
                  style={initialMarkStyle(`${line.agentId}-${line.stageLabel}`)}
                >
                  {shortLabel(line.displayName)}
                </span>
              </div>
              <div className="chat-message-body">
                <div className="chat-message-meta">
                  <strong>{line.displayName}</strong>
                  <span>
                    {line.stageLabel}
                    {line.source === 'user' ? ' · 手动' : ''}
                  </span>
                </div>
                <p>{line.content}</p>
              </div>
            </article>
          ))}

          {arenaLoading && !hasFreshArenaResult && (
            <article className="chat-message debate-chat-msg typing">
              <div className="debate-chat-msg-avatar ghost-avatar" />
              <div className="chat-message-body typing-body">
                <p className="debate-chat-pending-text">正在生成会议观点…</p>
              </div>
            </article>
          )}

          {showTypingTail ? (
            <article className="chat-message debate-chat-msg typing">
              <div className="debate-chat-msg-avatar ghost-avatar" />
              <div className="chat-message-body typing-body">
                <div className="typing-dots">
                  <span />
                  <span />
                  <span />
                </div>
              </div>
            </article>
          ) : null}
        </div>

        <div className="debate-chat-composer">
          <textarea
            className="debate-chat-input"
            placeholder={
              selectedAgents.length < 1
                ? '请先选择至少一位上桌人格'
                : arenaLoading || isArenaStreaming
                  ? '议会生成中，请稍候…'
                  : '输入消息，Enter 发送，Shift+Enter 换行'
            }
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            onKeyDown={onDraftKeyDown}
            disabled={!canCompose}
            rows={2}
          />
          <button
            type="button"
            className="debate-chat-send"
            disabled={!canCompose || !draft.trim()}
            onClick={sendDraft}
          >
            发送
          </button>
        </div>
        <p className="debate-chat-composer-hint">
          当前发言身份为上方高亮头像；启动议会后，AI 发言会按顺序实时出现在消息列表中。
        </p>
      </section>

      <div className="control-panel">
        <div className="control-header">
          <div>
            <span className="source-eyebrow">会议设置</span>
            <h3 className="control-title">设定这一轮要讨论的议题</h3>
          </div>
          <p className="control-help">问题越具体，发言会越聚焦，纪要也越有可执行性。</p>
        </div>

        <div className="topic-area">
          <label className="field-label" htmlFor="meeting-topic">会议议题</label>
          <textarea
            id="meeting-topic"
            className="topic-input"
            value={topic}
            onChange={(event) => setTopic(event.target.value)}
            placeholder="输入你想讨论的议题，例如：现在应该继续坚持，还是及时换一条更稳的路？"
          />
          <p className="helper-text">建议写成取舍题、决策题或阶段性难题，这样讨论更容易收敛。</p>
        </div>

        <div className="btn-row">
          <div className="mode-toggle">
            <button
              className={`mode-btn ${arenaMode === 'chat' ? 'active' : ''}`}
              onClick={() => setArenaMode('chat')}
            >
              对话
            </button>
            <button
              className={`mode-btn ${arenaMode === 'debate' ? 'active' : ''}`}
              onClick={() => setArenaMode('debate')}
            >
              辩论
            </button>
          </div>
          <button
            className="btn-primary"
            disabled={selectedAgents.length < 2 || arenaLoading || !topic.trim()}
            onClick={onRun}
          >
            {arenaLoading ? '会议生成中...' : '启动议会'}
          </button>
        </div>

        {notice && <p className="notice-text">{notice}</p>}
        {error && <p className="error-text">{error}</p>}
        {!hasFreshArenaResult && arenaResult && !arenaLoading && (
          <p className="stale-notice">你已经调整了议题、模式或上桌人格，请重新启动会议以刷新结果。</p>
        )}
      </div>

      {!arenaLoading && !hasFreshArenaResult && (
        <div className="empty-council">
          <div className="icon">○</div>
          <p>
            {selectedAgents.length < 2
              ? '选择至少两个时间线节点，才能开始本轮会议。'
              : '阵容和议题已经准备好了，点击“启动议会”即可开始实时发言。'}
          </p>
        </div>
      )}

      {arenaResult && hasFreshArenaResult && (
        <section className="summary-card">
          <div className="summary-header">
            <div>
              <span className="summary-eyebrow">本轮纪要</span>
              <h3 className="summary-title">{arenaResult.summary.title}</h3>
            </div>
            <span className="summary-meta">
              {arenaResult.messages.length} 条发言 · {arenaResult.participants.length} 位参与者
            </span>
          </div>

          <p className="summary-consensus">{arenaResult.summary.consensus}</p>

          <div className="summary-grid">
            <div className="summary-section">
              <h4>仍然存在的分歧</h4>
              <ul className="summary-list">
                {(arenaResult.summary.disagreements.length > 0
                  ? arenaResult.summary.disagreements
                  : ['本轮讨论中没有明显残留分歧。']
                ).map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>

            <div className="summary-section">
              <h4>可执行建议</h4>
              <ul className="summary-list">
                {(arenaResult.summary.actionableAdvice.length > 0
                  ? arenaResult.summary.actionableAdvice
                  : ['暂未生成具体建议，请重新组织议题后再试。']
                ).map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
            </div>
          </div>

          <div className="summary-hook">{arenaResult.summary.narrativeHook}</div>
        </section>
      )}
    </>
  )
}

export default App
