-- Creates a friendly image of the player as a temporary ally.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.ILLUSION,
    name = "the Illusion",
    effect_module = "policy.religion.cards.effects.illusion",
    deck_weights = {
        [decks.SUMMONING] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
