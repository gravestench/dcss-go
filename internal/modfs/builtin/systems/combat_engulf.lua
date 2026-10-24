local component = require("constants.component")
local engulf = require("policy.combat.engulf")

local system = {}

-- Theory of operation: The pass releases invalid holds, then applies drowning before death cleanup reads HP.
-- Engulf damage is processed after attacks and before death cleanup examines HP.
function system.update(ctx, active, elapsed_aut)
    engulf.release_far_all(ctx)

    if ctx:get(active, component.WATER_HOLD) then
        engulf.tick(ctx, active, elapsed_aut)
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
