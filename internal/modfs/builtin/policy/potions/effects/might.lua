local items = require("ids.items")
local potions = require("policy.potions")
local might = require("policy.character.might")

local effect = {}

function effect.can_quaff()
    return nil
end

function effect.apply(ctx, player)
    return might.apply(ctx, player, 40, "potion")
end

potions.register(items.POT_MIGHT, effect)

return effect
