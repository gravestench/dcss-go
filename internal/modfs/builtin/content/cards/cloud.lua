-- Surrounds threatening foes with clouds to create room to retreat.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.CLOUD,
    name = "the Cloud",
    effect_module = "policy.religion.cards.effects.cloud",
    deck_weights = {
        [decks.ESCAPE] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
