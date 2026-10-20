-- Theory of operation: this source layout opens one clipped octagonal room,
-- optionally smears its boundary, and puts rings of weighted-material pillars
-- around its center. It authors all six ordinary stair glyphs in one of six
-- regions. The minimum-area validation rejects overly obstructed results.
local grid = require("policy.generation.grid")
local spotty = require("policy.generation.layouts.spotty")
local material = require("policy.generation.layouts.material")
local glyphs = require("constants.vault_glyphs")

local layout = {}

local cardinal = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

local up_stairs = { "{", "(", "[" }
local down_stairs = { "}", ")", "]" }

-- Clip each corner by the source oblique offset before anything can place a
-- pillar. The source rectangle is inclusive and starts ten cells from edges.
local function carve_octagon(builder, oblique)
    local left = 10
    local top = 10
    local right = grid.width - 10
    local bottom = grid.height - 10

    for y = top, bottom do
        for x = left, right do
            local cut = math.max(oblique + left - x, 0) +
                math.max(oblique + x - right, 0)

            if y >= top + cut and y <= bottom - cut then
                builder:set(x, y, ".")
            end
        end
    end
end

-- Flood from the center after smearing and rock-fill any isolated floor.
-- This mirrors the source's temporary @ anchor without storing it in rows.
local function keep_center_region(builder)
    local center = {
        x = math.floor(grid.width / 2),
        y = math.floor(grid.height / 2),
    }
    local visited = {}
    local queue = { center }
    local first = 1

    builder:set(center.x, center.y, ".")
    visited[center.y * grid.width + center.x] = true

    while first <= #queue do
        local point = queue[first]
        first = first + 1

        for _, direction in ipairs(cardinal) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local key = y * grid.width + x

            if builder:inside({ x = x, y = y }) and
                not visited[key] and builder:cell(x, y) == "." then
                visited[key] = true
                queue[#queue + 1] = { x = x, y = y }
            end
        end
    end

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == "." and not visited[y * grid.width + x] then
                builder:set(x, y, "#")
            end
        end
    end
end

-- The source pillar choices are weighted by material. Their glyphs survive
-- through the shared DES terrain decoder, including water and lava pillars.
local function pillar_material(builder, lair)
    local total = lair and 45 or 30
    local draw = builder:roll(total)

    if draw < 15 then
        return "#"
    elseif draw < 20 then
        return "b"
    elseif draw < 24 then
        return "v"
    elseif draw < 27 then
        return "m"
    elseif draw < 29 then
        return "w"
    elseif draw < 30 then
        return "l"
    end

    return "t"
end

-- Paint one source pillar shape. Shape two is a diamond, while the fourth
-- omits only the extreme square corners.
local function pillar(builder, center_x, center_y, radius, shape, glyph)
    for dy = -radius, radius do
        for dx = -radius, radius do
            local inside = false

            if shape == 1 then
                inside = dx * dx + dy * dy < (radius + 0.5) ^ 2
            elseif shape == 2 then
                inside = math.abs(dx) + math.abs(dy) <= radius
            elseif shape == 3 then
                inside = true
            else
                inside = math.abs(dx) ~= radius or math.abs(dy) ~= radius
            end

            local x = center_x + dx
            local y = center_y + dy

            if inside and builder:inside({ x = x, y = y }) then
                builder:set(x, y, glyph)
            end
        end
    end
end

-- Later rings grow in radius so pillars stay spaced from the center. The
-- source's missing operator in its `num` expression is treated as a plus:
-- three plus twice the ring index plus a bounded extra count.
local function pillar_rings(builder, oblique, lair)
    local count = 1 + builder:roll(4)
    local radius = 2 + builder:roll(count == 1 and 6 or 3)
    local center_x = math.floor(grid.width / 2)
    local center_y = math.floor(grid.height / 2)

    for ring = 1, count do
        local shape = 1 + builder:roll(4)
        local number = 3 + 2 * ring + builder:roll(9 - 2 * ring)
        local pillar_radius = 1 + builder:roll(shape == 2 and 3 or 2)

        radius = radius + pillar_radius * 2 + number / 2

        if radius >= (grid.height - oblique) / 2 then
            break
        end

        local material = pillar_material(builder, lair)

        for index = 1, number do
            local angle = index * 2 * math.pi / number
            local x = center_x + math.floor(math.cos(angle) * math.floor(radius) + 0.5)
            local y = center_y + math.floor(math.sin(angle) * math.floor(radius) + 0.5)

            pillar(builder, x, y, pillar_radius, shape, material)
        end
    end
end

-- Choose one floor cell uniformly for the source's unconstrained stair
-- location. Already authored exits are no longer plain floor candidates.
local function random_floor(builder, glyph)
    local floor = {}

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == "." then
                floor[#floor + 1] = { x = x, y = y }
            end
        end
    end

    if #floor == 0 then
        error("octagon has no floor for authored stair")
    end

    local point = floor[builder:roll(#floor) + 1]
    builder:set(point.x, point.y, glyph)
end

-- Edge regions scan inward until they find ordinary floor. Unlike random
-- replacement, this preserves the source's directional stair grouping.
local function first_floor(builder, x, y, dx, dy, glyph)
    while x >= 0 and x < grid.width and y >= 0 and y < grid.height do
        if builder:cell(x, y) == "." then
            builder:set(x, y, glyph)
            return
        end

        x = x + dx
        y = y + dy
    end

    error("octagon has no floor on a source stair ray")
end

-- A source location names random floor, center, or one of four edges.
-- Center placement is deliberately direct, as in the original script.
local function place_at(builder, location, index, glyph)
    local middle_x = math.floor(grid.width / 2)
    local middle_y = math.floor(grid.height / 2)
    local offset = index - 2

    if location == 0 then
        random_floor(builder, glyph)
    elseif location == 1 then
        builder:set(middle_x + offset, middle_y + 1 - math.abs(offset), glyph)
    elseif location == 2 then
        first_floor(builder, middle_x + offset, 0, 0, 1, glyph)
    elseif location == 3 then
        first_floor(builder, grid.width - 1, middle_y + offset, -1, 0, glyph)
    elseif location == 4 then
        first_floor(builder, middle_x + offset, grid.height - 1, 0, -1, glyph)
    else
        first_floor(builder, 0, middle_y + offset, 1, 0, glyph)
    end
end

-- Half the source floors group each stair direction in one region; the
-- other half distribute all six variants to distinct regions.
local function place_stairs(builder)
    local locations = {}

    if builder:roll(2) == 0 then
        local up = builder:roll(6)
        local down = builder:roll(5)

        if down >= up then
            down = down + 1
        end

        locations[up] = up_stairs
        locations[down] = down_stairs
    else
        local remaining = { 0, 1, 2, 3, 4, 5 }
        local variants = { "{", "}", "(", ")", "[", "]" }

        for _, glyph in ipairs(variants) do
            local position = builder:roll(#remaining) + 1
            local location = table.remove(remaining, position)

            locations[location] = { glyph }
        end
    end

    for location = 0, 5 do
        for index, glyph in ipairs(locations[location] or {}) do
            place_at(builder, location, index, glyph)
        end
    end
end

-- Match the source OPEN threshold: more than twenty percent of the whole
-- map must be ordinary floor or an authored stair before accepting it.
function layout.validate(result)
    local count = 0
    local builder = result.builder

    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "." or glyphs.up[glyph] or glyphs.down[glyph] then
                count = count + 1
            end
        end
    end

    return count > grid.width * grid.height / 5
end

-- Run the named DES hook and keep the stair glyphs in its grid for the
-- shared postpass. Failed source validation gets a clear layout error.
function layout.layout_big_octagon(api)
    local builder = grid.new(api.ctx)
    local oblique = 10 + builder:roll(20)
    local do_smear = builder:roll(2) == 0
    local smear_before = builder:roll(2) == 0

    carve_octagon(builder, oblique)

    if do_smear and smear_before then
        spotty.smear(builder, 100 + builder:roll(800))
        keep_center_region(builder)
    end

    pillar_rings(builder, oblique, api.branch == "Lair")

    if do_smear and not smear_before then
        spotty.smear(builder, 100 + builder:roll(800))
        keep_center_region(builder)
    end

    place_stairs(builder)
    material.level(builder, api)

    if builder.bad_random then
        error("octagon random source failed to provide a bounded draw")
    end

    local result = {
        rows = builder:rows(),
        builder = builder,
    }

    if not layout.validate(result) then
        error("octagon does not meet source open-area threshold")
    end

    return result
end

return layout
