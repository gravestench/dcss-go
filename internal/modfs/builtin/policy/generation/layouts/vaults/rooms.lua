-- Theory of operation: Vaults primary layouts assemble a floor from small
-- authored DES maps. This owner discovers their tags through the ordinary
-- vault catalog, selects by source weight in stable ID order, and places a
-- candidate transactionally so a rejected fit cannot damage prior rooms.
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local selection = require("policy.generation.vaults.selection")

local rooms = {}

-- Catalog IDs are already sorted independently of path enumeration. Tags
-- come from the parsed DES map, including source setup expanded in place.
function rooms.ids(tag)
    catalog.load()

    local ids = {}

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = catalog.get(id)

        if definition.tags[tag] then
            ids[#ids + 1] = id
        end
    end

    return ids
end

-- Reuse the ordinary weighted tag selector; it already applies effective
-- depth, mod overlays, and source chance before consuming a random draw.
function rooms.choose(random, tag, context)
    local selected = selection.choose_tag(random, tag, context)

    if not selected then
        return nil
    end

    return catalog.get(selected.id)
end

-- Copy terrain before DES substitutions and keyed effects run. Failed
-- attempts consume their source RNG draws but never publish partial cells.
local function trial(builder)
    local copy = grid.new(builder.ctx)

    for y = 1, grid.height do
        for x = 1, grid.width do
            copy.cells[y][x] = builder.cells[y][x]
        end
    end

    return copy
end

-- A protected collision is an ordinary failed room attempt. Invalid DES
-- instructions remain errors so adding a mod cannot silently drop content.
local function fit_failure(reason)
    return reason:find("invalid exact room origin", 1, true) or
        reason:find("exact room origin overlaps protected terrain", 1, true)
end

-- The layout chooses an exact cell and quarter turn after checking its
-- usable wall. The shared placer still owns substitutions and typed records.
function rooms.place(ctx, builder, id, origin, orientation, protected)
    local definition = catalog.get(id)
    local copy = trial(builder)
    local options = {
        left = origin.x,
        top = origin.y,
        turns = orientation,
        protected = protected,
    }
    local ok, placed = pcall(placement.place, ctx, copy, definition, nil,
        options)

    if not ok then
        if fit_failure(tostring(placed)) then
            return nil
        end

        error(placed)
    end

    builder.cells = copy.cells

    return placed
end

return rooms
