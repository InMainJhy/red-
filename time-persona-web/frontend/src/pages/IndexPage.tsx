import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Users, Sparkles, Clock, ChevronRight, BookOpen } from 'lucide-react';
import { PersonaApi } from '../services/api';
import type { PresetProfile, ArenaRunHistoryItem } from '../types';

const TAB_ITEMS = [
  { key: 'roles', label: '角色库', icon: BookOpen },
  { key: 'arena', label: '人格会议', icon: Users },
  { key: 'records', label: '纪要', icon: Clock },
];

export default function IndexPage() {
  const [profiles, setProfiles] = useState<PresetProfile[]>([]);
  const [activeTab, setActiveTab] = useState('roles');
  const [records, setRecords] = useState<ArenaRunHistoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [connectionLabel, setConnectionLabel] = useState('连接中');
  const navigate = useNavigate();

  useEffect(() => {
    loadPresets();
    loadRecords();
  }, []);

  async function loadPresets() {
    setLoading(true);
    setError('');
    try {
      const presets = await PersonaApi.getPresets();
      setProfiles(presets);
      setConnectionLabel('已连接');
    } catch (err) {
      setError(err instanceof Error ? err.message : '加载失败');
      setConnectionLabel('未连接');
    } finally {
      setLoading(false);
    }
  }

  async function loadRecords() {
    try {
      const history = await PersonaApi.getArenaHistory();
      setRecords(history);
    } catch { /* ignore */ }
  }

  return (
    <div className="min-h-screen bg-background relative overflow-hidden">
      {/* Background decorations */}
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute -top-20 -left-20 w-80 h-80 rounded-full bg-indigo-50 opacity-60 blur-3xl" />
        <div className="absolute top-20 -right-20 w-72 h-72 rounded-full bg-purple-50 opacity-50 blur-3xl" />
        <div className="absolute bottom-0 left-1/4 w-96 h-96 rounded-full bg-rose-50 opacity-40 blur-3xl" />
      </div>

      <div className="relative max-w-2xl mx-auto px-4 pt-8 pb-24">
        {/* Hero */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-slate-900 mb-2">时序人格</h1>
          <p className="text-slate-500 text-sm flex items-center gap-2">
            <span className={`inline-block w-2 h-2 rounded-full ${connectionLabel === '已连接' ? 'bg-green-400' : 'bg-amber-400'}`} />
            {connectionLabel} · 连接人物库，开启跨时空对话
          </p>
        </div>

        {/* Error */}
        {error && (
          <div className="mb-4 p-4 bg-red-50 rounded-xxl text-sm text-red-600 flex items-center justify-between">
            <span>{error}</span>
            <button onClick={() => loadPresets()} className="text-red-800 font-medium hover:underline">重试</button>
          </div>
        )}

        {/* Loading */}
        {loading && (
          <div className="text-center py-12 text-slate-400">
            <div className="animate-spin w-8 h-8 border-2 border-mint border-t-transparent rounded-full mx-auto mb-3" />
            <p>正在连接后端并加载角色库...</p>
          </div>
        )}

        {/* Tab bar */}
        {!loading && (
          <div className="flex gap-1 bg-white/60 backdrop-blur-sm rounded-xxl p-1 mb-6 shadow-sm border border-slate-100">
            {TAB_ITEMS.map(tab => (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-[12px] text-sm font-medium transition-all ${
                  activeTab === tab.key
                    ? 'bg-white text-mint-dark shadow-sm'
                    : 'text-slate-400 hover:text-slate-600'
                }`}
              >
                <tab.icon size={16} />
                {tab.label}
              </button>
            ))}
          </div>
        )}

        {/* Tab content */}
        {!loading && activeTab === 'roles' && (
          <div className="space-y-4">
            {/* Action cards */}
            <div className="grid grid-cols-3 gap-3 mb-6">
              <Link to="/create" className="flex flex-col items-center gap-2 p-4 bg-white rounded-xxl border border-slate-100 shadow-card hover:shadow-md transition-shadow">
                <div className="w-10 h-10 rounded-full bg-mint-bg flex items-center justify-center">
                  <Sparkles size={18} className="text-mint-dark" />
                </div>
                <span className="text-xs font-medium text-slate-600">创建角色</span>
              </Link>
              <Link to="/explore" className="flex flex-col items-center gap-2 p-4 bg-white rounded-xxl border border-slate-100 shadow-card hover:shadow-md transition-shadow">
                <div className="w-10 h-10 rounded-full bg-lavender-pale flex items-center justify-center">
                  <BookOpen size={18} className="text-lavender-dark" />
                </div>
                <span className="text-xs font-medium text-slate-600">寻访前人</span>
              </Link>
              <Link to="/create?tab=ai" className="flex flex-col items-center gap-2 p-4 bg-white rounded-xxl border border-slate-100 shadow-card hover:shadow-md transition-shadow">
                <div className="w-10 h-10 rounded-full bg-purple-50 flex items-center justify-center">
                  <Users size={18} className="text-purple-600" />
                </div>
                <span className="text-xs font-medium text-slate-600">AI对话</span>
              </Link>
            </div>

            {/* Profile list */}
            <p className="text-xs text-slate-400 font-medium tracking-wide">
              已收集的切片 ({profiles.length})
            </p>
            <div className="space-y-3">
              {profiles.map(profile => (
                <div
                  key={profile.id}
                  onClick={() => navigate(`/profile/${profile.id}`)}
                  className="flex items-center gap-4 p-4 bg-white rounded-xxl border border-slate-100 shadow-card hover:shadow-md transition-all cursor-pointer group"
                >
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-mint to-mint-dark flex items-center justify-center text-white font-bold text-lg flex-shrink-0">
                    {profile.displayName.charAt(0)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold text-slate-800">{profile.displayName}</h3>
                    <p className="text-sm text-slate-400 truncate">{profile.subtitle}</p>
                    <div className="flex gap-1 mt-1 flex-wrap">
                      {profile.highlights.slice(0, 2).map(h => (
                        <span key={h} className="text-xs bg-mint-bg text-mint-dark px-2 py-0.5 rounded-full">{h}</span>
                      ))}
                    </div>
                  </div>
                  <ChevronRight size={18} className="text-slate-300 group-hover:text-slate-500 transition-colors" />
                </div>
              ))}
            </div>
          </div>
        )}

        {!loading && activeTab === 'arena' && (
          <div className="space-y-4">
            <div>
              <h2 className="text-xl font-bold text-slate-800 mb-1">人格会议</h2>
              <p className="text-sm text-slate-400">选择人物的不同人生阶段人格，让他们围绕议题展开讨论。</p>
            </div>
            {profiles.length > 0 ? (
              <div className="space-y-3">
                {profiles.slice(0, 4).map(profile => (
                  <div
                    key={profile.id}
                    onClick={() => navigate(`/arena/${profile.id}`)}
                    className="flex items-center gap-3 p-4 bg-white rounded-xxl border border-slate-100 shadow-card hover:shadow-md transition-all cursor-pointer"
                  >
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white font-bold flex-shrink-0">
                      {profile.displayName.charAt(0)}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-slate-700">{profile.displayName}</p>
                      <p className="text-xs text-slate-400">{profile.subtitle}</p>
                    </div>
                    <button className="px-4 py-2 bg-indigo-500 text-white text-sm rounded-pill font-medium hover:bg-indigo-600 transition-colors">
                      开始会议
                    </button>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-center py-8 text-slate-400">暂无可用角色，请先创建或导入角色</p>
            )}
          </div>
        )}

        {!loading && activeTab === 'records' && (
          <div className="space-y-4">
            <h2 className="text-xl font-bold text-slate-800">会议纪要</h2>
            {records.length > 0 ? (
              <div className="space-y-3">
                {records.map(record => (
                  <div
                    key={record.runId}
                    className="p-4 bg-white rounded-xxl border border-slate-100 shadow-card"
                  >
                    <h3 className="font-medium text-slate-700 mb-1">{record.title || '会议纪要'}</h3>
                    <p className="text-sm text-slate-400 mb-2">{record.topic}</p>
                    <div className="flex items-center gap-2 text-xs text-slate-400">
                      <span>{record.participantNames?.join(' · ')}</span>
                      <span>·</span>
                      <span>{record.mode === 'debate' ? '辩论' : '对谈'}</span>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-center py-8 text-slate-400">暂无会议纪要</p>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
