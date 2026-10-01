import Foundation
import CoreGraphics

// Read only window metadata belonging to the caller's own test process.
guard CommandLine.arguments.count == 2, let pid = Int(CommandLine.arguments[1]) else {
    exit(2)
}
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
let own = windows.filter {
    ($0[kCGWindowOwnerPID as String] as? Int) == pid &&
    ($0[kCGWindowLayer as String] as? Int) == 0
}
let data = try JSONSerialization.data(withJSONObject: own, options: [.prettyPrinted, .sortedKeys])
print(String(data: data, encoding: .utf8)!)
