-- Unleashes destructive miscasts on nearby enemies and returns magic.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.WILD_MAGIC,
    name = "Wild Magic",
    effect_module = "policy.religion.cards.effects.wild_magic",
    deck_weights = {
        [decks.DESTRUCTION] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
