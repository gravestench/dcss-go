-- Damages the player through torment or holy word.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.TORMENT,
    name = "Torment",
    effect_module = "policy.religion.cards.effects.torment",
    deck_weights = {
        [decks.PUNISHMENT] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
