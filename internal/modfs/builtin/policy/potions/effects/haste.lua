local items = require("ids.items")
local potions = require("policy.potions")
local haste = require("policy.character.haste")
local streams = require("constants.rng_streams")
local kinds = require("constants.religion_conduct")
local conduct = require("policy.religion.conduct")
local component = require("constants.component")

local effect = {}

-- Stasis from species or current form blocks Haste before any duration is rolled.
-- Example: stasis rejects Haste before a potion-stream duration roll.
function effect.can_quaff(ctx, player)
    return haste.restriction(ctx, player)
end

-- Source: potion.cc:PotionHaste::effect and spl-other.cc:haste_player.
function effect.apply(ctx, player, known)
    local message = haste.apply(ctx, player, 40, streams.POTION)

    -- Source PotionHaste::quaff reports a successful speed gain after the
    -- duration changes. Unknown potions can receive the god's pardon.
    if ctx:get(player, component.RELIGION_WORSHIP) and
        ctx:get(player, component.DURATIONS).haste_aut > 0 then
        conduct.record(ctx, {
            id = kinds.HASTY,
            level = 10,
            known = known ~= false,
        })
    end

    return message
end

potions.register(items.POT_HASTE, effect)

return effect
