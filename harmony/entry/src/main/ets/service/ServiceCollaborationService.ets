import { common } from '@kit.AbilityKit'
import distributedDeviceManager from '@ohos.distributedDeviceManager'
import abilityConnectionManager from '@ohos.distributedsched.abilityConnectionManager'

const APP_BUNDLE_NAME: string = 'com.example.myapplication'
const APP_MODULE_NAME: string = 'entry'
const APP_ABILITY_NAME: string = 'EntryAbility'
const APP_SERVICE_NAME: string = 'timepersona_collaboration'

type DeviceShareTarget = 'tablet' | 'screen'

export interface CollaborationLaunchPayload {
  launchAction: string
  summaryId?: string
  arenaRunId?: string
}

interface CollaborationConnectParameters extends Record<string, string> {
  launchAction: string
  summaryId: string
  arenaRunId: string
}

interface CollaborationPeerInfo {
  deviceId: string
  bundleName: string
  moduleName: string
  abilityName: string
}

interface CollaborationConnectOptions {
  needSendData: boolean
  startOptions: abilityConnectionManager.StartOptionParams
  parameters: CollaborationConnectParameters
}

function expectedDeviceTypes(target: DeviceShareTarget): string[] {
  if (target === 'tablet') {
    return ['tablet']
  }
  return ['tv', 'smartVision']
}

function normalizePayloadValue(value?: string): string {
  return value && value.trim().length > 0 ? value.trim() : ''
}

function buildConnectParameters(payload: CollaborationLaunchPayload): CollaborationConnectParameters {
  const summaryId = normalizePayloadValue(payload.summaryId)
  const arenaRunId = normalizePayloadValue(payload.arenaRunId)
  return {
    launchAction: payload.launchAction,
    summaryId,
    arenaRunId
  }
}

export class ServiceCollaborationService {
  static async startSummaryCollaboration(
    context: common.UIAbilityContext,
    target: DeviceShareTarget,
    payload: CollaborationLaunchPayload
  ): Promise<string> {
    const deviceManager = distributedDeviceManager.createDeviceManager(APP_BUNDLE_NAME)
    const devices = await deviceManager.getAvailableDeviceList()
    const preferredTypes = expectedDeviceTypes(target)
    const matchedDevice = devices.find((device) => preferredTypes.indexOf(device.deviceType) >= 0)

    if (!matchedDevice) {
      throw new Error(target === 'tablet' ? '没有发现可协同的平板设备' : '没有发现可协同的智慧屏设备')
    }

    const peerInfo: CollaborationPeerInfo = {
      deviceId: matchedDevice.deviceId,
      bundleName: APP_BUNDLE_NAME,
      moduleName: APP_MODULE_NAME,
      abilityName: APP_ABILITY_NAME
    }
    const connectOptions: CollaborationConnectOptions = {
      needSendData: false,
      startOptions: abilityConnectionManager.StartOptionParams.START_IN_FOREGROUND,
      parameters: buildConnectParameters(payload)
    }

    const sessionId = abilityConnectionManager.createAbilityConnectionSession(
      APP_SERVICE_NAME,
      context,
      peerInfo,
      connectOptions
    )

    const result = await abilityConnectionManager.connect(sessionId)
    if (!result.isConnected) {
      abilityConnectionManager.destroyAbilityConnectionSession(sessionId)
      throw new Error(result.reason && result.reason.length > 0 ? result.reason : '跨设备协同连接失败')
    }

    return matchedDevice.deviceName
  }
}
