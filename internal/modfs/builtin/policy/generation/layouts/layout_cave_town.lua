-- Theory of operation: source Hyper first paints one nearly whole-level
-- cave. It then chooses one cave-room style for the entire town and adds
-- one to three large rooms followed by eight to twelve ordinary or small
-- rooms. Every room gets a wall shell and at least one opening onto the
-- existing cave, giving Snake a recognizably built-up floor. The shared
-- region and stair passes finish the level after all rooms are placed.
local grid = require("policy.generation.grid")
local regions = require("policy.generation.layouts.cell_graph")
local material = require("policy.generation.layouts.material")
local noise = require("policy.generation.layouts.procedural_noise")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- Coordinate keys let the room painter check a prospective door without
-- painting a failed candidate over the live primary cave.
local function key(x, y)
    return x .. ":" .. y
end

-- The source cave callbacks use a border relative to each room rather
-- than the entire level. This also accounts for their one-cell margin.
local function room_border(x, y, width, height, padding, additive)
    local near_x = math.min(x + 1, width - x)
    local near_y = math.min(y + 1, height - y)
    local x_value = math.max(0,
        math.min(1, near_x / (padding + 1)))
    local y_value = math.max(0,
        math.min(1, near_y / (padding + 1)))

    if additive then
        return math.min(1, 2 - x_value - y_value)
    end

    return 1 - math.min(x_value, y_value)
end

-- The level's primary room spans almost the entire builder, leaving
-- between one and eleven cells of edge space before later rooms arrive.
local function primary_bounds(builder)
    local width = subdivision.range(builder,
        grid.width - 12, grid.width - 2)
    local height = subdivision.range(builder,
        grid.height - 12, grid.height - 2)
    local x1 = subdivision.range(builder,
        1, grid.width - width - 1)
    local y1 = subdivision.range(builder,
        1, grid.height - height - 1)

    return {
        x1 = x1,
        y1 = y1,
        width = width,
        height = height,
    }
end

-- Source Hyper alternates between a Worley cavern wall and a smoother
-- simplex cave wall. Their border terms prevent floor reaching the rim.
local function paint_primary(builder, bounds)
    local cavern = builder:one_in(2)
    local field
    local threshold
    local padding

    if cavern then
        field = noise.worley(builder, 0.25)
        threshold = subdivision.real(builder, 0.7, 0.9)
        padding = 10
    else
        field = noise.simplex(builder, 2, true)
        padding = math.max(1,
            math.floor(math.min(bounds.width, bounds.height) / 8))
    end

    for local_x = 0, bounds.width - 1 do
        for local_y = 0, bounds.height - 1 do
            local border = room_border(local_x, local_y,
                bounds.width, bounds.height, padding, not cavern)
            local value

            if cavern then
                value = noise.worley_at(field, local_x, local_y) + border
            else
                value = noise.simplex_at(field, local_x, local_y) +
                    border * 2
            end

            if (cavern and value < threshold) or
                (not cavern and value <= 1) then
                builder:set(bounds.x1 + local_x,
                    bounds.y1 + local_y, ".")
            end
        end
    end
end

-- One source draw fixes the painter for all later rooms. The common cave
-- version also selects its scale and border padding once per level.
local function choose_style(builder)
    if builder:one_in(4) then
        return { kind = "cavern" }
    end

    return {
        kind = "cave",
        scale = subdivision.real(builder, 3, 5),
        padding = subdivision.real(builder, 0.5, 2),
    }
end

-- Source Rooms1 uses only large huts. Rooms2 weights ordinary versus
-- small huts 15:10, then draws both dimensions independently.
local function room_size(builder, kind)
    local first
    local second
    local third

    if kind == "big" then
        first, second, third = 7, 9, 7
    elseif kind == "normal" then
        first, second, third = 5, 7, 5
    else
        first, second, third = 4, 4, 3
    end

    return first + builder:roll(second) + builder:roll(third),
        first + builder:roll(second) + builder:roll(third)
end

-- A source open-strategy room must lie mostly inside the primary cave
-- and must not overlap a previous hut's wall shell.
local function available(builder, room, placed)
    local floor = 0
    local area = room.width * room.height

    for _, prior in ipairs(placed) do
        if room.x1 <= prior.x2 + 2 and room.x2 + 2 >= prior.x1 and
            room.y1 <= prior.y2 + 2 and room.y2 + 2 >= prior.y1 then
            return false
        end
    end

    for y = room.y1, room.y2 do
        for x = room.x1, room.x2 do
            if builder:cell(x, y) == "." then
                floor = floor + 1
            end
        end
    end

    return floor >= area / 2
end

-- Room painters return an interior mask. Cavern rooms use a Worley
-- boundary; ordinary cave rooms use the one shared source simplex scale.
local function room_mask(builder, style, width, height)
    local field

    if style.kind == "cavern" then
        field = noise.worley(builder, 0.5)
    else
        field = noise.simplex(builder, style.scale, true)
    end

    local mask = {}

    for y = 0, height - 1 do
        mask[y] = {}

        for x = 0, width - 1 do
            local border
            local value

            if style.kind == "cavern" then
                border = room_border(x, y, width, height, 2, false)
                value = (1 - border) *
                    (0.1 + noise.worley_at(field, x, y))
                mask[y][x] = value >= 0.1
            else
                border = room_border(x, y,
                    width, height, style.padding, true)
                value = border * 2 +
                    noise.simplex_at(field, x, y)
                mask[y][x] = value <= 1
            end
        end
    end

    return mask
end

-- The source add_walls transform puts rock beside each painted floor
-- cell. A chosen boundary wall becomes a door into the old cave floor.
local function draw_room(builder, room, mask)
    local floors = {}
    local floor_set = {}
    local walls = {}
    local wall_set = {}
    local doors = {}

    for y = -1, room.height do
        for x = -1, room.width do
            local floor = mask[y] and mask[y][x]
            local around = false

            for _, direction in ipairs(directions) do
                local near_x = x + direction.x
                local near_y = y + direction.y

                if mask[near_y] and mask[near_y][near_x] then
                    around = true
                end
            end

            local world_x = room.x1 + x + 1
            local world_y = room.y1 + y + 1

            if floor then
                floors[#floors + 1] = {
                    x = world_x,
                    y = world_y,
                }
                floor_set[key(world_x, world_y)] = true
            elseif around then
                walls[#walls + 1] = {
                    x = world_x,
                    y = world_y,
                }
                wall_set[key(world_x, world_y)] = true
            end
        end
    end

    for _, wall in ipairs(walls) do
        local exterior = false
        local interior = false

        for _, direction in ipairs(directions) do
            local x = wall.x + direction.x
            local y = wall.y + direction.y
            local neighbor = key(x, y)

            if floor_set[neighbor] then
                interior = true
            elseif not wall_set[neighbor] and
                builder:cell(x, y) == "." then
                exterior = true
            end
        end

        if interior and exterior then
            doors[#doors + 1] = wall
        end
    end

    if #doors == 0 then
        return false
    end

    local door = doors[builder:roll(#doors) + 1]

    for _, floor in ipairs(floors) do
        builder:set(floor.x, floor.y, ".")
    end

    for _, wall in ipairs(walls) do
        builder:set(wall.x, wall.y, "#")
    end

    builder:set(door.x, door.y, "+")

    return true
end

-- Sample open anchors without moving an existing hut. The source may
-- decline a candidate that cannot fit; a bounded search does the same.
local function place_room(builder, style, kind, placed)
    local width, height = room_size(builder, kind)

    for _ = 1, 128 do
        local x1 = subdivision.range(builder,
            2, grid.width - width - 4)
        local y1 = subdivision.range(builder,
            2, grid.height - height - 4)
        local room = {
            x1 = x1,
            y1 = y1,
            x2 = x1 + width + 1,
            y2 = y1 + height + 1,
            width = width,
            height = height,
        }

        if available(builder, room, placed) then
            local mask = room_mask(builder, style, width, height)

            if draw_room(builder, room, mask) then
                placed[#placed + 1] = room
                return true
            end
        end
    end

    return false
end

-- The source draws both pass sizes before Hyper starts building. Keep
-- this order, then run one large-hut pass and one weighted mixed pass.
function layout.generate(api)
    local builder = grid.new(api.ctx)
    local style = choose_style(builder)
    local big_count = subdivision.range(builder, 1, 3)
    local mixed_count = subdivision.range(builder, 8, 12)
    local bounds = primary_bounds(builder)
    local placed = {}

    paint_primary(builder, bounds)

    for _ = 1, big_count do
        place_room(builder, style, "big", placed)
    end

    for _ = 1, mixed_count do
        local kind = builder:roll(25) < 15 and "normal" or "small"

        place_room(builder, style, kind, placed)
    end

    regions.keep_largest_region(builder)
    material.caves(builder, api)

    return {
        builder = builder,
        room_count = #placed,
    }
end

return layout
