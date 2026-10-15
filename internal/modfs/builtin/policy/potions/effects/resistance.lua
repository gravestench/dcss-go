local items = require("ids.items")
local potions = require("policy.potions")
local resistance = require("policy.potions.resistance")

local effect = {}

function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionResistance::effect.
function effect.apply(ctx, player)
    resistance.extend(ctx, player, 35 + ctx:random("potion", 40))

    return "You feel protected."
end

potions.register(items.POT_RESISTANCE, effect)

return effect
