-- Theory of operation: source Chaotic City opens a broad square of street,
-- then samples many building sites. Each candidate needs a floor margin;
-- accepted sites become solid blocks or hollow rooms with street doors.
-- Rejecting occupied margins keeps streets open between separate buildings.
local branches = require("ids.branches")

local boxes = {}

-- The source draws one of five attempt counts, favoring sixteen and
-- thirty-two sites. These are attempts: a crowded city accepts fewer.
local function attempt_count(builder)
    local draw = builder:roll(15000)

    if draw < 4000 then
        return 32
    elseif draw < 7000 then
        return 24
    elseif draw < 12000 then
        return 16
    elseif draw < 14000 then
        return 8
    end

    return 1
end

-- Lair fixes every building to rock. Other eligible branches choose one
-- base material, with later one-in-three chances to vary individual boxes.
local function base_wall(builder, branch)
    if branch == branches.BRANCH_LAIR then
        return "#", true
    end

    local draw = builder:roll(18)

    if draw < 10 then
        return "#", false
    elseif draw < 15 then
        return "c", false
    end

    return "v", false
end

-- A varied building uses the source rock:stone:metal weights. Its
-- material is selected once for the entire room, not per wall cell.
local function building_wall(builder, base, fixed)
    if fixed or not builder:one_in(3) then
        return base
    end

    local draw = builder:roll(417)

    if draw < 261 then
        return "#"
    elseif draw < 377 then
        return "c"
    end

    return "v"
end

-- The one-cell street buffer around a candidate must still be ordinary
-- floor. This is the source anti-feature check that prevents overlap.
local function has_street_margin(builder, room)
    for y = room.y1 - 1, room.y2 + 2 do
        for x = room.x1 - 1, room.x2 + 2 do
            if builder:cell(x, y) ~= "." then
                return false
            end
        end
    end

    return true
end

-- Hollow rooms offer every non-corner boundary cell as a door candidate.
-- Their street margin guarantees an outside floor on the opposite side.
local function door_sites(room)
    local sites = {}

    for x = room.x1 + 1, room.x2 - 1 do
        sites[#sites + 1] = { x = x, y = room.y1 }
        sites[#sites + 1] = { x = x, y = room.y2 }
    end

    for y = room.y1 + 1, room.y2 - 1 do
        sites[#sites + 1] = { x = room.x1, y = y }
        sites[#sites + 1] = { x = room.x2, y = y }
    end

    return sites
end

-- Source room walls surround an unchanged floor interior. Doors follow
-- its two/one/three weighted draw, with one fewer in a very small room.
local function paint_hollow(builder, room, wall)
    for y = room.y1, room.y2 do
        for x = room.x1, room.x2 do
            if x == room.x1 or x == room.x2 or
                y == room.y1 or y == room.y2 then
                builder:set(x, y, wall)
            end
        end
    end

    local draw = builder:roll(100)
    local doors

    if draw < 54 then
        doors = 2
    elseif draw < 77 then
        doors = 1
    else
        doors = 3
    end

    if (room.x2 - room.x1) * (room.y2 - room.y1) < 36 and
        doors > 1 then
        doors = doors - 1
    end

    local sites = door_sites(room)

    for _ = 1, doors do
        local index = builder:roll(#sites) + 1
        local site = table.remove(sites, index)

        builder:set(site.x, site.y, "+")
    end
end

-- Solid blocks leave their neighboring street intact. A hollow draw
-- paints only the boundary, then opens its source-weighted doors.
local function paint_room(builder, room, wall)
    if builder:one_in(3) then
        paint_hollow(builder, room, wall)

        return
    end

    for y = room.y1, room.y2 do
        for x = room.x1, room.x2 do
            builder:set(x, y, wall)
        end
    end
end

-- Sample source-sized boxes within the open 10-cell inset. The builder's
-- dimensions replace the legacy fixed GXM/GYM globals at this boundary.
function boxes.populate(builder, branch)
    local attempts = attempt_count(builder)
    local base, fixed = base_wall(builder, branch)
    local accepted = {}

    for _ = 1, attempts do
        local width = 3 + builder:roll(7) + builder:roll(5)
        local height = 3 + builder:roll(7) + builder:roll(5)
        local x1 = 11 + builder:roll(builder.width - 21 - width)
        local y1 = 11 + builder:roll(builder.height - 21 - height)
        local room = {
            x1 = x1,
            y1 = y1,
            x2 = x1 + width,
            y2 = y1 + height,
        }

        if has_street_margin(builder, room) then
            paint_room(builder, room, building_wall(builder, base, fixed))
            accepted[#accepted + 1] = room
        end
    end

    return accepted
end

return boxes
