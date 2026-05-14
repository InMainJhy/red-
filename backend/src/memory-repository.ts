import crypto from 'node:crypto';
import type {
  ArenaRun,
  ClaudeExecutionInfo,
  PersonaSpec,
  PresetProfile,
  ProfileBundle,
  ProfileCategory,
  SourceDocumentSummary,
  SourceSection,
  TimelineNode,
} from './domain.js';
import { PRESET_PROFILES_FULL } from './presets-data.js';

export interface SourceDocumentInput {
  title: string;
  author?: string;
  filePath: string;
  fileHash: string;
  sourceType: 'epub' | 'text';
  metadata: Record<string, unknown>;
  sections: SourceSection[];
}

export interface ProfileBundleInput {
  id: string;
  displayName: string;
  subtitle: string;
  category: ProfileCategory;
  coverSeed: string;
  biography: string;
  highlights: string[];
  suggestedTopics: string[];
  sourceDocumentId?: string | null;
  origin: 'default-import' | 'manual';
  isDefault: boolean;
  rawInput?: string;
  metadata?: Record<string, unknown>;
  nodes: TimelineNode[];
  agents?: PersonaSpec[];
  personaModelInfo?: ClaudeExecutionInfo;
}

interface SourceDocument {
  id: string;
  slug: string;
  sourceType: string;
  title: string;
  author: string | null;
  filePath: string;
  fileHash: string;
  metadata: Record<string, unknown>;
  importedAt: string;
  sections: SourceSection[];
}

interface ProfileRecord {
  id: string;
  displayName: string;
  subtitle: string;
  category: ProfileCategory;
  coverSeed: string;
  biography: string;
  highlights: string[];
  suggestedTopics: string[];
  sourceDocumentId: string | null;
  origin: string;
  isDefault: boolean;
  rawInput: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
  nodes: TimelineNode[];
  agents: PersonaSpec[];
}

interface ArenaRunRecord {
  id: string;
  topic: string;
  mode: string;
  participantIds: string[];
  participants: PersonaSpec[];
  messages: unknown[];
  summary: unknown;
  metadata: Record<string, unknown>;
  createdAt: string;
}

export class MemoryRepository {
  private sourceDocuments: Map<string, SourceDocument> = new Map();
  private profiles: Map<string, ProfileRecord> = new Map();
  private arenaRuns: Map<string, ArenaRunRecord> = new Map();

  async close(): Promise<void> {
    // No-op for memory storage
  }

  async ping(): Promise<void> {
    // Always healthy
  }

  async init(): Promise<void> {
    // 加载预设名人数据
    const now = new Date().toISOString();
    for (const preset of PRESET_PROFILES_FULL) {
      const existing = this.profiles.get(preset.profile.id);
      if (!existing) {
        this.profiles.set(preset.profile.id, {
          id: preset.profile.id,
          displayName: preset.profile.displayName,
          subtitle: preset.profile.subtitle,
          category: preset.profile.category,
          coverSeed: preset.profile.coverSeed,
          biography: preset.profile.biography,
          highlights: preset.profile.highlights,
          suggestedTopics: preset.profile.suggestedTopics,
          sourceDocumentId: null,
          origin: 'default-import',
          isDefault: true,
          rawInput: null,
          metadata: {},
          createdAt: now,
          updatedAt: now,
          nodes: preset.nodes,
          agents: preset.agents,
        });
      }
    }
    console.log(`Memory repository initialized with ${PRESET_PROFILES_FULL.length} preset profiles`);
  }

  async upsertSourceDocument(input: SourceDocumentInput): Promise<string> {
    const slug = input.title
      .toLowerCase()
      .replace(/[^a-z0-9\u4e00-\u9fa5]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .slice(0, 80);

    const existing = Array.from(this.sourceDocuments.values()).find(
      (doc) => doc.fileHash === input.fileHash
    );

    const documentId = existing?.id ?? crypto.randomUUID();

    this.sourceDocuments.set(documentId, {
      id: documentId,
      slug,
      sourceType: input.sourceType,
      title: input.title,
      author: input.author ?? null,
      filePath: input.filePath,
      fileHash: input.fileHash,
      metadata: input.metadata,
      importedAt: new Date().toISOString(),
      sections: input.sections,
    });

    return documentId;
  }

  async findSourceDocumentIdByHash(fileHash: string): Promise<string | null> {
    const doc = Array.from(this.sourceDocuments.values()).find(
      (d) => d.fileHash === fileHash
    );
    return doc?.id ?? null;
  }

  async getProfileIdBySourceDocument(documentId: string): Promise<string | null> {
    const profile = Array.from(this.profiles.values()).find(
      (p) => p.sourceDocumentId === documentId
    );
    return profile?.id ?? null;
  }

  async upsertProfileBundle(input: ProfileBundleInput): Promise<void> {
    const now = new Date().toISOString();
    const existing = this.profiles.get(input.id);

    this.profiles.set(input.id, {
      id: input.id,
      displayName: input.displayName,
      subtitle: input.subtitle,
      category: input.category,
      coverSeed: input.coverSeed,
      biography: input.biography,
      highlights: input.highlights,
      suggestedTopics: input.suggestedTopics,
      sourceDocumentId: input.sourceDocumentId ?? null,
      origin: input.origin,
      isDefault: input.isDefault,
      rawInput: input.rawInput ?? null,
      metadata: input.metadata ?? {},
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      nodes: input.nodes,
      agents: input.agents ?? [],
    });
  }

  async savePersonas(profileId: string, agents: PersonaSpec[]): Promise<void> {
    const profile = this.profiles.get(profileId);
    if (profile) {
      profile.agents = agents;
    }
  }

  async listDefaultPresets(): Promise<PresetProfile[]> {
    return Array.from(this.profiles.values())
      .filter((p) => p.isDefault)
      .sort((a, b) => a.displayName.localeCompare(b.displayName))
      .map((p) => this.mapProfileToPreset(p));
  }

  async getProfileBundle(profileId: string): Promise<ProfileBundle | null> {
    const profile = this.profiles.get(profileId);
    if (!profile) {
      return null;
    }

    let sourceDocument: SourceDocumentSummary | null = null;
    if (profile.sourceDocumentId) {
      const doc = this.sourceDocuments.get(profile.sourceDocumentId);
      if (doc) {
        sourceDocument = {
          id: doc.id,
          title: doc.title,
          author: doc.author,
          filePath: doc.filePath,
          importedAt: doc.importedAt,
          sectionCount: doc.sections.length,
        };
      }
    }

    return {
      profile: this.mapProfileToPreset(profile),
      nodes: profile.nodes,
      agents: profile.agents,
      sourceDocument,
    };
  }

  async getPersonasForProfile(profileId: string): Promise<PersonaSpec[]> {
    const profile = this.profiles.get(profileId);
    return profile?.agents ?? [];
  }

  async saveArenaRun(run: ArenaRun, executions: ClaudeExecutionInfo[]): Promise<void> {
    this.arenaRuns.set(run.runId, {
      id: run.runId,
      topic: run.topic,
      mode: run.mode,
      participantIds: run.participants.map((p) => p.agentId),
      participants: run.participants,
      messages: run.messages,
      summary: run.summary,
      metadata: { executions },
      createdAt: new Date().toISOString(),
    });
  }

  async getArenaRun(runId: string): Promise<ArenaRun | null> {
    const record = this.arenaRuns.get(runId);
    if (!record) return null;
    return {
      runId: record.id,
      topic: record.topic,
      mode: record.mode as ArenaRun['mode'],
      participants: record.participants as PersonaSpec[],
      messages: record.messages as ArenaRun['messages'],
      summary: record.summary as ArenaRun['summary'],
      createdAt: record.createdAt,
    };
  }

  async getOverview(): Promise<{ documents: number; defaultProfiles: number; arenaRuns: number }> {
    return {
      documents: this.sourceDocuments.size,
      defaultProfiles: Array.from(this.profiles.values()).filter((p) => p.isDefault).length,
      arenaRuns: this.arenaRuns.size,
    };
  }

  private mapProfileToPreset(profile: ProfileRecord): PresetProfile {
    return {
      id: profile.id,
      displayName: profile.displayName,
      subtitle: profile.subtitle,
      category: profile.category,
      coverSeed: profile.coverSeed,
      biography: profile.biography,
      highlights: profile.highlights,
      suggestedTopics: profile.suggestedTopics,
    };
  }
}
