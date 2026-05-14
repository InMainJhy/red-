import { SummaryRecord } from '../common/Models'

export function upsertSummaryRecordByArenaRunId(
  records: SummaryRecord[],
  incoming: SummaryRecord
): SummaryRecord[] {
  const arenaRunId = incoming.arenaRunId ? incoming.arenaRunId.trim() : ''
  if (arenaRunId.length <= 0) {
    const nextWithoutSameId = records.filter((record: SummaryRecord) => record.id !== incoming.id)
    return [incoming].concat(nextWithoutSameId)
  }

  const existingIndex = records.findIndex((record: SummaryRecord) => {
    return (record.arenaRunId ? record.arenaRunId.trim() : '') === arenaRunId
  })

  if (existingIndex < 0) {
    return [incoming].concat(records)
  }

  const existing = records[existingIndex]
  const merged: SummaryRecord = {
    id: existing.id,
    title: incoming.title,
    topic: incoming.topic,
    createdAt: existing.createdAt,
    updatedAt: incoming.updatedAt && incoming.updatedAt.length > 0 ? incoming.updatedAt : existing.updatedAt,
    duration: incoming.duration,
    messageCount: incoming.messageCount,
    consensus: incoming.consensus,
    disagreements: incoming.disagreements,
    actionableAdvice: incoming.actionableAdvice,
    narrativeHook: incoming.narrativeHook,
    moderatorNote: incoming.moderatorNote,
    participants: incoming.participants,
    highlights: incoming.highlights,
    tags: incoming.tags,
    isFavorite: existing.isFavorite,
    viewCount: incoming.viewCount,
    exportedAssets: incoming.exportedAssets,
    thumbnailPath: incoming.thumbnailPath,
    messageIds: incoming.messageIds,
    arenaRunId: incoming.arenaRunId,
    profileId: incoming.profileId
  }

  const next = records.slice()
  next.splice(existingIndex, 1)
  return [merged].concat(next)
}
