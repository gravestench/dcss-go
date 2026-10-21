-- Theory of operation: Vaults grid motifs leave walkable corridors around
-- islands of wall. Omnigrid recursively packs varied boxes; quadrants uses
-- two to four divisions per axis with some wall islands omitted.
local grid = require("policy.generation.grid")
local geometry = require("policy.generation.layouts.vaults.geometry")

local grids = {}

-- Split only where both children can retain the source minimum width.
-- The decreasing chance prevents a uniformly repetitive checkerboard.
local function subdivide(builder, x1, y1, x2, y2, chance, areas)
    local minimum = 15
    local width = x2 - x1 + 1
    local height = y2 - y1 + 1
    local can_split_x = width >= minimum * 2
    local can_split_y = height >= minimum * 2

    if (not can_split_x and not can_split_y) or
        builder:roll(100) >= chance then
        areas[#areas + 1] = {
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2,
        }

        return
    end

    local split_x = can_split_x and
        (not can_split_y or builder:one_in(2))
    local next_chance = chance * 0.8

    if split_x then
        local offset = geometry.range(builder, minimum, width - minimum)

        subdivide(builder, x1, y1, x1 + offset - 1, y2,
            next_chance, areas)
        subdivide(builder, x1 + offset, y1, x2, y2,
            next_chance, areas)
    else
        local offset = geometry.range(builder, minimum, height - minimum)

        subdivide(builder, x1, y1, x2, y1 + offset - 1,
            next_chance, areas)
        subdivide(builder, x1, y1 + offset, x2, y2,
            next_chance, areas)
    end
end

-- Each cell starts open. Sixty-four percent receive a wall island with a
-- two-cell passage; one floor-wide coin flip enables source corner jitter.
function grids.omnigrid(builder, wall)
    local areas = {}
    local jitter = builder:one_in(2)

    subdivide(builder, 1, 1, grid.width - 2, grid.height - 2,
        100, areas)

    for _, area in ipairs(areas) do
        geometry.rectangle(builder, area.x1, area.y1,
            area.x2, area.y2, ".")

        if builder:roll(100) < 64 then
            local left = area.x1 + 2
            local top = area.y1 + 2
            local right = area.x2 - 2
            local bottom = area.y2 - 2

            if jitter then
                left = left + geometry.range(builder, -1, 2)
                top = top + geometry.range(builder, -1, 2)
                right = right - geometry.range(builder, -1, 2)
                bottom = bottom - geometry.range(builder, -1, 2)
            end

            geometry.rectangle(builder, left, top, right, bottom, wall)
        end
    end
end

-- Quadrants leaves larger corridors when there are only two divisions;
-- four divisions use one-cell padding so their smaller islands still fit.
function grids.quadrants(builder, wall)
    local count_x = geometry.range(builder, 2, 4)
    local count_y = geometry.range(builder, 2, 4)
    local padding_x = count_x == 2 and 3 or count_x == 4 and 1 or 2
    local padding_y = count_y == 2 and 3 or count_y == 4 and 1 or 2
    local step_x = math.floor((grid.width - 2) / count_x)
    local step_y = math.floor((grid.height - 2) / count_y)

    geometry.rectangle(builder, 1, 1,
        grid.width - 2, grid.height - 2, ".")

    for x = 0, count_x - 1 do
        for y = 0, count_y - 1 do
            if not builder:one_in(3) then
                geometry.rectangle(builder,
                    1 + step_x * x + padding_x,
                    1 + step_y * y + padding_y,
                    1 + step_x * (x + 1) - padding_x - 1,
                    1 + step_y * (y + 1) - padding_y - 1,
                    wall)
            end
        end
    end
end

return grids
