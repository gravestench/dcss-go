local items = require("ids.items")
local potions = require("policy.potions")
local haste = require("policy.character.haste")
local streams = require("constants.rng_streams")

local effect = {}

-- Stasis from species or current form blocks Haste before any duration is rolled.
-- Example: stasis rejects Haste before a potion-stream duration roll.
function effect.can_quaff(ctx, player)
    return haste.restriction(ctx, player)
end

-- Source: potion.cc:PotionHaste::effect and spl-other.cc:haste_player.
function effect.apply(ctx, player)
    return haste.apply(ctx, player, 40, streams.POTION)
end

potions.register(items.POT_HASTE, effect)

return effect
