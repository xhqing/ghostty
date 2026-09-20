import AppKit
import GhosttyKit
import UniformTypeIdentifiers

extension NSPasteboard.PasteboardType {
    /// Initialize a pasteboard type from a MIME type string
    init?(mimeType: String) {
        // Explicit mappings for common MIME types
        switch mimeType {
        case "text/plain":
            self = .string
            return
        default:
            break
        }

        // Try to get UTType from MIME type
        guard let utType = UTType(mimeType: mimeType) else {
            // Fallback: use the MIME type directly as identifier
            self.init(mimeType)
            return
        }

        // Use the UTType's identifier
        self.init(utType.identifier)
    }
}

extension NSPasteboard {
    /// The pasteboard to used for Ghostty selection.
    static var ghosttySelection: NSPasteboard = {
        NSPasteboard(name: .init("com.mitchellh.ghostty.selection"))
    }()

    /// Gets the contents of the pasteboard as a string following a specific set of semantics.
    /// Does these things in order:
    /// - Tries to get the absolute filesystem path of the file in the pasteboard if there is one and ensures the file path is properly escaped.
    /// - Tries to get any string from the pasteboard.
    /// - Tries to get image data from the pasteboard (e.g. screenshots captured to
    ///   clipboard), writes it to a temp file, and returns the escaped path.
    /// If all of the above fail, returns None.
    func getOpinionatedStringContents() -> String? {
        if let urls = readObjects(forClasses: [NSURL.self]) as? [URL],
           urls.count > 0 {
            return urls
                .map { $0.isFileURL ? Ghostty.Shell.escape($0.path) : $0.absoluteString }
                .joined(separator: " ")
        }

        if let str = self.string(forType: .string), !str.isEmpty {
            return str
        }

        // Fallback: image-only clipboard (e.g. macOS screenshot to clipboard via
        // Cmd+Shift+Ctrl+4). Write it to a temp file and return the escaped path
        // so terminal applications can consume it. This runs last so existing
        // behavior is unchanged: any clipboard that currently pastes text
        // (URLs, strings) keeps doing so.
        if let imageData = self.data(forType: .png) ?? self.data(forType: .tiff) {
            let fileName = "ghostty-paste-\(UUID().uuidString).png"
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            do {
                // If we got TIFF data, convert to PNG for broader compatibility
                if self.data(forType: .png) == nil,
                   let tiffImage = NSImage(data: imageData),
                   let tiffData = tiffImage.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    try pngData.write(to: tempURL)
                } else {
                    try imageData.write(to: tempURL)
                }
                return Ghostty.Shell.escape(tempURL.path)
            } catch {
                // Fall through: paste nothing on failure, matching prior behavior
            }
        }

        return nil
    }

    /// The pasteboard for the Ghostty enum type.
    static func ghostty(_ clipboard: ghostty_clipboard_e) -> NSPasteboard? {
        switch clipboard {
        case GHOSTTY_CLIPBOARD_STANDARD:
            return Self.general

        case GHOSTTY_CLIPBOARD_SELECTION:
            return Self.ghosttySelection

        default:
            return nil
        }
    }
}
