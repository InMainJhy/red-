import crypto from 'node:crypto';
import postgres, { type Sql } from 'postgres';
import type {
  ArenaMessage, ArenaMode, ArenaPhase, ArenaRun, ArenaRunHistoryItem,
  ArenaRunRequest, CreateSummaryRequest, PersonaSpec, PresetProfile, ProfileBundle,
  SummaryFilter, SummaryListItem, SummaryListResponse, SummaryParticipant,
  SummaryRecord, TimelineNode, UpdateSummaryRequest,
} from './domain.js';

const COLORS = ['#FEE2E2', '#DBEAFE', '#D1FAE5', '#FEF3C7', '#E9D5FF', '#FECACA', '#BFDBFE', '#A7F3D0'];

function toIso(v: unknown): string { return new Date(String(v)).toISOString(); }
function strArr(v: unknown): string[] { return Array.isArray(v) ? v.map(String) : []; }
function objArr<T>(v: unknown): T[] { return Array.isArray(v) ? (v as T[]) : []; }
function asJson(v: unknown) { return JSON.parse(JSON.stringify(v)); }

function timeAgo(dateStr: string): string {
  const ms = Math.max(0, Date.now() - new Date(dateStr).getTime());
  const d = Math.floor(ms / 86400000);
  if (d <= 0) { const h = Math.floor(ms / 3600000); return h <= 0 ? '刚刚' : `${h}小时前`; }
  if (d === 1) return '昨天';
  if (d < 7) return `${d}天前`;
  if (d < 30) return `${Math.floor(d / 7)}周前`;
  return `${Math.floor(d / 30)}月前`;
}

// Demo presets for when DB is empty
const DEMO_PROFILES: PresetProfile[] = [
  { id: 'steve-jobs', displayName: '史蒂夫·乔布斯', subtitle: '苹果公司联合创始人', category: 'celebrity', coverSeed: 'jobs', biography: '美国发明家、企业家，苹果公司联合创始人。以追求完美和颠覆性创新著称，一生经历了被自己公司驱逐又回归的传奇历程。', highlights: ['追求极致产品', '现实扭曲力场', '改变六个产业'], suggestedTopics: ['该不该为理想牺牲生活质量？', '产品驱动还是市场驱动？'] },
  { id: 'warren-buffett', displayName: '沃伦·巴菲特', subtitle: '伯克希尔·哈撒韦CEO', category: 'celebrity', coverSeed: 'buffett', biography: '美国投资家、慈善家，被誉为"奥马哈先知"。以价值投资理念闻名，长期持有优质企业股票，是全球最成功的投资者之一。', highlights: ['价值投资', '长期主义', '复利思维'], suggestedTopics: ['现在该坚持长期投资还是及时止损？', '年轻人应该追求稳定还是冒险？'] },
  { id: 'confucius', displayName: '孔子', subtitle: '万世师表', category: 'history', coverSeed: 'confucius', biography: '中国春秋时期思想家、教育家，儒家学派创始人。提出仁义礼智信的思想体系，主张有教无类，对中国和东亚文化影响深远。', highlights: ['仁义礼智', '有教无类', '中庸之道'], suggestedTopics: ['教育应该注重知识还是品德？', '个人修养比制度建设更重要吗？'] },
  { id: 'elon-musk', displayName: '埃隆·马斯克', subtitle: '特斯拉、SpaceX CEO', category: 'celebrity', coverSeed: 'musk', biography: '南非裔美国企业家，特斯拉、SpaceX创始人。以大胆创新和颠覆性思维著称，致力于电动汽车、太空探索和人工智能领域。', highlights: ['第一性原理', '跨领域创新', '火星殖民'], suggestedTopics: ['AI发展应该加速还是减速？', '人类应该优先解决地球问题还是探索太空？'] },
  { id: 'graduate', displayName: '小研', subtitle: '研究生 / 打工人', category: 'self', coverSeed: 'graduate', biography: '一个正在经历人生转折期的年轻人，在学业、职业和感情之间寻找平衡。白天面对导师的压力，晚上在出租屋里思考未来方向。', highlights: ['毕业焦虑', '职业迷茫', '理想与现实'], suggestedTopics: ['该不该离开这份消耗我的工作？', '大城市打拼还是回老家发展？'] },
  { id: 'puyi', displayName: '溥仪', subtitle: '末代皇帝', category: 'history', coverSeed: 'puyi', biography: '清朝末代皇帝，三岁即位，六岁退位。经历了从皇帝到平民的巨大转变，一生见证了中国从封建帝制到共和国的变迁。', highlights: ['末代帝王', '时代巨变', '身份重塑'], suggestedTopics: ['当命运给你一个你无法掌控的身份，该如何自处？'] },
];

const DEMO_NODES: Record<string, TimelineNode[]> = {
  'steve-jobs': [
    { nodeId: 'jobs-1', timeLabel: '1976', stageLabel: '车库创业', stageType: 'early', keyEvent: '与沃兹尼亚克在车库创立苹果公司', summary: '年轻的乔布斯充满激情，在父母车库里开始了改变世界的旅程。', traits: ['狂热', '有远见'], values: ['创新', '完美'], tensions: ['理想与商业的冲突'], sourceEvidence: [{ quote: '求知若饥，虚心若愚', sourceLabel: '斯坦福演讲' }] },
    { nodeId: 'jobs-2', timeLabel: '1985', stageLabel: '被逐出苹果', stageType: 'crisis', keyEvent: '与CEO斯卡利发生权力斗争后被迫离开苹果', summary: '被自己创立的公司驱逐，这是乔布斯人生的至暗时刻。', traits: ['倔强', '偏执'], values: ['控制权', '产品理念'], tensions: ['理想主义与管理层的矛盾'], sourceEvidence: [{ quote: '被苹果解雇是我经历过最好的事情', sourceLabel: '斯坦福演讲' }] },
    { nodeId: 'jobs-3', timeLabel: '1997-2011', stageLabel: '王者归来', stageType: 'peak', keyEvent: '回归苹果并推出iPod、iPhone、iPad等革命性产品', summary: '回归后的乔布斯更加成熟，将苹果带向了前所未有的高度。', traits: ['果断', '追求极致'], values: ['简洁', '用户体验'], tensions: ['工作与健康的取舍'], sourceEvidence: [{ quote: 'Stay hungry, stay foolish', sourceLabel: '斯坦福演讲' }] },
  ],
  'warren-buffett': [
    { nodeId: 'buffett-1', timeLabel: '1950s', stageLabel: '投资启蒙', stageType: 'early', keyEvent: '师从格雷厄姆学习价值投资', summary: '年轻的巴菲特展现出对投资的极大热情和天赋。', traits: ['理性', '好学'], values: ['价值', '安全边际'], tensions: ['理论与实战'], sourceEvidence: [{ quote: '别人恐惧时我贪婪', sourceLabel: '致股东信' }] },
    { nodeId: 'buffett-2', timeLabel: '1965-2000', stageLabel: '伯克希尔崛起', stageType: 'stable', keyEvent: '将伯克希尔从纺织厂转型为投资控股帝国', summary: '稳健经营，持续复利，巴菲特建立了自己的投资王国。', traits: ['耐心', '自律'], values: ['长期主义', '能力圈'], tensions: ['坚守与变通'], sourceEvidence: [{ quote: '投资的第一条规则是不要亏钱', sourceLabel: '致股东信' }] },
  ],
  'confucius': [
    { nodeId: 'confucius-1', timeLabel: '鲁国', stageLabel: '周游列国前', stageType: 'early', keyEvent: '在鲁国从政，推行仁政', summary: '孔子在鲁国尝试推行自己的政治理想，但遭到权臣排挤。', traits: ['仁爱', '执着'], values: ['礼', '仁'], tensions: ['理想与现实的冲突'], sourceEvidence: [{ quote: '己所不欲，勿施于人', sourceLabel: '论语' }] },
    { nodeId: 'confucius-2', timeLabel: '前497-前484', stageLabel: '周游列国', stageType: 'crisis', keyEvent: '带领弟子周游列国寻找明君', summary: '十四年流浪，理想屡遭挫折，但从未放弃信念。', traits: ['坚韧', '豁达'], values: ['道', '义'], tensions: ['坚持与变通'], sourceEvidence: [{ quote: '知其不可而为之', sourceLabel: '论语' }] },
  ],
  'graduate': [
    { nodeId: 'grad-1', timeLabel: '本科毕业', stageLabel: '选择读研', stageType: 'turning-point', keyEvent: '放弃工作机会选择继续深造', summary: '站在人生的十字路口，选择了一条看似安稳的道路。', traits: ['谨慎', '有上进心'], values: ['知识', '稳定'], tensions: ['理想与现实的落差'], sourceEvidence: [{ quote: '也许读研是一个缓冲', sourceLabel: '内心独白' }] },
    { nodeId: 'grad-2', timeLabel: '研二', stageLabel: '迷茫期', stageType: 'crisis', keyEvent: '论文压力与就业焦虑同时袭来', summary: '科研没出成果，秋招也没拿到满意的offer，开始怀疑当初的选择。', traits: ['焦虑', '挣扎'], values: ['自我实现', '安全感'], tensions: ['理想与生存'], sourceEvidence: [{ quote: '读了这么多年书，到底为了什么', sourceLabel: '内心独白' }] },
  ],
};

const DEMO_AGENTS: Record<string, PersonaSpec[]> = {
  'steve-jobs': [
    { agentId: 'jobs-1-agent', displayName: '年轻乔布斯', personId: 'steve-jobs', avatarSeed: 'young-jobs', timeLabel: '1976', stageLabel: '车库创业', keyEvent: '创立苹果', knownFacts: ['在车库创业', '与沃兹搭档'], sourceEvidence: [{ quote: '求知若饥', sourceLabel: '斯坦福' }], traits: ['狂热', '有远见'], values: ['创新', '完美'], goal: '改变世界', fear: '平庸', voiceStyle: '充满激情和说服力', knowledgeBoundary: '只知道1976年之前', forbiddenFutureKnowledge: true, stanceSeed: '创新至上' },
    { agentId: 'jobs-2-agent', displayName: '流放乔布斯', personId: 'steve-jobs', avatarSeed: 'exile-jobs', timeLabel: '1985', stageLabel: '被逐出苹果', keyEvent: '被迫离开苹果', knownFacts: ['被自己公司驱逐', '创立NeXT'], sourceEvidence: [{ quote: '被解雇是最好的事', sourceLabel: '斯坦福' }], traits: ['倔强', '反思'], values: ['坚持', '自我证明'], goal: '证明自己', fear: '被遗忘', voiceStyle: '带着伤痕但不服输', knowledgeBoundary: '只知道1985年之前', forbiddenFutureKnowledge: true, stanceSeed: '绝不服输' },
    { agentId: 'jobs-3-agent', displayName: '成熟乔布斯', personId: 'steve-jobs', avatarSeed: 'mature-jobs', timeLabel: '2007', stageLabel: '王者归来', keyEvent: '发布iPhone', knownFacts: ['回归苹果', '推出iPhone'], sourceEvidence: [{ quote: 'Stay hungry', sourceLabel: '斯坦福' }], traits: ['果断', '极简'], values: ['简洁', '用户体验'], goal: '创造极致产品', fear: '时间不够', voiceStyle: '沉稳但犀利', knowledgeBoundary: '只知道2007年之前', forbiddenFutureKnowledge: true, stanceSeed: '产品为王' },
  ],
  'warren-buffett': [
    { agentId: 'buffett-1-agent', displayName: '年轻巴菲特', personId: 'warren-buffett', avatarSeed: 'young-buffett', timeLabel: '1950s', stageLabel: '投资启蒙', keyEvent: '师从格雷厄姆', knownFacts: ['学习价值投资', '开始合伙基金'], sourceEvidence: [{ quote: '别人恐惧时我贪婪', sourceLabel: '致股东信' }], traits: ['理性', '好学'], values: ['价值', '安全边际'], goal: '成为最好的投资者', fear: '亏钱', voiceStyle: '朴实幽默', knowledgeBoundary: '只知道1950年代之前', forbiddenFutureKnowledge: true, stanceSeed: '价值为本' },
    { agentId: 'buffett-2-agent', displayName: '成熟巴菲特', personId: 'warren-buffett', avatarSeed: 'mature-buffett', timeLabel: '2000s', stageLabel: '伯克希尔崛起', keyEvent: '建立投资帝国', knownFacts: ['收购众多企业', '成为世界首富之一'], sourceEvidence: [{ quote: '不要亏钱', sourceLabel: '致股东信' }], traits: ['耐心', '自律'], values: ['长期主义', '能力圈'], goal: '持续创造复利', fear: '失去原则', voiceStyle: '朴实中带有智慧', knowledgeBoundary: '只知道2000年代之前', forbiddenFutureKnowledge: true, stanceSeed: '长期主义' },
  ],
  'confucius': [
    { agentId: 'confucius-1-agent', displayName: '从政孔子', personId: 'confucius', avatarSeed: 'young-confucius', timeLabel: '鲁国时期', stageLabel: '推行仁政', keyEvent: '在鲁国从政', knownFacts: ['曾任鲁国司寇', '推行礼制改革'], sourceEvidence: [{ quote: '己所不欲勿施于人', sourceLabel: '论语' }], traits: ['仁爱', '执着'], values: ['礼', '仁'], goal: '恢复礼乐', fear: '天下无道', voiceStyle: '温文尔雅但坚定', knowledgeBoundary: '只知道鲁国从政之前', forbiddenFutureKnowledge: true, stanceSeed: '仁义为本' },
    { agentId: 'confucius-2-agent', displayName: '流浪孔子', personId: 'confucius', avatarSeed: 'exile-confucius', timeLabel: '前497-前484', stageLabel: '周游列国', keyEvent: '带着弟子流浪', knownFacts: ['周游列国十四年', '多次遭遇危险'], sourceEvidence: [{ quote: '知其不可而为之', sourceLabel: '论语' }], traits: ['坚韧', '豁达'], values: ['道', '义'], goal: '找到明君推行大道', fear: '理想无法实现', voiceStyle: '沧桑但不忘初心', knowledgeBoundary: '只知道周游列国期间', forbiddenFutureKnowledge: true, stanceSeed: '道义为先' },
  ],
  'graduate': [
    { agentId: 'grad-1-agent', displayName: '选择读研的小研', personId: 'graduate', avatarSeed: 'grad-1', timeLabel: '本科毕业', stageLabel: '选择读研', keyEvent: '放弃工作机会', knownFacts: ['选择读研', '对学术有期待'], sourceEvidence: [{ quote: '也许读研是一个缓冲', sourceLabel: '内心独白' }], traits: ['谨慎', '有上进心'], values: ['知识', '稳定'], goal: '通过学习获得更好未来', fear: '选错路', voiceStyle: '年轻但认真', knowledgeBoundary: '只知道本科毕业时', forbiddenFutureKnowledge: true, stanceSeed: '求稳' },
    { agentId: 'grad-2-agent', displayName: '迷茫的小研', personId: 'graduate', avatarSeed: 'grad-2', timeLabel: '研二', stageLabel: '迷茫期', keyEvent: '论文与就业双重压力', knownFacts: ['科研不顺利', '秋招没有好结果'], sourceEvidence: [{ quote: '读了这么多年书到底为了什么', sourceLabel: '内心独白' }], traits: ['焦虑', '挣扎'], values: ['自我实现', '安全感'], goal: '找到出路', fear: '一事无成', voiceStyle: '带着焦虑和自嘲', knowledgeBoundary: '只知道研二之前', forbiddenFutureKnowledge: true, stanceSeed: '迷茫中求生' },
  ],
};

// Arena response generator (simulates AI discussion)
function generateMockArenaRun(topic: string, mode: ArenaMode, agents: PersonaSpec[]): ArenaRun {
  const runId = `run-${Date.now()}`;
  const messages: ArenaMessage[] = [];
  const phases: ArenaPhase[] = mode === 'chat' ? ['opening', 'reflection', 'synthesis'] : ['opening', 'rebuttal', 'closing'];
  let seq = 0;

  for (let round = 1; round <= 2; round++) {
    for (const phase of phases) {
      for (const agent of agents) {
        const content = generateAgentResponse(agent, topic, phase, mode);
        messages.push({
          id: `msg-${++seq}`,
          agentId: agent.agentId,
          displayName: agent.displayName,
          stageLabel: agent.stageLabel,
          content,
          stance: ['support', 'oppose', 'reflective', 'neutral'][seq % 4] as ArenaMessage['stance'],
          round,
          phase,
          timestamp: new Date(Date.now() + seq * 30000).toISOString(),
        });
      }
    }
  }

  return {
    runId,
    sessionId: `session-${Date.now()}`,
    mode,
    topic,
    participants: agents,
    messages,
    summary: {
      title: `${topic.slice(0, 20)}...的${mode === 'debate' ? '辩论' : '讨论'}总结`,
      consensus: `经过讨论，各位人格在"${topic}"上达成了有限共识：需要平衡不同阶段的价值观和目标。`,
      disagreements: ['短期利益与长期目标的优先级存在分歧', '风险承受能力的态度不同'],
      actionableAdvice: ['列出当前最核心的三个优先事项', '设定一个可检验的时间节点来评估决策'],
      narrativeHook: `当${agents.map(a => a.displayName).join('、')}坐在一起讨论这个问题时，他们发现答案比想象中复杂得多。`,
      moderatorNote: '每个人生阶段的自己都有独特的智慧，关键是找到平衡。',
    },
    status: 'completed',
    createdAt: new Date().toISOString(),
  };
}

function generateAgentResponse(agent: PersonaSpec, topic: string, phase: ArenaPhase, mode: ArenaMode): string {
  const stanceMap: Record<string, string[]> = {
    support: ['我认同这个观点', '从我的经历来看确实如此', '我深有同感'],
    oppose: ['但我不这么认为', '我必须提出不同的看法', '这个观点忽略了一个重要因素'],
    reflective: ['这让我重新思考了一下', '站在另一个角度看的话', '也许我们可以找到一个折中方案'],
    neutral: ['这是一个复杂的问题', '两种观点都有道理', '需要更多维度的考量'],
  };

  const phaseIntro: Record<string, string> = {
    opening: `关于"${topic.slice(0, 15)}..."这个话题，`,
    reflection: '听了大家的发言后，',
    rebuttal: '我必须回应刚才的观点。',
    synthesis: '综合来看，',
    closing: '最后我想说的是，',
  };

  const goalMap = `作为${agent.stageLabel}阶段的我，最看重的是"${agent.goal}"。`;
  const fearMap = `我最担心的是"${agent.fear}"。`;
  const traitMap = agent.traits.length > 0 ? `我的性格特点是${agent.traits.join('和')}。` : '';
  const stance = stanceMap[['support', 'oppose', 'reflective', 'neutral'][Math.floor(Math.random() * 4)]];
  const intro = phaseIntro[phase] || '';

  return `${intro}${stance[Math.floor(Math.random() * stance.length)]}。${goalMap}${fearMap}${traitMap}基于我在"${agent.stageLabel}"阶段的经历——"${agent.keyEvent}"，我认为面对这个问题时，应该从${agent.values[0] || '多角度'}的角度来思考。${mode === 'debate' ? '我坚持我的立场。' : '希望能对大家有所启发。'}`;
}

export class BackendRepository {
  private readonly sql: Sql;
  private useDemoData = false;

  constructor(databaseUrl: string) {
    this.sql = postgres(databaseUrl, { max: 5, idle_timeout: 20, connect_timeout: 10 });
  }

  async close(): Promise<void> { await this.sql.end({ timeout: 5 }); }

  async ping(): Promise<void> {
    try { await this.sql`select 1`; }
    catch { this.useDemoData = true; }
  }

  async init(): Promise<void> {
    try {
      await this.sql.unsafe(`
        CREATE TABLE IF NOT EXISTS profiles (
          id TEXT PRIMARY KEY, display_name TEXT NOT NULL, subtitle TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'celebrity', cover_seed TEXT NOT NULL DEFAULT '',
          biography TEXT NOT NULL, highlights JSONB NOT NULL DEFAULT '[]',
          suggested_topics JSONB NOT NULL DEFAULT '[]', origin TEXT NOT NULL DEFAULT 'manual',
          is_default BOOLEAN NOT NULL DEFAULT false, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS timeline_nodes (
          id TEXT PRIMARY KEY, profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          ordinal INTEGER NOT NULL, time_label TEXT NOT NULL, age_label TEXT,
          stage_label TEXT NOT NULL, stage_type TEXT NOT NULL, key_event TEXT NOT NULL,
          summary TEXT NOT NULL, traits JSONB NOT NULL, values JSONB NOT NULL,
          tensions JSONB NOT NULL, source_evidence JSONB NOT NULL
        );
        CREATE TABLE IF NOT EXISTS persona_specs (
          id TEXT PRIMARY KEY, profile_id TEXT NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
          node_id TEXT REFERENCES timeline_nodes(id) ON DELETE CASCADE,
          display_name TEXT NOT NULL, avatar_seed TEXT NOT NULL, time_label TEXT NOT NULL,
          stage_label TEXT NOT NULL, key_event TEXT NOT NULL, known_facts JSONB NOT NULL,
          source_evidence JSONB NOT NULL, traits JSONB NOT NULL, values JSONB NOT NULL,
          goal TEXT NOT NULL, fear TEXT NOT NULL, voice_style TEXT NOT NULL,
          knowledge_boundary TEXT NOT NULL, forbidden_future_knowledge BOOLEAN NOT NULL DEFAULT true,
          stance_seed TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS arena_runs (
          id TEXT PRIMARY KEY, topic TEXT NOT NULL, mode TEXT NOT NULL,
          participant_ids JSONB NOT NULL, participants JSONB NOT NULL,
          messages JSONB NOT NULL, summary JSONB NOT NULL,
          metadata JSONB NOT NULL DEFAULT '{}', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS summaries (
          id TEXT PRIMARY KEY, arena_run_id TEXT UNIQUE REFERENCES arena_runs(id) ON DELETE CASCADE,
          profile_id TEXT REFERENCES profiles(id) ON DELETE SET NULL,
          title TEXT NOT NULL, topic TEXT NOT NULL, duration INTEGER NOT NULL DEFAULT 0,
          message_count INTEGER NOT NULL DEFAULT 0, consensus TEXT NOT NULL,
          disagreements JSONB NOT NULL, actionable_advice JSONB NOT NULL,
          narrative_hook TEXT NOT NULL, moderator_note TEXT, participants JSONB NOT NULL,
          highlights JSONB NOT NULL DEFAULT '[]', tags JSONB NOT NULL DEFAULT '[]',
          is_favorite BOOLEAN NOT NULL DEFAULT false, view_count INTEGER NOT NULL DEFAULT 0,
          exported_assets JSONB NOT NULL DEFAULT '[]', thumbnail_path TEXT,
          message_ids JSONB NOT NULL, metadata JSONB NOT NULL DEFAULT '{}',
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
      `);
    } catch {
      this.useDemoData = true;
    }
  }

  async listDefaultPresets(): Promise<PresetProfile[]> {
    if (this.useDemoData) return DEMO_PROFILES;
    const rows = await this.sql<{ id: string; display_name: string; subtitle: string; category: string; cover_seed: string; biography: string; highlights: unknown; suggested_topics: unknown }[]>`
      SELECT id, display_name, subtitle, category, cover_seed, biography, highlights, suggested_topics
      FROM profiles WHERE is_default = true ORDER BY updated_at DESC, display_name ASC`;
    if (rows.length === 0) return DEMO_PROFILES;
    return rows.map(r => ({
      id: r.id, displayName: r.display_name, subtitle: r.subtitle, category: r.category as PresetProfile['category'],
      coverSeed: r.cover_seed, biography: r.biography, highlights: strArr(r.highlights), suggestedTopics: strArr(r.suggested_topics),
    }));
  }

  async getProfileBundle(profileId: string): Promise<ProfileBundle | null> {
    const demoProfile = DEMO_PROFILES.find(p => p.id === profileId);
    if (this.useDemoData || !demoProfile?.id) {
      const profile = demoProfile || DEMO_PROFILES[0];
      if (!profile) return null;
      return {
        profile,
        nodes: DEMO_NODES[profile.id] || [],
        agents: DEMO_AGENTS[profile.id] || [],
      };
    }

    const [profileRow] = await this.sql`SELECT * FROM profiles WHERE id = ${profileId} LIMIT 1`;
    if (!profileRow) {
      const dp = DEMO_PROFILES.find(p => p.id === profileId);
      if (!dp) return null;
      return { profile: dp, nodes: DEMO_NODES[dp.id] || [], agents: DEMO_AGENTS[dp.id] || [] };
    }

    const nodeRows = await this.sql`SELECT * FROM timeline_nodes WHERE profile_id = ${profileId} ORDER BY ordinal ASC`;
    const personaRows = await this.sql`SELECT * FROM persona_specs WHERE profile_id = ${profileId} ORDER BY id ASC`;

    return {
      profile: {
        id: profileRow.id, displayName: profileRow.display_name, subtitle: profileRow.subtitle,
        category: profileRow.category, coverSeed: profileRow.cover_seed, biography: profileRow.biography,
        highlights: strArr(profileRow.highlights), suggestedTopics: strArr(profileRow.suggested_topics),
      },
      nodes: nodeRows.map(r => ({
        nodeId: r.id, timeLabel: r.time_label, ageLabel: r.age_label ?? undefined,
        stageLabel: r.stage_label, stageType: r.stage_type, keyEvent: r.key_event,
        summary: r.summary, traits: strArr(r.traits), values: strArr(r.values),
        tensions: strArr(r.tensions), sourceEvidence: objArr(r.source_evidence),
      })),
      agents: personaRows.map(r => ({
        agentId: r.id, displayName: r.display_name, personId: r.profile_id,
        avatarSeed: r.avatar_seed, timeLabel: r.time_label, stageLabel: r.stage_label,
        keyEvent: r.key_event, knownFacts: strArr(r.known_facts), sourceEvidence: objArr(r.source_evidence),
        traits: strArr(r.traits), values: strArr(r.values), goal: r.goal, fear: r.fear,
        voiceStyle: r.voice_style, knowledgeBoundary: r.knowledge_boundary,
        forbiddenFutureKnowledge: r.forbidden_future_knowledge, stanceSeed: r.stance_seed,
      })),
    };
  }

  async parseTimeline(req: { displayName: string; biography: string }): Promise<{ personId: string; displayName: string; nodes: TimelineNode[] }> {
    const personId = `custom-${Date.now()}`;
    return {
      personId,
      displayName: req.displayName,
      nodes: [
        { nodeId: `${personId}-1`, timeLabel: '早期', stageLabel: '成长期', stageType: 'early', keyEvent: '早年经历', summary: req.biography.slice(0, 100), traits: ['待补充'], values: ['待补充'], tensions: [], sourceEvidence: [{ quote: req.biography.slice(0, 50), sourceLabel: '传记' }] },
        { nodeId: `${personId}-2`, timeLabel: '现在', stageLabel: '当前阶段', stageType: 'stable', keyEvent: '当前状态', summary: req.biography.slice(50, 150) || '当前阶段', traits: ['待补充'], values: ['待补充'], tensions: [], sourceEvidence: [{ quote: req.biography.slice(0, 50), sourceLabel: '传记' }] },
      ],
    };
  }

  async buildAgents(req: { personId: string; displayName: string; nodes: TimelineNode[] }): Promise<{ agents: PersonaSpec[] }> {
    const agents: PersonaSpec[] = req.nodes.map((node, i) => ({
      agentId: `${req.personId}-${i + 1}-agent`,
      displayName: `${req.displayName}(${node.stageLabel})`,
      personId: req.personId, avatarSeed: `${req.personId}-${i}`,
      timeLabel: node.timeLabel, stageLabel: node.stageLabel, keyEvent: node.keyEvent,
      knownFacts: node.traits, sourceEvidence: node.sourceEvidence,
      traits: node.traits, values: node.values,
      goal: `在${node.stageLabel}阶段实现自我突破`, fear: '停滞不前',
      voiceStyle: '真实自然', knowledgeBoundary: `只知道${node.timeLabel}之前的事`,
      forbiddenFutureKnowledge: true, stanceSeed: `${node.stageLabel}视角`,
    }));
    return { agents };
  }

  async runArena(req: ArenaRunRequest): Promise<ArenaRun> {
    const agents = req.agents.filter(a => req.selectedAgentIds.includes(a.agentId));
    const run = generateMockArenaRun(req.topic, req.mode, agents);
    try {
      await this.sql`
        INSERT INTO arena_runs (id, topic, mode, participant_ids, participants, messages, summary)
        VALUES (${run.runId}, ${run.topic}, ${run.mode},
          ${this.sql.json(asJson(run.participants.map(p => p.agentId)))},
          ${this.sql.json(asJson(run.participants))},
          ${this.sql.json(asJson(run.messages))},
          ${this.sql.json(asJson(run.summary))})
        ON CONFLICT (id) DO UPDATE SET messages = excluded.messages, summary = excluded.summary`;
    } catch { /* demo mode */ }
    return run;
  }

  async streamArena(req: ArenaRunRequest, emit: (event: unknown) => void): Promise<void> {
    const agents = req.agents.filter(a => req.selectedAgentIds.includes(a.agentId));
    const runId = `run-${Date.now()}`;
    const sessionId = `session-${Date.now()}`;

    emit({ type: 'run_started', runId, mode: req.mode, topic: req.topic, sequence: 0, timestamp: new Date().toISOString(), sessionId });

    const phases: ArenaPhase[] = req.mode === 'chat' ? ['opening', 'reflection', 'synthesis'] : ['opening', 'rebuttal', 'closing'];
    const allMessages: ArenaMessage[] = [];
    let seq = 0;

    for (let round = 1; round <= 2; round++) {
      for (const phase of phases) {
        emit({ type: 'phase_started', runId, phase, round, sequence: ++seq, timestamp: new Date().toISOString() });

        for (const agent of agents) {
          const messageId = `msg-${Date.now()}-${seq}`;
          emit({ type: 'speaker_started', runId, agentId: agent.agentId, displayName: agent.displayName, stageLabel: agent.stageLabel, messageId, phase, round, sequence: ++seq, timestamp: new Date().toISOString() });

          const content = generateAgentResponse(agent, req.topic, phase, req.mode);
          const accumulated = content;
          emit({ type: 'speaker_delta', runId, messageId, delta: content, accumulatedText: accumulated, sequence: ++seq, timestamp: new Date().toISOString() });

          const msg: ArenaMessage = {
            id: messageId, agentId: agent.agentId, displayName: agent.displayName,
            stageLabel: agent.stageLabel, content, stance: ['support', 'oppose', 'reflective', 'neutral'][seq % 4] as ArenaMessage['stance'],
            round, phase, timestamp: new Date().toISOString(),
          };
          emit({ type: 'speaker_completed', runId, messageId, sequence: ++seq, timestamp: new Date().toISOString() });
          emit({ type: 'message', runId, message: msg, sequence: ++seq, timestamp: new Date().toISOString() });
          allMessages.push(msg);
        }

        emit({ type: 'phase_completed', runId, phase, round, sequence: ++seq, timestamp: new Date().toISOString() });
      }
    }

    const summary = {
      title: `${req.topic.slice(0, 20)}...的${req.mode === 'debate' ? '辩论' : '讨论'}总结`,
      consensus: `经过讨论，各位人格在"${req.topic}"上达成了有限共识。`,
      disagreements: ['短期利益与长期目标的优先级存在分歧'],
      actionableAdvice: ['列出当前最核心的三个优先事项'],
      narrativeHook: `当${agents.map(a => a.displayName).join('、')}坐在一起讨论时，他们发现答案比想象中复杂。`,
    };

    emit({ type: 'summary_started', runId, sequence: ++seq, timestamp: new Date().toISOString() });
    emit({ type: 'summary_delta', runId, delta: summary.consensus, sequence: ++seq, timestamp: new Date().toISOString() });

    const result: ArenaRun = { runId, sessionId, mode: req.mode, topic: req.topic, participants: agents, messages: allMessages, summary, status: 'completed', createdAt: new Date().toISOString() };
    emit({ type: 'done', runId, result, sequence: ++seq, timestamp: new Date().toISOString() });
  }

  async listArenaRuns(): Promise<ArenaRunHistoryItem[]> {
    if (this.useDemoData) return [];
    const rows = await this.sql`SELECT id, topic, mode, participants, summary, created_at FROM arena_runs ORDER BY created_at DESC LIMIT 50`;
    return rows.map(r => ({
      runId: r.id, mode: r.mode as ArenaMode, topic: r.topic,
      title: (r.summary as Record<string, string>)?.title,
      consensus: (r.summary as Record<string, string>)?.consensus,
      participantNames: (r.participants as { displayName: string }[])?.map((p: { displayName: string }) => p.displayName) || [],
      createdAt: toIso(r.created_at),
    }));
  }

  async listSummaries(filter: SummaryFilter = {}): Promise<SummaryListResponse> {
    if (this.useDemoData) return { total: 0, items: [], hasMore: false };
    const rows = await this.sql`SELECT * FROM summaries ORDER BY created_at DESC`;
    let records = rows.map(r => this.mapSummaryRow(r));

    if (filter.keyword) {
      const kw = filter.keyword.toLowerCase();
      records = records.filter(r => `${r.title} ${r.topic} ${r.consensus}`.toLowerCase().includes(kw));
    }
    if (filter.category === 'favorite') records = records.filter(r => r.isFavorite);

    return { total: records.length, items: records.map(r => this.toListItem(r)), hasMore: false };
  }

  async getSummary(id: string, incView = false): Promise<SummaryRecord | null> {
    if (this.useDemoData) return null;
    if (incView) {
      const [updated] = await this.sql`UPDATE summaries SET view_count = view_count + 1 WHERE id = ${id} RETURNING *`;
      if (updated) return this.mapSummaryRow(updated);
    }
    const [row] = await this.sql`SELECT * FROM summaries WHERE id = ${id} LIMIT 1`;
    return row ? this.mapSummaryRow(row) : null;
  }

  async createSummary(input: CreateSummaryRequest): Promise<SummaryRecord> {
    const id = `summary_${input.arenaRunId}`;
    const participants = input.participants.map((p, i) => ({
      agentId: p.agentId, displayName: p.displayName, stageLabel: p.stageLabel,
      avatarSeed: p.avatarSeed, accentColor: COLORS[i % COLORS.length],
    }));
    const [row] = await this.sql`
      INSERT INTO summaries (id, arena_run_id, profile_id, title, topic, duration, message_count,
        consensus, disagreements, actionable_advice, narrative_hook, moderator_note,
        participants, highlights, tags, message_ids, updated_at)
      VALUES (${id}, ${input.arenaRunId}, ${input.profileId ?? null},
        ${input.summary.title || '会议纪要'}, ${input.topic}, ${input.duration}, ${input.messageIds.length},
        ${input.summary.consensus}, ${this.sql.json(asJson(input.summary.disagreements))},
        ${this.sql.json(asJson(input.summary.actionableAdvice))}, ${input.summary.narrativeHook},
        ${input.summary.moderatorNote ?? null},
        ${this.sql.json(asJson(participants))}, ${this.sql.json(asJson([]))},
        ${this.sql.json(asJson([]))}, ${this.sql.json(asJson(input.messageIds))}, NOW())
      ON CONFLICT (arena_run_id) DO UPDATE SET title = excluded.title, consensus = excluded.consensus, updated_at = NOW()
      RETURNING *`;
    return this.mapSummaryRow(row);
  }

  async updateSummary(id: string, updates: UpdateSummaryRequest): Promise<SummaryRecord | null> {
    const existing = await this.getSummary(id);
    if (!existing) return null;
    const [row] = await this.sql`
      UPDATE summaries SET title = ${updates.title ?? existing.title},
        tags = ${this.sql.json(asJson(updates.tags ?? existing.tags))},
        is_favorite = ${updates.isFavorite ?? existing.isFavorite},
        highlights = ${this.sql.json(asJson(updates.highlights ?? existing.highlights))},
        updated_at = NOW() WHERE id = ${id} RETURNING *`;
    return row ? this.mapSummaryRow(row) : null;
  }

  async deleteSummary(id: string): Promise<boolean> {
    const [row] = await this.sql`DELETE FROM summaries WHERE id = ${id} RETURNING id`;
    return !!row;
  }

  private mapSummaryRow(r: Record<string, unknown>): SummaryRecord {
    return {
      id: r.id as string, title: r.title as string, topic: r.topic as string,
      createdAt: toIso(r.created_at), updatedAt: toIso(r.updated_at),
      duration: r.duration as number, messageCount: r.message_count as number,
      consensus: r.consensus as string, disagreements: strArr(r.disagreements),
      actionableAdvice: strArr(r.actionable_advice), narrativeHook: r.narrative_hook as string,
      moderatorNote: (r.moderator_note as string) || undefined,
      participants: objArr(r.participants), highlights: strArr(r.highlights),
      tags: strArr(r.tags), isFavorite: r.is_favorite as boolean, viewCount: r.view_count as number,
    };
  }

  private toListItem(r: SummaryRecord): SummaryListItem {
    const names = r.participants.map(p => p.displayName);
    return {
      id: r.id, title: r.title, topic: r.topic, createdAt: r.createdAt,
      timeAgo: timeAgo(r.createdAt), participantNames: names,
      consensusPreview: r.consensus.length > 50 ? r.consensus.slice(0, 50) + '...' : r.consensus,
      isFavorite: r.isFavorite, messageCount: r.messageCount, duration: r.duration,
    };
  }
}
