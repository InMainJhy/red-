import type { LaunchIntent } from './LaunchIntent'

let pendingLaunchIntent: LaunchIntent | null = null

export class LaunchIntentStore {
  static set(intent: LaunchIntent): void {
    pendingLaunchIntent = intent
  }

  static peek(): LaunchIntent | null {
    return pendingLaunchIntent
  }

  static take(): LaunchIntent | null {
    const intent = pendingLaunchIntent
    pendingLaunchIntent = null
    return intent
  }

  static clear(): void {
    pendingLaunchIntent = null
  }
}
