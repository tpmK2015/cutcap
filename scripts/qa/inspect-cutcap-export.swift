import AVFoundation
import CoreGraphics
import Foundation

let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
let duration = try await asset.load(.duration).seconds
let tracks = try await asset.loadTracks(withMediaType: .video)
guard let track = tracks.first else { fatalError("Missing video track") }
let size = try await track.load(.naturalSize)
let rate = try await track.load(.nominalFrameRate)
print("duration=\(duration), dimensions=\(size.width)x\(size.height), fps=\(rate)")
guard abs(duration - 4) < 0.1, size.width == 360, size.height == 640 else {
    fatalError("Unexpected export format")
}
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
for (second, expected) in [(0.5, "blue"), (2.5, "red")] {
    let frame = try await generator.image(at: CMTime(seconds: second, preferredTimescale: 600)).image
    var pixel = [UInt8](repeating: 0, count: 4)
    pixel.withUnsafeMutableBytes { bytes in
        let context = CGContext(data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(frame, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    let red = Int(pixel[0])
    let blue = Int(pixel[2])
    let actual = blue > red + 40 ? "blue" : red > blue + 40 ? "red" : "other"
    print("frame@\(second)s=\(actual), rgba=\(pixel)")
    guard actual == expected else { fatalError("Unexpected frame order") }
}
print("Decoded export PASS")
