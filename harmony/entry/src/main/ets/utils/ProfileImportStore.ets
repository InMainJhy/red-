import { ProfileBundle } from '../common/Models'

export class ProfileImportStore {
  private static pendingBundle: ProfileBundle | null = null

  static setPendingBundle(bundle: ProfileBundle): void {
    ProfileImportStore.pendingBundle = bundle
  }

  static takePendingBundle(): ProfileBundle | null {
    const bundle = ProfileImportStore.pendingBundle
    ProfileImportStore.pendingBundle = null
    return bundle
  }
}
