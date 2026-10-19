local spells = require("ids.spells")
local component = require("constants.component")
local tentacle = require("policy.magic.effects.summons.tentacle")

-- Theory of operation: Head movement refreshes segment links before expiry can remove orphans.
-- Source: mon-tentacle.cc reconnects segments after moving the head.
local attached = require("policy.combat.monster_summons.attached_tentacles")

local system = {}

-- Tentacle segments follow their anchor after movement and before summon expiry.
function system.update(ctx, active, aut)
    attached.move(ctx, active, aut or 10)

    for _, segment in ipairs(ctx:query({ component.SUMMON_SEGMENT })) do
        tentacle.segment_death(ctx, segment)
    end

    tentacle.clean_orphans(ctx)

    if active == ctx:player() then

        for _, head in ipairs(ctx:query({ component.SUMMON, component.POSITION })) do
            local state = ctx:get(head, component.SUMMON)

            -- Refresh can expire a segment that remains in this query snapshot.
            if state and (state.source_id == spells.SPELL_MALIGN_GATEWAY or
                state.source_id == spells.SPELL_CREATE_TENTACLES) and
                not ctx:has(head, component.SUMMON_SEGMENT) then
                tentacle.refresh(ctx, head)
            end
        end
    elseif ctx:has(active, component.SUMMON) and
        not ctx:has(active, component.SUMMON_SEGMENT) then
        local state = ctx:get(active, component.SUMMON)

        if (state.source_id == spells.SPELL_MALIGN_GATEWAY or
                state.source_id == spells.SPELL_CREATE_TENTACLES) and
            not ctx:has(active, component.SUMMON_SEGMENT) then
            tentacle.refresh(ctx, active)
        end
    end
end

register.system({
    id = "magic.summon.tentacle_segments",
    scope = "active",
    query = {},
    after = { "world.movement" },
    before = { "magic.summon.expiry", "actor.death" },
    update = system.update,
})

return system
