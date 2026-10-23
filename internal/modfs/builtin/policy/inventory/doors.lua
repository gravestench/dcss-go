local items = require("policy.inventory.items")

local doors = {}

-- Source props_marker strings may give an authored doorway its own
-- ordinary open and close verbs. Read them from the first connected
-- panel so every panel of a multi-cell door speaks the same way.
function doors.message(ctx, level, cell, opening, pushed)
    if pushed then
        return "You close the door, pushing everything out of the way."
    end

    local key = opening and "door_verb_open" or
        "door_verb_close"
    local template = ctx:marker_property(level,
        cell.x, cell.y, key)

    if template then
        local noun = ctx:marker_property(level,
            cell.x, cell.y, "door_description_noun") or "door"

        return string.format(template, noun, "")
    end

    if opening then
        return "You open the door."
    end

    return "You close the door."
end

-- Encode coordinates for the visited/exclusion sets used during a door
-- flood fill; a string key works for both positive and negative offsets.
local function key(x, y)
    return x .. ":" .. y
end

-- Sort a multi-cell door group before later obstacle handling so whichever
-- cell the player targeted, the same ordered work is performed.
local function cell_order(left, right)
    return left.x < right.x or
        (left.x == right.x and left.y < right.y)
end

-- Find orthogonally connected door cells with the same glyph. Large doors
-- open or close as one group rather than leaving an arbitrary panel behind.
-- Example: doors.group(ctx, level_id, x, y, "DNGN_OPEN_DOOR").
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

    table.sort(found, cell_order)

    return found
end

-- Find adjacent walkable cells outside the closing door group where floor
-- items could be pushed; diagonal neighbors are valid destinations.
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

-- Exclude every panel in the same door group so an item cannot be pushed
-- from one closing panel into another closing panel.
function doors.excluded(group)
    local excluded = {}

    for _, cell in ipairs(group) do
        excluded[key(cell.x, cell.y)] = true
    end

    return excluded
end

-- This is the free command check. Invisible monsters consume time and defer
-- the obstruction message to the ordered door system.
-- Item obstructions are free failures only when no push destination exists;
-- this lets the timed system attempt a legitimate displacement later.
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

-- Without a direction, one adjacent door is inferred but multiple doors require a new prompt.
-- Example: doors.prepare(ctx, player, false, 1, 0) returns an intent and
-- time cost only after the target door and free obstruction checks pass.
function doors.prepare(ctx, actor, opening, dx, dy)
    local position = ctx:get(actor, "core.position")

    if not position then
        error("door actor " .. ctx:id(actor) .. " has no position")
    end

    local glyph = opening and "DNGN_CLOSED_DOOR" or "DNGN_OPEN_DOOR"
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
