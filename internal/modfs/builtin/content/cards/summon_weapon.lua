-- Calls a temporary dancing weapon whose quality scales with power.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.SUMMON_WEAPON,
    name = "the Dance",
    effect_module = "policy.religion.cards.effects.summon_weapon",
    deck_weights = {
        [decks.SUMMONING] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
