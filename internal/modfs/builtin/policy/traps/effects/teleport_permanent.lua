-- Source: traps.cc. Permanent traps keep their zero-charge state.
local teleport = require("policy.traps.effects.teleport")

local effect = {}

-- Reuse normal teleport resolution while leaving this trap's permanent lifecycle to activation.
-- Example: effect.trigger(ctx, trap, player, site) teleports without consuming the trap.
function effect.trigger(ctx, trap, actor, site)
    teleport.trigger(ctx, trap, actor, site)
end

return effect
