import AppKit
import Foundation

let path = CommandLine.arguments[1]
let data = try Data(contentsOf: URL(fileURLWithPath: path))
guard let bitmap = NSBitmapImageRep(data: data) else { fatalError("Invalid screenshot") }
var blue = 0
var red = 0
for y in Int(Double(bitmap.pixelsHigh) * 0.64)..<Int(Double(bitmap.pixelsHigh) * 0.85) {
    for x in Int(Double(bitmap.pixelsWide) * 0.02)..<Int(Double(bitmap.pixelsWide) * 0.98) {
        guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
        let r = color.redComponent
        let g = color.greenComponent
        let b = color.blueComponent
        if b > r + 0.2 && b > g + 0.12 { blue += 1 }
        if r > b + 0.2 && r > g + 0.2 { red += 1 }
    }
}
print("Timeline pixels: blue=\(blue), red=\(red)")
if blue < 500 || red < 500 { exit(1) }
