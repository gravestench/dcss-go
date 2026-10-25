-- Nemelex's active wrath forces a draw from the catalog's Punishment deck.
-- The four source cards already have separate Lua effects; drawing through
-- that shared catalog preserves mod weights and avoids a second card table.
local decks = require("ids.decks")
local draw = require("policy.religion.cards.draw")
local effects = require("policy.religion.cards.effects.dispatch")
local power = require("policy.religion.cards.power")

local nemelex_xobeh = {}

-- Source card_effect marks this as punishment, so card power comes from XL
-- rather than Nemelex piety. These four effects do not ask for a target.
function nemelex_xobeh.apply(ctx, player)
    ctx:emit("religion",
        "Nemelex Xobeh makes you draw from the deck of Punishment.")

    local card_id = draw.sample(ctx, decks.PUNISHMENT)

    ctx:emit("religion", "You draw a card...")
    effects.apply(ctx, player, card_id, {
        power = power.value(ctx, player, true),
        punishment = true,
        dealt = false,
    })

    return true
end

return nemelex_xobeh
