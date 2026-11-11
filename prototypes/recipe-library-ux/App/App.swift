// PROTOTYPE — throwaway. Issue #18 "Recipe library and import UX".
// Three structurally different Recipes-tab variants, switched by the floating pill at the bottom
// (persisted with @AppStorage so it survives relaunch). Run in the iPhone Duo simulator, fold/unfold.
//   A  Split list   — compact list rows; "To review" section on top; NavigationSplitView (two panes unfolded)
//   B  Photo grid   — editorial photo cards; review items in a banner strip; full-width detail pushed
//   C  Inbox tabs   — segmented Library | To review | Bookmarks; wide single column unfolded
import SwiftUI

@main struct RecipeUXProtoApp: App {
    @State private var store = Store()
    var body: some Scene { WindowGroup { Root().environment(store) } }
}

struct Root: View {
    @AppStorage("variant") private var variant = "A"
    var body: some View {
        TabView {
            Tab("Recipes", systemImage: "book") {
                Group {
                    switch variant {
                    case "B": VariantB()
                    case "C": VariantC()
                    default: VariantA()
                    }
                }.id(variant)
            }
            Tab("Plan", systemImage: "calendar") { Text("Plan — not part of #18").foregroundStyle(.secondary) }
            Tab("Groceries", systemImage: "cart") { Text("Groceries — not part of #18").foregroundStyle(.secondary) }
            Tab("Fold probe", systemImage: "rectangle.portrait.on.rectangle.portrait") { FoldProbe() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .overlay(alignment: .bottom) { VariantSwitcher(variant: $variant).padding(.bottom, 90) }
    }
}

struct VariantSwitcher: View {
    @Binding var variant: String
    let keys = ["A", "B", "C"]
    let names = ["A": "Split list", "B": "Photo grid", "C": "Inbox tabs"]
    var body: some View {
        HStack(spacing: 14) {
            Button { cycle(-1) } label: { Image(systemName: "chevron.left") }
            Text("\(variant) (\(names[variant] ?? ""))").font(.caption.monospaced())
            Button { cycle(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.black, in: Capsule()).foregroundStyle(.yellow).shadow(radius: 6)
    }
    func cycle(_ d: Int) { let i = keys.firstIndex(of: variant) ?? 0; variant = keys[(i + d + keys.count) % keys.count] }
}

// MARK: - A: Split list

struct VariantA: View {
    @Environment(Store.self) private var store
    @State private var selection: Recipe.ID?
    @State private var reviewing: Recipe?
    @State private var search = ""
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if !store.toReview.isEmpty {
                    Section("To review") {
                        ForEach(store.toReview) { r in
                            Button { if r.pending == nil { reviewing = r } } label: { RowA(r: r) }.buttonStyle(.plain)
                        }
                    }
                }
                Section("Recipes") {
                    ForEach(store.library.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }) { r in
                        RowA(r: r).tag(r.id)
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Recipes")
            .toolbar { ImportMenu() }
        } detail: {
            if let id = selection, let r = store.recipes.first(where: { $0.id == id }) {
                RecipeDetail(recipe: store.binding(r))
            } else {
                ContentUnavailableView("Choose a recipe", systemImage: "book")
            }
        }
        .reviewSheet($reviewing)
    }
}

struct RowA: View {
    var r: Recipe
    var body: some View {
        HStack(spacing: 12) {
            Photo(color: r.color).frame(width: 56, height: 56).clipShape(.rect(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                HStack { Text(r.title).font(.body.weight(.medium)).lineLimit(1); if r.favorite { Image(systemName: "heart.fill").font(.caption).foregroundStyle(.pink) } }
                Text([r.source, r.minutes.map { "\($0) min" }].compactMap { $0 }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                StateBadge(r: r)
            }
        }
        .opacity(r.pending == nil ? 1 : 0.6)
    }
}

// MARK: - B: Photo grid

struct VariantB: View {
    @Environment(Store.self) private var store
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var reviewing: Recipe?
    @State private var path: [Recipe.ID] = []
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                if !store.toReview.isEmpty {
                    VStack(alignment: .leading) {
                        Text("To review").font(.headline).padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(store.toReview) { r in
                                    Button { if r.pending == nil { reviewing = r } } label: {
                                        VStack(alignment: .leading) {
                                            Photo(color: r.color).frame(width: 150, height: 90).clipShape(.rect(cornerRadius: 10))
                                            Text(r.title).font(.caption.bold()).lineLimit(1)
                                            StateBadge(r: r)
                                        }.frame(width: 150)
                                    }.buttonStyle(.plain)
                                }
                            }.padding(.horizontal)
                        }
                    }.padding(.vertical, 8).background(.quaternary.opacity(0.5))
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: hSize == .regular ? 3 : 2), spacing: 18) {
                    ForEach(store.library) { r in
                        NavigationLink(value: r.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Photo(color: r.color).aspectRatio(0.85, contentMode: .fit).clipShape(.rect(cornerRadius: 12))
                                    .overlay(alignment: .topTrailing) { if r.favorite { Image(systemName: "heart.fill").foregroundStyle(.white).padding(8) } }
                                Text(r.title).font(.system(.headline, design: .serif)).lineLimit(2).multilineTextAlignment(.leading)
                                if let m = r.minutes { Text("\(m) min").font(.caption).foregroundStyle(.secondary) }
                            }
                        }.buttonStyle(.plain)
                    }
                }.padding()
            }
            .navigationTitle("Recipes")
            .toolbar { ImportMenu() }
            .navigationDestination(for: Recipe.ID.self) { id in
                if let r = store.recipes.first(where: { $0.id == id }) { RecipeDetail(recipe: store.binding(r)) }
            }
        }
        .reviewSheet($reviewing)
    }
}

// MARK: - C: Inbox tabs

struct VariantC: View {
    @Environment(Store.self) private var store
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var scope = 0
    @State private var reviewing: Recipe?
    var rows: [Recipe] {
        switch scope {
        case 1: store.recipes.filter { $0.state == .imported }
        case 2: store.recipes.filter { $0.state == .bookmark }
        default: store.library
        }
    }
    var body: some View {
        NavigationStack {
            List {
                Picker("", selection: $scope) {
                    Text("Library").tag(0)
                    Text("To review (\(store.recipes.filter { $0.state == .imported }.count))").tag(1)
                    Text("Bookmarks (\(store.recipes.filter { $0.state == .bookmark }.count))").tag(2)
                }.pickerStyle(.segmented).listRowSeparator(.hidden)
                ForEach(rows) { r in
                    if r.state == .saved {
                        NavigationLink(value: r.id) { RowC(r: r) }
                    } else {
                        Button { if r.pending == nil { reviewing = r } } label: { RowC(r: r) }.buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Recipes")
            .toolbar { ImportMenu() }
            .navigationDestination(for: Recipe.ID.self) { id in
                if let r = store.recipes.first(where: { $0.id == id }) {
                    RecipeDetail(recipe: store.binding(r)).frame(maxWidth: 640) // wide single column, centred
                }
            }
        }
        .reviewSheet($reviewing)
    }
}

struct RowC: View {
    var r: Recipe
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(r.title).font(.system(.title3, design: .serif, weight: .semibold))
            HStack { Text(r.source); if let m = r.minutes { Text("· \(m) min") }; ForEach(r.tags, id: \.self) { Text("· \($0)") } }
                .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            StateBadge(r: r)
        }.padding(.vertical, 4)
    }
}

// MARK: - Fold probe: what survives fold/unfold?

struct FoldProbe: View {
    @State private var stateCounter = 0
    @SceneStorage("probe.counter") private var sceneCounter = 0
    @Environment(\.horizontalSizeClass) private var h
    @Environment(\.verticalSizeClass) private var v
    @State private var path: [Int] = []
    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { g in
                List {
                    Section("Now") {
                        LabeledContent("Size", value: "\(Int(g.size.width))×\(Int(g.size.height)) pt")
                        LabeledContent("Size classes", value: "h: \(h == .regular ? "regular" : "compact")  v: \(v == .regular ? "regular" : "compact")")
                    }
                    Section("Bump, then fold/unfold") {
                        Stepper("@State: \(stateCounter)", value: $stateCounter)
                        Stepper("@SceneStorage: \(sceneCounter)", value: $sceneCounter)
                        NavigationLink("Push level \(path.count + 1)", value: path.count + 1)
                    }
                    Section("Scroll down, fold, see if position holds") {
                        ForEach(0..<60) { Text("Row \($0)") }
                    }
                }
            }
            .navigationTitle("Fold probe")
            .navigationDestination(for: Int.self) { n in
                List { Text("Pushed level \(n)"); NavigationLink("Push level \(n + 1)", value: n + 1) }.navigationTitle("Level \(n)")
            }
        }
    }
}
