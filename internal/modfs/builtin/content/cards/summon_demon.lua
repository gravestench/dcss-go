-- Calls two demons, with a small chance the first is hostile.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.SUMMON_DEMON,
    name = "the Pentagram",
    effect_module = "policy.religion.cards.effects.summon_demon",
    deck_weights = {
        [decks.SUMMONING] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
