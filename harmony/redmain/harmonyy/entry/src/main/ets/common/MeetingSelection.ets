import { RouteParams } from './Models'

export interface MeetingSelectionState {
  profileIds: string[]
  selectedAgentIds: string[]
}

export const MAX_MEETING_PARTICIPANTS: number = 3

function normalizeStringArray(values: string[]): string[] {
  let unique: string[] = []
  values.forEach((value: string) => {
    const normalized = value.trim()
    if (normalized.length === 0) {
      return
    }
    if (!unique.includes(normalized)) {
      unique.push(normalized)
    }
  })
  return unique
}

export function encodeRouteStringArray(values: string[]): string {
  return encodeURIComponent(JSON.stringify(normalizeStringArray(values)))
}

export function parseRouteStringArray(raw?: string): string[] {
  if (!raw || raw.trim().length === 0) {
    return []
  }

  try {
    const decoded = decodeURIComponent(raw)
    const parsed = JSON.parse(decoded) as Object
    if (Array.isArray(parsed)) {
      return normalizeStringArray(parsed as string[])
    }
  } catch (_error) {
    // Fallback for legacy comma-separated params
  }

  return normalizeStringArray(raw.split(','))
}

export function mergeUniqueStrings(...groups: string[][]): string[] {
  let merged: string[] = []
  groups.forEach((group: string[]) => {
    merged = normalizeStringArray([...merged, ...group])
  })
  return merged
}

export function parseMeetingSelection(params: RouteParams): MeetingSelectionState {
  return {
    profileIds: parseRouteStringArray(params.profileIds),
    selectedAgentIds: parseRouteStringArray(params.selectedAgentIds)
  }
}

export function buildMeetingRouteParams(
  selection: MeetingSelectionState,
  extras?: RouteParams
): RouteParams {
  let nextParams: RouteParams = extras ? extras : {}
  nextParams.profileIds = encodeRouteStringArray(selection.profileIds)
  nextParams.selectedAgentIds = encodeRouteStringArray(selection.selectedAgentIds)
  return nextParams
}
