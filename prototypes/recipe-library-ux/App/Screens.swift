// PROTOTYPE — throwaway. Shared screens for issue #18: detail, cook mode, review, Bookmark retry, import entry.
import SwiftUI

// MARK: - Photo placeholder

struct Photo: View {
    var color: Color
    var height: CGFloat? = nil
    var body: some View {
        Rectangle().fill(color.gradient.opacity(0.75))
            .overlay(Image(systemName: "fork.knife").font(.largeTitle).foregroundStyle(.white.opacity(0.6)))
            .frame(height: height)
    }
}

struct StateBadge: View {
    var r: Recipe
    var body: some View {
        if let p = r.pending {
            Label(p.rawValue, systemImage: p == .importing ? "arrow.down.circle" : "iphone.and.arrow.forward")
                .font(.caption).foregroundStyle(.secondary)
        } else if r.state == .bookmark {
            Label("Bookmark — no recipe found", systemImage: "bookmark").font(.caption).foregroundStyle(.purple)
        } else if r.state == .imported {
            Label("Ready to review", systemImage: "checklist").font(.caption).foregroundStyle(.blue)
        }
    }
}

// MARK: - Recipe detail

/// Folded (compact width): one column, Ingredients/Steps via segmented picker.
/// Unfolded (regular width): ingredients and steps side by side under the photo.
struct RecipeDetail: View {
    @Binding var recipe: Recipe
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var section = 0
    @State private var cooking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Photo(color: recipe.color, height: hSize == .regular ? 320 : 240)
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title).font(.system(.largeTitle, design: .serif, weight: .semibold))
                    HStack(spacing: 12) {
                        Text(recipe.source)
                        if let m = recipe.minutes { Label("\(m) min", systemImage: "clock") }
                        Label("Serves \(recipe.servings)", systemImage: "person.2")
                    }.font(.subheadline).foregroundStyle(.secondary)
                    if recipe.aiWritten { Label("AI-written", systemImage: "sparkles").font(.caption).foregroundStyle(.orange) }
                    if let v = recipe.video {
                        Button { } label: { Label("Watch on \(v)", systemImage: "play.rectangle") }.buttonStyle(.bordered)
                    }
                }.padding(.horizontal)

                if hSize == .regular {
                    HStack(alignment: .top, spacing: 24) {
                        IngredientsList(items: recipe.ingredients).frame(maxWidth: .infinity, alignment: .leading)
                        StepsList(steps: recipe.steps).frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(.horizontal)
                } else {
                    Picker("", selection: $section) { Text("Ingredients").tag(0); Text("Steps").tag(1) }
                        .pickerStyle(.segmented).padding(.horizontal)
                    Group { if section == 0 { IngredientsList(items: recipe.ingredients) } else { StepsList(steps: recipe.steps) } }
                        .padding(.horizontal)
                }
            }.padding(.bottom, 80)
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            Button { recipe.favorite.toggle() } label: { Image(systemName: recipe.favorite ? "heart.fill" : "heart") }
            Menu {
                Button("Edit", systemImage: "pencil") {}
                Button("Re-extract from source", systemImage: "arrow.clockwise") {}
                Button("Snooze", systemImage: "moon.zzz") {}
                Button("Add to groceries", systemImage: "cart") {}
            } label: { Image(systemName: "ellipsis.circle") }
        }
        .safeAreaInset(edge: .bottom) {
            Button { cooking = true } label: { Label("Start cooking", systemImage: "flame").frame(maxWidth: .infinity).padding(.vertical, 6) }
                .buttonStyle(.borderedProminent).controlSize(.large).padding()
        }
        .fullScreenCover(isPresented: $cooking) { CookMode(recipe: recipe) }
    }
}

struct IngredientsList: View {
    var items: [Ingredient]
    @State private var checked: Set<UUID> = []
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ingredients").font(.title3.bold()).padding(.bottom, 8)
            ForEach(items) { i in
                Button { checked.formSymmetricDifference([i.id]) } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: checked.contains(i.id) ? "checkmark.circle.fill" : "circle")
                        Text(i.original).strikethrough(checked.contains(i.id)).multilineTextAlignment(.leading)
                        Spacer()
                    }.font(.title3).padding(.vertical, 10).contentShape(Rectangle())
                }.buttonStyle(.plain)
                Divider()
            }
        }
    }
}

struct StepsList: View {
    var steps: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steps").font(.title3.bold())
            ForEach(Array(steps.enumerated()), id: \.offset) { n, s in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(n + 1)").font(.title3.bold()).foregroundStyle(.tint)
                    Text(s).font(.title3)
                }
            }
        }
    }
}

// MARK: - Cook mode (screen stays awake; one step at a time; ingredients alongside when unfolded)

struct CookMode: View {
    var recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var step = 0

    var body: some View {
        NavigationStack {
            HStack(alignment: .top, spacing: 0) {
                if hSize == .regular {
                    ScrollView { IngredientsList(items: recipe.ingredients).padding() }
                        .frame(width: 260).background(.thinMaterial)
                }
                TabView(selection: $step) {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { n, s in
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Step \(n + 1) of \(recipe.steps.count)").font(.headline).foregroundStyle(.secondary)
                            Text(s).font(.system(size: 34, weight: .medium))
                            Spacer()
                        }.padding(32).tag(n)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .always))
            }
            .navigationTitle(recipe.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }
}

// MARK: - Review an Imported recipe (the form on every import path)

struct ReviewForm: View {
    @Binding var recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section { Photo(color: recipe.color, height: 140).listRowInsets(EdgeInsets()) }
                Section("Recipe") {
                    TextField("Title", text: $recipe.title)
                    LabeledContent("Source", value: recipe.source)
                    Stepper("Serves \(recipe.servings)", value: $recipe.servings, in: 1...20)
                    if recipe.aiWritten { Label("AI-written", systemImage: "sparkles").foregroundStyle(.orange) }
                }
                Section("Ingredients") {
                    ForEach($recipe.ingredients) { $i in TextField("Ingredient", text: $i.original) }
                        .onDelete { recipe.ingredients.remove(atOffsets: $0) }
                    Button("Add ingredient", systemImage: "plus") { recipe.ingredients.append(Ingredient(original: "")) }
                }
                Section("Steps") {
                    ForEach(recipe.steps.indices, id: \.self) { n in TextField("Step", text: $recipe.steps[n], axis: .vertical) }
                        .onDelete { recipe.steps.remove(atOffsets: $0) }
                }
                Section { Text("Captured: \(recipe.rawCapture)").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Review").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Later") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { recipe.state = .saved; dismiss() }.bold() }
                ToolbarItem(placement: .bottomBar) { Button("Delete import", role: .destructive) { dismiss() } }
            }
        }
    }
}

// MARK: - Bookmark retry (a main path, not an edge case)

struct BookmarkRetry: View {
    @Binding var recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var caption = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack { Photo(color: recipe.color).frame(width: 64, height: 64).clipShape(.rect(cornerRadius: 8))
                        VStack(alignment: .leading) { Text(recipe.title).bold(); Text(recipe.source).font(.caption).foregroundStyle(.secondary) } }
                    Text("No recipe found in what was shared. Add more and try again.").font(.callout).foregroundStyle(.secondary)
                }
                Section("Add more") {
                    TextField("Paste the caption or recipe text", text: $caption, axis: .vertical).lineLimit(4...8)
                    Button("Add screenshots", systemImage: "photo.on.rectangle") {}
                    Button("Take a photo", systemImage: "camera") {}
                }
                Section {
                    Button("Try again", systemImage: "arrow.clockwise") { recipe.state = .imported; recipe.rawCapture += "\n+ \(caption)"; dismiss() }
                        .disabled(caption.isEmpty)
                }
                Section(footer: Text("AI writes a recipe from the title and what was captured. It stays marked AI-written.")) {
                    Button("Write with AI", systemImage: "sparkles") {
                        recipe.state = .imported; recipe.aiWritten = true
                        recipe.ingredients = [Ingredient(original: "1 pizza dough"), Ingredient(original: "Hot honey")]
                        recipe.steps = ["Stretch dough.", "Top and bake at 500°F.", "Drizzle hot honey."]
                        dismiss()
                    }
                }
                Section { Button("Open original", systemImage: "safari") {} }
            }
            .navigationTitle("Bookmark").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Close") { dismiss() } }
        }
    }
}

// MARK: - In-app import entry: paste URL, paste text, camera, photo library

struct ImportMenu: View {
    @Environment(Store.self) private var store
    @State private var askingURL = false
    @State private var text = ""
    var body: some View {
        Menu {
            Button("Paste link", systemImage: "link") { askingURL = true }
            Button("Paste text", systemImage: "doc.on.clipboard") { store.fakeImport("Pasted text", kind: "Pasted text") }
            Button("Take photo", systemImage: "camera") { store.fakeImport("Cookbook photo", kind: "Photo") }
            Button("Choose photos", systemImage: "photo.on.rectangle") { store.fakeImport("Photo library", kind: "Photo") }
            Divider()
            Button("Simulate Instagram share", systemImage: "camera.metering.unknown") { store.fakeImport("instagram.com/reel/…", kind: "Instagram") }
        } label: { Image(systemName: "plus") }
        .alert("Paste a link", isPresented: $askingURL) {
            TextField("https://", text: $text)
            Button("Import") { store.fakeImport(text, kind: "Website"); text = "" }
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// Opens the right sheet for a non-Saved recipe.
struct ReviewSheetModifier: ViewModifier {
    @Environment(Store.self) private var store
    @Binding var target: Recipe?
    func body(content: Content) -> some View {
        content.sheet(item: $target) { r in
            if r.state == .bookmark { BookmarkRetry(recipe: store.binding(r)) } else { ReviewForm(recipe: store.binding(r)) }
        }
    }
}
extension View { func reviewSheet(_ t: Binding<Recipe?>) -> some View { modifier(ReviewSheetModifier(target: t)) } }
