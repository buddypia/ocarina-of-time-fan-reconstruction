import ApplicationServices
import Foundation

// Only manipulate windows owned by the smoke test's child PID. Do not request
// Accessibility permission or send keyboard/mouse input to other applications.
guard CommandLine.arguments.count == 2, let pid = Int32(CommandLine.arguments[1]) else { exit(2) }
guard AXIsProcessTrusted() else {
    fputs("Accessibility access is unavailable; window transitions are unverified.\n", stderr)
    exit(3)
}
let app = AXUIElementCreateApplication(pid)
var value: CFTypeRef?
guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
      let windows = value as? [AXUIElement], let window = windows.first else { exit(4) }
var owner: pid_t = 0
guard AXUIElementGetPid(window, &owner) == .success, owner == pid else { exit(5) }
var initialSize: CFTypeRef?
guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &initialSize) == .success,
      let savedSize = initialSize else { exit(6) }
var results: [[String: Any]] = []
var size = CGSize(width: 960, height: 720)
let resized = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString,
                                          AXValueCreate(.cgSize, &size)!)
results.append(["action": "resize", "status": resized.rawValue])
Thread.sleep(forTimeInterval: 2)
let minimized = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
results.append(["action": "minimize", "status": minimized.rawValue])
Thread.sleep(forTimeInterval: 2)
let restored = AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
results.append(["action": "restore", "status": restored.rawValue])
Thread.sleep(forTimeInterval: 2)
let reset = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, savedSize)
results.append(["action": "restore_size", "status": reset.rawValue])
print(String(data: try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted]), encoding: .utf8)!)
exit(results.allSatisfy { ($0["status"] as? Int32) == 0 } ? 0 : 7)
