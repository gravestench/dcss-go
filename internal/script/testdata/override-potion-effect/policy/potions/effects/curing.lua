local items = require("ids.items")
local potions = require("policy.potions")

local effect = {}

function effect.can_quaff()
    return nil
end

function effect.apply()
    return "The overlaid curing effect ran."
end

potions.register(items.POT_CURING, effect)

return effect
