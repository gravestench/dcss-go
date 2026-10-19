-- Theory of operation: damage can kill a spore during somebody else's
-- action. Scan only spore components before ordinary death cleanup so
-- every such death detonates once instead of silently removing a summon.
local component = require("constants.component")
local spore = require("policy.combat.monster_plants.spore")

local system = {}

-- The spore policy guards repeat explosions before it damages neighbors.
function system.update(ctx)
    for _, entity in ipairs(ctx:query({
        component.MONSTER_SPORE,
        component.HEALTH,
    })) do
        local health = ctx:get(entity, component.HEALTH)

        if health.current <= 0 then
            spore.explode(ctx, entity)
        end
    end
end

register.system({
    id = "combat.monster_spore_death",
    scope = "active",
    query = {},
    after = { "magic.summon.expiry" },
    before = { "actor.death" },
    update = system.update,
})

return system
