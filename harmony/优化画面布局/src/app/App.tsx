import React, { useState } from 'react';
import {
  Users,
  MessageCircle,
  Plus,
  ArrowRight,
  MoreHorizontal,
  Clock,
  UserPlus,
  Compass,
  Sparkles,
  Wind,
  Layers,
  BookOpen,
  CalendarDays,
  Heart,
  PlayCircle,
  Stars,
  ChevronRight,
} from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState('arena');

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-800 flex justify-center font-sans overflow-hidden selection:bg-blue-100">
      <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden bg-gradient-to-br from-[#F8FAFC] to-[#F1F5F9]">
        <div className="absolute top-[-5%] left-[-10%] w-[400px] h-[400px] bg-teal-100/50 rounded-full blur-[100px] animate-[pulse_10s_ease-in-out_infinite]" />
        <div className="absolute top-[20%] right-[-10%] w-[500px] h-[500px] bg-indigo-100/50 rounded-full blur-[120px] animate-[pulse_12s_ease-in-out_infinite_reverse]" />
        <div className="absolute bottom-[-10%] left-[20%] w-[600px] h-[600px] bg-rose-50/60 rounded-full blur-[130px] animate-[pulse_14s_ease-in-out_infinite]" />
      </div>

      <div className="w-full max-w-md relative min-h-screen flex flex-col z-10">
        <div className="flex-1 pb-28 overflow-y-auto custom-scrollbar px-6">
          {activeTab === 'roles' && <RolesTab />}
          {activeTab === 'arena' && <ArenaTab />}
          {activeTab === 'records' && <RecordsTab />}
        </div>

        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 w-[calc(100%-3rem)] max-w-[calc(28rem-3rem)] z-50">
          <div className="bg-white/70 backdrop-blur-2xl border border-white rounded-[2rem] p-2.5 flex justify-between items-center shadow-[0_8px_30px_rgba(0,0,0,0.04)]">
            <NavButton
              isActive={activeTab === 'roles'}
              onClick={() => setActiveTab('roles')}
              icon={<Users className="w-[22px] h-[22px]" />}
              label="角色"
            />
            <NavButton
              isActive={activeTab === 'arena'}
              onClick={() => setActiveTab('arena')}
              icon={<Wind className="w-[22px] h-[22px]" />}
              label="共振"
            />
            <NavButton
              isActive={activeTab === 'records'}
              onClick={() => setActiveTab('records')}
              icon={<BookOpen className="w-[22px] h-[22px]" />}
              label="纪要"
            />
          </div>
        </div>
      </div>
    </div>
  );
}

function NavButton({
  isActive,
  onClick,
  icon,
  label,
}: {
  isActive: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  label: string;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex-1 flex flex-col items-center justify-center gap-1.5 py-2.5 rounded-[1.5rem] transition-all duration-500 relative group ${
        isActive ? 'text-indigo-600' : 'text-slate-400 hover:text-slate-600'
      }`}
    >
      {isActive && (
        <div className="absolute inset-0 bg-indigo-50/50 rounded-[1.5rem] scale-100 transition-transform duration-500" />
      )}
      <div className={`relative z-10 transition-transform duration-500 ${isActive ? 'scale-110 drop-shadow-sm' : 'group-hover:scale-110'}`}>
        {icon}
      </div>
      <span className={`text-[10px] font-bold tracking-wider relative z-10 transition-opacity duration-300 ${isActive ? 'opacity-100' : 'opacity-80'}`}>
        {label}
      </span>
    </button>
  );
}

function RolesTab() {
  return (
    <div className="pt-14 animate-in fade-in slide-in-from-bottom-4 duration-700 ease-out">
      <div className="mb-8 pl-2">
        <h1 className="text-[28px] font-bold tracking-tight text-slate-800">时序人格</h1>
        <p className="text-indigo-500/75 text-xs font-medium italic tracking-[0.2em] mt-1">Chronological Persona</p>
        <p className="text-slate-500 text-sm mt-2 font-medium">收集与创造多元的思想切片</p>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-10">
        <ClearCard className="p-5 flex flex-col items-start gap-4 group cursor-pointer hover:bg-white/80 transition-colors">
          <div className="w-12 h-12 rounded-[1rem] bg-indigo-50/80 border border-indigo-100 flex items-center justify-center text-indigo-500 group-hover:scale-105 transition-transform duration-500 shadow-sm">
            <UserPlus className="w-[22px] h-[22px]" />
          </div>
          <div>
            <h3 className="font-bold text-slate-800 text-[14px] mb-1">创造新识</h3>
            <p className="text-[12px] text-slate-500 leading-relaxed">定义一个全新的人格</p>
          </div>
        </ClearCard>

        <ClearCard className="p-5 flex flex-col items-start gap-4 group cursor-pointer hover:bg-white/80 transition-colors">
          <div className="w-12 h-12 rounded-[1rem] bg-teal-50/80 border border-teal-100 flex items-center justify-center text-teal-500 group-hover:scale-105 transition-transform duration-500 shadow-sm">
            <Compass className="w-[22px] h-[22px]" />
          </div>
          <div>
            <h3 className="font-bold text-slate-800 text-[14px] mb-1">寻访前人</h3>
            <p className="text-[12px] text-slate-500 leading-relaxed">导入已有的人物传记</p>
          </div>
        </ClearCard>
      </div>

      <div className="flex items-center gap-3 mb-5 pl-2">
        <h2 className="text-[11px] font-bold text-slate-400 tracking-widest uppercase">已收集的切片 (3)</h2>
        <div className="h-[1px] flex-1 bg-gradient-to-r from-slate-200 to-transparent" />
      </div>

      <div className="space-y-3.5">
        <ClearCard className="p-4 flex items-center gap-4 hover:shadow-md transition-shadow cursor-pointer group">
          <div className="w-[46px] h-[46px] rounded-full bg-gradient-to-tr from-blue-100 to-indigo-50 border border-white flex items-center justify-center font-bold text-[16px] text-indigo-600 shadow-sm">
            乔
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-bold text-slate-800 text-[15px] truncate">乔布斯</h3>
            <p className="text-[12px] text-slate-500 truncate mt-0.5">从反叛青年到产品偏执狂</p>
          </div>
          <button className="text-slate-300 hover:text-slate-600 transition-colors p-2">
            <MoreHorizontal className="w-5 h-5" />
          </button>
        </ClearCard>

        <ClearCard className="p-4 flex items-center gap-4 hover:shadow-md transition-shadow cursor-pointer group">
          <div className="w-[46px] h-[46px] rounded-full bg-gradient-to-tr from-orange-50 to-rose-50 border border-white flex items-center justify-center font-bold text-[16px] text-rose-500 shadow-sm">
            秦
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-bold text-slate-800 text-[15px] truncate">秦始皇</h3>
            <p className="text-[12px] text-slate-500 truncate mt-0.5">从少年君主到一统天下</p>
          </div>
          <button className="text-slate-300 hover:text-slate-600 transition-colors p-2">
            <MoreHorizontal className="w-5 h-5" />
          </button>
        </ClearCard>

        <ClearCard className="p-4 flex items-center gap-4 hover:shadow-md transition-shadow cursor-pointer group">
          <div className="w-[46px] h-[46px] rounded-full bg-white border border-slate-100 flex items-center justify-center font-bold text-[16px] text-slate-600 shadow-sm">
            我
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-bold text-slate-800 text-[15px] truncate">普通人</h3>
            <p className="text-[12px] text-slate-500 truncate mt-0.5">在关系、工作和自我认同之间摇摆</p>
          </div>
          <button className="text-slate-300 hover:text-slate-600 transition-colors p-2">
            <MoreHorizontal className="w-5 h-5" />
          </button>
        </ClearCard>
      </div>
    </div>
  );
}

function ArenaTab() {
  return (
    <div className="pt-14 animate-in fade-in slide-in-from-bottom-4 duration-700 ease-out">
      <div className="mb-8 pl-1">
        <p className="text-[11px] font-bold text-teal-500/70 tracking-[0.28em] uppercase mb-3">Hi, Welcome</p>
        <h1 className="text-[30px] font-bold tracking-tight text-slate-800 leading-tight">体验用户</h1>
        <p className="text-slate-500 text-[15px] mt-2 leading-relaxed max-w-[280px]">
          欢迎回来，愿你和角色们的灵感对话，今天也能自然地展开。
        </p>
      </div>

      <ClearCard className="p-5 mb-5 relative overflow-hidden border-white/80 bg-white/72">
        <div className="absolute -top-10 -right-8 w-32 h-32 rounded-full bg-teal-100/70 blur-[36px]" />
        <div className="absolute bottom-0 left-8 w-28 h-28 rounded-full bg-sky-100/60 blur-[30px]" />

        <div className="relative z-10 flex items-start justify-between gap-4">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full bg-white/70 px-3 py-1 text-[11px] font-semibold text-teal-600 shadow-[0_4px_14px_rgba(148,163,184,0.08)]">
              <Heart className="h-3.5 w-3.5" />
              今日状态
            </div>
            <h2 className="mt-4 text-[20px] font-bold text-slate-800">适合轻一点地开始</h2>
            <p className="mt-2 max-w-[220px] text-[13px] leading-relaxed text-slate-500">
              先从一次温和的提问开始，不必急着定义答案，灵感会在对话里慢慢显形。
            </p>
          </div>

          <div className="rounded-[24px] bg-white/70 px-4 py-3 shadow-[0_8px_24px_rgba(148,163,184,0.10)]">
            <p className="text-[11px] font-semibold tracking-[0.18em] text-slate-400 uppercase">Mood</p>
            <p className="mt-1 text-[18px] font-bold text-slate-700">平静</p>
            <p className="text-[12px] text-slate-400">适合梳理想法</p>
          </div>
        </div>

        <div className="relative z-10 mt-5 grid grid-cols-3 gap-3">
          <SoftStat label="节奏" value="慢热开启" />
          <SoftStat label="推荐" value="开放提问" />
          <SoftStat label="陪伴感" value="很稳定" />
        </div>
      </ClearCard>

      <div className="mb-5 flex items-center justify-between px-1">
        <div>
          <h2 className="text-[18px] font-bold text-slate-800">今天适合做什么</h2>
          <p className="mt-1 text-[12px] text-slate-400">从轻量入口开始，不用一下子进入复杂流程。</p>
        </div>
        <div className="rounded-full bg-white/70 px-3 py-1 text-[11px] font-semibold text-slate-400 shadow-[0_4px_12px_rgba(148,163,184,0.08)]">
          柔和推荐
        </div>
      </div>

      <div className="space-y-4 mb-6">
        <RecommendationCard
          icon={<PlayCircle className="h-5 w-5" />}
          iconClassName="text-sky-500 shadow-[0_8px_22px_rgba(125,211,252,0.20)]"
          title="开始一次灵感对话"
          description="抛出一个最近反复想到的问题，让角色们帮你把思绪轻轻展开。"
          tags={['适合今天', '低压力进入']}
          cardClassName="bg-gradient-to-br from-white/78 via-sky-50/60 to-teal-50/50"
        />
        <RecommendationCard
          icon={<Stars className="h-5 w-5" />}
          iconClassName="text-emerald-500 shadow-[0_8px_22px_rgba(110,231,183,0.20)]"
          title="探索喜欢的人设"
          description="从你偏爱的角色切入，看看今天更适合被谁陪着思考和表达。"
          tags={['角色陪伴', '轻探索']}
          cardClassName="bg-gradient-to-br from-white/78 via-emerald-50/50 to-teal-50/40"
        />
      </div>

      <div className="mb-4 flex items-center justify-between px-1">
        <h3 className="text-[15px] font-bold text-slate-700">安静的快捷入口</h3>
        <span className="text-[11px] text-slate-400">不打断节奏</span>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <QuickEntryCard
          icon={<Layers className="h-4.5 w-4.5" />}
          iconClassName="bg-indigo-50 text-indigo-500"
          title="人格编织"
          description="继续组合不同思维锚点。"
        />
        <QuickEntryCard
          icon={<Compass className="h-4.5 w-4.5" />}
          iconClassName="bg-amber-50 text-amber-500"
          title="灵感漫游"
          description="看看最近适合探索的话题。"
        />
      </div>
    </div>
  );
}

function RecordsTab() {
  return (
    <div className="pt-14 animate-in fade-in slide-in-from-bottom-4 duration-700 ease-out">
      <div className="mb-6 pl-2">
        <h1 className="text-[28px] font-bold tracking-tight text-slate-800">灵感纪要</h1>
        <p className="text-slate-500 text-sm mt-2 font-medium">把最近的思绪、对话和回响，收进一条更自然的时间线里。</p>
      </div>

      <ClearCard className="p-5 mb-5 border-white/80 bg-white/68">
        <div className="flex items-center justify-between gap-3 mb-4">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full bg-sky-50 px-3 py-1 text-[11px] font-semibold text-sky-600">
              <CalendarDays className="h-3.5 w-3.5" />
              时间导航
            </div>
            <h2 className="mt-3 text-[18px] font-bold text-slate-800">把日历放进纪要里看</h2>
          </div>
          <div className="rounded-full bg-slate-50/90 px-3 py-1.5 text-[12px] font-semibold text-slate-400">
            2026 / 5
          </div>
        </div>

        <div className="flex gap-3 overflow-x-auto pb-1 custom-scrollbar">
          <DateChip label="Sat" day="09" />
          <DateChip label="Sun" day="10" active />
          <DateChip label="Mon" day="11" />
          <DateChip label="Tue" day="12" />
        </div>

        <p className="mt-4 text-[12px] leading-relaxed text-slate-400">
          用日期快速切到那一天的对话，不让时间控件脱离内容单独存在。
        </p>
      </ClearCard>

      <div className="space-y-4">
        <RecordCard
          accent="bg-sky-400"
          title="关于“绝对权力下的孤独感”的探讨"
          time="2天前"
          people={
            <div className="flex items-center gap-3">
              <div className="flex -space-x-1.5">
                <div className="w-[26px] h-[26px] rounded-full bg-rose-50 border-2 border-white flex items-center justify-center text-[10px] font-bold text-rose-500 shadow-sm z-20">秦</div>
                <div className="w-[26px] h-[26px] rounded-full bg-indigo-50 border-2 border-white flex items-center justify-center text-[10px] font-bold text-indigo-500 shadow-sm z-10">乔</div>
              </div>
              <span className="text-[12px] text-slate-500 font-medium">秦始皇 <span className="text-slate-300 mx-1">/</span> 乔布斯</span>
            </div>
          }
          summary="秦始皇认为权力需要绝对的集中来保证系统的运转，而乔布斯反驳道：没有对极简与纯粹的热爱，权力只会制造出平庸的废品..."
          chips={['权力', '孤独感', '深度对谈']}
        />

        <RecordCard
          accent="bg-teal-400"
          title="如何面对旷野与轨道的选择？"
          time="1周前"
          people={
            <div className="flex items-center gap-3">
              <div className="flex -space-x-1.5">
                <div className="w-[26px] h-[26px] rounded-full bg-white border-2 border-slate-100 flex items-center justify-center text-[10px] font-bold text-slate-500 shadow-sm z-20">我</div>
                <div className="w-[26px] h-[26px] rounded-[8px] bg-gradient-to-tr from-teal-50 to-emerald-50 border-2 border-white flex items-center justify-center shadow-sm z-10">
                  <Sparkles className="w-3 h-3 text-teal-500" />
                </div>
              </div>
              <span className="text-[12px] text-slate-500 font-medium">普通人 <span className="text-slate-300 mx-1">/</span> 偏执天才(融合)</span>
            </div>
          }
          summary="融合意识指出：不要试图在第一份工作中寻找一生的意义，去打破既定的轨道，把它当作一个收集数据点的实验场..."
          chips={['职业选择', '自我认同', '融合视角']}
        />

        <ClearCard className="p-5 border-white/80 bg-gradient-to-r from-white/72 via-amber-50/40 to-rose-50/30">
          <div className="flex items-start justify-between gap-4">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full bg-white/85 px-3 py-1 text-[11px] font-semibold text-amber-600 shadow-[0_4px_12px_rgba(251,191,36,0.12)]">
                <MessageCircle className="h-3.5 w-3.5" />
                继续记录
              </div>
              <h3 className="mt-3 text-[17px] font-bold text-slate-800">今天也留下新的回响吧</h3>
              <p className="mt-2 text-[13px] leading-relaxed text-slate-500">
                如果刚好有一个问题挂在心里，现在就可以开启下一次会谈，把它也放进这条时间线。
              </p>
            </div>
            <div className="flex h-12 w-12 items-center justify-center rounded-[18px] bg-white/90 text-amber-500 shadow-[0_10px_22px_rgba(251,191,36,0.14)]">
              <ArrowRight className="h-5 w-5" />
            </div>
          </div>
        </ClearCard>
      </div>
    </div>
  );
}

function SoftStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-[20px] bg-white/65 px-3 py-3 shadow-[0_6px_20px_rgba(148,163,184,0.08)]">
      <p className="text-[11px] text-slate-400">{label}</p>
      <p className="mt-1 text-[14px] font-semibold text-slate-700">{value}</p>
    </div>
  );
}

function RecommendationCard({
  icon,
  iconClassName,
  title,
  description,
  tags,
  cardClassName,
}: {
  icon: React.ReactNode;
  iconClassName: string;
  title: string;
  description: string;
  tags: string[];
  cardClassName: string;
}) {
  return (
    <ClearCard className={`p-5 relative overflow-hidden group cursor-pointer border-white/80 ${cardClassName}`}>
      <div className="absolute -right-6 -top-4 h-24 w-24 rounded-full bg-white/30 blur-2xl" />
      <div className="relative z-10 flex items-start justify-between gap-4">
        <div>
          <div className={`mb-3 inline-flex h-11 w-11 items-center justify-center rounded-[16px] bg-white/85 ${iconClassName}`}>
            {icon}
          </div>
          <h3 className="text-[20px] font-bold text-slate-800">{title}</h3>
          <p className="mt-2 max-w-[220px] text-[13px] leading-relaxed text-slate-500">{description}</p>
        </div>
        <ChevronRight className="mt-1 h-5 w-5 text-slate-300 transition-transform duration-300 group-hover:translate-x-1" />
      </div>
      <div className="relative z-10 mt-4 flex items-center gap-2 text-[12px] font-medium text-slate-500">
        {tags.map((tag) => (
          <span key={tag} className="rounded-full bg-white/80 px-2.5 py-1">
            {tag}
          </span>
        ))}
      </div>
    </ClearCard>
  );
}

function QuickEntryCard({
  icon,
  iconClassName,
  title,
  description,
}: {
  icon: React.ReactNode;
  iconClassName: string;
  title: string;
  description: string;
}) {
  return (
    <ClearCard className="p-4 border-white/75 bg-white/68">
      <div className={`mb-3 flex h-10 w-10 items-center justify-center rounded-[14px] ${iconClassName}`}>
        {icon}
      </div>
      <h3 className="text-[15px] font-bold text-slate-800">{title}</h3>
      <p className="mt-1 text-[12px] leading-relaxed text-slate-500">{description}</p>
    </ClearCard>
  );
}

function DateChip({ day, label, active = false }: { day: string; label: string; active?: boolean }) {
  return (
    <button
      className={`flex min-w-[70px] flex-col items-center rounded-[20px] px-4 py-3 transition-all ${
        active
          ? 'bg-sky-500 text-white shadow-[0_10px_24px_rgba(59,130,246,0.28)]'
          : 'bg-white/72 text-slate-700 shadow-[0_8px_20px_rgba(148,163,184,0.08)]'
      }`}
    >
      <span className={`text-[11px] font-semibold ${active ? 'text-white/80' : 'text-slate-400'}`}>{label}</span>
      <span className="mt-1 text-[22px] font-bold">{day}</span>
    </button>
  );
}

function RecordCard({
  accent,
  title,
  time,
  people,
  summary,
  chips,
}: {
  accent: string;
  title: string;
  time: string;
  people: React.ReactNode;
  summary: string;
  chips: string[];
}) {
  return (
    <ClearCard className="p-5 relative overflow-hidden group hover:shadow-md transition-shadow cursor-pointer border-white/80 bg-white/70">
      <div className={`absolute top-0 left-0 h-full w-1.5 rounded-l-[24px] ${accent}`} />
      <div className="flex justify-between items-start mb-3 pl-2 gap-3">
        <h3 className="font-bold text-slate-800 text-[15px] leading-snug pr-2 group-hover:text-sky-700 transition-colors">
          {title}
        </h3>
        <span className="text-[10px] text-slate-400 font-bold tracking-wider uppercase flex items-center gap-1 shrink-0 bg-slate-50/90 px-2 py-1 rounded-md">
          <Clock className="w-[10px] h-[10px]" />
          {time}
        </span>
      </div>

      <div className="pl-2">{people}</div>

      <div className="mt-4 rounded-[18px] bg-slate-50/75 border border-white/80 p-3.5">
        <p className="text-[12px] text-slate-500 leading-relaxed line-clamp-2">{summary}</p>
      </div>

      <div className="mt-3 flex flex-wrap gap-2 pl-2">
        {chips.map((chip) => (
          <span key={chip} className="rounded-full bg-white/85 px-2.5 py-1 text-[11px] font-medium text-slate-400 shadow-[0_3px_10px_rgba(148,163,184,0.08)]">
            {chip}
          </span>
        ))}
      </div>
    </ClearCard>
  );
}

function ClearCard({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`bg-white/60 backdrop-blur-2xl border border-white rounded-[24px] shadow-[0_8px_30px_rgba(0,0,0,0.04)] ${className}`}>
      {children}
    </div>
  );
}
