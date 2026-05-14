import type { MemoryRepository } from '../memory-repository.js';
import type { ArenaMessage, ArenaPhase, ArenaRun, ArenaRunRequest, ArenaRunResponse, PersonaSpec } from '../domain.js';
import { chatWithLlm } from './llm.js';

function messageId(runId: string, index: number): string {
  return `${runId}-msg-${index + 1}`;
}

function inferStance(persona: PersonaSpec): ArenaMessage['stance'] {
  if (persona.stanceSeed.includes('冒险') || persona.stanceSeed.includes('推进') || persona.stanceSeed.includes('进攻')) return 'support';
  if (persona.stanceSeed.includes('保守') || persona.stanceSeed.includes('防御')) return 'oppose';
  if (persona.stanceSeed.includes('平衡') || persona.stanceSeed.includes('长期') || persona.stanceSeed.includes('反思')) return 'reflective';
  return 'neutral';
}

function heuristicMessage(
  persona: PersonaSpec,
  topic: string,
  phase: ArenaPhase,
  designatedTarget?: PersonaSpec,
): Pick<ArenaMessage, 'content' | 'stance'> {
  const stance = inferStance(persona);

  if (phase === 'rebuttal' && designatedTarget) {
    return {
      content: `我不同意 ${designatedTarget.displayName} 的判断。围绕"${topic}"，你强调的是一时推进，但站在 ${persona.timeLabel} 的我更在意 ${persona.values.join('、')}，因为我最怕的是 ${persona.fear}。`,
      stance,
    };
  }

  if (phase === 'closing' || phase === 'synthesis') {
    return {
      content: `如果最后只能留下一句判断，围绕"${topic}"，我会坚持 ${persona.stanceSeed}。真正需要守住的是 ${persona.goal}，而不是被短期情绪推着走。`,
      stance,
    };
  }

  if (phase === 'reflection' && designatedTarget) {
    return {
      content: `我能理解 ${designatedTarget.displayName} 为什么会这样说，但站在 ${persona.timeLabel} 的我会补一句：别只看眼前势头，还得看 ${persona.values.join('、')} 是否撑得住这次选择。`,
      stance: 'reflective',
    };
  }

  return {
    content: `如果问题是"${topic}"，站在 ${persona.timeLabel} 的我会先看 ${persona.values.join('、')}。我最在意的是 ${persona.goal}，所以直觉会偏向 ${persona.stanceSeed}。`,
    stance,
  };
}

function heuristicChatSummary(topic: string, participants: PersonaSpec[], messages: ArenaMessage[]) {
  return {
    title: '阶段人格会议纪要',
    consensus: `围绕"${topic}"，这些阶段人格都不再把答案看成单一的是或否，而是更关注代价、边界和时机。`,
    disagreements: participants.map((agent) => `${agent.stageLabel} 更看重 ${agent.values.join('、')}`),
    actionableAdvice: [
      '先写清你当前最不能失去的东西，再决定是否行动。',
      '把冲动和恐惧拆开处理，不要让同一种情绪同时做判断和执行。',
      '如果要改变，优先做低后悔成本的那一步。',
    ],
    narrativeHook: messages[0]?.content ?? '不同阶段的自己在同一个问题上给出了明显不同的判断。',
    moderatorNote: '真正成熟的答案，不是立刻统一，而是先看清每个阶段为什么会这样说。',
  };
}

function heuristicDebateSummary(topic: string, participants: PersonaSpec[], messages: ArenaMessage[]) {
  const winner = participants[0];
  return {
    title: '阶段人格辩论结果',
    consensus: `围绕"${topic}"，大家都承认决策不能只看冲动，必须同时考虑代价、组织承受力和长期后果。`,
    disagreements: participants.map((agent) => `${agent.stageLabel} 对风险与机会的权重不同`),
    actionableAdvice: [
      '先验证团队和节奏能否承载目标，再决定推进速度。',
      '把"想证明自己"和"真正值得做"拆开判断。',
      '把第二次出手建立在第一次失败的复盘之上，而不是建立在不甘心之上。',
    ],
    narrativeHook: messages[0]?.content ?? '几个阶段的自己围绕同一个问题展开了真正的互相质问。',
    debateVerdict: {
      winnerAgentId: winner?.agentId,
      winnerDisplayName: winner?.displayName,
      rationale: '在 fallback 模式下，系统默认把论点最先完整展开的一方视作暂时领先。',
      scorecards: participants.map((participant, index) => ({
        agentId: participant.agentId,
        displayName: participant.displayName,
        argumentScore: Math.max(6, 8 - index),
        evidenceScore: Math.max(6, 8 - index),
        responsivenessScore: Math.max(6, 8 - index),
        comments: `${participant.stageLabel} 的立场清晰，但 fallback 模式无法给出更精细的评分。`,
      })),
    },
  };
}

function getRingTarget(participants: PersonaSpec[], index: number, direction: 'next' | 'previous'): PersonaSpec | undefined {
  if (participants.length <= 1) return undefined;
  if (direction === 'next') return participants[(index + 1) % participants.length];
  return participants[(index + participants.length - 1) % participants.length];
}

function buildPhaseInstruction(persona: PersonaSpec, topic: string, mode: string, phase: ArenaPhase, designatedTarget?: PersonaSpec, previousMessages?: ArenaMessage[]): string {
  const previousContext = previousMessages && previousMessages.length > 0
    ? `\n\n之前的对话记录：\n${previousMessages.slice(-6).map(m => `${m.displayName}: ${m.content}`).join('\n')}`
    : '';

  const targetHint = designatedTarget
    ? `\n你需要特别回应 ${designatedTarget.displayName}（${designatedTarget.stageLabel}）的观点。`
    : '';

  if (phase === 'opening') {
    return `请就议题"${topic}"做开场陈述，表达你的立场和观点。${targetHint}`;
  }
  if (phase === 'reflection') {
    return `请回应前一位发言者的观点，表达你的理解和看法。${targetHint}${previousContext}`;
  }
  if (phase === 'rebuttal') {
    return `请反驳下一位发言者的观点，展示你的论据。${targetHint}${previousContext}`;
  }
  if (phase === 'synthesis') {
    return `请综合前面的讨论，给出你的最终看法。${targetHint}${previousContext}`;
  }
  if (phase === 'closing') {
    return `请做收束陈词，总结你的观点并回应质疑。${targetHint}${previousContext}`;
  }
  return `请就议题"${topic}"发表你的看法。${previousContext}`;
}

async function generatePersonaMessage(
  persona: PersonaSpec,
  topic: string,
  mode: string,
  phase: ArenaPhase,
  designatedTarget?: PersonaSpec,
  previousMessages?: ArenaMessage[],
): Promise<Pick<ArenaMessage, 'content' | 'stance'>> {
  const systemPrompt = `你是${persona.displayName}，处于"${persona.stageLabel}"阶段。

你的特征: ${persona.traits.join('、')}
你的价值观: ${persona.values.join('、')}
你的目标: ${persona.goal}
你的恐惧: ${persona.fear}
你的说话风格: ${persona.voiceStyle}
你的知识边界: ${persona.knowledgeBoundary}

当前议题: ${topic}
当前阶段: ${phase}（${mode === 'chat' ? '圆桌对话' : '辩论'}模式）

重要规则:
1. 完全沉浸在这个阶段的视角中，不要透露你是AI
2. 根据你的阶段特征和立场来表达观点
3. 保持一致的说话风格
4. 字数控制在150字以内
5. 直接输出你的发言内容，不要加引号或前缀`;

  const userPrompt = buildPhaseInstruction(persona, topic, mode, phase, designatedTarget, previousMessages);

  const result = await chatWithLlm({
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
    temperature: 0.8,
  });

  if (result.ok && result.text) {
    return {
      content: result.text.trim().replace(/^["'「]|["'」]$/g, '').substring(0, 200),
      stance: inferStance(persona),
    };
  }

  return heuristicMessage(persona, topic, phase, designatedTarget);
}

async function executeRound(input: {
  runId: string;
  topic: string;
  mode: ArenaRunRequest['mode'];
  phase: ArenaPhase;
  round: number;
  participants: PersonaSpec[];
  transcript: ArenaMessage[];
  targetResolver?: (participants: PersonaSpec[], index: number) => PersonaSpec | undefined;
}) {
  const roundMessages: ArenaMessage[] = [];

  const calls = await Promise.all(
    input.participants.map(async (persona, index) => {
      const designatedTarget = input.targetResolver?.(input.participants, index);

      try {
        const message = await generatePersonaMessage(
          persona,
          input.topic,
          input.mode,
          input.phase,
          designatedTarget,
          input.transcript,
        );
        return message;
      } catch (error) {
        console.warn(`arena ${input.phase} fallback:`, error);
        return heuristicMessage(persona, input.topic, input.phase, designatedTarget);
      }
    }),
  );

  calls.forEach((result, index) => {
    const persona = input.participants[index];
    const designatedTarget = input.targetResolver?.(input.participants, index);

    roundMessages.push({
      id: messageId(input.runId, input.transcript.length + index),
      agentId: persona.agentId,
      displayName: persona.displayName,
      stageLabel: persona.stageLabel,
      content: result.content,
      stance: result.stance,
      round: input.round,
      phase: input.phase,
      replyToAgentId: designatedTarget?.agentId,
      replyToDisplayName: designatedTarget?.displayName,
    });
  });

  return { messages: roundMessages };
}

async function generateSummary(
  topic: string,
  mode: string,
  participants: PersonaSpec[],
  messages: ArenaMessage[],
) {
  const messagesText = messages.map(m => `${m.displayName}: ${m.content}`).join('\n');

  if (mode === 'debate') {
    const prompt = `基于以下辩论，生成裁判评判：

议题: ${topic}
参与人数: ${participants.length}

对话内容:
${messagesText}

请生成JSON格式评判：
{
  "title": "辩论标题（20字以内）",
  "consensus": "共识点（1-2句话）",
  "disagreements": ["分歧点1", "分歧点2"],
  "actionableAdvice": ["建议1", "建议2"],
  "narrativeHook": "引人入胜的总结（1句话）",
  "debateVerdict": {
    "winnerAgentId": "获胜者agentId",
    "winnerDisplayName": "获胜者名称",
    "rationale": "评判理由（2句话）",
    "scorecards": [
      {
        "agentId": "...",
        "displayName": "...",
        "argumentScore": 8,
        "evidenceScore": 7,
        "responsivenessScore": 8,
        "comments": "点评"
      }
    ]
  }
}`;

    const result = await chatWithLlm({
      messages: [
        { role: 'system', content: '你是一位专业的辩论裁判。请严格按照JSON格式返回。' },
        { role: 'user', content: prompt },
      ],
      temperature: 0.6,
    });

    if (result.ok) {
      try {
        const jsonMatch = result.text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          return JSON.parse(jsonMatch[0]);
        }
      } catch (e) {
        console.warn('parse debate summary failed:', e);
      }
    }

    return heuristicDebateSummary(topic, participants, messages);
  }

  // Chat mode summary
  const prompt = `基于以下对话，生成一个总结：

议题: ${topic}
参与人数: ${participants.length}

对话内容:
${messagesText}

请生成JSON格式总结：
{
  "title": "对话标题（20字以内）",
  "consensus": "共识点（1-2句话）",
  "disagreements": ["分歧点1", "分歧点2"],
  "actionableAdvice": ["建议1", "建议2"],
  "narrativeHook": "引人入胜的总结（1句话）",
  "moderatorNote": "主持人点评（1-2句话）"
}`;

  const result = await chatWithLlm({
    messages: [
      { role: 'system', content: '你是一位专业的对话总结者。请严格按照JSON格式返回。' },
      { role: 'user', content: prompt },
    ],
    temperature: 0.6,
  });

  if (result.ok) {
    try {
      const jsonMatch = result.text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      }
    } catch (e) {
      console.warn('parse chat summary failed:', e);
    }
  }

  return heuristicChatSummary(topic, participants, messages);
}

export async function runArena(
  repository: MemoryRepository,
  input: ArenaRunRequest,
): Promise<ArenaRunResponse> {
  const participants = input.selectedAgentIds
    .map((agentId) => input.agents.find((agent) => agent.agentId === agentId))
    .filter((agent): agent is PersonaSpec => Boolean(agent))
    .slice(0, 3);

  if (participants.length < 2) {
    throw new Error('至少需要 2 个 agent 才能开始讨论');
  }

  const runId = `run-${Date.now()}`;
  let transcript: ArenaMessage[] = [];

  const roundPlans =
    input.mode === 'debate'
      ? [
          { round: 1, phase: 'opening' as ArenaPhase },
          { round: 2, phase: 'rebuttal' as ArenaPhase, targetResolver: (items: PersonaSpec[], index: number) => getRingTarget(items, index, 'next') },
          { round: 3, phase: 'closing' as ArenaPhase, targetResolver: (items: PersonaSpec[], index: number) => getRingTarget(items, index, 'previous') },
        ]
      : [
          { round: 1, phase: 'opening' as ArenaPhase },
          { round: 2, phase: 'reflection' as ArenaPhase, targetResolver: (items: PersonaSpec[], index: number) => getRingTarget(items, index, 'previous') },
          { round: 3, phase: 'synthesis' as ArenaPhase, targetResolver: (items: PersonaSpec[], index: number) => getRingTarget(items, index, 'next') },
        ];

  for (const roundPlan of roundPlans) {
    const executed = await executeRound({
      runId,
      topic: input.topic,
      mode: input.mode,
      phase: roundPlan.phase,
      round: roundPlan.round,
      participants,
      transcript,
      targetResolver: roundPlan.targetResolver,
    });

    transcript = [...transcript, ...executed.messages];
  }

  const messages = transcript;

  let summary;
  try {
    summary = await generateSummary(input.topic, input.mode, participants, messages);
  } catch (error) {
    console.warn('summary generation fallback:', error);
    summary = input.mode === 'debate'
      ? heuristicDebateSummary(input.topic, participants, messages)
      : heuristicChatSummary(input.topic, participants, messages);
  }

  const result: ArenaRun = {
    runId,
    mode: input.mode,
    topic: input.topic,
    participants,
    messages,
    summary,
  };

  await repository.saveArenaRun(result, []);
  return { result };
}
