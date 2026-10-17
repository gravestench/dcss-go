local monsters = require("ids.monsters")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local summons = require("policy.magic.effects.summons.common")

-- Source: timed-effects.cc:timeout_malign_gateways. The marker first owns a
-- solid portal cell, then keeps it while its tentacle lives. The source also
-- emits translocation clouds, which need the future cloud field.
local system = {}

function system.update(ctx, active)
    if active ~= ctx:player() then
        return
    end

    for _, marker in ipairs(ctx:query({ component.SUMMON_GATEWAY })) do
        local state = ctx:get(marker, component.SUMMON_GATEWAY)

        if state.phase == 0 and ctx:aut() >= state.expires_aut and
            not ctx:actor_at(state.level_id, state.x, state.y) then
            local tentacle = summons.spawn(ctx, state.owner,
                state.source_id, monsters.MONS_ELDRITCH_TENTACLE, 1, 1, {
                    anchor = {
                        level_id = state.level_id,
                        x = state.x,
                        y = state.y,
                    },
                    exact = { x = state.x, y = state.y },
                    expires_aut = ctx:aut() + 90,
                    source_category = state.source_category,
                    hostile = state.hostile,
                })

            if tentacle then
                state.phase = 1
                state.tentacle_id = ctx:id(tentacle)
                ctx:set(marker, component.SUMMON_GATEWAY, state)
                ctx:emit("spell", "An eldritch tentacle emerges from the portal!")
            end
        elseif state.phase == 1 then
            local tentacle = ctx:entity(state.tentacle_id)

            if not tentacle or not ctx:has(tentacle, component.HEALTH) then
                if ctx:cell(state.level_id, state.x, state.y) ==
                    terrain_ids.DNGN_MALIGN_GATEWAY then
                    ctx:set_cell(state.level_id, state.x, state.y,
                        terrain_ids.DNGN_FLOOR)
                end

                ctx:destroy(marker)
            end
        end
    end
end

register.system({
    id = "magic.summon.gateway",
    scope = "active",
    query = {},
    after = { "magic.summon.terrain" },
    before = { "actor.death" },
    update = system.update,
})

return system
