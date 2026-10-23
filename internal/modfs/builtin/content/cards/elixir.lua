-- Restores health and magic over time rather than dealing damage.
-- This separate definition lets mods replace its weight or effect by path.
local cards = require("ids.cards")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local definition = {
    id = cards.ELIXIR,
    name = "the Elixir",
    effect_module = "policy.religion.cards.effects.elixir",
    deck_weights = {
        [decks.ESCAPE] = 5,
    },
}

register.definition(categories.CARDS, definition)

return definition
