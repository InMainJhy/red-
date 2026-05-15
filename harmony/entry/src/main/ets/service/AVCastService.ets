import { common } from '@kit.AbilityKit'
import { avSession } from '@kit.AVSessionKit'

export class AVCastService {
  static async openVideoCastPicker(context: common.UIAbilityContext): Promise<void> {
    const picker = new avSession.AVCastPickerHelper(context)
    await picker.select({
      sessionType: 'video'
    })
  }
}
