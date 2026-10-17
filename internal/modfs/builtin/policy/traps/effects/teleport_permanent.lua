-- Source: traps.cc:545-559. Permanent traps keep their zero-charge state.
local teleport = require("policy.traps.effects.teleport")

local effect = {}

function effect.trigger(ctx, trap, actor, site)
    teleport.trigger(ctx, trap, actor, site)
end

return effect
