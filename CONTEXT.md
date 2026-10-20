# KitchenMate

A personal recipe manager for a single owner that plans the week's cooking and turns it into an HEB grocery order.

## Language

### Planning

**Weekly Picks**:
The set of recipes KitchenMate proposes for the coming week; a draft the owner can swap or reject before accepting.
_Avoid_: Suggestions, recommendations

**Weekly Plan**:
The recipes the owner has accepted for a given week. Accepting a plan does not by itself put anything on the grocery list.
_Avoid_: Meal plan, menu

**Favorite**:
A recipe the owner has marked as preferred; twice as likely to be drawn into Weekly Picks.
_Avoid_: Starred, liked

**Snooze**:
A temporary or open-ended hold that keeps a recipe out of automatic Weekly Picks while leaving it in the library and available to add by hand. Independent of Favorite.
_Avoid_: Hide, block, dismiss

**Swap**:
Replacing one of the Weekly Picks with a fresh random draw. A swapped-out recipe is excluded only for that round.
_Avoid_: Reject, skip

### Groceries

**Item**:
A store-agnostic thing the owner buys, which recipe ingredients and reminders resolve to. Has many Aliases and at most one Product per Store. Drawn as coarsely as possible: things the owner always buys the same Product for are one Item ("Milk"); things bought as different Products are separate Items ("Eggo Waffles", "Kodiak Waffles").
_Avoid_: Food, ingredient, grocery

**Alias**:
A phrase that names an Item (e.g. "waffles", "thick and fluffy", "eggo waffles"). Each Alias names exactly one Item.
_Avoid_: Synonym, keyword

**Product**:
A specific listing in a Store's catalog, chosen as what to buy for an Item at that Store.
_Avoid_: SKU, listing

**Store**:
A grocery retailer whose account KitchenMate places Products into. HEB is the only Store in V1.
_Avoid_: Retailer, vendor
