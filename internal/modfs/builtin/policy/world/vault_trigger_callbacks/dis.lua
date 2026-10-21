-- Dis's iron hall animates its marked statues on the first player move
-- across a source trigger cell. Trigger entities carry oriented positions.
local component = require("constants.component")
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local factory = require("policy.population.factory")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")

local handler = {}

-- The source checks each G statue independently and animates it on a
-- one-in-four roll. Consume every sibling trigger after the first event;
-- its dgn.persist flag prevents a second animation on this floor.
function handler.iron_hall_animate(ctx, state)
    local siblings = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_TRIGGER })) do
        local marker = ctx:get(entity, component.WORLD_VAULT_TRIGGER)

        if marker.level_id == state.level_id and
            marker.vault_id == state.vault_id and
            marker.callback_module == "dis" then
            if marker.callback_method == "trap_statue" and
                ctx:random(streams.PLACEMENT, 4) == 0 then
                ctx:set_cell(state.level_id, marker.x, marker.y,
                    terrain.DNGN_FLOOR)
                factory.spawn(ctx, monsters.MONS_IRON_GOLEM,
                    state.level_id, marker.x, marker.y, {
                        generate_awake = true,
                        patrolling = true,
                    })
            end

            -- The generic trigger owner consumes the entered entity.
            if marker.record_index ~= state.record_index then
                siblings[#siblings + 1] = entity
            end
        end
    end

    for _, entity in ipairs(siblings) do
        ctx:destroy(entity)
    end

    ctx:emit(channels.VAULT,
        "You hear the creaking of ancient metal!")
end

-- A statue target is normally an impassable G cell. The method exists so
-- the generic trigger loader can materialize its saved target position.
function handler.trap_statue()
    return false
end

return handler
