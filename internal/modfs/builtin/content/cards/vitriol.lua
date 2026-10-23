-- Fires an acid effect and can corrode visible enemies at high power.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.VITRIOL,
    name = "Vitriol",
    effect_module = "policy.religion.cards.effects.vitriol",
    deck_weights = {
        [decks.DESTRUCTION] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
