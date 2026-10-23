-- Blasts enemies with wind and electrical explosions.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.STORM,
    name = "the Storm",
    effect_module = "policy.religion.cards.effects.storm",
    deck_weights = {
        [decks.DESTRUCTION] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
