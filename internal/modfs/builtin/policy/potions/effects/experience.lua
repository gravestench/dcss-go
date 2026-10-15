local items = require("ids.items")
local potions = require("policy.potions")
local experience = require("policy.potions.experience")

local effect = {}

function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionExperience::effect.
function effect.apply(ctx, player)
    return experience.grant(ctx, player)
end

potions.register(items.POT_EXPERIENCE, effect)

return effect
