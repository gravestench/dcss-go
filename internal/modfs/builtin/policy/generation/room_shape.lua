local shape = {}

local function open_connection(builder, x, y)
    local glyph = builder:cell(x, y)
    return glyph == "." or glyph == "+"
end

local function connections(builder, left, top, right, bottom)
    local count = 0
    local corners = 0

    for x = left, right do
        if open_connection(builder, x, top) then
            count = count + 1
        end

        if open_connection(builder, x, bottom) then
            count = count + 1
        end
    end

    for y = top + 1, bottom - 1 do
        if open_connection(builder, left, y) then
            count = count + 1
        end

        if open_connection(builder, right, y) then
            count = count + 1
        end
    end

    local corner_cells = {
        { x = left, y = top },
        { x = right, y = top },
        { x = left, y = bottom },
        { x = right, y = bottom },
    }

    for _, corner in ipairs(corner_cells) do
        if open_connection(builder, corner.x, corner.y) then
            corners = corners + 1
        end
    end

    return count, corners
end

local function solid(builder, x, y)
    local glyph = builder:cell(x, y)
    return glyph == "#" or glyph == "+"
end

local function maybe_door(builder, x, y, flank_x, flank_y, door_level)
    if builder:cell(x, y) ~= "." or
        not solid(builder, x - flank_x, y - flank_y) or
        not solid(builder, x + flank_x, y + flank_y) then
        return
    end

    if builder:chance_in(door_level, 10) then
        builder:set(x, y, "+")
    end
end

function shape.make(builder, left, top, right, bottom, max_doors, door_level)
    local count, corners = connections(builder, left, top, right, bottom)

    if max_doors == 1 and count + corners > 1 then
        return false
    end

    if count == 0 or count > max_doors then
        return false
    end

    for y = top, bottom do
        for x = left, right do
            local glyph = builder:cell(x, y)

            if glyph == "#" or glyph == "+" then
                builder:set(x, y, ".")
            end
        end
    end

    for y = top + 1, bottom - 1 do
        maybe_door(builder, left - 1, y, 0, 1, door_level)
        maybe_door(builder, right + 1, y, 0, 1, door_level)
    end

    for x = left + 1, right - 1 do
        maybe_door(builder, x, top - 1, 1, 0, door_level)
        maybe_door(builder, x, bottom + 1, 1, 0, door_level)
    end

    return true
end

return shape
