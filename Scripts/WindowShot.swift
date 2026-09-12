import CoreGraphics
import Foundation

// Prints the CGWindowID of the first on-screen window owned by the given
// process name, so screencapture can target that exact window surface
// (-l<id>) instead of a screen region that another window might overlap.
guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: WindowShot <OwnerProcessName>\n".data(using: .utf8)!)
    exit(1)
}
let targetOwner = CommandLine.arguments[1]

guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: AnyObject]] else {
    exit(1)
}

for window in windowList {
    guard let owner = window[kCGWindowOwnerName as String] as? String, owner == targetOwner else { continue }
    guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
    if let number = window[kCGWindowNumber as String] as? Int {
        print(number)
        exit(0)
    }
}
exit(1)
