-- Theory of operation: Diamond Mine chooses a room radius, then samples a
-- square lattice with a preference for its center. Each accepted diamond
-- contributes concentric rock, wall-edge, floor, and rough-edge bands.
-- A source smear erodes the outer bands before the temporary glyphs become
-- terrain; a small spotty pass then softens the surviving mine chambers.
local grid = require("policy.generation.grid")
local material = require("policy.generation.layouts.material")
local regions = require("policy.generation.layouts.cell_graph")
local spotty = require("policy.generation.layouts.spotty")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- Counts of the source GLYPH_BY_RADIUS bands. The rest of each radius is
-- the colon edge, which becomes floor only after the rock smear has run.
local radius_options = {
    [4] = { core = 1, edge = 1, floor = 2, spacing = 6, across = 10 },
    [5] = { core = 1, edge = 1, floor = 2, spacing = 6, across = 10 },
    [6] = { core = 2, edge = 1, floor = 2, spacing = 8, across = 7 },
    [7] = { core = 2, edge = 2, floor = 2, spacing = 8, across = 7 },
    [8] = { core = 2, edge = 2, floor = 2, spacing = 10, across = 5 },
    [9] = { core = 2, edge = 2, floor = 3, spacing = 12, across = 4 },
    [10] = { core = 2, edge = 3, floor = 3, spacing = 12, across = 4 },
    [11] = { core = 2, edge = 3, floor = 4, spacing = 14, across = 3 },
    [12] = { core = 3, edge = 2, floor = 4, spacing = 16, across = 3 },
    [13] = { core = 3, edge = 3, floor = 4, spacing = 16, across = 3 },
    [14] = { core = 3, edge = 3, floor = 4, spacing = 16, across = 3 },
    [15] = { core = 4, edge = 3, floor = 4, spacing = 18, across = 3 },
}

local priority = {
    c = 0,
    ["-"] = 1,
    ["."] = 2,
    [":"] = 3,
    ["#"] = 4,
}

-- The source's random_real affects both radius and population fraction.
-- A six-digit draw shares the normal saved layout stream.
local function real(builder)
    return builder:roll(1000000) / 1000000
end

-- The radius range expands toward Orc's bottom but always remains in the
-- source's four-through-fifteen lookup table.
local function choose_radius(builder, api)
    local fraction = (api.depth - 1) /
        math.max(1, api.branch_bottom - 1)
    local radius = math.floor(8.5 + fraction * 3 +
        real(builder) * 4 - real(builder) * 4)

    return math.max(4, math.min(15, radius))
end

-- Lower-priority glyphs replace an older diamond's edge, so overlapping
-- rooms keep their dense center and never lose it to an outer smear band.
local function draw_diamond(builder, center_x, center_y, radius, options)
    for dx = -radius, radius do
        for dy = -radius, radius do
            local distance = math.abs(dx) + math.abs(dy)

            if distance <= radius then
                local glyph = ":"

                if distance < options.core then
                    glyph = "c"
                elseif distance < options.core + options.edge then
                    glyph = "-"
                elseif distance < options.core + options.edge +
                    options.floor then
                    glyph = "."
                end

                local x = center_x + dx
                local y = center_y + dy
                local old = builder:cell(x, y)

                if old and priority[glyph] < priority[old] then
                    builder:set(x, y, glyph)
                end
            end
        end
    end
end

-- The source gives equal chance to each lattice cell but rejects sites
-- with a quadratic superellipse falloff. The accepted-room quota bounds
-- the final density more reliably than one independent draw per site.
local function place_rooms(builder, api, radius, options)
    local across = options.across
    local center = (across - 1) / 2
    local total = across * across
    local fraction = api.depth == api.branch_bottom and
        0.4 + real(builder) * 0.2 or
        0.3 + real(builder) * 0.1
    local target = math.floor(total * fraction)
    local accepted = {}
    local count = 0

    for _ = 1, total * 10 do
        if count >= target then
            break
        end

        local column = builder:roll(across)
        local row = builder:roll(across)
        local key = row * across + column

        if not accepted[key] then
            local offset_x = column / center - 1
            local offset_y = row / center - 1
            local distance = math.sqrt(offset_x ^ 4 + offset_y ^ 4)
            local chance = 0.8 - 0.3 * distance * distance

            if real(builder) < chance then
                local x = grid.width / 2 +
                    math.floor((column - center) * options.spacing)
                local y = grid.height / 2 +
                    math.floor((row - center) * options.spacing)

                draw_diamond(builder, x, y, radius, options)
                accepted[key] = true
                count = count + 1
            end
        end
    end

    return count
end

-- Source substitutions turn the core into rock and the first edge band
-- into temporary colon. Smearing then makes some colon cells rock before
-- the remaining colon becomes floor.
local function settle_glyphs(builder)
    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local glyph = builder:cell(x, y)

            if glyph == "c" then
                builder:set(x, y, "#")
            elseif glyph == "-" then
                builder:set(x, y, ":")
            end
        end
    end

    spotty.smear(builder, subdivision.range(builder, 300, 500),
        true, ":", "#")

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == ":" then
                builder:set(x, y, ".")
            end
        end
    end

    if builder:one_in(2) then
        spotty.carve(builder, false,
            subdivision.range(builder, 50, 100))
    end
end

-- Nonbottom Orc keeps up to three floor bubbles of at least twenty cells.
-- Source substitutions mark a down stair in each bubble, then shuffle the
-- three glyph variants. The first Orc floor also authors its up stair.
local function keep_playable_regions(builder, api)
    if api.depth == api.branch_bottom then
        regions.keep_largest_region(builder)

        return
    end

    local kept = regions.keep_regions(builder, 3, 20)
    local down = { "}", ")", "]" }

    for index = #down, 2, -1 do
        local other = builder:roll(index) + 1

        down[index], down[other] = down[other], down[index]
    end

    for index, region in ipairs(kept) do
        local point = region[builder:roll(#region) + 1]

        builder:set(point.x, point.y, down[index])
    end

    if api.depth == 1 and kept[1] then
        local region = kept[1]

        for _ = 1, #region do
            local point = region[builder:roll(#region) + 1]

            if builder:cell(point.x, point.y) == "." then
                builder:set(point.x, point.y, "{")

                break
            end
        end
    end
end

-- NARROW_CAVES in the source rejects fewer than ten percent floor cells.
function layout.validate(result)
    local floor = 0

    for _, row in ipairs(result.builder:rows()) do
        for glyph in row:gmatch(".") do
            if glyph == "." then
                floor = floor + 1
            end
        end
    end

    return floor > grid.width * grid.height * 0.1
end

-- Execute the named DES hook using source radii, lattice density, and
-- temporary-glyph substitutions; the catalog adds paired stairs later.
function layout.layout_diamond_mine(api)
    local builder = grid.new(api.ctx)
    local radius = choose_radius(builder, api)
    local options = radius_options[radius]
    local count = place_rooms(builder, api, radius, options)

    settle_glyphs(builder)
    keep_playable_regions(builder, api)
    material.caves(builder, api)

    if builder.bad_random then
        error("Diamond Mine random source failed to provide a bounded draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        radius = radius,
        room_count = count,
    }
end

return layout
