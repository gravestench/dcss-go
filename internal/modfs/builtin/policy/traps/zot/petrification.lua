-- Source: traps.cc:zot_effects[5].
local policy = require("policy.combat.player_petrification")

local effect = {}

function effect.apply(ctx, player)
    policy.apply(ctx, player)
end

return effect
