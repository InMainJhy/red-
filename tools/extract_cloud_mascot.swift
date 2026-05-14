import Foundation
import CoreGraphics
import CoreVideo
import ImageIO
import UniformTypeIdentifiers
import VideoToolbox
import Vision

enum CloudMascotExtractor {
  static func processImage(inputPath: String, outputPath: String) async throws {
    let inputUrl = URL(fileURLWithPath: inputPath)
    let outputUrl = URL(fileURLWithPath: outputPath)

    guard let source = CGImageSourceCreateWithURL(inputUrl as CFURL, nil),
          let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      throw NSError(domain: "CloudMascotExtractor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to load image at \(inputPath)"])
    }

    let request = GenerateForegroundInstanceMaskRequest()
    guard let observation = try await request.perform(on: sourceImage) else {
      throw NSError(domain: "CloudMascotExtractor", code: 2, userInfo: [NSLocalizedDescriptionKey: "No foreground mask was detected for \(inputPath)"])
    }

    let instances = observation.allInstances
    let maskBuffer = try observation.generateScaledMask(for: instances, scaledToImageFrom: ImageRequestHandler(sourceImage))
    let maskImage = try cgImage(from: maskBuffer)
    let rgbaImage = try applyMask(maskImage, to: sourceImage)
    let alphaCropRect = detectOpaqueBounds(in: rgbaImage)
    let expanded = alphaCropRect.insetBy(dx: -18, dy: -18).intersection(CGRect(x: 0, y: 0, width: rgbaImage.width, height: rgbaImage.height))

    guard let cropped = rgbaImage.cropping(to: expanded) else {
      throw NSError(domain: "CloudMascotExtractor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to crop extracted image for \(inputPath)"])
    }

    try writePNG(cgImage: cropped, to: outputUrl)
  }

  static func cgImage(from pixelBuffer: CVPixelBuffer) throws -> CGImage {
    var cgImage: CGImage?
    let status = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
    guard status == noErr, let image = cgImage else {
      throw NSError(domain: "CloudMascotExtractor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to convert pixel buffer mask to CGImage"])
    }
    return image
  }

  static func applyMask(_ mask: CGImage, to source: CGImage) throws -> CGImage {
    let width = source.width
    let height = source.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

    var sourceBuffer = [UInt8](repeating: 0, count: height * bytesPerRow)
    guard let sourceContext = CGContext(
      data: &sourceBuffer,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo.rawValue
    ) else {
      throw NSError(domain: "CloudMascotExtractor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to create source drawing context"])
    }
    sourceContext.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))

    let maskWidth = mask.width
    let maskHeight = mask.height
    let maskBytesPerRow = maskWidth * bytesPerPixel
    var maskBuffer = [UInt8](repeating: 0, count: maskHeight * maskBytesPerRow)
    guard let maskContext = CGContext(
      data: &maskBuffer,
      width: maskWidth,
      height: maskHeight,
      bitsPerComponent: 8,
      bytesPerRow: maskBytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo.rawValue
    ) else {
      throw NSError(domain: "CloudMascotExtractor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to create mask drawing context"])
    }
    maskContext.draw(mask, in: CGRect(x: 0, y: 0, width: maskWidth, height: maskHeight))

    for y in 0..<height {
      for x in 0..<width {
        let sourceOffset = y * bytesPerRow + x * bytesPerPixel
        let maskX = min(maskWidth - 1, x)
        let maskY = min(maskHeight - 1, y)
        let maskOffset = maskY * maskBytesPerRow + maskX * bytesPerPixel
        let maskValue = UInt16(maskBuffer[maskOffset])
        let originalAlpha = UInt16(sourceBuffer[sourceOffset + 3])
        sourceBuffer[sourceOffset + 3] = UInt8((originalAlpha * maskValue) / 255)
      }
    }

    guard let outputContext = CGContext(
      data: &sourceBuffer,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo.rawValue
    ), let cgImage = outputContext.makeImage() else {
      throw NSError(domain: "CloudMascotExtractor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to create RGBA image from masked pixels"])
    }

    return cgImage
  }

  static func detectOpaqueBounds(in image: CGImage) -> CGRect {
    let width = image.width
    let height = image.height
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    var buffer = [UInt8](repeating: 0, count: height * bytesPerRow)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let context = CGContext(
      data: &buffer,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo.rawValue
    ) else {
      return CGRect(x: 0, y: 0, width: width, height: height)
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0
    var found = false

    for y in 0..<height {
      for x in 0..<width {
        let offset = y * bytesPerRow + x * bytesPerPixel
        let alpha = buffer[offset + 3]
        if alpha > 10 {
          found = true
          minX = min(minX, x)
          minY = min(minY, y)
          maxX = max(maxX, x)
          maxY = max(maxY, y)
        }
      }
    }

    if !found {
      return CGRect(x: 0, y: 0, width: width, height: height)
    }

    return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
  }

  static func writePNG(cgImage: CGImage, to url: URL) throws {
    let directory = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
      throw NSError(domain: "CloudMascotExtractor", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unable to create png destination at \(url.path)"])
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    if !CGImageDestinationFinalize(destination) {
      throw NSError(domain: "CloudMascotExtractor", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to write png to \(url.path)"])
    }
  }
}

let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2, args.count.isMultiple(of: 2) else {
  fputs("Usage: extract_cloud_mascot <input output> [<input output> ...]\n", stderr)
  Foundation.exit(1)
}

let semaphore = DispatchSemaphore(value: 0)
var exitCode = 0

Task {
  do {
    let pairs = stride(from: 0, to: args.count, by: 2).map { index in
      (args[index], args[index + 1])
    }

    for (inputPath, outputPath) in pairs {
      try await CloudMascotExtractor.processImage(inputPath: inputPath, outputPath: outputPath)
      print("Processed \(inputPath) -> \(outputPath)")
    }
  } catch {
    exitCode = 1
    fputs("extract_cloud_mascot failed: \(error)\n", stderr)
  }

  semaphore.signal()
}

semaphore.wait()
Foundation.exit(Int32(exitCode))
