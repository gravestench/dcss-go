local items = require("ids.items")
local potions = require("policy.potions")
local experience = require("policy.potions.experience")

local effect = {}

-- Experience gain is always eligible; level and skill decisions occur during apply.
function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionExperience::effect.
-- Example: Experience delegates its level and pending skill-XP changes to experience.grant.
function effect.apply(ctx, player)
    return experience.grant(ctx, player)
end

potions.register(items.POT_EXPERIENCE, effect)

return effect
