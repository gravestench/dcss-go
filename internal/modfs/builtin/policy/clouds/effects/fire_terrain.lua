-- cloud.cc:_cloud_interacts_with_terrain. Fire next to water may make steam.
local terrain = require("constants.terrain")
local streams = require("constants.rng_streams")
local ids = require("ids.clouds")
local placement = require("policy.clouds.placement")
local neighbors = require("constants.adjacent_cells")

local interaction = {}

function interaction.neighbors()
    return neighbors
end

function interaction.steam(ctx, state)
    for _, offset in ipairs(neighbors) do
        local x = state.x + offset[1]
        local y = state.y + offset[2]
        local feature = ctx:cell(state.level_id, x, y)
        local water = feature == terrain.DNGN_SHALLOW_WATER or
            feature == terrain.DNGN_DEEP_WATER

        if water and
            not placement.at(ctx, state.level_id, x, y) and
            ctx:random(streams.CLOUDS, 14) == 0 then
            local source = state.source_actor_id > 0 and
                ctx:entity(state.source_actor_id) or nil
            local duration = 2 + ctx:random(streams.CLOUDS, 5)

            placement.place(ctx, ids.CLOUD_STEAM, source,
                state.level_id, x, y, duration, {
                    source_actor_id = state.source_actor_id,
                    kill_category = state.kill_category,
                    killer_type = state.killer_type,
                    spread_rate = 11,
                    exclusion_radius = -1,
                })
        end
    end
end

return interaction
