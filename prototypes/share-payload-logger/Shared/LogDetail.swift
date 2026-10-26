// PROTOTYPE — throwaway. Renders one share log; used by the extension and the app.
import SwiftUI

struct LogDetail: View {
    let log: ShareLog

    var body: some View {
        Section("Overview") {
            Text("Source: \(log.source)")
            Text("Input items: \(log.itemCount), attachments: \(log.attachments.count)")
            Text("Content text: \(log.contentText ?? "nil")").textSelection(.enabled)
        }
        ForEach(Array(log.attachments.enumerated()), id: \.offset) { _, a in
            Section("Item \(a.itemIndex) · attachment \(a.attachmentIndex)") {
                Text("Types: \(a.registeredTypes.joined(separator: ", "))").font(.caption.monospaced())
                if let name = a.suggestedName { Text("Suggested name: \(name)").font(.caption) }
                ForEach(Array(a.loads.enumerated()), id: \.offset) { _, l in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(l.type) → \(l.valueClass)\(l.byteCount.map { " · \($0) bytes" } ?? "")")
                            .font(.caption.monospaced().bold())
                        if !l.summary.isEmpty { Text(l.summary).font(.caption.monospaced()).lineLimit(12) }
                        if let e = l.error { Text("error: \(e)").font(.caption).foregroundStyle(.red) }
                    }
                    .textSelection(.enabled)
                }
            }
        }
    }
}
