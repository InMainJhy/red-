import { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, Heart, Share2, Star } from 'lucide-react';
import { PersonaApi } from '../services/api';
import type { SummaryRecord } from '../types';

export default function SummaryDetailPage() {
  const { summaryId } = useParams<{ summaryId: string }>();
  const [record, setRecord] = useState<SummaryRecord | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (summaryId) loadSummary();
  }, [summaryId]);

  async function loadSummary() {
    if (!summaryId) return;
    setLoading(true);
    try {
      const data = await PersonaApi.getSummary(summaryId);
      setRecord(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : '加载失败');
    } finally {
      setLoading(false);
    }
  }

  async function toggleFavorite() {
    if (!record) return;
    try {
      const updated = await PersonaApi.updateSummary(record.id, { isFavorite: !record.isFavorite });
      setRecord(updated);
    } catch { /* ignore */ }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-2 border-mint border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!record) {
    return (
      <div className="min-h-screen bg-background flex flex-col items-center justify-center text-slate-400">
        <p className="text-lg mb-4">{error || '纪要未找到'}</p>
        <Link to="/" className="text-mint hover:underline">返回首页</Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-2xl mx-auto px-4 pt-6 pb-16">
        {/* Header */}
        <div className="flex items-center gap-3 mb-6">
          <Link to="/" className="w-9 h-9 rounded-full bg-white flex items-center justify-center shadow-sm border border-slate-100">
            <ArrowLeft size={16} className="text-mint-dark" />
          </Link>
          <div className="flex-1">
            <h1 className="text-xl font-bold text-slate-900">{record.title}</h1>
            <p className="text-sm text-slate-400">{record.topic}</p>
          </div>
          <button onClick={toggleFavorite} className="w-9 h-9 rounded-full bg-white flex items-center justify-center shadow-sm border border-slate-100">
            <Heart size={16} className={record.isFavorite ? 'text-red-400 fill-red-400' : 'text-slate-400'} />
          </button>
        </div>

        {/* Participants */}
        <div className="flex gap-2 mb-6 overflow-x-auto pb-1">
          {record.participants.map(p => (
            <div key={p.agentId} className="flex items-center gap-2 px-3 py-2 bg-white rounded-pill border border-slate-100 flex-shrink-0">
              <div className="w-6 h-6 rounded-full flex items-center justify-center text-white text-xs font-bold" style={{ backgroundColor: p.accentColor }}>
                {p.displayName.charAt(0)}
              </div>
              <span className="text-xs font-medium text-slate-700">{p.displayName}</span>
              <span className="text-xs text-slate-400">· {p.stageLabel}</span>
            </div>
          ))}
        </div>

        {/* Narrative hook */}
        <div className="bg-gradient-to-r from-indigo-50 to-purple-50 rounded-xxl p-5 mb-6 border border-indigo-100">
          <p className="text-indigo-600 font-medium mb-1">导语</p>
          <p className="text-slate-700 leading-relaxed text-sm">{record.narrativeHook}</p>
        </div>

        {/* Consensus */}
        <div className="bg-mint-bg rounded-xxl p-5 mb-4">
          <div className="flex items-center gap-2 mb-2">
            <Star size={16} className="text-mint-dark" />
            <h2 className="font-semibold text-slate-800">共识</h2>
          </div>
          <p className="text-slate-600 leading-relaxed text-sm">{record.consensus}</p>
        </div>

        {/* Disagreements */}
        {record.disagreements.length > 0 && (
          <div className="bg-lavender-pale rounded-xxl p-5 mb-4">
            <h2 className="font-semibold text-slate-800 mb-3">分歧</h2>
            <div className="space-y-2">
              {record.disagreements.map((d, i) => (
                <div key={i} className="flex gap-3 text-sm">
                  <span className="text-red-400">•</span>
                  <span className="text-slate-600">{d}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Actionable advice */}
        {record.actionableAdvice.length > 0 && (
          <div className="bg-amber-50 rounded-xxl p-5 mb-4">
            <h2 className="font-semibold text-slate-800 mb-3">行动建议</h2>
            <div className="space-y-2">
              {record.actionableAdvice.map((a, i) => (
                <div key={i} className="flex gap-3 text-sm">
                  <span className="text-amber-500 font-medium">{i + 1}.</span>
                  <span className="text-slate-600">{a}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Moderator note */}
        {record.moderatorNote && (
          <div className="bg-white rounded-xxl p-5 mb-4 border border-slate-100">
            <h2 className="font-semibold text-slate-800 mb-2">主持人提醒</h2>
            <p className="text-slate-500 text-sm italic">{record.moderatorNote}</p>
          </div>
        )}

        {/* Meta */}
        <div className="flex items-center justify-between text-xs text-slate-400 mt-8 pt-4 border-t border-slate-100">
          <span>{record.messageCount} 条对话</span>
          <span>{record.viewCount} 次浏览</span>
          <span>{new Date(record.createdAt).toLocaleDateString('zh-CN')}</span>
        </div>
      </div>
    </div>
  );
}
