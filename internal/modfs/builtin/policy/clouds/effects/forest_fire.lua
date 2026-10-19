local fire = require("policy.clouds.effects.fire")
local terrain = require("constants.terrain")
local streams = require("constants.rng_streams")
local ids = require("ids.clouds")
local placement = require("policy.clouds.placement")
local interaction = require("policy.clouds.effects.fire_terrain")
local component = require("constants.component")
local signals = require("constants.world_signals")

local forest_fire = {}
forest_fire.apply = fire.apply
forest_fire.immune = fire.immune
forest_fire.risk_resistance = fire.risk_resistance

local flammable = {
    [terrain.DNGN_TREE] = terrain.DNGN_FLOOR,
    [terrain.DNGN_MANGROVE] = terrain.DNGN_SHALLOW_WATER,
    [terrain.DNGN_DEMONIC_TREE] = terrain.DNGN_FLOOR,
}

-- Do not burn a cell already owned by temporary terrain; its expiry must still restore the original feature.
local function temporary(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({
        component.TEMPORARY_TERRAIN,
    })) do
        local state = ctx:get(entity, component.TEMPORARY_TERRAIN)

        if state.level_id == level_id and
            state.x == x and state.y == y then
            return true
        end
    end

    return false
end

-- Spread or transform adjacent terrain before aging this cloud, using cloud occupancy to avoid overlap.
-- Example: a forest fire can spread flames to adjacent terrain before the parent cloud ages.
function forest_fire.before_age(ctx, state)
    interaction.steam(ctx, state)
    local make_flames = ctx:random(streams.CLOUDS, 5) == 0
    local source = state.source_actor_id > 0 and
        ctx:entity(state.source_actor_id) or nil

    for _, offset in ipairs(interaction.neighbors()) do
        local x = state.x + offset[1]
        local y = state.y + offset[2]
        local feature = ctx:cell(state.level_id, x, y)

        if feature and
            not placement.at(ctx, state.level_id, x, y) then
            local replacement = flammable[feature]

            if make_flames and ctx:walkable(state.level_id, x, y) then
                placement.place(ctx, ids.CLOUD_FIRE, source,
                    state.level_id, x, y,
                    math.floor(state.decay_aut / 2) + 1, {
                        source_actor_id = state.source_actor_id,
                        kill_category = state.kill_category,
                        killer_type = state.killer_type,
                    })
            end

            if replacement and
                not temporary(ctx, state.level_id, x, y) and
                ctx:random(streams.CLOUDS, 20) == 0 then
                -- Vault marker policy can consume this typed attempt once
                -- the broader marker domain supplies destruction vetoes.
                ctx:signal(signals.TERRAIN_DESTROY_ATTEMPT, {
                    level_id = state.level_id,
                    x = x,
                    y = y,
                    original_feature = feature,
                    replacement_feature = replacement,
                    source_kind_id = ids.CLOUD_FOREST_FIRE,
                })
                ctx:set_cell(state.level_id, x, y, replacement)
                placement.place(ctx, ids.CLOUD_FOREST_FIRE, source,
                    state.level_id, x, y,
                    25 + ctx:random(streams.CLOUDS, 30), {
                        source_actor_id = state.source_actor_id,
                        kill_category = state.kill_category,
                        killer_type = state.killer_type,
                    })
                ctx:emit("cloud", "The forest fire spreads!")
            end
        end
    end
end

return forest_fire
