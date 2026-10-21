-- Theory of operation: Cocytus first freezes irregular water pools, then
-- delves one dry main route and puts an up/down stair pair on its distant
-- ends. Later passages and diamond rooms may be cut off by water, so their
-- floor carries the source no_tele_into property. Ordinary stair placement
-- uses the safe main route after the temporary alphabet is resolved.
local grid = require("policy.generation.grid")
local delve = require("policy.generation.layouts.delve")
local shapes = require("policy.generation.layouts.delve_shapes")
local effects = require("constants.vault_effects")
local properties = require("constants.vault_properties")

local layout = {}

-- Keep temporary route coordinates compact without inline field packing.
local function coordinate(x, y)
    return {
        x = x,
        y = y,
    }
end

local directions = {
    coordinate(1, 0),
    coordinate(-1, 0),
    coordinate(0, 1),
    coordinate(0, -1),
}
local adjacent = {
    coordinate(-1, -1),
    coordinate(0, -1),
    coordinate(1, -1),
    coordinate(-1, 0),
    coordinate(1, 0),
    coordinate(-1, 1),
    coordinate(0, 1),
    coordinate(1, 1),
}

-- Hell builder bounds are smaller on non-bottom floors. The five-cell
-- border prevents water and side rooms from touching an external edge.
local function field(builder)
    local left = 5
    local top = 5
    local right = builder.width - 6
    local bottom = builder.height - 6

    for y = top, bottom do
        for x = left, right do
            local edge = x == left or x == right or
                y == top or y == bottom

            builder:set(x, y, edge and "X" or "x")
        end
    end

    return left, top, right, bottom
end

-- Source spotty_map retries a seed only while its center and all cardinal
-- neighbors one or two cells away are still diggable x. A nearby floor,
-- water-circle edge, or reserved border lets this seed grow a patch.
local function water_seed_available(builder, x, y)
    local checks = {
        coordinate(0, 0),
        coordinate(1, 0),
        coordinate(-1, 0),
        coordinate(0, 1),
        coordinate(0, -1),
        coordinate(2, 0),
        coordinate(-2, 0),
        coordinate(0, 2),
        coordinate(0, -2),
    }

    for _, offset in ipairs(checks) do
        if builder:cell(x + offset.x, y + offset.y) ~= "x" then
            return true
        end
    end

    return false
end

-- Rounded spotty growth paints a radius-one patch into x alone; existing
-- cells keep their glyphs until the later water substitution and border pass.
local function grow_water_patch(builder, x, y)
    for _, offset in ipairs(directions) do
        local nx = x + offset.x
        local ny = y + offset.y

        if builder:cell(nx, ny) == "x" then
            builder:set(nx, ny, ".")
        end
    end

    if builder:cell(x, y) == "x" then
        builder:set(x, y, ".")
    end
end

-- Paint source circles and then grow them into small pools. The temporary
-- R glyph blocks subsequent delve passes and becomes deep water at the end.
local function water(builder, left, top, right, bottom)
    local scale = builder.height / 70
    local minimum = math.max(1, math.floor(20 * scale))
    local maximum = math.max(minimum, math.floor(30 * scale))
    local count = minimum + builder:roll(maximum - minimum + 1)

    for _ = 1, count do
        local x = left + builder:roll(right - left + 1)
        local y = top + builder:roll(bottom - top + 1)
        local radius = builder:roll(2)

        if builder:one_in(15) then
            radius = 2 + builder:roll(3)
        end

        shapes.circle(builder, x, y, radius, ".")
    end

    local growth = math.floor((100 + builder:roll(201)) * scale)

    local attempts = 0

    for _ = 1, growth do
        local found = false

        while not found and attempts < growth * 10 do
            attempts = attempts + 1

            local x = left + builder:roll(right - left + 1)
            local y = top + builder:roll(bottom - top + 1)

            if water_seed_available(builder, x, y) then
                grow_water_patch(builder, x, y)
                found = true
            end
        end

        if not found then
            break
        end
    end

    for y = top, bottom do
        for x = left, right do
            if builder:cell(x, y) == "." then
                builder:set(x, y, "R")
            end
        end
    end
end

-- Source farthest_from floods through all eight traversable neighbors and
-- draws among cells at the maximum distance. At this phase, only the first
-- delve's floor, beacon, and authored stairs are traversable.
local function farthest(builder, start, excluded)
    local queue = { start }
    local visited = { [start.y * builder.width + start.x] = true }
    local first = 1
    local distance = { 0 }
    local farthest_cells = {}
    local greatest = -1

    while first <= #queue do
        local point = queue[first]
        local next_distance = distance[first] + 1

        first = first + 1

        for _, direction in ipairs(adjacent) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local key = y * builder.width + x
            local glyph = builder:cell(x, y)

            if not visited[key] and (glyph == "." or glyph == "@" or
                glyph == "{" or glyph == "}") then
                visited[key] = true
                queue[#queue + 1] = coordinate(x, y)
                distance[#distance + 1] = next_distance

                if not excluded or x ~= excluded.x or y ~= excluded.y then
                    if next_distance > greatest then
                        farthest_cells = {}
                        greatest = next_distance
                    end

                    if next_distance == greatest then
                        farthest_cells[#farthest_cells + 1] = coordinate(x, y)
                    end
                end
            end
        end
    end

    return farthest_cells[builder:roll(#farthest_cells) + 1]
end

-- Delve can leave small seed fragments while retrying a difficult water
-- field. The longest connected dry component is the only valid stair route;
-- choosing the first row-major cell could pick a one-cell fragment.
local function largest_route(builder)
    local visited = {}
    local best = {}

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            local key = y * builder.width + x

            if builder:cell(x, y) == "." and not visited[key] then
                local start = coordinate(x, y)
                local queue = { start }
                local first = 1

                visited[key] = true

                while first <= #queue do
                    local point = queue[first]

                    first = first + 1

                    for _, direction in ipairs(adjacent) do
                        local nx = point.x + direction.x
                        local ny = point.y + direction.y
                        local neighbor = ny * builder.width + nx

                        if builder:cell(nx, ny) == "." and
                            not visited[neighbor] then
                            visited[neighbor] = true
                            queue[#queue + 1] = coordinate(nx, ny)
                        end
                    end
                end

                if #queue > #best then
                    best = queue
                end
            end
        end
    end

    return best
end

-- Mark one source floor as @. The rest of the first delve becomes > before
-- side digging, so only the one beacon controls fill_disconnected later.
local function main_route(builder)
    local target = 100 + builder:roll(201)

    delve.carve(builder, 2, 4, 0, target, 10)

    local route = largest_route(builder)

    if #route < 3 then
        error("Cocytus delve could not establish its dry main route")
    end

    local beacon = route[builder:roll(#route) + 1]

    builder:set(beacon.x, beacon.y, "@")

    local up = farthest(builder, beacon)

    builder:set(up.x, up.y, "{")

    local down = farthest(builder, up, beacon)

    if down.x == up.x and down.y == up.y then
        error("Cocytus delve main route has no second stair cell")
    end

    builder:set(down.x, down.y, "}")

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == "." then
                builder:set(x, y, ">")
            end
        end
    end
end

-- Source adds about one short side delve per twenty map rows. Their x
-- frontier may also be opened by the later geometric rooms.
local function side_passages(builder)
    for _ = 1, math.max(1, math.floor(builder.height / 20)) do
        delve.carve(builder, 2, 3, 3, 50, 100)
    end

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            if builder:cell(x, y) == "." then
                builder:set(x, y, "<")
            end
        end
    end
end

-- Delve and spotty growth can reach into the temporary padding. The source
-- reseals the entire five-cell rim before placing its diamond rooms.
local function seal_border(builder, left, top, right, bottom)
    for y = 0, builder.height - 1 do
        for x = 0, builder.width - 1 do
            if x <= left or x >= right or y <= top or y >= bottom then
                builder:set(x, y, "x")
            end
        end
    end
end

-- Diamond rooms replace only diggable walls. They are side-floor cells,
-- never a shortcut that overwrites the guaranteed stair-bearing route.
local function rooms(builder)
    local count = 1 + builder:roll(5)

    for _ = 1, count do
        local x = 8 + builder:roll(math.max(1, builder.width - 16))
        local y = 8 + builder:roll(math.max(1, builder.height - 16))
        local draw = builder:roll(100)
        local radius

        if draw < 30 then
            radius = 1
        elseif draw < 80 then
            radius = 2
        elseif draw < 95 then
            radius = 3
        elseif draw < 99 then
            radius = 4
        else
            radius = 5
        end

        for dy = -radius, radius do
            for dx = -radius, radius do
                local px = x + dx
                local py = y + dy

                if math.abs(dx) + math.abs(dy) <= radius and
                    builder:cell(px, py) == "x" then
                    builder:set(px, py, "<")
                end
            end
        end
    end
end

-- Source fill_disconnected keeps any traversable region containing @ and
-- seals every other region. Deep water counts as traversable for this
-- cleanup, although the player may need flight to cross it afterward.
local function retain_main_regions(builder)
    local visited = {}
    local passable = {
        ["."] = true,
        ["@"] = true,
        ["R"] = true,
        [">"] = true,
        ["<"] = true,
        ["{"] = true,
        ["}"] = true,
    }

    for y = 1, builder.height - 2 do
        for x = 1, builder.width - 2 do
            local key = y * builder.width + x

            if not visited[key] and passable[builder:cell(x, y)] then
                local cells = { coordinate(x, y) }
                local first = 1
                local wanted = false

                visited[key] = true

                while first <= #cells do
                    local current = cells[first]

                    first = first + 1
                    wanted = wanted or builder:cell(current.x, current.y) == "@"

                    for _, direction in ipairs(adjacent) do
                        local nx = current.x + direction.x
                        local ny = current.y + direction.y
                        local neighbor = ny * builder.width + nx

                        if passable[builder:cell(nx, ny)] and
                            not visited[neighbor] then
                            visited[neighbor] = true
                            cells[#cells + 1] = coordinate(nx, ny)
                        end
                    end
                end

                if not wanted then
                    for _, cell in ipairs(cells) do
                        builder:set(cell.x, cell.y, "x")
                    end
                end
            end
        end
    end
end

-- The pending-effect owner carries no_tele_into through save/restore.
-- Replacing < with plain floor before decoding keeps terrain and policy
-- separate, while preserving each source side-area cell's property.
local function finish(builder)
    local records = {}

    for y = 0, builder.height - 1 do
        for x = 0, builder.width - 1 do
            local glyph = builder:cell(x, y)

            if glyph == "R" then
                builder:set(x, y, "w")
            elseif glyph == "@" or glyph == ">" then
                builder:set(x, y, ".")
            elseif glyph == "<" or glyph == "." then
                builder:set(x, y, ".")
                records[#records + 1] = {
                    kind = effects.PROPERTY,
                    identity = properties.NO_TELE_INTO,
                    source = ".",
                    x = x,
                    y = y,
                    vault_id = "layout_cocytus_delve",
                }
            end
        end
    end

    delve.finish(builder)

    return records
end

-- The normal catalog postpass adds any remaining connected stairs after
-- the source pair, without placing them in restricted side pools.
function layout.generate(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local left, top, right, bottom = field(builder)

    water(builder, left, top, right, bottom)
    main_route(builder)
    side_passages(builder)
    seal_border(builder, left, top, right, bottom)
    rooms(builder)
    retain_main_regions(builder)

    local records = finish(builder)

    return {
        builder = builder,
        records = records,
    }
end

return layout
