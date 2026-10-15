local component = require("constants.component")
local engulf = require("policy.combat.engulf")

local system = {}

function system.update(ctx, active)
    engulf.release_far_all(ctx)

    if active ~= ctx:player() and
        ctx:get(active, component.WATER_HOLD) then
        engulf.tick(ctx, active)
    end
end

register.system({
    id = "combat.engulf",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
