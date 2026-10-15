local items = require("ids.items")
local potions = require("policy.potions")
local rage = require("policy.character.rage")

local effect = {}

function effect.can_quaff(ctx, player)
    if not rage.can_begin(ctx, player) then
        return "You cannot go berserk right now."
    end
end

-- Source: potion.cc:PotionBerserk::effect and player-act.cc:go_berserk.
function effect.apply(ctx, player)
    rage.begin(ctx, player, "potion")
end

potions.register(items.POT_BERSERK_RAGE, effect)

return effect
