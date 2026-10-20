-- Pair one newly built Dungeon floor with its live parent. The parent may
-- have changed since its own generation, so this module returns a small
-- patch instead of replaying or replacing the older floor.
local branches = require("ids.branches")
local terrain = require("constants.terrain")
local branch_levels = require("policy.generation.branch_levels")
local glyphs = require("constants.vault_glyphs")

local stairs = {}

local directions = {
    {
        x = 1,
        y = 0,
    },

    {
        x = -1,
        y = 0,
    },

    {
        x = 0,
        y = 1,
    },

    {
        x = 0,
        y = -1,
    },
}

local exit_unavailable = "Leaving the Dungeon is unavailable in the Go port."
local depths_unavailable = "The Depths are unavailable in the Go port."

-- Coordinate order makes pair choice independent of source vault file order.
local function before(left, right)
    if left.y ~= right.y then
        return left.y < right.y
    end

    return left.x < right.x
end

-- Keep keys local to one generation call; none of this transient search state
-- belongs in the saved Level or in a module global.
local function key(x, y)
    return x .. ":" .. y
end

-- Gather both ordinary and authored exits without treating one kind as a
-- special case after the floor has been built.
local function exits(floor, upward)
    local points = {}
    local seen = {}

    -- A source map may report an authored exit already included by layout
    -- completion. One terrain cell can own only one durable stair link.
    local function add(point)
        if not point then
            return
        end

        local source = floor.layout.builder:cell(point.x, point.y)

        if not (upward and glyphs.up[source] or
            not upward and glyphs.down[source]) then
            return
        end

        local position = key(point.x, point.y)

        if not seen[position] then
            seen[position] = true
            points[#points + 1] = point
        end
    end

    for _, pair in ipairs(floor.layout.stairs) do
        add(upward and pair.up or pair.down)
    end

    local authored = upward and floor.source_up or floor.source_down

    for _, point in ipairs(authored) do
        add(point)
    end

    table.sort(points, before)

    return points
end

-- The first floor has no parent. Its up exits are explicit boundaries and
-- every down exit retains only the next depth until the player chooses one.
function stairs.first(floor)
    local up = exits(floor, true)
    local down = exits(floor, false)

    for _, point in ipairs(up) do
        floor.links[#floor.links + 1] = {
            x = point.x,
            y = point.y,
            to_level_id = 0,
            to_x = 0,
            to_y = 0,
            unavailable = exit_unavailable,
        }
    end

    for _, point in ipairs(down) do
        floor.links[#floor.links + 1] = {
            x = point.x,
            y = point.y,
            to_level_id = branch_levels.id(floor.branch_id,
                floor.depth + 1),
            to_x = 0,
            to_y = 0,
            pending = true,
            unavailable = "",
        }
    end
end

-- Search connected child floor through the finished builder. A source map
-- may add more downward exits than the child authored upward exits; each
-- surplus exit needs a real, walkable reciprocal stair near the base trail.
local function child_landings(floor, count)
    local builder = floor.layout.builder
    local start = floor.layout.stairs[1].up
    local queue = { start }
    local visited = { [key(start.x, start.y)] = true }
    local result = {}
    local cursor = 1

    while cursor <= #queue and #result < count do
        local point = queue[cursor]
        local position = key(point.x, point.y)

        cursor = cursor + 1

        if builder:cell(point.x, point.y) == "." and
            not floor.protected[position] then
            builder:set(point.x, point.y, "<")
            floor.protected[position] = true
            result[#result + 1] = point
        end

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local neighbor = key(x, y)

            if x > 0 and x < 79 and y > 0 and y < 69 and
                not visited[neighbor] then
                local glyph = builder:cell(x, y)

                if glyph and glyph ~= "#" then
                    visited[neighbor] = true
                    queue[#queue + 1] = {
                        x = x,
                        y = y,
                    }
                end
            end
        end
    end

    if #result ~= count then
        error("new Dungeon floor has too few connected up landings")
    end

    return result
end

-- A child source vault can bring additional up exits. Search the parent's
-- live grid from a known down stair and prefer unseen floor, so generation
-- does not overwrite an actor, an authored feature, or a visited stair.
local function parent_departures(ctx, parent, start, count)
    local queue = { start }
    local visited = { [key(start.x, start.y)] = true }
    local unseen = {}
    local seen = {}
    local seen_cells = {}
    local cursor = 1

    for _, point in ipairs(parent.seen or {}) do
        seen_cells[key(point.x, point.y)] = true
    end

    while cursor <= #queue do
        local point = queue[cursor]
        local position = key(point.x, point.y)

        cursor = cursor + 1

        if ctx:cell(parent.id, point.x, point.y) == terrain.DNGN_FLOOR and
            not ctx:actor_at(parent.id, point.x, point.y) and
            not (parent.protected and parent.protected[position]) then
            local candidates = seen_cells[position] and seen or unseen

            candidates[#candidates + 1] = point
        end

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local neighbor = key(x, y)

            if x > 0 and x < parent.width - 1 and
                y > 0 and y < parent.height - 1 and
                not visited[neighbor] and
                ctx:walkable(parent.id, x, y) then
                visited[neighbor] = true
                queue[#queue + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    local result = {}

    for _, candidates in ipairs({ unseen, seen }) do
        for _, point in ipairs(candidates) do
            result[#result + 1] = point

            if #result == count then
                return result
            end
        end
    end

    error("parent Dungeon floor has too few safe down departures")
end

-- Resolve every parent pending link against child up exits, adding landing
-- cells only for an authored surplus. The selected source stair determines
-- this action's entry; the remaining links are equally durable for return.
function stairs.pair(ctx, parent, child, selected)
    local parent_down = {}
    local branch_entry = child.depth == 1 and
        child.branch_id ~= branches.BRANCH_DUNGEON

    for _, link in ipairs(parent.stairs) do
        local chosen_entry = branch_entry and
            link.target_branch_id == child.branch_id and
            link.x == selected.x and link.y == selected.y
        local same_child = not branch_entry and link.pending and
            link.to_level_id == child.id

        if chosen_entry or same_child then
            parent_down[#parent_down + 1] = {
                x = link.x,
                y = link.y,
                new = false,
            }
        end
    end

    table.sort(parent_down, before)

    if #parent_down == 0 then
        error("parent floor has no stair to the chosen branch floor")
    end

    local child_up = exits(child, true)

    if #parent_down > #child_up then
        for _, point in ipairs(child_landings(child,
            #parent_down - #child_up)) do
            child_up[#child_up + 1] = point
        end
    elseif #child_up > #parent_down and not branch_entry then
        for _, point in ipairs(parent_departures(ctx, parent,
            parent_down[1], #child_up - #parent_down)) do
            parent_down[#parent_down + 1] = {
                x = point.x,
                y = point.y,
                new = true,
                feature = terrain.DNGN_STONE_STAIRS_DOWN_I,
            }
        end
    end

    table.sort(parent_down, before)
    table.sort(child_up, before)

    local patches = {}
    local entry

    for index, departure in ipairs(parent_down) do
        local landing = child_up[index]

        departure.to_x = landing.x
        departure.to_y = landing.y
        patches[#patches + 1] = departure

        child.links[#child.links + 1] = {
            x = landing.x,
            y = landing.y,
            to_level_id = parent.id,
            to_x = departure.x,
            to_y = departure.y,
            unavailable = "",
        }

        if selected.x == departure.x and selected.y == departure.y then
            entry = landing
        end
    end

    -- Source maps can author more up exits than the single scheduled
    -- parent entrance. Keep their glyphs visible without fabricating
    -- extra parent entrances or false reciprocal links.
    if branch_entry then
        for index = #parent_down + 1, #child_up do
            local point = child_up[index]

            child.links[#child.links + 1] = {
                x = point.x,
                y = point.y,
                to_level_id = 0,
                to_x = 0,
                to_y = 0,
                unavailable = "This stair has no matching branch entrance.",
            }
        end
    end

    if not entry then
        error("selected Dungeon stair is not a pending parent exit")
    end

    local branch = register.get("branches", child.branch_id)
    local bottom = branch.depth

    for _, point in ipairs(exits(child, false)) do
        local boundary = child.depth == bottom

        child.links[#child.links + 1] = {
            x = point.x,
            y = point.y,
            to_level_id = boundary and 0 or branch_levels.id(
                child.branch_id, child.depth + 1),
            to_x = 0,
            to_y = 0,
            pending = not boundary,
            unavailable = boundary and
                (child.branch_id == branches.BRANCH_DUNGEON and
                    depths_unavailable or
                    "There are no deeper floors in " .. branch.long_name .. ".") or "",
        }
    end

    return patches, entry
end

return stairs
