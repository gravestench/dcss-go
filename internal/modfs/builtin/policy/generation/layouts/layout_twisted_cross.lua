-- Theory of operation: four disjoint temporary wall alphabets let each
-- Depths arm be carved independently. Four of six arm styles are shuffled
-- into the quarters, then a central cross joins them and owns an up stair.
-- The source validator rejects maps with too little traversable area.
local grid = require("policy.generation.grid")
local delve = require("policy.generation.layouts.delve")
local shapes = require("policy.generation.layouts.delve_shapes")

local layout = {}
local quarters = { "c", "v", "m", "n" }
-- Each row is one of the four source digger motifs. The other two motifs
-- are straight arms, painted separately with an optional end room.
local delved_arms = {
    {
        minimum = 3,
        maximum = 3,
        connection = 0,
        first = 200,
        last = 400,
        top = 1,
    },
    {
        minimum = 3,
        maximum = 4,
        connection = 0,
        first = 250,
        last = 500,
        top = 1,
    },
    {
        minimum = 2,
        maximum = 4,
        connection = 10,
        first = 150,
        last = 250,
        top = 1,
    },
    {
        minimum = 2,
        maximum = 3,
        connection = 25,
        first = 200,
        last = 300,
        top = 10000,
    },
}

-- A thick diagonal X divides the quarters so one delve call cannot eat
-- another arm's wall cells. The outer rim stays reserved as well.
local function partition(builder, center_x, center_y)
    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            local dx = x - center_x
            local dy = y - center_y
            local ax = math.abs(dx)
            local ay = math.abs(dy)
            local glyph

            if math.abs(ax - ay) < 2 then
                glyph = "X"
            elseif ax > ay then
                glyph = dx < 0 and "c" or "v"
            else
                glyph = dy < 0 and "m" or "n"
            end

            builder:set(x, y, glyph)
        end
    end

    shapes.box(builder, center_x - 6, center_y,
        center_x - 6, center_y, ".")
    shapes.box(builder, center_x + 6, center_y,
        center_x + 6, center_y, ".")
    shapes.box(builder, center_x, center_y - 6,
        center_x, center_y - 6, ".")
    shapes.box(builder, center_x, center_y + 6,
        center_x, center_y + 6, ".")
end

-- Source smear_map retries until it has spread X into 200 quarter cells or
-- has exhausted ten attempts per requested smear. Diagonal contact counts.
local function roughen(builder)
    local changed = 0
    local attempts = 0

    while changed < 200 and attempts < 2000 do
        attempts = attempts + 1

        local x = 1 + builder:roll(builder.width - 2)
        local y = 1 + builder:roll(builder.height - 2)
        local glyph = builder:cell(x, y)

        if glyph == "c" or glyph == "v" or glyph == "m" or glyph == "n" then
            local adjacent = builder:cell(x - 1, y) == "X" or
                builder:cell(x + 1, y) == "X" or
                builder:cell(x, y - 1) == "X" or
                builder:cell(x, y + 1) == "X" or
                builder:cell(x - 1, y - 1) == "X" or
                builder:cell(x + 1, y - 1) == "X" or
                builder:cell(x - 1, y + 1) == "X" or
                builder:cell(x + 1, y + 1) == "X"

            if adjacent then
                builder:set(x, y, "X")
                changed = changed + 1
            end
        end
    end
end

-- A Fisher-Yates draw gives four unique arm motifs without relying on Lua
-- table iteration order or a growing case statement in the catalog.
local function arm_order(builder)
    local order = { 1, 2, 3, 4, 5, 6 }

    for last = #order, 2, -1 do
        local index = builder:roll(last) + 1

        order[last], order[index] = order[index], order[last]
    end

    return order
end

-- Reserve only one quarter for the digger. Uncarved x is sealed before
-- the next quarter becomes active, matching the source substitution cycle.
local function activate(builder, marker)
    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == marker then
                builder:set(x, y, "x")
            end
        end
    end
end

-- Seal unused diggable cells after one arm so its frontier cannot invade
-- the next quarter when a different source motif begins.
local function seal(builder)
    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == "x" then
                builder:set(x, y, "X")
            end
        end
    end
end

-- The two straight motifs end either in a passage or a geometric room.
-- Branch direction determines the arm's axis and distant endpoint.
local function straight_arm(builder, index, center_x, center_y, room)
    local half = 1 + builder:roll(2)
    local length = room and 20 or 25
    local dx = index == 1 and -1 or index == 2 and 1 or 0
    local dy = index == 3 and -1 or index == 4 and 1 or 0
    local end_x = center_x + dx * length
    local end_y = center_y + dy * length

    shapes.box(builder, math.min(center_x, end_x) - (dy ~= 0 and half or 0),
        math.min(center_y, end_y) - (dx ~= 0 and half or 0),
        math.max(center_x, end_x) + (dy ~= 0 and half or 0),
        math.max(center_y, end_y) + (dx ~= 0 and half or 0), ".")

    if room then
        local radius = 4 + builder:roll(4)
        local kind = builder:roll(9)

        if kind < 3 then
            shapes.circle(builder, end_x, end_y, radius, ".")
        elseif kind < 6 then
            shapes.diamond(builder, end_x, end_y, radius, ".")
        elseif kind < 8 then
            shapes.box(builder, end_x - radius, end_y - radius,
                end_x + radius, end_y + radius, ".")
        else
            shapes.round_box(builder, end_x, end_y, radius, ".", ".")
        end
    end
end

-- Each source arm has distinct neighbor thresholds and frontier size.
local function carve_arm(builder, index, motif, center_x, center_y)
    activate(builder, quarters[index])

    local options = delved_arms[motif]

    if options then
        local count = options.first +
            builder:roll(options.last - options.first + 1)

        delve.carve(builder, options.minimum, options.maximum,
            options.connection, count, options.top)
    else
        straight_arm(builder, index, center_x, center_y, motif == 6)
    end

    seal(builder)
end

-- A validator is separate from generation so a sparse random draw can be
-- retried without introducing fallback geometry or changing layout identity.
function layout.validate(result)
    return delve.has_minimum_area(result)
end

-- Finish the diagonal reservation only after the central room has opened
-- all four arms; then retain one connected playable territory.
function layout.generate(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local center_x = math.floor(builder.width / 2)
    local center_y = math.floor(builder.height / 2)
    local motifs = arm_order(builder)

    partition(builder, center_x, center_y)
    roughen(builder)

    for index = 1, 4 do
        carve_arm(builder, index, motifs[index], center_x, center_y)
    end

    shapes.box(builder, center_x - 1, center_y - 5,
        center_x + 1, center_y + 5, ".")
    shapes.box(builder, center_x - 5, center_y - 1,
        center_x + 5, center_y + 1, ".")
    builder:set(center_x, center_y, "{")
    delve.finish(builder)
    delve.keep_largest_region(builder)

    return {
        builder = builder,
        motifs = motifs,
    }
end

return layout
