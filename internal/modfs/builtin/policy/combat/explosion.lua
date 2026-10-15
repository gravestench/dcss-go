-- Generic blast propagation from beam.cc:determine_affected_cells and
-- _radial_sweep. Spell policies decide damage, resistance, and who is hit.
local explosion = {}

local directions = {
    { x = -1, y = -1 },
    { x = 0, y = -1 },
    { x = 1, y = -1 },
    { x = -1, y = 0 },
    { x = 1, y = 0 },
    { x = -1, y = 1 },
    { x = 0, y = 1 },
    { x = 1, y = 1 },
}

local function key(x, y)
    return x .. ":" .. y
end

function explosion.cells(ctx, level_id, center_x, center_y, radius,
    allow_solid_center)
    if radius < 0 or radius > 9 then
        error("explosion radius outside source map")
    end

    local best = {}

    local function visit(dx, dy, cost)
        if math.max(math.abs(dx), math.abs(dy)) > radius or
            cost > 10 * radius then
            return
        end

        local x = center_x + dx
        local y = center_y + dy

        local center = dx == 0 and dy == 0

        if not ctx:cell(level_id, x, y) or
            (not ctx:walkable(level_id, x, y) and
                not (center and allow_solid_center)) then
            return
        end

        local id = key(dx, dy)

        if best[id] and best[id] <= cost then
            return
        end

        best[id] = cost

        for _, direction in ipairs(directions) do
            local next_x = dx + direction.x
            local next_y = dy + direction.y
            local extra = 5

            if math.max(math.abs(dx), math.abs(dy)) == 1 and
                math.max(math.abs(next_x), math.abs(next_y)) == 1 then
                extra = 0
            elseif dx * direction.x < 0 or dy * direction.y < 0 then
                extra = 17
            end

            visit(next_x, next_y, cost + extra)
        end
    end

    visit(0, 0, 0)

    local result = {}

    local function append(dx, dy)
        if best[key(dx, dy)] then
            result[#result + 1] = {
                x = center_x + dx,
                y = center_y + dy,
            }
        end
    end

    append(0, 0)

    for ring = 1, radius do
        for offset = -ring, ring do
            if offset ~= -ring and offset ~= ring then
                append(-ring, offset)
                append(ring, offset)
            end

            append(offset, -ring)
            append(offset, ring)
        end
    end

    return result
end

return explosion
