-- Raises temporary walls around the user to interrupt nearby threats.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.TOMB,
    name = "the Tomb",
    effect_module = "policy.religion.cards.effects.tomb",
    deck_weights = {
        [decks.ESCAPE] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
