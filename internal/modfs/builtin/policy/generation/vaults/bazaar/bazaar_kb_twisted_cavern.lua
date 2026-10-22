-- Theory of operation: the source map delves 150 narrow cavern cells,
-- places one marker on a random open cell, then repeatedly places another
-- at the farthest reachable floor. Two markers become entry and exit;
-- the others become shops. The local map is generated only after this
-- source map wins the effective weighted Bazaar draw.
local delve = require("policy.generation.layouts.delve")
local directives = require("constants.vault_directives")
local shared = require("policy.generation.vaults.bazaar.shared")

local handler = {}
local width = 80
local height = 70

local directions = {
    { x = -1, y = -1 },
    { x = 0, y = -1 },
    { x = 1, y = -1 },
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = -1, y = 1 },
    { x = 0, y = 1 },
    { x = 1, y = 1 },
}

-- Delve's existing source algorithm reads a small grid interface. This
-- local view writes into the hook's actual DES cells, so there is no second
-- map that could drift from the placed terrain.
local function carve_view(api)
    local builder = {
        width = width,
        height = height,
    }

    function builder:cell(x, y)
        return api:cell(x, y)
    end

    function builder:set(x, y, glyph)
        api:set_cell(x, y, glyph)
    end

    function builder:roll(bound)
        return api:roll(bound)
    end

    function builder:chance_in(chance, total)
        return api:chance(chance, total)
    end

    return builder
end

-- List open cells before the first source nsubst draw. The initial marker
-- must exist on floor so every later farthest-from search is reachable.
local function open_cells(api)
    local cells = {}

    for y = 1, height - 2 do
        for x = 1, width - 2 do
            if api:cell(x, y) == "." then
                cells[#cells + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return cells
end

-- Flood from every existing marker and take a farthest open cell. Ties
-- use the hook RNG, preserving one bounded draw for the source choice.
local function farthest(api, markers)
    local queue = {}
    local distance = {}
    local first = 1

    for _, point in ipairs(markers) do
        local key = point.y * width + point.x

        queue[#queue + 1] = point
        distance[key] = 0
    end

    local farthest_cells = {}
    local greatest = -1

    while first <= #queue do
        local point = queue[first]
        local step = distance[point.y * width + point.x]

        first = first + 1

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y

            if x > 0 and x < width - 1 and
                y > 0 and y < height - 1 and
                api:cell(x, y) == "." then
                local key = y * width + x

                if not distance[key] then
                    local next_step = step + 1

                    distance[key] = next_step
                    queue[#queue + 1] = {
                        x = x,
                        y = y,
                    }

                    if next_step > greatest then
                        greatest = next_step
                        farthest_cells = {}
                    end

                    if next_step == greatest then
                        farthest_cells[#farthest_cells + 1] = {
                            x = x,
                            y = y,
                        }
                    end
                end
            end
        end
    end

    if #farthest_cells == 0 then
        error("generated Bazaar cavern has no distant shop site")
    end

    return farthest_cells[api:roll(#farthest_cells) + 1]
end

-- Nsubst's source order chooses one initial marker, five or six distant
-- sites, then one entry and one exit from the marked sites.
local function place_sites(api)
    local floor = open_cells(api)

    if #floor < 7 then
        error("generated Bazaar cavern has too little open floor")
    end

    local first = floor[api:roll(#floor) + 1]
    local markers = { first }

    api:set_cell(first.x, first.y, "C")

    local added = 5 + api:roll(2)

    for _ = 1, added do
        local point = farthest(api, markers)

        markers[#markers + 1] = point
        api:set_cell(point.x, point.y, "C")
    end

    local entry = table.remove(markers, api:roll(#markers) + 1)
    local exit = table.remove(markers, api:roll(#markers) + 1)

    api:set_cell(entry.x, entry.y, "<")
    api:set_cell(exit.x, exit.y, ">")
end

-- The source calls delve(3, 3, 0, 150, 1). Keep those five values here
-- because they define this map's distinctive winding shape.
local function generate(api)
    api:resize(width, height, "x")

    local builder = carve_view(api)

    delve.carve(builder, 3, 3, 0, 150, 1)
    place_sites(api)

    api:emit(directives.KFEAT, "C = any shop")
    shared.setup(api)
end

handler.generate = generate

return handler
