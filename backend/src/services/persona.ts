import type { MemoryRepository } from '../memory-repository.js';
import type { BuildAgentsRequest, BuildAgentsResponse, PersonaBlueprint, PersonaSpec, TimelineNode } from '../domain.js';
import { chatWithLlm } from './llm.js';

function defaultGoal(node: TimelineNode): string {
  if (node.stageType === 'early') return '证明自己有资格被看见';
  if (node.stageType === 'turning-point') return '抓住转折并把势能放大';
  if (node.stageType === 'crisis') return '避免再次受伤，同时守住体面';
  if (node.stageType === 'rebuild') return '重新建立更稳定的选择方式';
  if (node.stageType === 'peak') return '把经验沉淀成更有掌控感的判断';
  return '把眼前的局面撑住';
}

function defaultFear(node: TimelineNode): string {
  if (node.stageType === 'early') return '害怕还没开始就被现实定义';
  if (node.stageType === 'turning-point') return '害怕错过机会后再也追不上';
  if (node.stageType === 'crisis') return '害怕投入再次变成损耗';
  if (node.stageType === 'rebuild') return '害怕退回旧模式';
  if (node.stageType === 'peak') return '害怕因为自负而忽略风险';
  return '害怕选择被动发生';
}

function defaultVoiceStyle(node: TimelineNode): string {
  if (node.stageType === 'early') return '语气直接、带一点冲劲';
  if (node.stageType === 'turning-point') return '表达强势，偏行动导向';
  if (node.stageType === 'crisis') return '更谨慎，也更容易显露情绪';
  if (node.stageType === 'rebuild') return '说话更慢，更强调边界';
  if (node.stageType === 'peak') return '表达简洁，结论性强';
  return '语气克制，偏观察型';
}

function defaultStanceSeed(node: TimelineNode): string {
  if (node.stageType === 'early') return '倾向冒险，认为先行动再修正';
  if (node.stageType === 'turning-point') return '倾向强推进，认为窗口期最重要';
  if (node.stageType === 'crisis') return '倾向保守，先降低损失';
  if (node.stageType === 'rebuild') return '倾向平衡，强调边界与节奏';
  if (node.stageType === 'peak') return '倾向聚焦，强调长期判断';
  return '倾向先观察再判断';
}

function mergeBlueprint(personId: string, displayName: string, node: TimelineNode, blueprint?: PersonaBlueprint): PersonaSpec {
  return {
    agentId: `${node.nodeId}-agent`,
    displayName: `${displayName} · ${node.stageLabel}`,
    personId,
    avatarSeed: `${personId}-${node.stageType}`,
    timeLabel: node.timeLabel,
    stageLabel: node.stageLabel,
    keyEvent: node.keyEvent,
    knownFacts: blueprint?.knownFacts?.length ? blueprint.knownFacts : [node.summary, ...node.tensions].slice(0, 4),
    sourceEvidence: node.sourceEvidence,
    traits: node.traits,
    values: node.values,
    goal: blueprint?.goal ?? defaultGoal(node),
    fear: blueprint?.fear ?? defaultFear(node),
    voiceStyle: blueprint?.voiceStyle ?? defaultVoiceStyle(node),
    knowledgeBoundary: blueprint?.knowledgeBoundary ?? `只能知道 ${node.timeLabel} 及之前已经发生的事实，不知道后续结局。`,
    forbiddenFutureKnowledge: true,
    stanceSeed: blueprint?.stanceSeed ?? defaultStanceSeed(node),
  };
}

const PERSONA_SYSTEM_PROMPT = `你是一位专业的人格铸造师。你的任务是为人物的每个生命阶段生成完整的对话人格规格。

对于每个阶段，请生成以下字段：
- nodeId: 对应的节点ID
- knownFacts: 这个阶段已知的关键事实数组（2-4条）
- goal: 这个阶段最想实现什么（一句话）
- fear: 这个阶段最怕什么（一句话）
- voiceStyle: 说话风格描述（2-3句话，描述语气、用词习惯、表达特点）
- knowledgeBoundary: 知识边界（这个阶段知道什么、不知道什么，一句话）
- stanceSeed: 讨论立场种子（这个阶段的典型立场倾向，一句话）

请严格按照JSON格式返回：
{
  "blueprints": [
    {
      "nodeId": "...",
      "knownFacts": ["..."],
      "goal": "...",
      "fear": "...",
      "voiceStyle": "...",
      "knowledgeBoundary": "...",
      "stanceSeed": "..."
    }
  ]
}`;

export async function buildAgents(
  repository: MemoryRepository,
  input: BuildAgentsRequest,
): Promise<BuildAgentsResponse> {
  const existingAgents = await repository.getPersonasForProfile(input.personId);
  if (existingAgents.length === input.nodes.length && existingAgents.every((agent) => input.nodes.some((node) => `${node.nodeId}-agent` === agent.agentId))) {
    return { agents: existingAgents };
  }

  let blueprints: PersonaBlueprint[] = [];

  try {
    const nodesInfo = input.nodes.map((node, i) =>
      `[阶段${i + 1}] nodeId=${node.nodeId}, 时间=${node.timeLabel}, 阶段=${node.stageLabel}, 类型=${node.stageType}, 事件=${node.keyEvent}, 摘要=${node.summary}, 特征=${node.traits.join(',')}, 价值观=${node.values.join(',')}`
    ).join('\n');

    const biography = input.biography ?? input.nodes.map((node) => node.summary).join('\n');

    const userPrompt = `请为以下人物的每个阶段生成人格规格：

人物: ${input.displayName}
传记: ${biography.substring(0, 2000)}

阶段信息:
${nodesInfo}

共${input.nodes.length}个阶段，请为每个阶段生成一个人格规格。`;

    const result = await chatWithLlm({
      messages: [
        { role: 'system', content: PERSONA_SYSTEM_PROMPT },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.6,
    });

    if (result.ok) {
      const jsonMatch = result.text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        blueprints = (parsed.blueprints || []).map((b: Record<string, unknown>) => ({
          nodeId: String(b.nodeId || ''),
          knownFacts: Array.isArray(b.knownFacts) ? b.knownFacts.map(String) : [],
          goal: String(b.goal || ''),
          fear: String(b.fear || ''),
          voiceStyle: String(b.voiceStyle || ''),
          knowledgeBoundary: String(b.knowledgeBoundary || ''),
          stanceSeed: String(b.stanceSeed || ''),
        }));
      }
    }
  } catch (error) {
    console.warn('persona generation fallback (DeepSeek):', error);
  }

  const blueprintMap = new Map(blueprints.map((item) => [item.nodeId, item]));
  const agents = input.nodes.map((node) => mergeBlueprint(input.personId, input.displayName, node, blueprintMap.get(node.nodeId)));

  await repository.savePersonas(input.personId, agents);
  return { agents };
}
