local items = require("ids.items")
local potions = require("policy.potions")
local brilliance = require("policy.potions.brilliance")

local effect = {}

-- Brilliance can refresh its timer even if already active.
function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionBrilliance::effect.
-- Example: a Brilliance potion adds a potion-stream duration to an existing Brilliance status.
function effect.apply(ctx, player)
    local active = brilliance.active(ctx, player)

    brilliance.extend(ctx, player, 35 + ctx:random("potion", 40))

    if active then
        return "You feel more clever all of a sudden."
    end

    return "You feel clever all of a sudden."
end

potions.register(items.POT_BRILLIANCE, effect)

return effect
