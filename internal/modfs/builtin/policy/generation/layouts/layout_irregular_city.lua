-- Theory of operation: Irregular City first carves one broad street area
-- within a divided outer wall. Three stages then try progressively smaller
-- buildings, rejecting sites that touch an existing wall or door. Each
-- accepted building uses the same irregular-box primitive as the source;
-- later solid blocks and varied wall materials give the city its texture.
local grid = require("policy.generation.grid")
local irregular_box = require("policy.generation.layouts.irregular_box")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

local stages = {
    {
        minimum = 15,
        maximum = 40,
        doors = 8,
        solid_percent = 0,
        inset = 6,
    },
    {
        minimum = 6,
        maximum = 18,
        doors = 4,
        solid_percent = 10,
        inset = 5,
    },
    {
        minimum = 4,
        maximum = 10,
        doors = 2,
        solid_percent = 40,
        inset = 3,
    },
}

-- Keep a single wall material across the blank map and outer street wall.
-- Source weights ordinary rock seven times as strongly as stone or metal.
local function base_material(builder, branch)
    if branch == "Dis" then
        return "#"
    end

    local draw = builder:roll(10)

    if draw < 7 then
        return "#"
    elseif draw < 9 then
        return "c"
    end

    return "v"
end

-- A building may reuse the city material or receive rock, stone, metal,
-- or a rare crystal wall. This is one source weighted draw per accepted
-- building, not a per-cell random choice.
local function building_material(builder, branch, base, frequency)
    if branch == "Dis" then
        return "#"
    end

    local draw = builder:roll(frequency + 101)

    if draw < frequency then
        return base
    end

    draw = draw - frequency

    if draw < 50 then
        return "#"
    elseif draw < 80 then
        return "c"
    elseif draw < 100 then
        return "v"
    end

    return "b"
end

-- The source extend_map fills the whole builder before its outer box.
-- This preserves the chosen rock material even outside the street area.
local function fill_map(builder, glyph)
    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            builder:set(x, y, glyph)
        end
    end
end

-- The first irregular box provides open ground for later buildings. Its
-- large inset produces a ragged edge without closing off the central city.
local function outer_box(builder, wall)
    irregular_box.carve(builder, {
        x1 = 5,
        y1 = 5,
        x2 = grid.width - 6,
        y2 = grid.height - 6,
        div_x = math.floor(grid.width / 6),
        div_y = math.floor(grid.height / 6),
        in_x = 8,
        in_y = 8,
        doors = 0,
        wall = wall,
        floor = ".",
    })
end

-- Early city stages are optional. Stage three always makes hundreds of
-- attempts, which lets small buildings occupy the gaps left by large ones.
local function stage_ends(builder)
    local first = 0

    if builder:one_in(2) then
        first = subdivision.range(builder, 10, 25)
    end

    local second = first

    if builder:chance_in(2, 3) then
        second = second + subdivision.range(builder, 50, 200)
    end

    return {
        first,
        second,
        second + subdivision.range(builder, 500, 1000),
    }
end

-- Source find_in_area rejects a candidate when its one-cell padded box
-- contains an existing wall or door. Existing open street is required.
local function blocked(builder, x, y, width, height)
    for check_y = y - 1, y + height + 1 do
        for check_x = x - 1, x + width + 1 do
            local glyph = builder:cell(check_x, check_y)

            if glyph == "#" or glyph == "c" or glyph == "v" or
                glyph == "b" or glyph == "+" then
                return true
            end
        end
    end

    return false
end

-- An accepted site receives source-sized walls, a variable number of
-- doors, and sometimes a solid stone block in later stages.
local function place_building(builder, branch, base, frequency,
    stage, x, y, width, height)
    local door_count = subdivision.range(builder, 1, stage.doors)
    local wall = building_material(builder, branch, base, frequency)
    local floor = "."

    if builder:chance_in(stage.solid_percent, 100) then
        door_count = 0
        floor = wall
    end

    irregular_box.carve(builder, {
        x1 = x,
        y1 = y,
        x2 = x + width,
        y2 = y + height,
        div_x = math.floor(width / subdivision.range(builder, 4, 8)),
        div_y = math.floor(height / subdivision.range(builder, 4, 8)),
        in_x = stage.inset,
        in_y = stage.inset,
        doors = door_count,
        wall = wall,
        floor = floor,
    })

    return {
        x = x,
        y = y,
        width = width,
        height = height,
        solid = floor == wall,
    }
end

-- Each stage samples its source size and position even when blocked. The
-- rejection keeps buildings separated by at least one open street cell.
local function populate(builder, branch, base, frequency)
    local ends = stage_ends(builder)
    local rooms = {}
    local stage_index = 1

    for attempt = 1, ends[3] do
        while attempt > ends[stage_index] do
            stage_index = stage_index + 1
        end

        local stage = stages[stage_index]
        local width = subdivision.range(builder,
            stage.minimum, stage.maximum)
        local height = subdivision.range(builder,
            stage.minimum, stage.maximum)
        local x = subdivision.range(builder, 8,
            grid.width - 9 - width)
        local y = subdivision.range(builder, 8,
            grid.height - 9 - height)

        if not blocked(builder, x, y, width, height) then
            rooms[#rooms + 1] = place_building(builder, branch,
                base, frequency, stage, x, y, width, height)
        end
    end

    return rooms
end

-- Run the named DES hook and expose its accepted buildings so tests can
-- distinguish actual city placement from a generic fallback layout.
function layout.layout_irregular_city(api)
    local builder = grid.new(api.ctx)
    local base = base_material(builder, api.branch)
    local frequency = subdivision.range(builder, 0, 900)

    fill_map(builder, base)
    outer_box(builder, base)

    local rooms = populate(builder, api.branch, base, frequency)

    if builder.bad_random then
        error("Irregular City random source failed to provide a bounded draw")
    end

    return {
        rows = builder:rows(),
        builder = builder,
        rooms = rooms,
    }
end

return layout
