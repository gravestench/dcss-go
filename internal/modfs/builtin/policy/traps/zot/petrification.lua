-- Source: traps.cc:zot_effects[5].
local policy = require("policy.combat.player_petrification")

local effect = {}

-- Delegate to the shared player stone transition so Zot and other sources use the same state.
-- Example: effect.apply(ctx, player) starts the player's petrification status.
function effect.apply(ctx, player)
    policy.apply(ctx, player)
end

return effect
