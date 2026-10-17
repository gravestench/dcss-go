local vortex = {}

function vortex.immune(ctx, actor)
    if actor ~= ctx:player() then
        return false
    end

    local ids = require("policy.magic.effects.zaps.ids")

    return ctx:has(actor, ids.component.POLAR_VORTEX)
end

function vortex.apply()
    -- The source vortex cloud has no direct damage or status effect.
    -- Avoidance and Polar Vortex immunity are its active behavior.
end

return vortex
