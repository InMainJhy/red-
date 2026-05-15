export class QrCodeService {
  static async buildSvgDataUrl(text: string, width: number = 360): Promise<string> {
    const normalizedText = text.trim()
    if (normalizedText.length <= 0) {
      return ''
    }

    const size = Math.max(240, width)
    return `https://quickchart.io/qr?size=${size}&margin=1&text=${encodeURIComponent(normalizedText)}`
  }
}
