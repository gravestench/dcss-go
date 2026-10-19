-- Theory of operation: a spore acts before generic monster AI and death.
-- The ECS component marks it as a one-use bomb; summon expiry handles
-- timeout and this system handles contact and lethal damage.
local component = require("constants.component")
local spore = require("policy.combat.monster_plants.spore")

local system = {}

-- Give living spores a movement or detonation decision; dead spores
-- detonate here before ordinary corpse and XP processing can erase them.
function system.update(ctx, entity)
    local health = ctx:get(entity, component.HEALTH)

    if not health then
        return
    end

    if health.current <= 0 then
        spore.explode(ctx, entity)

        return
    end

    if ctx:has(entity, component.INTENT) then
        return
    end

    local action = spore.act(ctx, entity)

    if action and ctx:has(entity, component.ACTOR) then
        ctx:add(entity, component.INTENT, action)
    end
end

register.system({
    id = "combat.monster_spore",
    scope = "active",
    query = { component.MONSTER_SPORE },
    before = { "monster.decision", "actor.death" },
    update = system.update,
})

return system
