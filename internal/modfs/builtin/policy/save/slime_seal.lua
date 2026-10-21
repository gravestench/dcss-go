-- The Slime Pit seal is durable ECS state backed by authored DES cells.
-- Restore checks the source wall and marker in both directions instead of
-- rebuilding a hidden level flag from the current terrain appearance.
local component = require("constants.component")
local grid = require("policy.generation.grid")
local layouts = require("policy.generation.layouts.catalog")
local names = require("constants.slime_pit")
local population = require("policy.population.slime_seal")
local terrain = require("constants.terrain")

local slime_seal = {}

-- Record indexes are stable within a saved level, even after the terrain
-- changes or the Royal Jelly entity disappears following its death.
local function key(level_id, index)
    return level_id .. ":" .. index
end

-- Reconstruct the authored wall coordinates from the effective DES MAP,
-- which a saved record cannot change. Encompass maps are centered without
-- rotation; a sparse same-path mod can change their size and wall pattern.
local function authored_walls(level)
    if level.vault_id ~= names.MAP_ID then
        return nil
    end

    local definition = layouts.get(names.MAP_ID)

    if definition.orientation ~= "encompass" then
        error("Slime end seal needs an encompassing authored MAP")
    end

    local map_width = 0

    for _, row in ipairs(definition.rows) do
        map_width = math.max(map_width, #row)
    end

    local left = math.floor((grid.width - map_width) / 2)
    local top = math.floor((grid.height - #definition.rows) / 2)
    local walls = {}

    for y, row in ipairs(definition.rows) do
        for x = 1, #row do
            if row:sub(x, x) == "n" then
                local position = key(left + x - 1, top + y - 1)

                walls[position] = true
            end
        end
    end

    return walls
end

-- Match every saved marker against its immutable authored MAP location
-- before using the markers as the expected set of live ECS seal cells.
local function expected_cells(input)
    local expected = {}

    for _, level in ipairs(input.levels or {}) do
        local walls = authored_walls(level)

        for index, record in ipairs(level.vault_records or {}) do
            if population.is_record(record) then
                if walls then
                    local position = key(record.x, record.y)

                    if not walls[position] then
                        error("Slime seal marker has no authored wall at " ..
                            position)
                    end

                    walls[position] = nil
                end

                expected[key(level.id, index)] = {
                    level_id = level.id,
                    x = record.x,
                    y = record.y,
                }
            end
        end

        if walls and next(walls) then
            error("authored Slime wall has no saved source marker")
        end
    end

    return expected
end

-- A released wall can be changed again by later terrain magic, but it
-- cannot still be the source clear stone wall it was meant to remove.
function slime_seal.validate(ctx, input)
    local expected = expected_cells(input)

    for _, entity in ipairs(ctx:query({ component.SLIME_SEAL })) do
        local state = ctx:get(entity, component.SLIME_SEAL)
        local cell_key = key(state.level_id, state.record_index)
        local source = expected[cell_key]

        if not source or state.level_id ~= source.level_id or
            state.x ~= source.x or state.y ~= source.y then
            error("Slime seal has no matching source wall " .. cell_key)
        end

        if state.released and ctx:cell(state.level_id,
            state.x, state.y) == terrain.DNGN_CLEAR_STONE_WALL then
            error("released Slime seal still has a clear stone wall")
        end

        expected[cell_key] = nil
    end

    if next(expected) then
        error("authored Slime seal wall has no ECS marker")
    end

    return {}
end

return slime_seal
