-- Source: traps.cc:zot_effects[6].
local policy = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")

local effect = {}

-- Bound Zot's rolled duration before writing the shared player will debuff.
-- Example: effect.apply(ctx, player) lowers the player's willpower for Zot's timed effect.
function effect.apply(ctx, player)
    local duration = (5 + ctx:random(streams.TRAPS, 15)) * 10

    policy.lower_will(ctx, player, math.min(200, duration))
    ctx:emit("trap", "Your willpower is stripped away!")
end

return effect
