local items = require("policy.inventory.items")

local doors = {}

local function key(x, y)
    return x .. ":" .. y
end

function doors.group(ctx, level, x, y, glyph)
    if ctx:cell(level, x, y) ~= glyph then
        error("level " .. level .. " has no " .. glyph .. " door at (" .. x .. "," .. y .. ")")
    end

    local queue = { { x = x, y = y } }
    local seen = {}
    local found = {}
    local next_index = 1

    while next_index <= #queue do
        local cell = queue[next_index]
        next_index = next_index + 1
        local id = key(cell.x, cell.y)

        if not seen[id] and ctx:cell(level, cell.x, cell.y) == glyph then
            seen[id] = true
            found[#found + 1] = cell
            queue[#queue + 1] = { x = cell.x + 1, y = cell.y }
            queue[#queue + 1] = { x = cell.x - 1, y = cell.y }
            queue[#queue + 1] = { x = cell.x, y = cell.y + 1 }
            queue[#queue + 1] = { x = cell.x, y = cell.y - 1 }
        end
    end

    table.sort(found, function(a, b)
        return a.x < b.x or (a.x == b.x and a.y < b.y)
    end)

    return found
end

function doors.push_targets(ctx, level, cell, excluded)
    local targets = {}

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = cell.x + dx
                local y = cell.y + dy

                if not excluded[key(x, y)] and ctx:walkable(level, x, y) then
                    targets[#targets + 1] = { x = x, y = y }
                end
            end
        end
    end

    return targets
end

function doors.excluded(group)
    local excluded = {}

    for _, cell in ipairs(group) do
        excluded[key(cell.x, cell.y)] = true
    end

    return excluded
end

-- This is the free command check. Invisible monsters consume time and defer
-- the obstruction message to the ordered door system.
function doors.close_obstruction(ctx, player, level, group)
    local excluded = doors.excluded(group)
    local origin = ctx:get(player, "core.position")

    for _, cell in ipairs(group) do
        local occupant = ctx:actor_at(level, cell.x, cell.y)

        if occupant and occupant ~= player then
            if ctx:visible(level, origin.x, origin.y, 7, cell.x, cell.y) then
                return "There's a creature in the doorway!", false
            end

            return nil, true
        end

        local position = { level_id = level, x = cell.x, y = cell.y }

        if #items.at(ctx, position) > 0 and
            #doors.push_targets(ctx, level, cell, excluded) == 0 then
            return "There's something jamming the doorway.", false
        end

        if occupant == player then
            return "There's a thick-headed creature in the doorway!", false
        end
    end

    return nil, false
end

function doors.prepare(ctx, actor, opening, dx, dy)
    local position = ctx:get(actor, "core.position")

    if not position then
        error("door actor " .. ctx:id(actor) .. " has no position")
    end

    local glyph = opening and "+" or "'"
    local verb = opening and "open" or "close"
    dx = dx or 0
    dy = dy or 0

    if dx == 0 and dy == 0 then
        local choices = {}

        for offset_y = -1, 1 do
            for offset_x = -1, 1 do
                if (offset_x ~= 0 or offset_y ~= 0) and
                    ctx:cell(position.level_id, position.x + offset_x,
                        position.y + offset_y) == glyph then
                    choices[#choices + 1] = { x = offset_x, y = offset_y }
                end
            end
        end

        if #choices == 0 then
            return { message = "There's nothing to " .. verb .. " nearby." }
        end

        if #choices > 1 then
            return { message = "Choose a direction to " .. verb .. "." }
        end

        dx = choices[1].x
        dy = choices[1].y
    end

    if dx < -1 or dx > 1 or dy < -1 or dy > 1 or (dx == 0 and dy == 0) then
        return { message = "Choose an adjacent direction." }
    end

    local x = position.x + dx
    local y = position.y + dy

    if ctx:cell(position.level_id, x, y) ~= glyph then
        return { message = "There isn't a door to " .. verb .. " there." }
    end

    local intent = { kind = opening and 8 or 9, dx = dx, dy = dy }

    if not opening then
        local group = doors.group(ctx, position.level_id, x, y, glyph)
        local message, spends_time = doors.close_obstruction(
            ctx, actor, position.level_id, group)

        if message and not spends_time then
            return { message = message }
        end
    end

    return { intent = intent, cost = 10 }
end

return doors
