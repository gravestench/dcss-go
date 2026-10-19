local vortex = {}

-- The Polar Vortex caster ignores its cloud while other actors use the normal contact policy.
-- Example: Polar Vortex protects its player caster from the matching vortex cloud.
function vortex.immune(ctx, actor)
    if actor ~= ctx:player() then
        return false
    end

    local ids = require("policy.magic.effects.zaps.ids")

    return ctx:has(actor, ids.component.POLAR_VORTEX)
end

-- Vortex cloud contact itself is inert; the owning spell supplies movement and damage.
function vortex.apply()
    -- The source vortex cloud has no direct damage or status effect.
    -- Avoidance and Polar Vortex immunity are its active behavior.
end

return vortex
