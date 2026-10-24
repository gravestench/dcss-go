-- Powered divination reveals a square around the player, with weaker odds
-- near its edge. Scrolls can request a whole-floor reveal through the same
-- map owner; neither path marks a cell as actually seen.
local branch_flags = require("constants.branch_flags")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")

local mapping = {}

-- The branch catalog owns whether knowledge can persist. Both a known
-- scroll preflight and an involuntary Xom act ask this exact question.
function mapping.persistent(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return false
    end

    local branch_id = ctx:level_branch(position.level_id)
    local branch = catalog.get(categories.BRANCHES, branch_id)

    for _, flag in ipairs(branch.flags or {}) do
        if flag == branch_flags.NO_MAP then
            return false
        end
    end

    return true
end

-- Source magic_mapping reduces the per-cell threshold past 70% and 90%
-- of the radius. The grid command decides if a selected solid feature is
-- truly exposed, preserving its own wall-adjacency rule.
local function threshold(proportion, distance, radius)
    if distance > math.floor(radius * 9 / 10) then
        return math.floor(proportion / 3)
    end

    if distance > math.floor(radius * 7 / 10) then
        return math.floor(proportion * 2 / 3)
    end

    return proportion
end

-- Iterate coordinates in a stable order. Mapping chances use a named RNG
-- stream, so a mod file's load order cannot change which cells are offered.
function mapping.reveal(ctx, player, radius, proportion, stream)
    if not mapping.persistent(ctx, player) then
        return 0
    end

    local position = ctx:get(player, component.POSITION)
    local width, height = ctx:level_size(position.level_id)
    local count = 0

    radius = math.max(5, radius)

    for y = math.max(0, position.y - radius),
        math.min(height - 1, position.y + radius) do
        for x = math.max(0, position.x - radius),
            math.min(width - 1, position.x + radius) do
            local distance = math.max(math.abs(x - position.x),
                math.abs(y - position.y))
            local chance = threshold(proportion, distance, radius)

            if (chance >= 100 or ctx:random(stream, 100) <= chance) and
                ctx:map_cell(position.level_id, x, y) then
                count = count + 1
            end
        end
    end

    return count
end

-- A scroll's power 500 and proportion 100 cover every current floor cell.
-- Returning a count lets the caller explain an unmappable or empty result.
function mapping.full(ctx, player, stream)
    local position = ctx:get(player, component.POSITION)
    local width, height = ctx:level_size(position.level_id)
    local radius = math.max(width, height) * 2

    return mapping.reveal(ctx, player, radius, 100, stream)
end

return mapping
