-- The source Tartarus gauntlet waits until its closing wall is clear, then
-- opens the outer wall, closes the passage, and releases pestilent clouds.
local attribution = require("constants.cloud_attribution")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local clouds = require("ids.clouds")
local placement = require("policy.clouds.placement")

local handler = {}

-- Gather all oriented source markers belonging to this placed vault. The
-- callback receives the entered marker but owns the whole shared group.
local function markers(ctx, state)
    local result = {
        triggers = {},
        open_walls = {},
        close_walls = {},
    }

    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_TRIGGER })) do
        local marker = ctx:get(entity, component.WORLD_VAULT_TRIGGER)

        if marker.level_id == state.level_id and
            marker.vault_id == state.vault_id and
            marker.callback_module == "tar" then
            local entry = { entity = entity, state = marker }

            if marker.callback_method == "trap_wall" then
                result.open_walls[#result.open_walls + 1] = entry
            elseif marker.callback_method == "trap_wall2" then
                result.close_walls[#result.close_walls + 1] = entry
            elseif marker.callback_method == "gauntlet_activate" then
                result.triggers[#result.triggers + 1] = entry
            end
        end
    end

    return result
end

-- Source delays activation while any future stone wall has a monster or
-- player on it. Returning false keeps every entry trigger armed.
local function closing_wall_occupied(ctx, state, targets)
    for _, entry in ipairs(targets) do
        if ctx:actor_at(state.level_id, entry.state.x, entry.state.y) then
            return true
        end
    end

    return false
end

-- Change the opening d cells to floor before placing 5-9 turn miasma
-- clouds. The normal cloud ECS owner persists lifetime and attribution.
local function open_outer_wall(ctx, state, targets)
    for _, entry in ipairs(targets) do
        local x = entry.state.x
        local y = entry.state.y

        ctx:set_cell(state.level_id, x, y, terrain.DNGN_FLOOR)
        placement.place(ctx, clouds.CLOUD_MIASMA, nil,
            state.level_id, x, y,
            (ctx:random(streams.PLACEMENT, 5) + 5) * 10, {
                kill_category = attribution.OTHER,
                killer_type = attribution.MISC,
            })
    end
end

-- The source recolours the newly closed stone wall light magenta. Runtime
-- cell colour mutation must be saved with terrain for restore fidelity.
local function close_inner_wall(ctx, state, targets)
    for _, entry in ipairs(targets) do
        local x = entry.state.x
        local y = entry.state.y

        ctx:set_cell(state.level_id, x, y, terrain.DNGN_STONE_WALL)
        ctx:set_cell_colour(state.level_id, x, y, "lightmagenta")
    end
end

-- Destroy the whole source TriggerableFunction group only after success.
-- Target markers are consumed too; save/restore then cannot replay it.
local function consume_group(ctx, grouped)
    for _, kind in ipairs({ "triggers", "open_walls", "close_walls" }) do
        for _, entry in ipairs(grouped[kind]) do
            ctx:destroy(entry.entity)
        end
    end
end

-- Match callback.grunt_gauntlet_trap_activate's occupancy guard, two wall
-- mutations, cloud lifetime, and warning messages in source order.
local function gauntlet_activate(ctx, state)
    local grouped = markers(ctx, state)

    if closing_wall_occupied(ctx, state, grouped.close_walls) then
        return false
    end

    open_outer_wall(ctx, state, grouped.open_walls)
    close_inner_wall(ctx, state, grouped.close_walls)
    ctx:emit("warning",
        "You hear an unearthly scream, and the grinding of stone!")
    ctx:emit("warning", "The path is suddenly blocked!")
    consume_group(ctx, grouped)

    return false
end

-- The two marker methods only make their wall coordinates available to
-- the shared callback; neither source wall is a player-move trigger.
local function trap_wall()
    return false
end

local function trap_wall2()
    return false
end

handler.gauntlet_activate = gauntlet_activate
handler.trap_wall = trap_wall
handler.trap_wall2 = trap_wall2

return handler
