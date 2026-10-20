-- Theory of operation: Layer Cave paints a narrow, branching first noise
-- field, then optionally overlays a larger shape in either rock or floor.
-- Its source validator rejects maps with too little playable area, so this
-- hook retries whole candidates before the shared region and stair passes.
local grid = require("policy.generation.grid")
local cell_graph = require("policy.generation.layouts.cell_graph")
local material = require("policy.generation.layouts.material")
local noise = require("policy.generation.layouts.procedural_noise")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

local minimum_floor = grid.width * grid.height / 10
local maximum_attempts = 8

-- A twisted absolute simplex field produces narrow corridors; the Worley
-- alternative produces straight-edged branches. Both fade at the map rim.
local function primary_field(builder)
    if builder:one_in(2) then
        local scale = subdivision.real(builder, 0.5, 1)

        return {
            kind = "twist",
            limit = 0.2,
            source = noise.simplex(builder, scale, false),
        }
    end

    local scale = subdivision.real(builder, 0.2, 0.4)

    return {
        kind = "angular",
        limit = 0.3,
        source = noise.worley(builder, scale),
    }
end

-- Evaluate the first field and add the source eight-cell rock border.
local function primary_value(field, x, y)
    local value

    if field.kind == "twist" then
        value = math.abs(noise.simplex_at(field.source, x, y))
    else
        value = noise.worley_at(field.source, x, y)
    end

    return value + noise.border(x, y, 8, false) * field.limit
end

-- Render the source's full first pass before choosing an optional overlay.
local function paint_primary(builder, field)
    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            if primary_value(field, x, y) < field.limit then
                builder:set(x, y, ".")
            end
        end
    end
end

-- One of four equal-weight choices leaves the first pass alone. The others
-- draw blobby rooms, angular pockets, or a large central cavern.
local function secondary_field(builder, choice)
    if choice == 0 then
        return nil
    elseif choice == 1 then
        local limit = subdivision.real(builder, 0.2, 0.4)
        local scale = subdivision.real(builder, 0.2, 0.4)

        return {
            kind = "blob",
            limit = limit,
            source = noise.simplex(builder, scale, true),
        }
    elseif choice == 2 then
        local scale = subdivision.real(builder, 0.02, 0.1)

        return {
            kind = "angular",
            limit = 0.5,
            source = noise.worley(builder, scale),
        }
    end

    local scale = subdivision.real(builder, 0.4, 0.8)

    return {
        kind = "central",
        limit = 0.8,
        source = noise.worley(builder, scale),
    }
end

-- Use the source's field combination for each overlay type. The border
-- term suppresses islands at the edge regardless of its rock/floor glyph.
local function secondary_value(field, x, y)
    local value

    if field.kind == "blob" then
        value = noise.simplex_at(field.source, x, y)
    elseif field.kind == "angular" then
        value = 1 - noise.worley_at(field.source, x, y)
    else
        local radius = math.min(grid.width, grid.height) / 3

        value = noise.distance(x, y, grid.width / 2,
            grid.height / 2, radius) +
            noise.worley_at(field.source, x, y)
    end

    return value + noise.border(x, y, 8, false) * field.limit
end

-- Source overlays replace cells only below their field limit. A rock
-- overlay narrows passages; a floor overlay connects larger cave chambers.
local function paint_secondary(builder, field, glyph)
    if not field then
        return
    end

    for x = 1, grid.width - 2 do
        for y = 1, grid.height - 2 do
            if secondary_value(field, x, y) < field.limit then
                builder:set(x, y, glyph)
            end
        end
    end
end

-- Preserve the source draw order: choose overlay shape, then whether it
-- adds rock or floor, then construct any chosen noise field.
local function candidate(builder)
    paint_primary(builder, primary_field(builder))

    local choice = builder:roll(4)
    local glyph = builder:one_in(2) and "#" or "."
    local field = secondary_field(builder, choice)

    paint_secondary(builder, field, glyph)
    cell_graph.keep_largest_region(builder)
end

-- The source validator requires over ten percent traversable map area.
-- Counting after region cleanup prevents isolated noise specks from passing.
local function enough_floor(builder)
    local count = 0

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            if builder:cell(x, y) == "." then
                count = count + 1
            end
        end
    end

    return count > minimum_floor
end

-- The named DES validator keeps the source minimum visible to the catalog.
-- The run hook already retries small candidates before returning one.
function layout.validate(result)
    return enough_floor(result.builder)
end

-- Run the source DES hook. Failed source-size candidates consume their
-- draws and retry, while a persistent failure remains an explicit error.
function layout.layout_layer_cave(api)
    for attempt = 1, maximum_attempts do
        local builder = grid.new(api.ctx)

        candidate(builder)

        if enough_floor(builder) then
            material.caves(builder, api)

            if builder.bad_random then
                error("Layer Cave random source failed to provide a bounded draw")
            end

            return {
                rows = builder:rows(),
                builder = builder,
                attempts = attempt,
            }
        end
    end

    error("Layer Cave did not meet the source minimum floor area")
end

return layout
