-- Theory of operation: Caves starts three separate down-stair bubbles and
-- grows spotty caverns around them. Orc also puts one up stair beside the
-- first bubble. The source branch bottom keeps only the largest floor
-- region, while ordinary levels may retain smaller reachable bubbles.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local spotty = require("policy.generation.layouts.spotty")
local material = require("policy.generation.layouts.material")

local layout = {}

local downstairs = { "}", ")", "]" }

local passable = {
    ["."] = true,
    ["{"] = true,
    ["}"] = true,
    [")"] = true,
    ["]"] = true,
}

-- Four cardinal cells open around each source stair. Slime widens the
-- bubble with an eight-point ring and omits the paired up stair.
local function stair_bubble(builder, x, y, slime)
    builder:set(x - 1, y, ".")
    builder:set(x + 1, y, ".")
    builder:set(x, y - 1, ".")
    builder:set(x, y + 1, ".")

    if slime then
        for dy = -2, 2 do
            for dx = -2, 2 do
                if dx * dx + dy * dy <= 4 then
                    builder:set(x + dx, y + dy, ".")
                end
            end
        end
    end
end

-- A source spotty stair needs two adjacent untouched rock cells so the
-- first Orc up stair can occupy the cell immediately to its east.
local function place_stairs(builder, slime)
    local bubbles = {}

    for _, glyph in ipairs(downstairs) do
        local x
        local y

        for _ = 1, 1000 do
            x = 5 + builder:roll(grid.width - 10)
            y = 5 + builder:roll(grid.height - 10)

            if builder:cell(x, y) == "#" and
                builder:cell(x + 1, y) == "#" then
                break
            end
        end

        if builder:cell(x, y) ~= "#" then
            error("Caves could not place its source stair bubbles")
        end

        stair_bubble(builder, x, y, slime)
        builder:set(x, y, glyph)
        bubbles[#bubbles + 1] = { x = x, y = y }

        if not slime and glyph == "}" then
            builder:set(x + 1, y, "{")
        end
    end

    return bubbles
end

-- The source uses more spotty growth on a branch bottom and then fills
-- disconnected pockets. Nonbottom levels keep their authored stair bubbles.
local function grow(builder, api)
    local bottom = api.depth == api.branch_bottom
    local iterations

    if bottom then
        iterations = 600 + builder:roll(600)
    else
        iterations = 100 + builder:roll(500)
    end

    spotty.carve(builder, false, iterations)

    if bottom then
        regions.keep_largest_region(builder, passable)
    end
end

-- OPEN_CAVES in the source requires over fifteen percent plain floor.
-- This validator runs before the catalog adds any missing stair pairs.
function layout.validate(result)
    local floor = 0

    for _, row in ipairs(result.builder:rows()) do
        for glyph in row:gmatch(".") do
            if glyph == "." then
                floor = floor + 1
            end
        end
    end

    return floor > grid.width * grid.height * 0.15
end

-- Build source stair bubbles and the spotty cave field in one Lua hook.
function layout.layout_caves(api)
    local builder = grid.new(api.ctx)

    local bubbles = place_stairs(builder, api.branch == "Slime")
    grow(builder, api)
    material.caves(builder, api)

    if builder.bad_random then
        error("Caves random source failed to provide a bounded draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        bubbles = bubbles,
    }
end

return layout
