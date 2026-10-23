-- Uses necromantic damage and gains torment at high card power.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.PAIN,
    name = "Pain",
    effect_module = "policy.religion.cards.effects.pain",
    deck_weights = {
        [decks.DESTRUCTION] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
