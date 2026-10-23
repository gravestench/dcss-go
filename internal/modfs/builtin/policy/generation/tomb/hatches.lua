-- Tomb's escape hatches are one-way routes. Source markers name the exit
-- and a unique destination; the landing need not itself be a stair.
local effects = require("constants.vault_effects")
local terrain = require("constants.terrain")

local hatches = {}

local stair_cells = {
    [terrain.DNGN_STONE_STAIRS_UP_I] = true,
    [terrain.DNGN_STONE_STAIRS_DOWN_I] = true,
}

local landing_cells = {
    [terrain.DNGN_FLOOR] = true,
    [terrain.DNGN_STONE_STAIRS_UP_I] = true,
    [terrain.DNGN_STONE_STAIRS_DOWN_I] = true,
    [terrain.DNGN_OPEN_DOOR] = true,
}

-- A source marker may precede a substitution that removes its candidate
-- hatch. Only the final stair cell is a live outgoing route.
local function live_source(level, record)
    local row = level.cells[record.y + 1]
    local feature = row and row[record.x + 1]

    return stair_cells[feature] == true
end

-- Collect final named marker positions from the placed, transformed maps.
-- Several outgoing cells can share a name, but destinations are unique.
local function collect(levels)
    local sources = {}
    local destinations = {}

    for _, level in ipairs(levels) do
        for _, record in ipairs(level.vault_records) do
            local arguments = record.arguments or {}
            local name = arguments.hatch_name

            if record.kind == effects.MARKER and name then
                local endpoint = {
                    level = level,
                    x = record.x,
                    y = record.y,
                }

                if arguments.hatch_kind == "name" then
                    if live_source(level, record) then
                        sources[name] = sources[name] or {}
                        sources[name][#sources[name] + 1] = endpoint
                    end
                elseif arguments.hatch_kind == "dest" then
                    if destinations[name] then
                        error("Tomb hatch " .. name ..
                            " has duplicate destination markers")
                    end

                    destinations[name] = endpoint
                else
                    error("Tomb hatch " .. name .. " has invalid kind")
                end
            end
        end
    end

    return sources, destinations
end

-- Verify source directions now, before a modded route can enter the save.
-- Attach links without reciprocals; that asymmetry defines Tomb's layout.
function hatches.resolve(levels)
    local sources, destinations = collect(levels)
    local count = 0

    for name, exits in pairs(sources) do
        local destination = destinations[name]

        if not destination then
            local available = {}

            for key in pairs(destinations) do
                available[#available + 1] = key
            end

            table.sort(available)
            error("Tomb hatch " .. name .. " has no destination; found " ..
                table.concat(available, ","))
        end

        local row = destination.level.cells[destination.y + 1]
        local feature = row and row[destination.x + 1]

        if not landing_cells[feature] then
            error("Tomb hatch " .. name .. " has blocked destination")
        end

        for _, source in ipairs(exits) do
            local source_feature = source.level.cells[source.y + 1][source.x + 1]
            local direction = source_feature ==
                terrain.DNGN_STONE_STAIRS_DOWN_I and 1 or -1
            local expected_depth = source.level.local_depth + direction

            if destination.level.local_depth ~= expected_depth then
                error("Tomb hatch " .. name ..
                    " has a destination on the wrong depth")
            end

            local occupied = false

            for _, link in ipairs(source.level.stairs) do
                if link.x == source.x and link.y == source.y then
                    occupied = true
                    break
                end
            end

            if occupied then
                error("Tomb hatch " .. name .. " has duplicate source")
            end

            source.level.stairs[#source.level.stairs + 1] = {
                x = source.x,
                y = source.y,
                to_level_id = destination.level.id,
                to_x = destination.x,
                to_y = destination.y,
                unavailable = "",
            }
            count = count + 1
        end
    end

    return count
end

return hatches
