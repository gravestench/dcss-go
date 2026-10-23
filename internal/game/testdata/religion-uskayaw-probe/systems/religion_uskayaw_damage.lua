-- This fixture makes one direct, player-sourced hit during an ordinary
-- turn. Production monster health and religion reaction systems do the rest.
local component = require("constants.component")
local health = require("policy.combat.monster_health")

local system = {}

-- Keep the test independent of attack hit chance while preserving the
-- exact damage owner used by melee and missiles.
function system.update(ctx)
    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.HEALTH,
    })) do
        if monster ~= ctx:player() then
            health.damage(ctx, monster, 1, ctx:player())

            return
        end
    end
end

register.system({
    id = "test.religion_uskayaw_damage",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "actor.death" },
    update = system.update,
})

return system
