// PROTOTYPE — throwaway. Logs everything the share sheet hands over, then asks which app it came from.
import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let model = CaptureModel(context: extensionContext)
        let host = UIHostingController(rootView: CaptureView(model: model))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        Task { await model.capture() }
    }
}

@MainActor
final class CaptureModel: ObservableObject {
    @Published var log = ShareLog()
    @Published var done = false
    let context: NSExtensionContext?

    static let sources = ["YouTube", "Instagram", "TikTok", "Tasty", "Safari", "Chrome", "Photos", "Other"]

    init(context: NSExtensionContext?) { self.context = context }

    func capture() async {
        let items = context?.inputItems as? [NSExtensionItem] ?? []
        log.itemCount = items.count
        log.contentText = items.compactMap { $0.attributedContentText?.string }.joined(separator: "\n---\n").nilIfEmpty
        for (i, item) in items.enumerated() {
            for (j, provider) in (item.attachments ?? []).enumerated() {
                var entry = AttachmentLog(itemIndex: i, attachmentIndex: j,
                                          suggestedName: provider.suggestedName,
                                          registeredTypes: provider.registeredTypeIdentifiers)
                for type in provider.registeredTypeIdentifiers {
                    entry.loads.append(await Self.load(type, from: provider))
                }
                log.attachments.append(entry)
            }
        }
        done = true
    }

    func finish(source: String?) {
        if let source {
            log.source = source
            LogStore.save(log)
        }
        context?.completeRequest(returningItems: nil)
    }

    static func load(_ type: String, from provider: NSItemProvider) async -> TypeLoad {
        // Big media: never pull into memory (extension memory limit); just measure the file.
        if let ut = UTType(type), ut.conforms(to: .audiovisualContent) {
            return await withCheckedContinuation { cont in
                _ = provider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
                    let size = url.flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize }
                    cont.resume(returning: TypeLoad(type: type, valueClass: "file", summary: url?.lastPathComponent ?? "-",
                                                    byteCount: size, error: error?.localizedDescription))
                }
            }
        }
        do {
            let value = try await provider.loadItem(forTypeIdentifier: type)
            return describe(value, type: type)
        } catch {
            return TypeLoad(type: type, valueClass: "error", summary: "", error: error.localizedDescription)
        }
    }

    static func describe(_ value: Any, type: String) -> TypeLoad {
        let cls = String(describing: Swift.type(of: value))
        switch value {
        case let url as URL where url.isFileURL:
            let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            return TypeLoad(type: type, valueClass: "file URL", summary: url.lastPathComponent, byteCount: size)
        case let url as URL:
            return TypeLoad(type: type, valueClass: "URL", summary: url.absoluteString)
        case let s as String:
            return TypeLoad(type: type, valueClass: "String", summary: s.clip(4000), byteCount: s.utf8.count)
        case let s as NSAttributedString:
            return TypeLoad(type: type, valueClass: "NSAttributedString", summary: s.string.clip(4000), byteCount: s.string.utf8.count)
        case let img as UIImage:
            return TypeLoad(type: type, valueClass: "UIImage", summary: "\(Int(img.size.width))×\(Int(img.size.height)) @\(img.scale)x")
        case let dict as NSDictionary:
            return describeDictionary(dict, type: type)
        case let data as Data:
            if let s = String(data: data, encoding: .utf8) {
                return TypeLoad(type: type, valueClass: "Data (utf8)", summary: s.clip(4000), byteCount: data.count)
            }
            if let img = UIImage(data: data) {
                return TypeLoad(type: type, valueClass: "Data (image)", summary: "\(Int(img.size.width))×\(Int(img.size.height))", byteCount: data.count)
            }
            return TypeLoad(type: type, valueClass: "Data", summary: data.prefix(16).map { String(format: "%02x", $0) }.joined(), byteCount: data.count)
        default:
            return TypeLoad(type: type, valueClass: cls, summary: String(describing: value).clip(2000))
        }
    }

    /// Safari's JavaScript preprocessing results arrive as a property list dictionary.
    static func describeDictionary(_ dict: NSDictionary, type: String) -> TypeLoad {
        if let js = dict[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] {
            var js = js
            let html = js.removeValue(forKey: "html") as? String
            let lines = js.keys.sorted().map { "\($0): \(String(describing: js[$0]!).clip(600))" }
            return TypeLoad(type: type, valueClass: "JS preprocessing results",
                            summary: (lines + ["html (first 300): \(html?.clip(300) ?? "nil")"]).joined(separator: "\n"),
                            byteCount: html?.utf8.count)
        }
        return TypeLoad(type: type, valueClass: "NSDictionary", summary: dict.description.clip(2000))
    }
}

struct CaptureView: View {
    @ObservedObject var model: CaptureModel

    var body: some View {
        NavigationStack {
            List {
                Section("Which app did you share from?") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
                        ForEach(CaptureModel.sources, id: \.self) { s in
                            Button(s) { model.finish(source: s) }
                                .buttonStyle(.borderedProminent)
                                .disabled(!model.done)
                        }
                    }
                }
                LogDetail(log: model.log)
            }
            .navigationTitle(model.done ? "Captured" : "Capturing…")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Discard") { model.finish(source: nil) }
            }
        }
    }
}

extension String {
    func clip(_ n: Int) -> String { count > n ? String(prefix(n)) + "… [\(count) chars]" : self }
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
