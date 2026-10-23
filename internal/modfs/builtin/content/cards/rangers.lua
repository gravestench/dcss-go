-- Calls ranged allies, with stronger species at higher card power.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.RANGERS,
    name = "the Rangers",
    effect_module = "policy.religion.cards.effects.rangers",
    deck_weights = {
        [decks.SUMMONING] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
