local spells = require("ids.spells")
local component = require("constants.component")
local summons = require("policy.magic.effects.summons.common")
local vortex = require("policy.magic.effects.summons.fire_vortex")

-- Source: monster::mark_summoned and ENCH_ABJ expiry. The component belongs
-- to the summoned actor, so its timeout and owner survive save and restore.
local system = {}

function system.update(ctx, active)
    local player = ctx:player()

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)
        local health = ctx:get(entity, component.HEALTH)
        local expired = active == player and state.expires_aut > 0 and
            ctx:aut() >= state.expires_aut

        local dead_vortex = state.source_id == spells.SPELL_FIRE_STORM and
            health and health.current <= 0

        if entity ~= active and not dead_vortex and (expired or not health or
            health.current <= 0) then
            if expired and state.source_id == spells.SPELL_FIRE_STORM then
                vortex.dissipate(ctx, entity)
            else
                summons.expire(ctx, entity)
            end

            if expired then
                ctx:emit("spell", "A summoned creature fades away.")
            end
        end
    end
end

register.system({
    id = "magic.summon.expiry",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "actor.death" },
    update = system.update,
})

return system
