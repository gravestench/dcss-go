-- Weakens hostile monsters through polymorph or dazing.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.DEGEN,
    name = "Degeneration",
    effect_module = "policy.religion.cards.effects.degen",
    deck_weights = {
        [decks.DESTRUCTION] = 3,
    },
}

register.definition(categories.CARDS, definition)

return definition
