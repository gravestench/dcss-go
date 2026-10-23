-- Changes nearby speed, making an escape card useful before the next action.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.VELOCITY,
    name = "Velocity",
    effect_module = "policy.religion.cards.effects.velocity",
    deck_weights = {
        [decks.ESCAPE] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
