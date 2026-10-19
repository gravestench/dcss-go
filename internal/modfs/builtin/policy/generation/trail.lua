-- Example: A sealed stair candidate is skipped before a new trail is carved.
local corridors = require("policy.generation.corridors")

local trail = {}

local cardinal = {
    { x = 0, y = -1 },
    { x = 1, y = 0 },
    { x = 0, y = 1 },
    { x = -1, y = 0 },
}

-- A stair candidate needs adjacent traversable space; a marker or sealed cell cannot start a trail.
local function viable(builder, position)
    local glyph = builder:cell(position.x, position.y)

    if glyph ~= "#" and glyph ~= "." then
        return false
    end

    for _, direction in ipairs(cardinal) do
        local adjacent = {
            x = position.x + direction.x,
            y = position.y + direction.y,
        }

        if builder:inside(adjacent) and
            builder:cell(adjacent.x, adjacent.y) == "#" then
            return true
        end
    end

    return false
end

-- Bound both start search and segment growth; failed trails cause the caller to retry the whole floor.
function trail.make(builder, start)
    local position
    local found = false

    -- The start search has a fixed draw budget so a crowded floor can be retried by the caller.
    for _ = 1, 201 do
        local x = start.x + builder:roll(start.width)
        local y = start.y + builder:roll(start.height)
        position = {
            x = x,
            y = y,
        }

        if viable(builder, position) then
            found = true
            break
        end
    end

    if not found then
        return nil, "no viable start within 201 draws"
    end

    local begin = position
    local length = 0
    local finish = 0

    for _ = 1, 200 do
        if finish >= builder.corr_count then
            break
        end

        local direction = corridors.choose_direction(builder, position)

        if direction.x ~= 0 or direction.y ~= 0 then
            if direction.x == 0 or length == 0 then
                length = builder:roll(builder.corr_length) + 2
            end

            local next_position, err = corridors.carve_segment(builder, position, direction, length)

            if err then
                return nil, err
            end

            position = next_position

            -- The final trail segment must satisfy the stair-placement condition before returning a pair.
            if finish == builder.corr_count - 1 and
                builder:cell(position.x, position.y) ~= "." then
                finish = finish - 2
            end

            finish = finish + 1
        end
    end

    if finish < builder.corr_count then
        return nil, string.format(
            "corridor ended after %d of %d segments within 200 attempts",
            finish,
            builder.corr_count
        )
    end

    return {
        down = begin,
        up = position,
    }, nil
end

trail.cardinal = cardinal

return trail
