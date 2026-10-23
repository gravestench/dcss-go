-- Attempts to trap the player in pig form as punishment.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.SWINE,
    name = "the Swine",
    effect_module = "policy.religion.cards.effects.swine",
    deck_weights = {
        [decks.PUNISHMENT] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
