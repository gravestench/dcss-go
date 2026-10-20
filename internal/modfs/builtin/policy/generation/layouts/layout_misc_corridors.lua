-- Theory of operation: Misc Corridors chains 15-25 random points through
-- joined paths. Crypt straightens each join; Zot uses fewer, sometimes
-- diagonal, thicker joins. A final source spotty pass expands the narrow
-- network without spawning unrelated floor islands.
local grid = require("policy.generation.grid")
local material = require("policy.generation.layouts.material")
local spotty = require("policy.generation.layouts.spotty")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- Source random_coord stays eight cells inside the map rim. Primary vault
-- avoidance will use this same site choice when branch vaults become live.
local function point(builder)
    return {
        x = 8 + builder:roll(grid.width - 16),
        y = 8 + builder:roll(grid.height - 16),
    }
end

-- A thick Zot join paints a compact neighborhood around each path cell.
-- Every painted point is clipped to the immutable one-cell level border.
local function paint(builder, x, y, thickness)
    local low = math.floor((thickness - 1) / 2)
    local high = math.ceil((thickness - 1) / 2)

    for dy = -low, high do
        for dx = -low, high do
            local target_x = x + dx
            local target_y = y + dy

            if target_x > 0 and target_x < grid.width - 1 and
                target_y > 0 and target_y < grid.height - 1 then
                builder:set(target_x, target_y, ".")
            end
        end
    end
end

-- Source force_straight draws one Bresenham-like line. A normal join
-- chooses its next axis from remaining distances, making a wandering but
-- always connected path between the same two source points.
local function join(builder, first, last, straight, diagonals, thickness)
    local x = first.x
    local y = first.y
    local horizontal = math.abs(last.x - x)
    local vertical = math.abs(last.y - y)
    local x_direction = x < last.x and 1 or -1
    local y_direction = y < last.y and 1 or -1
    local error_term = horizontal - vertical

    paint(builder, x, y, thickness)

    while x ~= last.x or y ~= last.y do
        if straight then
            local doubled = 2 * error_term

            if doubled > -vertical and x ~= last.x then
                error_term = error_term - vertical
                x = x + x_direction
            end

            if doubled < horizontal and y ~= last.y then
                error_term = error_term + horizontal
                y = y + y_direction
            end
        else
            local dx = math.abs(last.x - x)
            local dy = math.abs(last.y - y)

            if diagonals and dx > 0 and dy > 0 and
                builder:one_in(2) then
                x = x + x_direction
                y = y + y_direction
            elseif dx > 0 and (dy == 0 or builder:roll(dx + dy) < dx) then
                x = x + x_direction
            else
                y = y + y_direction
            end
        end

        paint(builder, x, y, thickness)
    end
end

-- Branch-bottom floors draw twenty to fifty percent more segments. Source
-- primary-vault area reduction is irrelevant before any branch primary
-- vault is placed and belongs with that later placement integration.
local function segment_count(builder, api)
    local count = subdivision.range(builder, 15, 25)

    if api.branch == "Zot" then
        count = subdivision.range(builder, 10, 16)
    end

    if api.depth == api.branch_bottom then
        local factor = 1.2 +
            builder:roll(1000000) / 1000000 * 0.3

        count = math.floor(count * factor)
    end

    return count
end

-- Carve the complete source chain before spotty expansion. The shared
-- stair pass later chooses a connected region of this floor.
function layout.layout_misc_corridors(api)
    local builder = grid.new(api.ctx)
    local corridors = segment_count(builder, api)
    local straight = api.branch == "Crypt" or api.branch == "Zot"
    local diagonals = api.branch == "Zot" and builder:one_in(2)
    local maximum = api.branch == "Zot" and 3 or 1
    local previous = point(builder)

    for _ = 1, corridors do
        local next_point = point(builder)
        local thickness = subdivision.range(builder, 1, maximum)

        join(builder, previous, next_point,
            straight, diagonals, thickness)
        previous = next_point
    end

    spotty.carve(builder, true,
        subdivision.range(builder, 75, 125))
    material.level(builder, api)

    if builder.bad_random then
        error("Misc Corridors random source failed to provide a bounded draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
        corridor_count = corridors,
    }
end

return layout
