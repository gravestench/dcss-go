-- Room layouts share the shape and joining rules from the source Dungeon
-- builder. Coordinates are zero-based and inclusive, as in the source .des
-- scripts. Keeping geometry here lets each layout explain its own choices.
local geometry = {}
local grid = require("policy.generation.grid")

-- Change only rock inside a rectangle. Later rooms can overlap a corridor
-- without erasing a feature that a previous pass deliberately placed.
function geometry.fill_rock(builder, room)
    for y = math.max(1, room.y1), math.min(builder.height - 2, room.y2) do
        for x = math.max(1, room.x1), math.min(builder.width - 2, room.x2) do
            if builder:cell(x, y) == "#" then
                builder:set(x, y, ".")
            end
        end
    end
end

-- Source room rejection counts existing non-rock cells in the whole box,
-- including corridors. This keeps the "exclusive" draw meaningful.
function geometry.non_rock_count(builder, room)
    local count = 0

    for y = room.y1, room.y2 do
        for x = room.x1, room.x2 do
            if builder:cell(x, y) ~= "#" then
                count = count + 1
            end
        end
    end

    return count
end

-- The source script uses the midpoint of the bounding box even for rounded
-- rooms. Retaining that choice keeps its corridor anchors reproducible.
function geometry.center(room)
    return {
        x = math.floor((room.x1 + room.x2) / 2),
        y = math.floor((room.y1 + room.y2) / 2),
    }
end

-- A source join draws toward its target using the remaining x/y distance
-- as its axis probability. Elf chooses diagonal progress whenever possible.
local function joining_path(builder, from, to, straight)
    local x = from.x
    local y = from.y
    local points = {}

    while true do
        points[#points + 1] = { x = x, y = y }

        if x == to.x and y == to.y then
            return points
        end

        local x_diff = math.abs(to.x - x)
        local y_diff = math.abs(to.y - y)
        local x_step = x < to.x and 1 or -1
        local y_step = y < to.y and 1 or -1

        if straight and x_diff > 0 and y_diff > 0 then
            x = x + x_step
            y = y + y_step
        elseif x_diff > 0 and (y_diff == 0 or builder:roll(x_diff + y_diff) < x_diff) then
            x = x + x_step
        else
            y = y + y_step
        end
    end
end

-- Source join_the_dots evaluates both directions and breaks an equal path
-- tie randomly. Before vaults exist, neither route carries a vault penalty.
function geometry.join(builder, from, to, straight)
    if from.x == to.x and from.y == to.y then
        return
    end

    local forward = joining_path(builder, from, to, straight)
    local backward = joining_path(builder, to, from, straight)
    local selected = builder:roll(2) == 0 and forward or backward

    for _, point in ipairs(selected) do
        if builder:cell(point.x, point.y) == "#" then
            builder:set(point.x, point.y, ".")
        end
    end
end

-- The rounded room branch in the source paints circles, not a rectangle.
-- A point inside the radius becomes floor only if it was rock beforehand.
function geometry.circle(builder, center_x, center_y, radius)
    local left = math.ceil(center_x - radius)
    local right = math.floor(center_x + radius)
    local top = math.ceil(center_y - radius)
    local bottom = math.floor(center_y + radius)

    for y = math.max(1, top), math.min(builder.height - 2, bottom) do
        for x = math.max(1, left), math.min(builder.width - 2, right) do
            local dx = x - center_x
            local dy = y - center_y

            if dx * dx + dy * dy <= radius * radius and builder:cell(x, y) == "#" then
                builder:set(x, y, ".")
            end
        end
    end
end

return geometry
