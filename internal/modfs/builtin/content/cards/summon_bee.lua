-- Calls a power-scaled group of temporary killer bees.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.SUMMON_BEE,
    name = "the Swarm",
    effect_module = "policy.religion.cards.effects.summon_bee",
    deck_weights = {
        [decks.SUMMONING] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
