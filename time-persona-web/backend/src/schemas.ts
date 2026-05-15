import { z } from 'zod';

export const sourceEvidenceSchema = z.object({
  quote: z.string().min(1), sourceLabel: z.string().min(1),
});

export const timelineNodeSchema = z.object({
  nodeId: z.string().min(1), timeLabel: z.string().min(1),
  ageLabel: z.string().min(1).optional(), stageLabel: z.string().min(1),
  stageType: z.enum(['early', 'turning-point', 'stable', 'crisis', 'rebuild', 'peak']),
  keyEvent: z.string().min(1), summary: z.string().min(1),
  traits: z.array(z.string().min(1)).min(1).max(5),
  values: z.array(z.string().min(1)).min(1).max(5),
  tensions: z.array(z.string().min(1)).min(1).max(4),
  sourceEvidence: z.array(sourceEvidenceSchema).min(1).max(4),
});

export const personaSpecSchema = z.object({
  agentId: z.string().min(1), displayName: z.string().min(1),
  personId: z.string().min(1), avatarSeed: z.string().min(1),
  timeLabel: z.string().min(1), stageLabel: z.string().min(1),
  keyEvent: z.string().min(1), knownFacts: z.array(z.string().min(1)).min(1),
  sourceEvidence: z.array(sourceEvidenceSchema).min(1),
  traits: z.array(z.string().min(1)).min(1), values: z.array(z.string().min(1)).min(1),
  goal: z.string().min(1), fear: z.string().min(1), voiceStyle: z.string().min(1),
  knowledgeBoundary: z.string().min(1), forbiddenFutureKnowledge: z.boolean(),
  stanceSeed: z.string().min(1),
});

export const parseTimelineRequestSchema = z.object({
  profileId: z.string().min(1).optional(), displayName: z.string().min(1), biography: z.string().min(10),
});

export const buildAgentsRequestSchema = z.object({
  personId: z.string().min(1), displayName: z.string().min(1),
  biography: z.string().min(10).optional(), nodes: z.array(timelineNodeSchema).min(1),
});

export const arenaRunRequestSchema = z.object({
  topic: z.string().min(1), mode: z.enum(['chat', 'debate']),
  selectedAgentIds: z.array(z.string().min(1)).min(2),
  agents: z.array(personaSpecSchema).min(2),
});

export const arenaSummarySchema = z.object({
  title: z.string().min(1), consensus: z.string().min(1),
  disagreements: z.array(z.string().min(1)),
  actionableAdvice: z.array(z.string().min(1)),
  narrativeHook: z.string().min(1), moderatorNote: z.string().min(1).optional(),
});

export const createSummaryRequestSchema = z.object({
  arenaRunId: z.string().min(1), profileId: z.string().min(1).optional(),
  topic: z.string().min(1), summary: arenaSummarySchema,
  participants: z.array(personaSpecSchema).min(1),
  messageIds: z.array(z.string().min(1)), duration: z.number().int().min(0),
});

export const updateSummaryRequestSchema = z.object({
  title: z.string().min(1).optional(), tags: z.array(z.string().min(1)).max(20).optional(),
  isFavorite: z.boolean().optional(), highlights: z.array(z.string().min(1)).max(10).optional(),
}).refine((v) => Object.keys(v).length > 0, { message: 'at least one field required' });
