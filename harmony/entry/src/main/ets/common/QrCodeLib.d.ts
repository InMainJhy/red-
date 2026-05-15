declare module 'qrcode' {
  export interface QRCodeToStringOptions {
    type?: string
    margin?: number
    width?: number
  }

  export function toString(text: string, options?: QRCodeToStringOptions): Promise<string>
}
