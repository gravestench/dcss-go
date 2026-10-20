-- Onion City is the last map in the source layout_city.des family. Its
-- branch metadata and real nested-room geometry must survive catalog loading.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local features = require("content.terrain_features")
local harness = require("tests.harness")
local weight = require("policy.generation.vaults.weight")

local test = {}
local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- A deterministic stream tests the production layout entry point without
-- making a branch-only layout depend on live branch travel.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "Onion City stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- A city with many visually plausible rooms is still broken if one room
-- cannot be reached. Count every open cell from the first floor cell.
local function reachable_cells(rows)
    local open = {}
    local start

    for y, row in ipairs(rows) do
        for x = 1, #row do
            local glyph = row:sub(x, x)

            if glyph == "." or glyph == "+" or glyph == "~" or
                glyph == "{" or glyph == "(" or glyph == "[" or
                glyph == "}" or glyph == ")" or glyph == "]" then
                local key = y * 80 + x

                open[key] = true
                start = start or { x = x, y = y }
            end
        end
    end

    local visited = {}
    local queue = { start }
    local front = 1

    visited[start.y * 80 + start.x] = true

    while front <= #queue do
        local point = queue[front]

        front = front + 1

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local key = y * 80 + x

            if open[key] and not visited[key] then
                visited[key] = true
                queue[#queue + 1] = { x = x, y = y }
            end
        end
    end

    local total = 0

    for _ in pairs(open) do
        total = total + 1
    end

    return #queue, total
end

-- Source Elf and Pan weights should select a city that contains many
-- nested rooms, entrance doors, and the shared connected stair postpass.
function test.run()
    local definition = catalog.get("layout_onion_city")

    harness.equal(weight.for_branch(definition,
        branches.BRANCH_ELF), 10, "Elf Onion City weight")
    harness.equal(weight.for_branch(definition,
        branches.BRANCH_PANDEMONIUM), 5, "Pan Onion City weight")

    for _, branch in ipairs({
        branches.BRANCH_ELF,
        branches.BRANCH_PANDEMONIUM,
    }) do
        local result = catalog.execute(context_for(7291),
            definition, branch, 2)
        local doors = 0
        local clear_doors = 0

        harness.truthy(#result.stairs >= 3,
            "Onion City has connected stairs")
        harness.truthy(result.room_count >= 4,
            "Onion City recursively creates rooms")

        for _, row in ipairs(result.rows) do
            for glyph in row:gmatch(".") do
                if glyph == "+" or glyph == "~" then
                    doors = doors + 1
                end

                if glyph == "~" then
                    clear_doors = clear_doors + 1
                end
            end
        end

        harness.truthy(doors >= 4,
            "Onion City leaves several room entrances")
        harness.truthy(#features.decode_source_rows(result.rows) > 0,
            "every Onion City cell decodes to terrain")

        local reached, total = reachable_cells(result.rows)

        harness.equal(reached, total,
            "all Onion City rooms remain reachable")

        if branch == branches.BRANCH_ELF then
            harness.truthy(clear_doors > 0,
                "Elf Onion City adds clear doors")
        else
            harness.equal(clear_doors, 0,
                "Pan Onion City keeps opaque doors")
        end
    end
end

return test
