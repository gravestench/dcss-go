local vortex = {}

-- A Polar Vortex caster ignores its own cloud while other actors use the
-- normal contact policy. The saved aura now belongs to either actor type.
function vortex.immune(ctx, actor)
    local ids = require("policy.magic.effects.zaps.ids")

    return ctx:has(actor, ids.component.POLAR_VORTEX)
end

-- Vortex cloud contact itself is inert; the owning spell supplies movement and damage.
function vortex.apply()
    -- The source vortex cloud has no direct damage or status effect.
    -- Avoidance and Polar Vortex immunity are its active behavior.
end

return vortex
