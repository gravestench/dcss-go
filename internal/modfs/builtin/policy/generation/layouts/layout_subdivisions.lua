-- Theory of operation: Dis subdivisions recursively splits a large open
-- rectangle into alternating vertical and horizontal rooms. The ordinary
-- variant opens one door in each divider. The alternate variant opens
-- sampled neighboring walls afterward, then keeps the largest open zone.
-- Both variants retain the source's sparse symmetrical room decoration.
local grid = require("policy.generation.grid")
local rooms = require("policy.generation.layouts.dis_rooms")
local subdivision = require("policy.generation.layouts.subdivision")

local layout = {}

-- Place the source's four mirrored iron statues only when they do not form
-- adjacent pairs. The dry fountain is a separate one-in-ten room detail.
local function decorate(builder, x1, y1, x2, y2)
    if x1 + 2 <= x2 - 2 and y1 + 2 <= y2 - 2 and
        builder:one_in(10) then
        local x3 = subdivision.range(builder, x1 + 2, x2 - 2)
        local y3 = subdivision.range(builder, y1 + 2, y2 - 2)
        local x4 = x1 + x2 - x3
        local y4 = y1 + y2 - y3

        if math.abs(x3 - x4) ~= 1 and math.abs(y3 - y4) ~= 1 then
            builder:set(x3, y3, "G")
            builder:set(x4, y3, "G")
            builder:set(x3, y4, "G")
            builder:set(x4, y4, "G")
        end
    end

    if (x1 + x2) % 2 == 0 and (y1 + y2) % 2 == 0 and
        builder:one_in(10) then
        builder:set((x1 + x2) / 2, (y1 + y2) / 2, "V")
    end
end

-- The source replace_random picks a rock cell along the completed divider.
-- Limit the search to the divider interior so an outer wall stays intact.
local function divider_door(builder, first, last, fixed, vertical)
    local candidates = {}

    for offset = first, last do
        local x = vertical and fixed or offset
        local y = vertical and offset or fixed

        if builder:cell(x, y) == "x" then
            candidates[#candidates + 1] = { x = x, y = y }
        end
    end

    if #candidates > 0 then
        local point = candidates[builder:roll(#candidates) + 1]

        builder:set(point.x, point.y, "+")
    end
end

-- Cut along the requested axis. A short axis switches to the other one;
-- once both are short the region becomes one decorated source room.
local function split(builder, x1, y1, x2, y2, vertical, threshold, alt)
    local span = vertical and (x2 - x1) or (y2 - y1)
    local other = vertical and (y2 - y1) or (x2 - x1)

    if span < threshold then
        if other >= threshold then
            split(builder, x1, y1, x2, y2,
                not vertical, threshold, alt)
        elseif x1 < x2 and y1 < y2 then
            rooms.box(builder, x1, y1, x2, y2)
            decorate(builder, x1, y1, x2, y2)
        end

        return
    end

    local cut = (vertical and x1 or y1) + 4 +
        builder:roll(span - 7)

    if vertical then
        split(builder, x1, y1, cut, y2, false, threshold, alt)
        split(builder, cut, y1, x2, y2, false, threshold, alt)

        if not alt then
            divider_door(builder, y1 + 1, y2 - 1, cut, true)
        end
    else
        split(builder, x1, y1, x2, cut, true, threshold, alt)
        split(builder, x1, cut, x2, y2, true, threshold, alt)

        if not alt then
            divider_door(builder, x1 + 1, x2 - 1, cut, false)
        end
    end
end

-- The named DES validator uses the same fifteen-percent floor rule as the
-- original minimum_map_area DIVISIONS setting.
function layout.validate(result)
    return rooms.valid(result)
end

-- Build the source 8-cell inset before subdividing. Keeping the variant
-- decision early preserves the source's distinct connected-room styles.
function layout.layout_subdivisions(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local threshold = 9 + builder.height / 35
    local alt = builder:chance_in(2, 3)

    for y = 8, builder.height - 9 do
        for x = 8, builder.width - 9 do
            builder:set(x, y, ".")
        end
    end

    split(builder, 7, 7, builder.width - 8, builder.height - 8,
        true, threshold, alt)

    if alt then
        local minimum = 150 + 50 * builder.height / 35

        rooms.connect(builder, minimum,
            subdivision.range(builder, 2 * minimum, 3 * minimum))
        rooms.keep_largest(builder)
    end

    if builder.bad_random then
        error("Dis subdivisions could not obtain a bounded random draw")
    end

    return {
        builder = builder,
        rows = builder:rows(),
    }
end

return layout
