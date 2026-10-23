-- Launches an orb of destruction or a stronger burst.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.ORB,
    name = "the Orb",
    effect_module = "policy.religion.cards.effects.orb",
    deck_weights = {
        [decks.DESTRUCTION] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
