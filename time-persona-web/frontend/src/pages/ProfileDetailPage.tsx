import { useState, useEffect } from 'react';
import { useParams, useLocation, Link, useNavigate } from 'react-router-dom';
import { ArrowLeft, ChevronDown, ChevronRight, Check, Plus } from 'lucide-react';
import { PersonaApi } from '../services/api';
import type { PresetProfile, ProfileBundle, TimelineNode, PersonaSpec } from '../types';

const STAGE_COLORS: Record<string, string> = {
  'early': 'bg-blue-400', 'turning-point': 'bg-amber-400', 'stable': 'bg-green-400',
  'crisis': 'bg-red-400', 'rebuild': 'bg-purple-400', 'peak': 'bg-indigo-400',
};

export default function ProfileDetailPage() {
  const { profileId } = useParams<{ profileId: string }>();
  const location = useLocation();
  const navigate = useNavigate();
  const stateBundle = location.state as ProfileBundle | null;

  const [profile, setProfile] = useState<PresetProfile | null>(stateBundle?.profile ?? null);
  const [nodes, setNodes] = useState<TimelineNode[]>(stateBundle?.nodes ?? []);
  const [agents, setAgents] = useState<PersonaSpec[]>(stateBundle?.agents ?? []);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [expandedIds, setExpandedIds] = useState<string[]>([]);
  const [loading, setLoading] = useState(!stateBundle);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!stateBundle && profileId) loadBundle();
  }, [profileId]);

  async function loadBundle() {
    if (!profileId) return;
    setLoading(true);
    try {
      const bundle = await PersonaApi.getProfileBundle(profileId);
      setProfile(bundle.profile);
      setNodes(bundle.nodes);
      setAgents(bundle.agents);
      // Default select first 2 agents
      if (bundle.agents.length >= 2) {
        setSelectedIds([bundle.agents[0].agentId, bundle.agents[1].agentId]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : '加载失败');
    } finally {
      setLoading(false);
    }
  }

  function toggleAgent(agentId: string) {
    setSelectedIds(prev =>
      prev.includes(agentId)
        ? prev.filter(id => id !== agentId)
        : [...prev, agentId]
    );
  }

  function toggleExpand(nodeId: string) {
    setExpandedIds(prev =>
      prev.includes(nodeId)
        ? prev.filter(id => id !== nodeId)
        : [...prev, nodeId]
    );
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-mint border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center text-slate-400">
        <p className="text-lg mb-4">{error || '角色未找到'}</p>
        <Link to="/" className="text-mint hover:underline">返回首页</Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background relative">
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute -top-16 -left-16 w-64 h-64 rounded-full bg-mint/5 blur-3xl" />
        <div className="absolute -top-8 -right-16 w-56 h-56 rounded-full bg-lavender/5 blur-3xl" />
      </div>

      <div className="relative max-w-2xl mx-auto px-4 pt-6 pb-16">
        {/* Header */}
        <div className="flex items-center gap-3 mb-6">
          <Link to="/" className="w-9 h-9 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow-sm border border-slate-100 hover:bg-white transition-colors">
            <ArrowLeft size={16} className="text-mint-dark" />
          </Link>
          <h1 className="text-2xl font-bold text-slate-900">{profile.displayName}</h1>
        </div>

        {/* Profile card */}
        <div className="bg-white rounded-xxl3 p-6 border border-slate-100 shadow-card mb-6">
          <h2 className="text-xl font-bold text-slate-800 mb-2">{profile.displayName}</h2>
          <p className="text-sm text-slate-500 leading-relaxed mb-4">{profile.biography}</p>

          <div className="flex items-center justify-between">
            <div className="text-center">
              <p className="text-xl font-bold text-mint">{selectedIds.length}</p>
              <p className="text-xs text-slate-400">已选人格</p>
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => navigate(`/arena/${profile.id}`, {
                  state: { profile, agents, selectedAgentIds: selectedIds }
                })}
                disabled={selectedIds.length < 2}
                className="px-5 py-2.5 bg-indigo-500 text-white rounded-pill text-sm font-medium hover:bg-indigo-600 transition-colors disabled:opacity-40"
              >
                开始会议 ({selectedIds.length})
              </button>
            </div>
          </div>
        </div>

        {/* Timeline */}
        <h3 className="text-base font-semibold text-slate-700 mb-3">人生时间线</h3>
        <div className="space-y-3">
          {nodes.map((node, idx) => {
            const isExpanded = expandedIds.includes(node.nodeId);
            const matchedAgent = agents.find(a => a.stageLabel === node.stageLabel || a.timeLabel === node.timeLabel);
            const isSelected = matchedAgent ? selectedIds.includes(matchedAgent.agentId) : false;

            return (
              <div key={node.nodeId} className="bg-white rounded-xxl border border-slate-100 shadow-card overflow-hidden">
                {/* Node header */}
                <button
                  onClick={() => toggleExpand(node.nodeId)}
                  className="w-full flex items-center gap-3 p-4 hover:bg-slate-50/50 transition-colors"
                >
                  <div className={`w-7 h-7 rounded-full ${STAGE_COLORS[node.stageType] || 'bg-slate-300'} flex items-center justify-center text-white text-xs font-bold`}>
                    {idx + 1}
                  </div>
                  <div className="flex-1 text-left">
                    <p className="font-medium text-slate-700">{node.stageLabel}</p>
                    {!isExpanded && (
                      <p className="text-xs text-slate-400 truncate">{node.summary.slice(0, 44)}...</p>
                    )}
                  </div>
                  <span className="text-xs text-slate-400 mr-1">{node.timeLabel}</span>
                  {isExpanded ? <ChevronDown size={14} className="text-slate-400" /> : <ChevronRight size={14} className="text-slate-400" />}
                </button>

                {/* Expanded content */}
                {isExpanded && (
                  <div className="px-4 pb-4 space-y-3 border-t border-slate-50">
                    <p className="text-sm text-slate-500 leading-relaxed pt-3">{node.summary}</p>
                    <div className="flex items-start gap-2">
                      <span className="text-xs text-slate-400 flex-shrink-0">关键事件：</span>
                      <span className="text-sm text-slate-700">{node.keyEvent}</span>
                    </div>
                    <div className="flex flex-wrap gap-1.5">
                      {node.traits.map(trait => (
                        <span key={trait} className="text-xs bg-mint-bg text-mint-dark px-2 py-1 rounded-full">{trait}</span>
                      ))}
                    </div>
                    {node.values.length > 0 && (
                      <div className="flex items-start gap-2">
                        <span className="text-xs text-slate-400 flex-shrink-0">价值观：</span>
                        <span className="text-sm text-slate-600">{node.values.join(' / ')}</span>
                      </div>
                    )}
                    {node.sourceEvidence.length > 0 && (
                      <div className="bg-lavender-pale rounded-lg p-3">
                        <p className="text-xs text-slate-400 mb-1">证据引用</p>
                        <p className="text-sm text-lavender-dark italic">"{node.sourceEvidence[0].quote}"</p>
                      </div>
                    )}
                  </div>
                )}

                {/* Select agent button */}
                {matchedAgent && (
                  <div className="px-4 pb-3">
                    <button
                      onClick={() => toggleAgent(matchedAgent.agentId)}
                      className={`w-full py-3 rounded-xxl text-sm font-medium transition-all flex items-center justify-center gap-2 ${
                        isSelected
                          ? 'bg-mint text-white'
                          : 'bg-slate-50 text-mint-dark hover:bg-mint-bg'
                      }`}
                    >
                      {isSelected ? <><Check size={16} /> 已选人格</> : <><Plus size={16} /> 选择人格</>}
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
