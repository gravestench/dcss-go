local monsters = require("ids.monsters")
local component = require("constants.component")
local terrain_ids = require("constants.terrain")
local summons = require("policy.magic.effects.summons.common")

-- Theory of operation: The marker changes from portal to tentacle only when its cell is free after terrain aging.
-- Source: timed-effects.cc:timeout_malign_gateways. The marker first owns a
-- solid portal cell, then keeps its marker while the tentacle lives.
-- Monster portals also emit saved translocation clouds before emergence.
local portal = require("policy.combat.monster_summons.portal")
local cloud_area = require("policy.clouds.area")
local clouds = require("ids.clouds")
local streams = require("constants.rng_streams")

local system = {}

-- Gateway lifetime and occupancy are checked after temporary terrain ages.
function system.update(ctx, active)
    if active ~= ctx:player() then
        return
    end

    local player_position = ctx:get(active, component.POSITION)

    for _, marker in ipairs(ctx:query({ component.SUMMON_GATEWAY })) do
        local state = ctx:get(marker, component.SUMMON_GATEWAY)

        -- Area clouds use the current player's LOS; off-level portals stay quiet.
        if player_position and player_position.level_id == state.level_id and
            state.phase == 0 and ctx:aut() < state.expires_aut and
            state.owner ~= ctx:player() then
            cloud_area.place(ctx, clouds.CLOUD_TLOC_ENERGY, nil,
                state.level_id, state.x, state.y,
                3 + ctx:random(streams.MONSTER_SPELL, 10),
                2 + ctx:random(streams.MONSTER_SPELL, 5), streams.MONSTER_SPELL)
        end

        if state.phase == 0 and ctx:aut() >= state.expires_aut and
            not ctx:actor_at(state.level_id, state.x, state.y) then
            local tentacle

            if state.owner ~= ctx:player() then
                tentacle = portal.spawn(ctx, marker, state)
            else
                tentacle = summons.spawn(ctx, state.owner,
                    state.source_id, monsters.MONS_ELDRITCH_TENTACLE, 1, 1, {
                        anchor = {
                            level_id = state.level_id,
                            x = state.x,
                            y = state.y,
                        },
                        exact = { x = state.x, y = state.y },
                        expires_aut = ctx:aut() + 90,
                        source_category = state.source_category,
                        attitude = state.attitude,
                    })
            end

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
    after = { "world.temporary_terrain" },
    before = { "actor.death" },
    update = system.update,
})

return system
