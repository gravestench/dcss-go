local items = require("ids.items")
local potions = require("policy.potions")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")

local effect = {}

function effect.can_quaff()
    return nil
end

-- Source: potion.cc:PotionDegeneration::effect drains each stat in enum
-- order, with an independent one-to-three roll for each.
function effect.apply(ctx, player)
    for _, field in ipairs(stats.ORDER) do
        stat_loss.drain(ctx, player, field,
            1 + ctx:random("potion", 3))
    end

    return "There was something very wrong with that liquid."
end

potions.register(items.POT_DEGENERATION, effect)

return effect
