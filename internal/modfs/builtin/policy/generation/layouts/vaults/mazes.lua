-- Theory of operation: source Vaults mazes start from a small room and grow
-- connected chambers from their exposed walls. On the fixed 80x70 port grid,
-- these room chains preserve that sparse, branching topology before tagged
-- DES rooms replace some chambers in the shared placement pass.
local grid = require("policy.generation.grid")
local geometry = require("policy.generation.layouts.vaults.geometry")

local mazes = {}

-- Keep a room center and its chosen dimensions together so the next room
-- can join this one without scanning the entire map for a candidate wall.
local function chamber(builder, center)
    local width = geometry.range(builder, 4, 10)
    local height = geometry.range(builder, 4, 10)
    local left = math.max(2, center.x - math.floor(width / 2))
    local top = math.max(2, center.y - math.floor(height / 2))

    geometry.rectangle(builder, left, top,
        math.min(grid.width - 3, left + width - 1),
        math.min(grid.height - 3, top + height - 1), ".")

    return center
end

-- Move one chamber width along a chosen axis, leaving a narrow passage
-- between rooms. Clamping protects the level's immutable outer wall.
local function advance(builder, center, axis, sign)
    local distance = geometry.range(builder, 6, 12)
    local next_center = {
        x = center.x,
        y = center.y,
    }

    if axis == "x" then
        next_center.x = math.max(5,
            math.min(grid.width - 6, center.x + sign * distance))
    else
        next_center.y = math.max(5,
            math.min(grid.height - 6, center.y + sign * distance))
    end

    chamber(builder, next_center)
    geometry.join(builder, center, next_center)

    return next_center
end

-- Ordinary maze branches from any earlier chamber. Each new lobe stays
-- connected, while the random parent choice makes several arms rather than
-- one giant rectangular hall.
function mazes.ordinary(builder)
    local centers = {
        chamber(builder, {
            x = math.floor(grid.width / 2),
            y = math.floor(grid.height / 2),
        }),
    }

    for _ = 1, 18 do
        local parent = centers[builder:roll(#centers) + 1]
        local axis = builder:one_in(2) and "x" or "y"
        local sign = builder:one_in(2) and -1 or 1

        centers[#centers + 1] = advance(builder, parent, axis, sign)
    end
end

-- Snakey maze alternates horizontal and vertical attachment after one or
-- two rooms, following the source's axis-switch interval and offset idea.
function mazes.snakey(builder)
    local center = chamber(builder, {
        x = math.floor(grid.width / 2),
        y = math.floor(grid.height / 2),
    })
    local interval = geometry.range(builder, 1, 2)
    local offset = builder:roll(interval)
    local horizontal_first = builder:one_in(2)

    for step = 1, 18 do
        local horizontal = (math.floor((step + offset) / interval) % 2 == 0) ==
            horizontal_first
        local axis = horizontal and "x" or "y"
        local sign = builder:one_in(2) and -1 or 1

        center = advance(builder, center, axis, sign)
    end
end

-- Bifurcated maze extends in opposite directions along one axis, then
-- sprouts shorter side branches from both arms to make two bulbous regions.
function mazes.bifurcated(builder)
    local origin = chamber(builder, {
        x = math.floor(grid.width / 2),
        y = math.floor(grid.height / 2),
    })
    local first_axis = builder:one_in(2) and "x" or "y"
    local second_axis = first_axis == "x" and "y" or "x"
    local reach = geometry.range(builder, 2, 3)
    local arms = {}

    for _, sign in ipairs({ -1, 1 }) do
        local center = origin

        for _ = 1, reach do
            center = advance(builder, center, first_axis, sign)
        end

        arms[#arms + 1] = center
    end

    for _, arm in ipairs(arms) do
        for _ = 1, 5 do
            local sign = builder:one_in(2) and -1 or 1

            arm = advance(builder, arm, second_axis, sign)
        end
    end
end

return mazes
