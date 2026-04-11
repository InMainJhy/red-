import React, { useState } from 'react';
import {
  ArrowRight,
  BookOpen,
  Clock,
  Compass,
  Layers,
  MessageCircle,
  MoreHorizontal,
  Sparkles,
  UserPlus,
  Users,
  Wind,
} from 'lucide-react';

const bumperDrivers = [
  {
    id: 'jobs',
    name: '乔布斯',
    short: '乔',
    tone: 'indigo',
    role: '产品极致派',
    style: {
      '--x0': '8%',
      '--y0': '20%',
      '--x1': '58%',
      '--y1': '12%',
      '--x2': '64%',
      '--y2': '58%',
      '--x3': '18%',
      '--y3': '65%',
      '--dur': '6.4s',
      '--delay': '-1.6s',
    },
  },
  {
    id: 'qin',
    name: '秦始皇',
    short: '秦',
    tone: 'rose',
    role: '秩序掌控派',
    style: {
      '--x0': '68%',
      '--y0': '16%',
      '--x1': '16%',
      '--y1': '28%',
      '--x2': '22%',
      '--y2': '68%',
      '--x3': '70%',
      '--y3': '64%',
      '--dur': '7.2s',
      '--delay': '-3.4s',
    },
  },
  {
    id: 'everyman',
    name: '普通人',
    short: '我',
    tone: 'slate',
    role: '现实平衡派',
    style: {
      '--x0': '32%',
      '--y0': '68%',
      '--x1': '72%',
      '--y1': '34%',
      '--x2': '46%',
      '--y2': '10%',
      '--x3': '10%',
      '--y3': '54%',
      '--dur': '5.8s',
      '--delay': '-0.8s',
    },
  },
];

export default function App() {
  const [activeTab, setActiveTab] = useState('arena');

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-800 flex justify-center font-sans overflow-hidden selection:bg-blue-100">
      <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden bg-gradient-to-br from-[#F8FAFC] to-[#EEF5FF]">
        <div className="absolute top-[-5%] left-[-10%] w-[380px] h-[380px] bg-teal-100/45 rounded-full blur-[95px] animate-[pulse_10s_ease-in-out_infinite]" />
        <div className="absolute top-[22%] right-[-12%] w-[460px] h-[460px] bg-indigo-100/45 rounded-full blur-[110px] animate-[pulse_12s_ease-in-out_infinite_reverse]" />
        <div className="absolute bottom-[-12%] left-[18%] w-[560px] h-[560px] bg-amber-50/55 rounded-full blur-[130px] animate-[pulse_14s_ease-in-out_infinite]" />
      </div>

      <div className="w-full max-w-md relative min-h-screen flex flex-col z-10">
        <div className="flex-1 pb-28 overflow-y-auto custom-scrollbar px-5 sm:px-6">
          {activeTab === 'roles' && <RolesTab />}
          {activeTab === 'arena' && <ArenaTab />}
          {activeTab === 'records' && <RecordsTab />}
        </div>

        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 w-[calc(100%-2.5rem)] max-w-[calc(28rem-2.5rem)] z-50">
          <div className="bg-white/72 backdrop-blur-2xl border border-white rounded-[2rem] p-2.5 flex justify-between items-center shadow-[0_8px_30px_rgba(0,0,0,0.06)]">
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
              label="辩论"
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
      {isActive && <div className="absolute inset-0 bg-indigo-50/55 rounded-[1.5rem]" />}
      <div
        className={`relative z-10 transition-transform duration-500 ${
          isActive ? 'scale-110 drop-shadow-sm' : 'group-hover:scale-110'
        }`}
      >
        {icon}
      </div>
      <span className="text-[10px] font-bold tracking-wider relative z-10">{label}</span>
    </button>
  );
}

function RolesTab() {
  return (
    <div className="pt-14 animate-in fade-in slide-in-from-bottom-4 duration-700 ease-out">
      <div className="mb-8 pl-1">
        <h1 className="text-[28px] font-bold tracking-tight text-slate-800">灵感岛屿</h1>
        <p className="text-slate-500 text-sm mt-2 font-medium anti-overlap-text">收集与创造多元的思想切片</p>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-10">
        <ClearCard className="p-5 flex flex-col items-start gap-4 group cursor-pointer hover:bg-white/80 transition-colors">
          <div className="w-12 h-12 rounded-[1rem] bg-indigo-50/90 border border-indigo-100 flex items-center justify-center text-indigo-500 group-hover:scale-105 transition-transform duration-500 shadow-sm">
            <UserPlus className="w-[22px] h-[22px]" />
          </div>
          <div>
            <h3 className="font-bold text-slate-800 text-[14px] mb-1">创造新角色</h3>
            <p className="text-[12px] text-slate-500 leading-relaxed anti-overlap-text">定义一个全新的人格模板</p>
          </div>
        </ClearCard>

        <ClearCard className="p-5 flex flex-col items-start gap-4 group cursor-pointer hover:bg-white/80 transition-colors">
          <div className="w-12 h-12 rounded-[1rem] bg-teal-50/90 border border-teal-100 flex items-center justify-center text-teal-500 group-hover:scale-105 transition-transform duration-500 shadow-sm">
            <Compass className="w-[22px] h-[22px]" />
          </div>
          <div>
            <h3 className="font-bold text-slate-800 text-[14px] mb-1">导入传记</h3>
            <p className="text-[12px] text-slate-500 leading-relaxed anti-overlap-text">从已有素材中提炼人物</p>
          </div>
        </ClearCard>
      </div>

      <div className="flex items-center gap-3 mb-5 pl-1">
        <h2 className="text-[11px] font-bold text-slate-400 tracking-widest uppercase">已收集人物 (3)</h2>
        <div className="h-[1px] flex-1 bg-gradient-to-r from-slate-200 to-transparent" />
      </div>

      <div className="space-y-3.5">
        <RoleItem initials="乔" name="乔布斯" desc="从反叛青年到产品偏执狂" tone="from-blue-100 to-indigo-50 text-indigo-600" />
        <RoleItem initials="秦" name="秦始皇" desc="从少年君主到一统天下" tone="from-orange-50 to-rose-50 text-rose-500" />
        <RoleItem initials="我" name="普通人" desc="在关系、工作和自我认同之间摇摆" tone="from-slate-100 to-slate-50 text-slate-600" />
      </div>
    </div>
  );
}

function RoleItem({
  initials,
  name,
  desc,
  tone,
}: {
  initials: string;
  name: string;
  desc: string;
  tone: string;
}) {
  return (
    <ClearCard className="p-4 flex items-start gap-4 hover:shadow-md transition-shadow cursor-pointer group">
      <div
        className={`w-[46px] h-[46px] rounded-full bg-gradient-to-tr border border-white flex items-center justify-center font-bold text-[16px] shadow-sm shrink-0 ${tone}`}
      >
        {initials}
      </div>
      <div className="flex-1 min-w-0 pr-1">
        <h3 className="font-bold text-slate-800 text-[15px] leading-tight anti-overlap-text">{name}</h3>
        <p className="text-[12px] text-slate-500 mt-1 leading-relaxed anti-overlap-text">{desc}</p>
      </div>
      <button className="text-slate-300 hover:text-slate-600 transition-colors p-2 shrink-0">
        <MoreHorizontal className="w-5 h-5" />
      </button>
    </ClearCard>
  );
}

function ArenaTab() {
  return (
    <div className="pt-14 animate-in fade-in slide-in-from-bottom-4 duration-700 ease-out">
      <div className="mb-7 pl-1">
        <h1 className="text-[28px] font-bold tracking-tight text-slate-800">圆桌辩论</h1>
        <p className="text-slate-500 text-sm mt-2 font-medium anti-overlap-text">
          让不同思维视角在同一议题中碰撞，输出更清晰的行动结论
        </p>
      </div>

      <ClearCard className="p-5 mb-6 relative overflow-hidden">
        <div className="absolute -top-8 -right-8 w-28 h-28 bg-indigo-100/65 rounded-full blur-[24px]" />
        <div className="relative z-10 flex items-center justify-between gap-3 mb-4">
          <h2 className="font-bold text-slate-800 flex items-center gap-2 text-[14px]">
            <Layers className="w-[18px] h-[18px] text-indigo-400" />
            圆桌会议配置
          </h2>
          <span className="text-[10px] font-bold tracking-wider text-indigo-600 bg-indigo-50 border border-indigo-100/70 px-2.5 py-1 rounded-full">
            实时可调
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-[1fr_auto_1fr] gap-3 items-stretch">
          <SeatCard
            title="主辩席 A"
            subtitle="当前：乔布斯"
            hint="负责提出核心观点"
            badge="已就位"
            tone="indigo"
          />

          <div className="hidden sm:flex items-center justify-center px-1 text-slate-300">
            <ArrowRight className="w-4 h-4" />
          </div>

          <SeatCard
            title="对辩席 B"
            subtitle="等待加入角色"
            hint="补充不同立场与反例"
            badge="待邀请"
            tone="slate"
            dashed
          />
        </div>
      </ClearCard>

      <ClearCard className="p-5 mb-6 overflow-hidden">
        <div className="flex items-center justify-between gap-3 mb-3">
          <h3 className="font-bold text-slate-700 text-[14px] flex items-center gap-2">
            <Sparkles className="w-[17px] h-[17px] text-amber-500" />
            辩论碰碰车场
          </h3>
          <span className="text-[11px] text-slate-400">头像动态碰撞演示</span>
        </div>

        <div className="bumper-zone">
          <div className="bumper-lane" />
          {bumperDrivers.map((driver) => (
            <div
              key={driver.id}
              className={`bumper-driver bumper-${driver.tone}`}
              style={driver.style as React.CSSProperties}
              title={`${driver.name} · ${driver.role}`}
            >
              <span className="bumper-short">{driver.short}</span>
              <span className="bumper-tag">{driver.name}</span>
            </div>
          ))}
        </div>

        <p className="text-[12px] text-slate-500 mt-3 leading-relaxed anti-overlap-text">
          通过持续移动强化“观点碰撞”感，头像会在场内循环位移，避免固定站位导致界面呆板。
        </p>
      </ClearCard>

      <div className="mb-4">
        <h3 className="font-bold text-slate-700 text-[14px] mb-3 flex items-center gap-2 pl-1">
          <MessageCircle className="w-[18px] h-[18px] text-teal-400" />
          议题输入
        </h3>
        <div className="bg-white/70 backdrop-blur-xl rounded-[24px] p-4 border border-white shadow-[0_4px_20px_rgba(0,0,0,0.04)] mb-4">
          <textarea
            placeholder="例如：在高不确定环境下，应该优先稳定现金流，还是押注高风险增长？"
            className="w-full bg-transparent text-[14px] text-slate-700 placeholder:text-slate-400 outline-none resize-none min-h-[92px] custom-scrollbar leading-relaxed anti-overlap-text"
          />
        </div>

        <button className="w-full bg-slate-900 hover:bg-slate-800 text-white font-bold py-4 rounded-[20px] shadow-[0_8px_20px_rgba(15,23,42,0.15)] transition-all active:scale-[0.98] flex justify-center items-center gap-2">
          <span className="tracking-widest text-[14px]">开启圆桌会议</span>
        </button>
      </div>
    </div>
  );
}

function SeatCard({
  title,
  subtitle,
  hint,
  badge,
  tone,
  dashed,
}: {
  title: string;
  subtitle: string;
  hint: string;
  badge: string;
  tone: 'indigo' | 'slate';
  dashed?: boolean;
}) {
  const toneClass =
    tone === 'indigo'
      ? 'bg-indigo-50 text-indigo-600 border-indigo-100'
      : 'bg-slate-100 text-slate-500 border-slate-200';

  return (
    <div
      className={`rounded-2xl p-3.5 border ${
        dashed ? 'border-dashed border-slate-200 bg-white/50' : 'border-white bg-white/75'
      }`}
    >
      <div className="flex items-center justify-between gap-2 mb-2">
        <h4 className="text-[13px] font-bold text-slate-700">{title}</h4>
        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${toneClass}`}>{badge}</span>
      </div>
      <p className="text-[13px] font-semibold text-slate-800 leading-snug anti-overlap-text">{subtitle}</p>
      <p className="text-[12px] text-slate-500 mt-1 leading-relaxed anti-overlap-text">{hint}</p>
    </div>
  );
}

function RecordsTab() {
  return (
    <div className="pt-14 animate-in fade-in slide-in-from-bottom-4 duration-700 ease-out">
      <div className="mb-8 pl-1">
        <h1 className="text-[28px] font-bold tracking-tight text-slate-800">灵感纪要</h1>
        <p className="text-slate-500 text-sm mt-2 font-medium anti-overlap-text">留存每一次观点碰撞的关键结论</p>
      </div>

      <div className="space-y-4">
        <RecordItem
          title="关于“极端掌控与创新自由”的对辩"
          time="2天前"
          speakers="秦始皇 / 乔布斯"
          summary="权力需要秩序，创新需要自由，会议建议采用“规则红线 + 创新沙盒”的双轨治理。"
          tone="indigo"
        />
        <RecordItem
          title="如何面对职业路径中的二选一"
          time="1周前"
          speakers="普通人 / 融合人格"
          summary="先用低成本试错验证方向，再决定是否重仓投入，减少情绪化决策带来的机会损失。"
          tone="teal"
        />
      </div>
    </div>
  );
}

function RecordItem({
  title,
  time,
  speakers,
  summary,
  tone,
}: {
  title: string;
  time: string;
  speakers: string;
  summary: string;
  tone: 'indigo' | 'teal';
}) {
  const lineTone = tone === 'indigo' ? 'bg-indigo-400' : 'bg-teal-400';
  const titleHover = tone === 'indigo' ? 'group-hover:text-indigo-600' : 'group-hover:text-teal-600';

  return (
    <ClearCard className="p-5 relative overflow-hidden group hover:shadow-md transition-shadow cursor-pointer">
      <div className={`absolute top-0 left-0 w-1.5 h-full rounded-l-2xl ${lineTone}`} />

      <div className="flex justify-between items-start mb-3 pl-2 gap-3">
        <h3 className={`font-bold text-slate-800 text-[15px] leading-snug anti-overlap-text ${titleHover}`}>{title}</h3>
        <span className="text-[10px] text-slate-400 font-bold tracking-wider uppercase flex items-center gap-1 shrink-0 bg-slate-50 px-2 py-1 rounded-md">
          <Clock className="w-[10px] h-[10px]" />
          {time}
        </span>
      </div>

      <div className="pl-2 mb-3">
        <p className="text-[12px] text-slate-500 font-medium anti-overlap-text">{speakers}</p>
      </div>

      <div className="bg-slate-50/85 border border-slate-100/60 rounded-xl p-3.5">
        <p className="text-[12px] text-slate-500 leading-relaxed anti-overlap-text line-clamp-3">{summary}</p>
      </div>
    </ClearCard>
  );
}

function ClearCard({
  children,
  className = '',
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={`bg-white/62 backdrop-blur-2xl border border-white rounded-[24px] shadow-[0_8px_30px_rgba(0,0,0,0.04)] ${className}`}>
      {children}
    </div>
  );
}
