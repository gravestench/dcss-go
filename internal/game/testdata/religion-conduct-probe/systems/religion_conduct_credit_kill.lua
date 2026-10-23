-- An integration fixture credits the fixed-map rat during the normal death
-- phase. The production actor-death system still owns XP and conduct.
local component = require("constants.component")

local system = {}

-- Kill one live monster after attacks but before death processing. This
-- avoids making the test depend on hit chance or weapon damage rolls.
function system.update(ctx)
    for _, entity in ipairs(ctx:query({ component.ACTOR,
        component.HEALTH })) do
        if entity ~= ctx:player() then
            local health = ctx:get(entity, component.HEALTH)

            if health.current > 0 then
                health.current = 0
                ctx:set(entity, component.HEALTH, health)
                ctx:signal("player_kill", entity)

                return
            end
        end
    end
end

register.system({
    id = "test.religion_credit_kill",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
