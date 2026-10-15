local spells = require("ids.spells")
local component = require("constants.component")
local tentacle = require("policy.magic.effects.summons.tentacle")

-- Source: mon-tentacle.cc reconnects segments after moving the head.
local system = {}

function system.update(ctx, active)
    for _, segment in ipairs(ctx:query({ component.SUMMON_SEGMENT })) do
        tentacle.segment_death(ctx, segment)
    end

    if active == ctx:player() then
        tentacle.clean_orphans(ctx)

        for _, head in ipairs(ctx:query({ component.SUMMON, component.POSITION })) do
            local state = ctx:get(head, component.SUMMON)

            if state.source_id == spells.SPELL_MALIGN_GATEWAY and
                not ctx:has(head, component.SUMMON_SEGMENT) then
                tentacle.refresh(ctx, head)
            end
        end
    elseif ctx:has(active, component.SUMMON) and
        not ctx:has(active, component.SUMMON_SEGMENT) then
        local state = ctx:get(active, component.SUMMON)

        if state.source_id == spells.SPELL_MALIGN_GATEWAY and
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
