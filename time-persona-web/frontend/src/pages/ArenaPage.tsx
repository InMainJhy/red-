import { useState, useEffect, useRef } from 'react';
import { useParams, useLocation, Link } from 'react-router-dom';
import { ArrowLeft, Send, Square, RotateCcw, FileText, Sparkles } from 'lucide-react';
import { PersonaApi } from '../services/api';
import type { ArenaMode, ArenaMessage, PersonaSpec, PresetProfile, ArenaRun, ArenaStreamEvent } from '../types';

type MeetingState = 'idle' | 'running' | 'completed' | 'error';

const PHASE_LABELS: Record<string, string> = {
  opening: '开场陈述', reflection: '互相理解', rebuttal: '正面交锋',
  synthesis: '综合回应', closing: '收束陈词', manual: '提问',
};

export default function ArenaPage() {
  const { profileId } = useParams<{ profileId: string }>();
  const location = useLocation();
  const stateData = location.state as {
    profile?: PresetProfile;
    agents?: PersonaSpec[];
    selectedAgentIds?: string[];
  } | null;

  const [profile, setProfile] = useState<PresetProfile | null>(stateData?.profile ?? null);
  const [agents, setAgents] = useState<PersonaSpec[]>(stateData?.agents ?? []);
  const [selectedIds, setSelectedIds] = useState<string[]>(stateData?.selectedAgentIds ?? []);
  const [topic, setTopic] = useState('现在该不该离开这份长期消耗我的工作？');
  const [mode, setMode] = useState<ArenaMode>('chat');
  const [meetingState, setMeetingState] = useState<MeetingState>('idle');
  const [messages, setMessages] = useState<ArenaMessage[]>([]);
  const [liveDraft, setLiveDraft] = useState<{ agentId: string; displayName: string; text: string } | null>(null);
  const [summaryText, setSummaryText] = useState('');
  const [result, setResult] = useState<ArenaRun | null>(null);
  const [error, setError] = useState('');
  const [phaseLabel, setPhaseLabel] = useState('');
  const [activeSegment, setActiveSegment] = useState<0 | 1>(0);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!stateData?.profile && profileId) loadBundle();
  }, [profileId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, liveDraft]);

  async function loadBundle() {
    if (!profileId) return;
    try {
      const bundle = await PersonaApi.getProfileBundle(profileId);
      setProfile(bundle.profile);
      setAgents(bundle.agents);
      if (selectedIds.length === 0 && bundle.agents.length >= 2) {
        setSelectedIds([bundle.agents[0].agentId, bundle.agents[1].agentId]);
      }
      if (bundle.profile.suggestedTopics.length > 0) {
        setTopic(bundle.profile.suggestedTopics[0]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : '加载失败');
    }
  }

  function toggleAgent(agentId: string) {
    if (meetingState === 'running') return;
    setSelectedIds(prev =>
      prev.includes(agentId)
        ? prev.length > 1 ? prev.filter(id => id !== agentId) : prev
        : [...prev, agentId]
    );
  }

  async function startMeeting() {
    const selectedAgents = agents.filter(a => selectedIds.includes(a.agentId));
    if (selectedAgents.length < 2) return;

    setMeetingState('running');
    setError('');
    setMessages([]);
    setLiveDraft(null);
    setSummaryText('');
    setResult(null);
    setPhaseLabel('准备中...');
    setActiveSegment(1);

    try {
      const run = await PersonaApi.runArena(topic, selectedAgents, mode);
      setMessages(run.messages);
      setResult(run);
      setPhaseLabel('会议完成');
      setMeetingState('completed');
    } catch (err) {
      setError(err instanceof Error ? err.message : '会议失败');
      setMeetingState('error');
      setPhaseLabel('发生错误');
    }
  }

  function resetMeeting() {
    setMeetingState('idle');
    setMessages([]);
    setLiveDraft(null);
    setSummaryText('');
    setResult(null);
    setError('');
    setPhaseLabel('');
    setActiveSegment(0);
  }

  function getAgentName(agentId: string): string {
    return agents.find(a => a.agentId === agentId)?.displayName ?? agentId;
  }

  const selectedAgents = agents.filter(a => selectedIds.includes(a.agentId));

  return (
    <div className="min-h-screen bg-background relative flex flex-col">
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute -top-16 -left-16 w-72 h-72 rounded-full bg-indigo-50 opacity-60 blur-3xl" />
        <div className="absolute top-20 -right-16 w-64 h-64 rounded-full bg-purple-50 opacity-40 blur-3xl" />
      </div>

      <div className="relative max-w-2xl mx-auto px-4 pt-4 pb-6 w-full flex-1 flex flex-col">
        {/* Top bar */}
        <div className="flex items-center gap-3 mb-4">
          <Link to={profileId ? `/profile/${profileId}` : '/'} className="w-9 h-9 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow-sm border border-slate-100 hover:bg-white transition-colors flex-shrink-0">
            <ArrowLeft size={16} className="text-mint-dark" />
          </Link>
          <div className="flex-1">
            <p className="font-medium text-slate-800 text-sm">{profile?.displayName ?? '人格会议'}</p>
            <p className="text-xs text-slate-400 flex items-center gap-1">
              <span className={`inline-block w-1.5 h-1.5 rounded-full ${
                meetingState === 'running' ? 'bg-red-400 animate-pulse' :
                meetingState === 'completed' ? 'bg-green-400' :
                meetingState === 'error' ? 'bg-red-400' : 'bg-slate-300'
              }`} />
              {phaseLabel || '等待发起'}
            </p>
          </div>
          <span className="text-xs font-medium text-mint bg-mint-bg px-3 py-1.5 rounded-pill">
            {selectedIds.length}人格
          </span>
        </div>

        {/* Segment control */}
        <div className="flex gap-1 bg-white/60 rounded-xl p-1 mb-4 shadow-sm border border-slate-100">
          <button
            onClick={() => setActiveSegment(0)}
            className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${activeSegment === 0 ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400'}`}
          >
            {activeSegment === 0 ? '● ' : ''}设定
          </button>
          <button
            onClick={() => setActiveSegment(1)}
            className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${activeSegment === 1 ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-400'}`}
          >
            {activeSegment === 1 ? '● ' : ''}现场
          </button>
        </div>

        {/* Config segment */}
        {activeSegment === 0 && (
          <div className="space-y-4 flex-1">
            {/* Topic */}
            <div>
              <label className="text-xs text-slate-400 block mb-1.5">辩题 / 议题</label>
              <textarea
                value={topic}
                onChange={e => setTopic(e.target.value)}
                disabled={meetingState === 'running'}
                rows={2}
                className="w-full px-4 py-3 bg-white rounded-xl border border-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-mint/30 resize-none disabled:opacity-50"
                placeholder="输入讨论话题..."
              />
            </div>

            {/* Mode */}
            <div>
              <label className="text-xs text-slate-400 block mb-1.5">讨论模式</label>
              <div className="flex gap-2">
                <button
                  onClick={() => setMode('chat')}
                  disabled={meetingState === 'running'}
                  className={`flex-1 py-2.5 rounded-xl text-sm font-medium transition-all ${mode === 'chat' ? 'bg-indigo-500 text-white' : 'bg-white text-slate-500 border border-slate-100'}`}
                >
                  聊天模式
                </button>
                <button
                  onClick={() => setMode('debate')}
                  disabled={meetingState === 'running'}
                  className={`flex-1 py-2.5 rounded-xl text-sm font-medium transition-all ${mode === 'debate' ? 'bg-red-500 text-white' : 'bg-white text-slate-500 border border-slate-100'}`}
                >
                  辩论模式
                </button>
              </div>
            </div>

            {/* Agent selector */}
            <div>
              <label className="text-xs text-slate-400 block mb-1.5">
                阶段人格 · 已选 {selectedIds.length} 位
              </label>
              <div className="space-y-2">
                {agents.map(agent => (
                  <button
                    key={agent.agentId}
                    onClick={() => toggleAgent(agent.agentId)}
                    disabled={meetingState === 'running'}
                    className={`w-full flex items-center gap-3 p-3 rounded-xl text-left transition-all ${
                      selectedIds.includes(agent.agentId)
                        ? 'bg-indigo-50 border-2 border-indigo-200'
                        : 'bg-white border border-slate-100 hover:border-mint/30'
                    }`}
                  >
                    <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 ${
                      selectedIds.includes(agent.agentId) ? 'bg-indigo-500 text-white' : 'bg-slate-100 text-slate-500'
                    }`}>
                      {agent.displayName.charAt(0)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-slate-700 text-sm">{agent.displayName}</p>
                      <p className="text-xs text-slate-400 truncate">{agent.stageLabel} · {agent.timeLabel}</p>
                    </div>
                  </button>
                ))}
              </div>
            </div>

            {error && <p className="text-sm text-red-500 bg-red-50 p-3 rounded-xl">{error}</p>}
          </div>
        )}

        {/* Live segment */}
        {activeSegment === 1 && (
          <div className="flex-1 flex flex-col gap-3">
            {/* Messages */}
            <div className="flex-1 overflow-y-auto space-y-3 pb-2">
              {messages.length === 0 && !liveDraft && meetingState !== 'running' && (
                <div className="flex flex-col items-center justify-center py-16 text-slate-400">
                  <FileText size={32} className="mb-3 text-slate-300" />
                  <p className="font-medium">对话尚未开始</p>
                  <p className="text-sm">在「设定」区选择人格后点击「启动讨论」</p>
                </div>
              )}

              {messages.map(msg => (
                <div key={msg.id} className={`flex ${msg.agentId === 'user-prompt' ? 'justify-end' : 'justify-start'}`}>
                  {msg.agentId !== 'user-prompt' && (
                    <div className="w-8 h-8 rounded-full bg-indigo-500 flex items-center justify-center text-white text-xs font-bold mr-2 flex-shrink-0 mt-1">
                      {getAgentName(msg.agentId).charAt(0)}
                    </div>
                  )}
                  <div className={`max-w-[78%] ${
                    msg.agentId === 'user-prompt'
                      ? 'bg-mint/15 rounded-2xl rounded-tr-sm'
                      : 'bg-white border border-slate-100 rounded-2xl rounded-tl-sm'
                  }`}>
                    {msg.agentId !== 'user-prompt' && (
                      <div className="flex items-center gap-1.5 px-3 pt-2.5">
                        <span className="text-xs font-medium text-slate-700">{getAgentName(msg.agentId)}</span>
                        {msg.phase && (
                          <>
                            <span className="text-xs text-slate-300">·</span>
                            <span className="text-xs text-indigo-500">{PHASE_LABELS[msg.phase] || msg.phase}</span>
                          </>
                        )}
                      </div>
                    )}
                    <p className="text-sm text-slate-700 px-3 py-2 leading-relaxed">{msg.content}</p>
                  </div>
                </div>
              ))}

              {/* Live draft */}
              {liveDraft && (
                <div className="flex justify-start">
                  <div className="w-8 h-8 rounded-full bg-indigo-200 flex items-center justify-center text-indigo-600 text-xs font-bold mr-2 flex-shrink-0 mt-1">
                    {liveDraft.displayName.charAt(0)}
                  </div>
                  <div className="max-w-[78%] bg-indigo-50 rounded-2xl rounded-tl-sm">
                    <div className="flex items-center gap-1.5 px-3 pt-2.5">
                      <span className="text-xs font-medium text-slate-700">{liveDraft.displayName}</span>
                      <span className="text-xs text-indigo-400">输入中...</span>
                    </div>
                    <p className="text-sm text-slate-500 px-3 py-2">{liveDraft.text || '...'}<span className="text-indigo-400">|</span></p>
                  </div>
                </div>
              )}

              <div ref={messagesEndRef} />
            </div>

            {/* Summary */}
            {result?.summary && (
              <div className="bg-white rounded-xxl p-4 border border-slate-100 space-y-3">
                <h3 className="font-semibold text-slate-800">{result.summary.title}</h3>
                <div className="bg-mint-bg rounded-lg p-3">
                  <p className="text-xs text-mint-dark font-medium mb-1">共识</p>
                  <p className="text-sm text-slate-600">{result.summary.consensus}</p>
                </div>
                {result.summary.disagreements.length > 0 && (
                  <div className="bg-purple-50 rounded-lg p-3">
                    <p className="text-xs text-purple-600 font-medium mb-1">分歧</p>
                    {result.summary.disagreements.map((d, i) => (
                      <p key={i} className="text-sm text-slate-600">• {d}</p>
                    ))}
                  </div>
                )}
                {result.summary.actionableAdvice.length > 0 && (
                  <div className="bg-amber-50 rounded-lg p-3">
                    <p className="text-xs text-amber-600 font-medium mb-1">行动建议</p>
                    {result.summary.actionableAdvice.map((a, i) => (
                      <p key={i} className="text-sm text-slate-600">• {a}</p>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* Control buttons */}
        <div className="mt-4 bg-white rounded-xxl p-3 border border-slate-100 shadow-sm">
          {meetingState === 'idle' && (
            <button
              onClick={startMeeting}
              disabled={selectedIds.length < 2}
              className="w-full py-3 bg-indigo-500 text-white rounded-pill font-medium text-sm hover:bg-indigo-600 transition-colors disabled:opacity-40 flex items-center justify-center gap-2"
            >
              <Sparkles size={16} />
              {selectedIds.length >= 2 ? '启动讨论' : `还需 ${2 - selectedIds.length} 位人格`}
            </button>
          )}
          {meetingState === 'running' && (
            <div className="flex gap-2">
              <div className="flex-1 py-3 text-center text-sm text-slate-400 animate-pulse">会议进行中...</div>
            </div>
          )}
          {meetingState === 'completed' && (
            <div className="space-y-2">
              <div className="flex gap-2">
                <button onClick={resetMeeting} className="flex-1 py-3 bg-white text-slate-500 rounded-pill font-medium text-sm border border-slate-100 hover:bg-slate-50 transition-colors">
                  再来一轮
                </button>
              </div>
            </div>
          )}
          {meetingState === 'error' && (
            <button onClick={resetMeeting} className="w-full py-3 bg-indigo-500 text-white rounded-pill font-medium text-sm hover:bg-indigo-600 transition-colors">
              重新开始
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
