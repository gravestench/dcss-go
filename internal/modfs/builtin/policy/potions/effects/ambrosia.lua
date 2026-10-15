local items = require("ids.items")
local potions = require("policy.potions")
local ambrosia = require("policy.potions.ambrosia")
local confusion = require("policy.magic.player_confusion")

local effect = {}

function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionAmbrosia::effect. Intentional confusion ignores
-- clarity and activates the concurrent regeneration duration.
function effect.apply(ctx, player)
    local active = ambrosia.active(ctx, player)
    local turns = 3 + ctx:random("potion", 8)

    confusion.extend(ctx, player, turns)
    ambrosia.extend(ctx, player, turns)

    if active then
        return "You feel more invigorated."
    end

    return "You feel invigorated."
end

potions.register(items.POT_AMBROSIA, effect)

return effect
