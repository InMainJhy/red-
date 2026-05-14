import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { ArrowLeft, Edit2, MessageCircle, Upload, Sparkles } from 'lucide-react';
import { PersonaApi } from '../services/api';
import type { ProfileBundle } from '../types';

const TABS = [
  { key: 'manual', label: '手动输入', icon: Edit2 },
  { key: 'chat', label: 'AI对话', icon: MessageCircle },
  { key: 'import', label: '上传资料', icon: Upload },
];

const AI_QUESTIONS = [
  '当计划被打乱时，你通常会怎么做？',
  '在团队讨论中，你更常扮演什么角色？',
  '面对长期压力时，你靠什么恢复状态？',
];

export default function CreateRolePage() {
  const [tab, setTab] = useState('manual');
  const [name, setName] = useState('');
  const [bio, setBio] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // AI dialogue state
  const [aiStep, setAiStep] = useState(0);
  const [aiMessages, setAiMessages] = useState<{ sender: 'ai' | 'user'; text: string }[]>([]);
  const [aiInput, setAiInput] = useState('');
  const [aiAnswers, setAiAnswers] = useState<string[]>([]);

  const navigate = useNavigate();

  async function handleCreate() {
    if (!name.trim()) { setError('请输入人物名称'); return; }
    if (bio.trim().length < 10) { setError('请输入至少10个字的描述'); return; }
    setLoading(true);
    setError('');
    try {
      // Parse timeline from bio
      const parsed = await PersonaApi.parseTimeline({ displayName: name.trim(), biography: bio.trim() });
      // Build agents
      const { agents } = await PersonaApi.buildAgents({
        personId: parsed.personId,
        displayName: name.trim(),
        biography: bio.trim(),
        nodes: parsed.nodes,
      });
      // Navigate to profile detail with the bundle
      navigate(`/profile/${parsed.personId}`, {
        state: {
          profile: { id: parsed.personId, displayName: name.trim(), subtitle: '自定义角色', category: 'self' as const, coverSeed: parsed.personId, biography: bio.trim(), highlights: [], suggestedTopics: [] },
          nodes: parsed.nodes,
          agents,
        },
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : '创建失败');
    } finally {
      setLoading(false);
    }
  }

  function startAIDialogue() {
    setTab('chat');
    setAiMessages([{ sender: 'ai', text: '你好！我会帮你生成角色画像。我们从姓名开始，请告诉我这个角色的名字。' }]);
    setAiStep(1);
  }

  function submitAIInput() {
    if (!aiInput.trim()) return;
    setAiMessages(prev => [...prev, { sender: 'user', text: aiInput.trim() }]);
    const answer = aiInput.trim();
    setAiInput('');

    if (aiStep === 1) {
      setName(answer);
      setAiMessages(prev => [...prev, { sender: 'ai', text: `好的，${answer}。接下来介绍一下Ta的背景经历吧。` }]);
      setAiStep(2);
    } else if (aiStep === 2) {
      setBio(answer);
      setAiMessages(prev => [...prev, { sender: 'ai', text: '收到！最后通过3个简短问题来补全人格。' }]);
      setAiMessages(prev => [...prev, { sender: 'ai', text: `1/3 ${AI_QUESTIONS[0]}` }]);
      setAiStep(3);
    } else if (aiStep === 3 || aiStep === 4) {
      const qIndex = aiStep - 3;
      const newAnswers = [...aiAnswers, answer];
      setAiAnswers(newAnswers);
      if (qIndex < AI_QUESTIONS.length - 1) {
        setAiMessages(prev => [...prev, { sender: 'ai', text: `${qIndex + 2}/3 ${AI_QUESTIONS[qIndex + 1]}` }]);
        setAiStep(aiStep + 1);
      } else {
        setAiMessages(prev => [...prev, { sender: 'ai', text: 'AI对话完成！信息已回填，可以提交了。' }]);
        setBio(prev => `${prev}\n\n【性格测试回答】${newAnswers.join('；')}`);
        setAiStep(5);
        setTab('manual');
      }
    }
  }

  return (
    <div className="min-h-screen bg-background relative">
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute top-0 right-0 w-64 h-48 rounded-full bg-mint/5 blur-3xl" />
        <div className="absolute bottom-20 left-0 w-56 h-40 rounded-full bg-lavender/5 blur-3xl" />
      </div>

      <div className="relative max-w-2xl mx-auto px-4 pt-6 pb-16">
        {/* Header */}
        <div className="flex items-center gap-3 mb-6">
          <Link to="/" className="w-9 h-9 rounded-full bg-white/80 backdrop-blur flex items-center justify-center shadow-sm border border-slate-100 hover:bg-white transition-colors">
            <ArrowLeft size={16} className="text-mint-dark" />
          </Link>
          <h1 className="text-2xl font-bold text-slate-900">创建专属角色</h1>
        </div>

        {/* Hero illustration */}
        <div className="flex flex-col items-center mb-8">
          <div className="w-32 h-32 rounded-full bg-gradient-to-br from-mint-bg to-lavender-pale flex items-center justify-center mb-4">
            <div className="w-20 h-20 rounded-full bg-white/80 flex items-center justify-center shadow-lg">
              <Sparkles size={28} className="text-mint-dark" />
            </div>
          </div>
          <p className="text-sm text-slate-400 text-center max-w-xs">
            通过文字、AI对话或资料上传，让角色设定更完整更有质感
          </p>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 bg-white/60 backdrop-blur-sm rounded-xxl p-1 mb-6 shadow-sm border border-slate-100">
          {TABS.map(t => (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-[12px] text-sm font-medium transition-all ${
                tab === t.key ? 'bg-white text-mint-dark shadow-sm' : 'text-slate-400'
              }`}
            >
              <t.icon size={16} />
              {t.label}
            </button>
          ))}
        </div>

        {/* Manual tab */}
        {tab === 'manual' && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">人物名称</label>
              <input
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="请输入角色名称"
                className="w-full px-4 py-3 bg-white rounded-xxl border border-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-mint/30 shadow-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2 flex justify-between">
                <span>人物传记</span>
                <span className="text-slate-400">{bio.length}/500</span>
              </label>
              <textarea
                value={bio}
                onChange={e => setBio(e.target.value)}
                placeholder="请描述角色的背景、性格、特点..."
                rows={5}
                maxLength={500}
                className="w-full px-4 py-3 bg-white rounded-xxl border border-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-mint/30 shadow-sm resize-none"
              />
            </div>
          </div>
        )}

        {/* AI chat tab */}
        {tab === 'chat' && (
          <div className="space-y-4">
            <div className="space-y-3 max-h-80 overflow-y-auto mb-4">
              {aiMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[80%] px-4 py-3 rounded-2xl text-sm ${
                    msg.sender === 'ai'
                      ? 'bg-white text-slate-700 border border-slate-100'
                      : 'bg-mint text-white'
                  }`}>
                    {msg.text}
                  </div>
                </div>
              ))}
            </div>
            <div className="flex gap-2">
              <input
                value={aiInput}
                onChange={e => setAiInput(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && submitAIInput()}
                placeholder={aiStep >= 5 ? '对话已完成' : '输入你的回答...'}
                disabled={aiStep >= 5}
                className="flex-1 px-4 py-3 bg-white rounded-xxl border border-slate-100 text-sm focus:outline-none focus:ring-2 focus:ring-mint/30"
              />
              <button
                onClick={submitAIInput}
                disabled={aiStep >= 5}
                className="px-6 py-3 bg-mint text-white rounded-xxl text-sm font-medium hover:bg-mint-dark transition-colors disabled:opacity-50"
              >
                {aiStep >= 5 ? '完成' : '发送'}
              </button>
            </div>
          </div>
        )}

        {/* Import tab */}
        {tab === 'import' && (
          <div className="space-y-4">
            <div className="border-2 border-dashed border-slate-200 rounded-xxl p-8 text-center bg-white/50">
              <Upload size={32} className="mx-auto mb-3 text-slate-400" />
              <p className="font-medium text-slate-700 mb-1">上传微信聊天记录或文本资料</p>
              <p className="text-sm text-slate-400 mb-4">支持 .txt 格式，系统会自动分析并提取人物特征</p>
              <button className="px-6 py-2.5 bg-lavender text-white rounded-pill text-sm font-medium hover:bg-lavender-dark transition-colors">
                选择文件
              </button>
            </div>
            <p className="text-xs text-slate-400 text-center">也可以直接手动输入或在AI对话中补全信息</p>
          </div>
        )}

        {/* Error */}
        {error && (
          <div className="mt-4 p-3 bg-red-50 text-red-600 text-sm rounded-xxl">{error}</div>
        )}

        {/* Submit */}
        <button
          onClick={handleCreate}
          disabled={loading || !name.trim()}
          className="mt-6 w-full py-4 bg-mint text-white rounded-xxl font-semibold text-base shadow-button hover:bg-mint-dark transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          {loading ? (
            <>
              <div className="animate-spin w-5 h-5 border-2 border-white border-t-transparent rounded-full" />
              创建中...
            </>
          ) : (
            '创建角色'
          )}
        </button>
      </div>
    </div>
  );
}
