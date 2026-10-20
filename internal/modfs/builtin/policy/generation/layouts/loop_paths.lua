-- Theory of operation: the source Loop family draws orthogonal paths in
-- short runs whose perpendicular coordinates vary. Their turning points
-- become positions for smaller loops and rooms, producing interlocking
-- corridors without a separate room-and-corridor graph.
local grid = require("policy.generation.grid")

local paths = {}

-- Source randomLow draws twice and favors the smaller value. Loop radii
-- and negative-side wall positions use this to stay closer to the center.
function paths.low(builder, bound)
    return math.min(builder:roll(bound), builder:roll(bound))
end

-- Positive-side wall positions favor the larger of two draws.
function paths.high(builder, bound)
    return math.max(builder:roll(bound), builder:roll(bound))
end

-- Jitter one coordinate uniformly around a requested connection point.
function paths.near(builder, center, radius)
    return center - radius + builder:roll(radius * 2 + 1)
end

-- The source occasionally makes all rock on a level stone or metal before
-- drawing loop paths. The chosen glyph is also used for room interiors.
function paths.wall(builder, api)
    local absolute_depth = api.absolute_depth or api.depth

    if api.branch == "D" and absolute_depth >= 4 and builder:one_in(20) then
        return builder:one_in(3) and "v" or "c"
    end

    return "#"
end

-- Fill the whole builder with a chosen material before carving paths.
function paths.fill(builder, wall)
    for y = 0, grid.height - 1 do
        for x = 0, grid.width - 1 do
            builder:set(x, y, wall)
        end
    end
end

-- Keep source corner multiplicity: a repeated point is a second chance
-- to grow a loop around that junction, not a duplicate to remove.
local function append(points, x, y)
    points[#points + 1] = { x = x, y = y }
end

-- Weighted side positions bend each wall run inward or outward in the
-- same way on x- and y-directed source helpers.
local function side_value(builder, minimum, maximum, weight)
    local size = maximum - minimum + 1

    if weight < 0 then
        return minimum + paths.low(builder, size)
    elseif weight > 0 then
        return minimum + paths.high(builder, size)
    end

    return minimum + builder:roll(size)
end

-- Interleave cut and side draws exactly as the source does. Drawing every
-- cut first would change later corner positions even with the same seed.
local function line_values(builder, main_first, main_last,
    side_first, side_last, minimum, maximum, weight, divisions)
    local cuts = { [1] = main_first, [divisions + 1] = main_last }
    local levels = { [1] = side_first, [divisions] = side_last }
    local span = main_last - main_first

    for index = 2, divisions do
        local low = math.floor((index - 1.5) / divisions * span)
        local high = math.floor((index - 0.5) / divisions * span)

        cuts[index] = main_first + low + builder:roll(high - low)

        if index < divisions then
            levels[index] = side_value(builder, minimum, maximum, weight)
        end
    end

    return cuts, levels
end

-- Carve one horizontal run while preserving the source's inclusive ends.
local function horizontal(builder, first, last, y)
    for x = first, last do
        builder:set(x, y, ".")
    end
end

-- Carve one vertical run while preserving the source's inclusive ends.
local function vertical(builder, first, last, x)
    for y = first, last do
        builder:set(x, y, ".")
    end
end

-- Source divided-line X records each segment start and connector corner.
-- Those points feed the next loop generation instead of global map state.
function paths.line_x(builder, points, first, last, low_y, high_y,
    weight, divisions)
    if high_y - low_y < 1 then
        weight = 0
    end

    local cuts_x, levels = line_values(builder,
        first.x, last.x, first.y, last.y,
        low_y, high_y, weight, divisions)

    for index = 1, divisions do
        local y = levels[index]

        horizontal(builder, cuts_x[index], cuts_x[index + 1], y)
        append(points, cuts_x[index], y)

        if index < divisions then
            vertical(builder, math.min(y, levels[index + 1]),
                math.max(y, levels[index + 1]), cuts_x[index + 1])
            append(points, cuts_x[index + 1], y)
        end
    end
end

-- Source divided-line Y is the transposed operation, so both orientations
-- make comparable turns and corner opportunities.
function paths.line_y(builder, points, first, last, low_x, high_x,
    weight, divisions)
    if high_x - low_x < 1 then
        weight = 0
    end

    local cuts_y, levels = line_values(builder,
        first.y, last.y, first.x, last.x,
        low_x, high_x, weight, divisions)

    for index = 1, divisions do
        local x = levels[index]

        vertical(builder, cuts_y[index], cuts_y[index + 1], x)
        append(points, x, cuts_y[index])

        if index < divisions then
            horizontal(builder, math.min(x, levels[index + 1]),
                math.max(x, levels[index + 1]), cuts_y[index + 1])
            append(points, x, cuts_y[index + 1])
        end
    end
end

-- Pick one corner on each quadrant of a loop's annular band. Two-draw
-- weights make the outer sides spread farther than a uniform rectangle.
local function quadrants(builder, x, y, minimum, maximum)
    local negative_x = x - maximum
    local positive_x = x + minimum
    local negative_y = y - maximum
    local positive_y = y + minimum
    local span = maximum - minimum + 1

    return {
        northwest = {
            x = negative_x + paths.low(builder, span),
            y = negative_y + paths.low(builder, span),
        },
        northeast = {
            x = positive_x + paths.high(builder, span),
            y = negative_y + paths.low(builder, span),
        },
        southwest = {
            x = negative_x + paths.low(builder, span),
            y = positive_y + paths.high(builder, span),
        },
        southeast = {
            x = positive_x + paths.high(builder, span),
            y = positive_y + paths.high(builder, span),
        },
        negative_x = negative_x,
        positive_x = positive_x,
        negative_y = negative_y,
        positive_y = positive_y,
        span = span,
    }
end

-- A one-division loop is a source rectangle without recorded corners;
-- higher divisions use the four separately bent sides below.
local function rectangle(builder, center_x, center_y, minimum, maximum)
    local span = maximum - minimum + 1
    local west = center_x - maximum + paths.low(builder, span)
    local east = center_x + minimum + paths.high(builder, span)
    local north = center_y - maximum + paths.low(builder, span)
    local south = center_y + minimum + paths.high(builder, span)

    horizontal(builder, west + 1, east - 1, north)
    horizontal(builder, west + 1, east - 1, south)
    vertical(builder, north, south, west)
    vertical(builder, north, south, east)
end

-- Draw one annular loop. It may intersect older paths; the resulting
-- junctions are intentional and keep this family more connected than rooms.
function paths.divided(builder, points, center_x, center_y,
    minimum, maximum, divisions)
    if divisions == 1 then
        rectangle(builder, center_x, center_y, minimum, maximum)
        return
    end

    local band = quadrants(builder, center_x, center_y, minimum, maximum)

    paths.line_x(builder, points, band.northwest, band.northeast,
        band.negative_y, center_y - minimum + 1, -1, divisions)
    paths.line_x(builder, points, band.southwest, band.southeast,
        center_y + minimum, center_y + maximum + 1, 1, divisions)
    paths.line_y(builder, points, band.northwest, band.southwest,
        band.negative_x, center_x - minimum + 1, -1, divisions)
    paths.line_y(builder, points, band.northeast, band.southeast,
        center_x + minimum, center_x + maximum + 1, 1, divisions)
end

-- Choose source corner positions without replacement, clamp each loop
-- inside its border, and carry unused positions into the next room pass.
function paths.group(builder, output, positions, count,
    radius_min, radius_max, border, divisions)
    local made = 0
    local minimum_x = border + radius_max
    local maximum_x = grid.width - border - radius_max - 1
    local minimum_y = border + radius_max
    local maximum_y = grid.height - border - radius_max - 1

    for _ = 1, count do
        if #positions == 0 then
            break
        end

        local index = builder:roll(#positions) + 1
        local point = positions[index]
        local x = math.max(minimum_x, math.min(maximum_x, point.x))
        local y = math.max(minimum_y, math.min(maximum_y, point.y))

        paths.divided(builder, output, x, y,
            radius_min, radius_max, divisions)
        positions[index] = positions[#positions]
        positions[#positions] = nil
        made = made + 1
    end

    for _, point in ipairs(positions) do
        append(output, point.x, point.y)
    end

    return made
end

return paths
