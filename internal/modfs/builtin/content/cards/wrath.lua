-- Invokes another god's retribution as Nemelex punishment.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.WRATH,
    name = "Wrath",
    effect_module = "policy.religion.cards.effects.wrath",
    deck_weights = {
        [decks.PUNISHMENT] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
