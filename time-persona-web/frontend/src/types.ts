// ============================================
// Domain Types for TimePersona Web
// ============================================

export type ArenaMode = 'chat' | 'debate';
export type ArenaPhase = 'opening' | 'reflection' | 'rebuttal' | 'synthesis' | 'closing' | 'manual';
export type ArenaStance = 'support' | 'oppose' | 'reflective' | 'neutral';
export type PersonaCategory = 'self' | 'celebrity' | 'history' | 'fictional';
export type TimelineStageType = 'early' | 'turning-point' | 'stable' | 'crisis' | 'rebuild' | 'peak';

export interface PresetProfile {
  id: string;
  displayName: string;
  subtitle: string;
  category: PersonaCategory;
  coverSeed: string;
  biography: string;
  highlights: string[];
  suggestedTopics: string[];
}

export interface SourceEvidence {
  quote: string;
  sourceLabel: string;
}

export interface TimelineNode {
  nodeId: string;
  timeLabel: string;
  ageLabel?: string;
  stageLabel: string;
  stageType: TimelineStageType;
  keyEvent: string;
  summary: string;
  traits: string[];
  values: string[];
  tensions: string[];
  sourceEvidence: SourceEvidence[];
}

export interface PersonaSpec {
  agentId: string;
  displayName: string;
  personId: string;
  avatarSeed: string;
  timeLabel: string;
  stageLabel: string;
  keyEvent: string;
  knownFacts: string[];
  sourceEvidence: SourceEvidence[];
  traits: string[];
  values: string[];
  goal: string;
  fear: string;
  voiceStyle: string;
  knowledgeBoundary: string;
  forbiddenFutureKnowledge: boolean;
  stanceSeed: string;
}

export interface ProfileBundle {
  profile: PresetProfile;
  nodes: TimelineNode[];
  agents: PersonaSpec[];
  sourceDocument?: { id: string; title: string; author?: string | null } | null;
}

export interface ArenaMessage {
  id: string;
  agentId: string;
  displayName: string;
  stageLabel: string;
  content: string;
  stance: ArenaStance;
  round?: number;
  phase?: ArenaPhase;
  replyToAgentId?: string;
  replyToDisplayName?: string;
  timestamp?: string;
}

export interface ArenaSummary {
  title: string;
  consensus: string;
  disagreements: string[];
  actionableAdvice: string[];
  narrativeHook: string;
  moderatorNote?: string;
}

export interface ArenaRun {
  runId: string;
  sessionId?: string;
  mode: ArenaMode;
  topic: string;
  participants: PersonaSpec[];
  messages: ArenaMessage[];
  summary: ArenaSummary;
  status?: 'completed' | 'interrupted';
  createdAt?: string;
}

export interface ArenaRunHistoryItem {
  runId: string;
  mode: ArenaMode;
  topic: string;
  title?: string;
  consensus?: string;
  participantNames: string[];
  messageCount?: number;
  createdAt?: string;
}

// Stream events
export type ArenaStreamEventType =
  | 'run_started' | 'phase_started' | 'speaker_started'
  | 'speaker_delta' | 'speaker_completed' | 'message'
  | 'phase_completed' | 'summary_started' | 'summary_delta'
  | 'summary' | 'done' | 'error';

export interface ArenaStreamEvent {
  type: ArenaStreamEventType;
  runId: string;
  mode: ArenaMode;
  topic: string;
  sequence: number;
  timestamp: string;
  sessionId?: string;
  plannedRounds?: { round: number; phase: ArenaPhase }[];
  participants?: PersonaSpec[];
  round?: number;
  phase?: ArenaPhase;
  messageId?: string;
  agentId?: string;
  displayName?: string;
  stageLabel?: string;
  delta?: string;
  accumulatedText?: string;
  message?: ArenaMessage;
  summary?: ArenaSummary;
  result?: ArenaRun;
  error?: string;
}

// Search / Explore types
export type SearchCategory =
  | 'all' | 'business' | 'finance' | 'tech' | 'politics'
  | 'culture' | 'sports' | 'entertainment' | 'education' | 'philosophy';

export interface PersonaSearchResult {
  id: string;
  displayName: string;
  subtitle: string;
  category: SearchCategory;
  coverSeed: string;
  matchReason: string[];
  hotLevel: number;
  tags: string[];
}

// Summary types
export interface SummaryParticipant {
  agentId: string;
  displayName: string;
  stageLabel: string;
  avatarSeed: string;
  accentColor: string;
}

export interface SummaryRecord {
  id: string;
  title: string;
  topic: string;
  createdAt: string;
  updatedAt: string;
  duration: number;
  messageCount: number;
  consensus: string;
  disagreements: string[];
  actionableAdvice: string[];
  narrativeHook: string;
  moderatorNote?: string;
  participants: SummaryParticipant[];
  highlights: string[];
  tags: string[];
  isFavorite: boolean;
  viewCount: number;
}

export interface SummaryListItem {
  id: string;
  title: string;
  topic: string;
  createdAt: string;
  timeAgo: string;
  participantNames: string[];
  consensusPreview: string;
  isFavorite: boolean;
  messageCount: number;
  duration: number;
}

export interface SummaryFilter {
  category?: 'all' | 'favorite' | 'tag';
  tag?: string;
  keyword?: string;
  sortBy?: 'createdAt' | 'updatedAt' | 'viewCount';
  sortOrder?: 'asc' | 'desc';
}

export interface SummaryListResponse {
  total: number;
  items: SummaryListItem[];
  hasMore: boolean;
}

// API request/response types
export interface ParseTimelineRequest {
  profileId?: string;
  displayName: string;
  biography: string;
}

export interface ParseTimelineResponse {
  personId: string;
  displayName: string;
  nodes: TimelineNode[];
}

export interface BuildAgentsRequest {
  personId: string;
  displayName: string;
  biography?: string;
  nodes: TimelineNode[];
}

export interface BuildAgentsResponse {
  agents: PersonaSpec[];
}

export interface ArenaRunRequest {
  topic: string;
  mode: ArenaMode;
  selectedAgentIds: string[];
  agents: PersonaSpec[];
  reasoningEffort?: string;
  roundCount?: number;
}

export interface CreateSummaryRequest {
  arenaRunId: string;
  profileId?: string;
  topic: string;
  summary: ArenaSummary;
  participants: PersonaSpec[];
  messageIds: string[];
  duration: number;
}

export const EMPTY_PROFILE: PresetProfile = {
  id: '',
  displayName: '',
  subtitle: '',
  category: 'self',
  coverSeed: '',
  biography: '',
  highlights: [],
  suggestedTopics: [],
};
