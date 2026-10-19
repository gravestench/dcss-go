local items = require("ids.items")
local potions = require("policy.potions")
local might = require("policy.character.might")

local effect = {}

-- Might's drink check precedes the duration update used by the potion registry.
function effect.can_quaff()
    return nil
end

-- Reuse the common Might timer with a potion-specific duration so combat reads one status.
-- Example: Might uses the shared might policy with a forty-turn potion duration.
function effect.apply(ctx, player)
    return might.apply(ctx, player, 40, "potion")
end

potions.register(items.POT_MIGHT, effect)

return effect
