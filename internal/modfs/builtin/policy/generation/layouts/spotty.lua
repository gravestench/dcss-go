-- Source spotty_map grows small patches of floor around existing open cells.
-- Layouts use it after carving a backbone, so the patches roughen its edge
-- without starting unrelated islands deep in uncarved rock.
local grid = require("policy.generation.grid")

local spotty = {}

-- Avoid a seed surrounded by rock in all cardinal directions out to two
-- cells. The source retries such seeds rather than carving isolated spots.
local function surrounded(builder, x, y)
    local offsets = {
        { 0, 0 },
        { -1, 0 },
        { 1, 0 },
        { 0, -1 },
        { 0, 1 },
        { -2, 0 },
        { 2, 0 },
        { 0, -2 },
        { 0, 2 },
    }

    for _, offset in ipairs(offsets) do
        if builder:cell(x + offset[1], y + offset[2]) ~= "#" then
            return false
        end
    end

    return true
end

-- Source radius_iterator paints a circular patch of radius two for boxy
-- mode or radius one otherwise. Both replace only rock cells.
local function patch(builder, x, y, boxy)
    local radius = boxy and 2 or 1

    for dy = -radius, radius do
        for dx = -radius, radius do
            local rounded = dx * dx + dy * dy <= radius * radius

            if rounded and builder:cell(x + dx, y + dy) == "#" then
                builder:set(x + dx, y + dy, ".")
            end
        end
    end
end

-- Stop after the source's ten seed attempts per requested patch. A map
-- that cannot grow farther remains valid instead of entering an RNG loop.
function spotty.carve(builder, boxy, iterations)
    local attempts = 0
    local limit = iterations * 10

    for _ = 1, iterations do
        local x
        local y

        repeat
            attempts = attempts + 1

            if attempts > limit then
                return
            end

            x = 4 + builder:roll(grid.width - 8)
            y = 4 + builder:roll(grid.height - 8)
        until not surrounded(builder, x, y)

        patch(builder, x, y, boxy)
    end
end

-- Smearing grows neighboring rock into existing floor. Boxy source maps
-- require a cardinal rock neighbor; rounded maps also accept diagonals.
-- Octagons use the latter behavior and discard disconnected floor later.
function spotty.smear(builder, iterations, boxy)
    local attempts = 0
    local limit = iterations * 10

    for _ = 1, iterations do
        local x
        local y
        local adjacent

        repeat
            attempts = attempts + 1

            if attempts > limit then
                return
            end

            x = 1 + builder:roll(grid.width - 2)
            y = 1 + builder:roll(grid.height - 2)
            adjacent = builder:cell(x + 1, y) == "#" or
                builder:cell(x - 1, y) == "#" or
                builder:cell(x, y + 1) == "#" or
                builder:cell(x, y - 1) == "#"

            if not boxy then
                adjacent = adjacent or
                    builder:cell(x + 1, y + 1) == "#" or
                    builder:cell(x - 1, y + 1) == "#" or
                    builder:cell(x + 1, y - 1) == "#" or
                    builder:cell(x - 1, y - 1) == "#"
            end
        until builder:cell(x, y) == "." and adjacent

        builder:set(x, y, "#")
    end
end

return spotty
