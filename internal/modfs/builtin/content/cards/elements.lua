-- Calls friendly creatures from rotating elemental groups.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.ELEMENTS,
    name = "the Elements",
    effect_module = "policy.religion.cards.effects.elements",
    deck_weights = {
        [decks.SUMMONING] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
