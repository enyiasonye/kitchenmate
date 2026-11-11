// PROTOTYPE — throwaway. In-memory mock data for issue #18. No persistence.
import SwiftUI

enum RecipeState: String { case imported = "Imported", saved = "Saved", bookmark = "Bookmark" }
enum Pending: String { case importing = "Importing…", needsDeviceFetch = "Open in app to finish" }

struct Ingredient: Identifiable, Hashable {
    let id = UUID()
    var original: String
}

struct Recipe: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var source: String
    var state: RecipeState
    var pending: Pending? = nil
    var aiWritten = false
    var favorite = false
    var minutes: Int? = 30
    var servings = 4
    var tags: [String] = []
    var color: Color = .orange
    var video: String? = nil
    var ingredients: [Ingredient] = []
    var steps: [String] = []
    var rawCapture: String = ""
}

private func ing(_ s: [String]) -> [Ingredient] { s.map { Ingredient(original: $0) } }

@Observable final class Store {
    var recipes: [Recipe] = [
        Recipe(title: "Sheet-Pan Chicken Fajitas", source: "seriouseats.com", state: .saved, favorite: true, minutes: 40, tags: ["Dinner", "Mexican"], color: .orange,
               ingredients: ing(["1½ lb chicken thighs, sliced", "3 bell peppers, sliced", "1 onion, sliced", "2 tbsp olive oil", "1 tbsp chili powder", "8 flour tortillas"]),
               steps: ["Heat oven to 425°F.", "Toss chicken, peppers and onion with oil and spices.", "Roast 20–25 minutes, stirring once.", "Serve in warm tortillas."]),
        Recipe(title: "Miso Butter Salmon", source: "nytcooking.com", state: .saved, minutes: 20, tags: ["Dinner", "Fish"], color: .pink,
               ingredients: ing(["4 salmon fillets", "2 tbsp white miso", "2 tbsp butter, softened", "1 tsp honey"]),
               steps: ["Heat broiler.", "Mash miso, butter and honey.", "Spread over salmon and broil 8 minutes."]),
        Recipe(title: "Birria Tacos", source: "TikTok · @cookingwithlynja", state: .saved, minutes: 180, tags: ["Mexican"], color: .red, video: "TikTok",
               ingredients: ing(["3 lb chuck roast", "4 guajillo chiles", "2 ancho chiles", "1 onion", "Corn tortillas", "Oaxaca cheese"]),
               steps: ["Toast and soak chiles.", "Blend with onion and spices.", "Braise beef 3 hours.", "Dip tortillas in consommé, fill and fry."]),
        Recipe(title: "Lemon Ricotta Pancakes", source: "Cookbook photo", state: .saved, favorite: true, minutes: 25, tags: ["Breakfast"], color: .yellow,
               ingredients: ing(["1 cup ricotta", "2 eggs", "1 cup flour", "1 lemon, zested"]), steps: ["Whisk wet.", "Fold in dry.", "Cook on griddle."]),
        Recipe(title: "Weeknight Dal", source: "youtube.com · Chetna Makan", state: .saved, minutes: 35, tags: ["Vegetarian"], color: .yellow, video: "YouTube",
               ingredients: ing(["1 cup red lentils", "1 tsp turmeric", "1 can coconut milk"]), steps: ["Rinse lentils.", "Simmer with turmeric.", "Add coconut milk."]),
        Recipe(title: "Crispy Gnocchi with Greens", source: "bonappetit.com", state: .imported, minutes: 25, tags: ["Dinner"], color: .green,
               ingredients: ing(["1 lb shelf-stable gnocchi", "1 bunch kale", "1/4 cup parmesan"]), steps: ["Crisp gnocchi.", "Wilt greens.", "Toss with cheese."],
               rawCapture: "JSON-LD Recipe from bonappetit.com"),
        Recipe(title: "Hot Honey Pizza", source: "Instagram · @pizzalab", state: .bookmark, minutes: nil, tags: [], color: .purple, video: "Instagram",
               rawCapture: "https://www.instagram.com/reel/Cx…  (URL only — no caption shared)"),
        Recipe(title: "tasty.co/recipe/one-pot-pasta", source: "tasty.co", state: .imported, pending: .needsDeviceFetch, minutes: nil, color: .gray),
        Recipe(title: "smittenkitchen.com/…", source: "smittenkitchen.com", state: .imported, pending: .importing, minutes: nil, color: .gray),
    ]

    var library: [Recipe] { recipes.filter { $0.state == .saved } }
    var toReview: [Recipe] { recipes.filter { $0.state != .saved } }

    func binding(_ r: Recipe) -> Binding<Recipe> {
        Binding(get: { self.recipes.first { $0.id == r.id } ?? r },
                set: { new in if let i = self.recipes.firstIndex(where: { $0.id == r.id }) { self.recipes[i] = new } })
    }

    func fakeImport(_ input: String, kind: String) {
        var r = Recipe(title: input.isEmpty ? "New import" : input, source: kind, state: .imported, pending: .importing, minutes: nil, color: .gray)
        recipes.insert(r, at: 0)
        let id = r.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard let i = self.recipes.firstIndex(where: { $0.id == id }) else { return }
            if kind == "Instagram" {
                r = self.recipes[i]; r.pending = nil; r.state = .bookmark; r.title = "Instagram reel"; r.color = .purple
                r.rawCapture = "URL only"; self.recipes[i] = r
            } else {
                r = self.recipes[i]; r.pending = nil; r.title = "Imported: \(kind) recipe"; r.color = .teal
                r.ingredients = ing(["2 cups something", "1 tbsp something else"]); r.steps = ["Do the thing.", "Eat."]
                self.recipes[i] = r
            }
        }
    }
}
