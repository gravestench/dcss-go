-- Drains the player as a Nemelex punishment rather than a draw.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.WRAITH,
    name = "the Wraith",
    effect_module = "policy.religion.cards.effects.wraith",
    deck_weights = {
        [decks.PUNISHMENT] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
