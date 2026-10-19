local items = require("ids.items")
local potions = require("policy.potions")
local resistance = require("policy.potions.resistance")

local effect = {}

-- Resistance may extend its protection timer, so repeated use remains allowed.
function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionResistance::effect.
-- Example: Resistance extends one saved protection timer rather than stacking a second component.
function effect.apply(ctx, player)
    resistance.extend(ctx, player, 35 + ctx:random("potion", 40))

    return "You feel protected."
end

potions.register(items.POT_RESISTANCE, effect)

return effect
