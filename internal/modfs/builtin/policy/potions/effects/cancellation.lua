local items = require("ids.items")
local potions = require("policy.potions")
local cancellation = require("policy.potions.cancellation")

local effect = {}

function effect.can_quaff(ctx, player)
    if not cancellation.available(ctx, player) then
        return "Drinking this now will have no effect."
    end
end

-- Source: potion.cc:PotionCancellation::effect.
function effect.apply(ctx, player)
    cancellation.purge(ctx, player)

    return "You feel magically purged."
end

potions.register(items.POT_CANCELLATION, effect)

return effect
