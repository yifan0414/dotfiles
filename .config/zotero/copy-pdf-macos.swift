// Native file clipboard bridge. No UI automation, network access or shell interpolation.
import AppKit
import Foundation

let paths = Array(CommandLine.arguments.dropFirst())
guard paths.count == 1 else { exit(2) }
let url = URL(fileURLWithPath: paths[0]).standardizedFileURL
var isDirectory: ObjCBool = false
guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      !isDirectory.boolValue, FileManager.default.isReadableFile(atPath: url.path) else { exit(3) }
let clipboard = NSPasteboard.general
clipboard.clearContents()
guard clipboard.writeObjects([url as NSURL]) else { exit(4) }
guard let copied = clipboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
      copied.count == 1, copied[0].standardizedFileURL.path == url.path else { exit(5) }
