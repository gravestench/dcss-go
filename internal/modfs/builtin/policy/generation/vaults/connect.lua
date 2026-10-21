-- Example: An isolated vault exit gets a corridor to reachable Dungeon floor.
local connect = {}
local effects = require("constants.vault_effects")
local glyphs = require("constants.vault_glyphs")
local hooks = require("policy.generation.vaults.hooks")
local history = require("policy.population.unique_history")
local runes = require("policy.character.runes")

-- The connector runs on several branch themes. Testing only rock would
-- mistake Vaults metal or crystal walls for walkable floor.
local function passable(glyph)
    return glyph == "." or glyph == "+" or glyph == "~" or
        glyph == "=" or glyph == "W" or
        glyphs.up[glyph] or glyphs.down[glyph]
end

-- Every source exit must reach the surrounding Dungeon. The connector marks
-- any source terrain it carves through so projection does not restore it.
local function key(x, y)
    return x .. ":" .. y
end

-- Distinguish cells beyond the placed map bounds from interior connector targets.
local function outside(bounds, x, y)
    return x < bounds.x or x >= bounds.x + bounds.width or
        y < bounds.y or y >= bounds.y + bounds.height
end

-- Find the shortest map-edge escape route before searching ordinary floor.
local function closest_edge(point, bounds)
    local candidates = {
        { distance = point.x - bounds.x, x = bounds.x - 1, y = point.y },
        {
            distance = bounds.x + bounds.width - 1 - point.x,
            x = bounds.x + bounds.width,
            y = point.y,
        },
        { distance = point.y - bounds.y, x = point.x, y = bounds.y - 1 },
        {
            distance = bounds.y + bounds.height - 1 - point.y,
            x = point.x,
            y = bounds.y + bounds.height,
        },
    }
    local chosen = candidates[1]

    for _, candidate in ipairs(candidates) do
        if candidate.distance < chosen.distance then
            chosen = candidate
        end
    end

    return chosen
end

-- Record every rock cell opened so source projection cannot restore it later.
local function carve(builder, from, to, carved, path)
    local x = from.x
    local y = from.y

    while x ~= to.x or y ~= to.y do
        if x < to.x then
            x = x + 1
        elseif x > to.x then
            x = x - 1
        elseif y < to.y then
            y = y + 1
        else
            y = y - 1
        end

        local glyph = builder:cell(x, y)

        path[key(x, y)] = true

        if not glyphs.up[glyph] and not glyphs.down[glyph] and
            glyph ~= "." then
            builder:set(x, y, ".")
            carved[key(x, y)] = true
        end
    end
end

-- A zero-one search prefers existing floor over newly carved rock when routing an exit.
local function nearest_outside_floor(builder, bounds, from)
    local best
    local best_distance

    for y = 1, 68 do
        for x = 1, 78 do
            if outside(bounds, x, y) and builder:cell(x, y) == "." then
                local distance = math.abs(x - from.x) + math.abs(y - from.y)

                if not best_distance or distance < best_distance then
                    best = { x = x, y = y }
                    best_distance = distance
                end
            end
        end
    end

    return best
end

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

-- Exclude the Dungeon border while finding walkable connector cells.
local function interior(builder, x, y)
    return x > 0 and y > 0 and x < 79 and y < 69 and
        builder:cell(x, y) ~= nil
end

-- Check all required stairs against the connected walkable region after carving.
local function reachable(builder, start)
    local seen = { [key(start.x, start.y)] = true }
    local previous = {}
    local queue = { start }
    local cursor = 1

    while cursor <= #queue do
        local point = queue[cursor]

        cursor = cursor + 1

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local id = key(x, y)

            if interior(builder, x, y) and not seen[id] and
                passable(builder:cell(x, y)) then
                seen[id] = true
                previous[id] = point
                queue[#queue + 1] = { x = x, y = y }
            end
        end
    end

    return seen, previous
end

-- A zero-one search cuts the fewest walls needed to join an isolated source
-- stair to the already connected map. Existing walkable source cells cost zero.
-- Find the cheapest carve from a vault exit into the already connected Dungeon floor.
local function bridge(builder, from, connected, carved, path)
    local queue = { [0] = from }
    local head = 0
    local tail = 0
    local distance = { [key(from.x, from.y)] = 0 }
    local previous = {}

    while head <= tail do
        local point = queue[head]
        local id = key(point.x, point.y)

        queue[head] = nil
        head = head + 1

        if connected[id] then
            while previous[id] do
                path[id] = true

                if not passable(builder:cell(point.x, point.y)) then
                    builder:set(point.x, point.y, ".")
                    carved[id] = true
                end

                point = previous[id]
                id = key(point.x, point.y)
            end

            return
        end

        for _, direction in ipairs(directions) do
            local x = point.x + direction.x
            local y = point.y + direction.y
            local next_id = key(x, y)

            if interior(builder, x, y) then
                local cost = passable(builder:cell(x, y)) and 0 or 1
                local next_distance = distance[id] + cost

                if not distance[next_id] or next_distance < distance[next_id] then
                    local next_point = { x = x, y = y }

                    distance[next_id] = next_distance
                    previous[next_id] = point

                    if cost == 0 then
                        head = head - 1
                        queue[head] = next_point
                    else
                        tail = tail + 1
                        queue[tail] = next_point
                    end
                end
            end
        end
    end

    error("arrival source exit cannot reach the surrounding Dungeon")
end

-- Run authored veto hooks after the candidate map has its final surrounding terrain.
local function check_vetoes(ctx, builder, placed)
    local api = {}

    -- Pan source hooks inspect saved run state after the candidate's map
    -- fits. Their decision reads the same player components as pickup and
    -- unique monster spawning, rather than a second vault-only ledger.
    function api:unique_seen(kind_id)
        return history.seen(ctx, kind_id)
    end

    -- The rune gate reads durable progress after its floor item is gone.
    function api:has_rune(kind_id)
        return runes.has(ctx, ctx:player(), kind_id)
    end

    -- Ignacio's chance uses the number of Pan runes only.
    function api:pan_rune_count()
        return runes.pan_count(ctx, ctx:player())
    end

    -- Ignacio's once-per-run coinflip is owned by player unique history.
    function api:pan_unique_state(kind_id)
        return history.pan_state(ctx, kind_id)
    end

    -- A successful first chance stores the decision before map placement.
    function api:set_pan_unique_state(kind_id, decision)
        history.set_pan_state(ctx, kind_id, decision)
    end

    -- Veto randomness stays on the current level's layout stream.
    function api:roll(bound)
        return builder:roll(bound)
    end

    -- Expose authored marker coordinates to veto hooks after placement.
    function api:marker_positions(property, value)
        local found = {}
        local needle = property .. "=" .. tostring(value)

        for _, record in ipairs(placed.records) do
            if record.kind == effects.MARKER and
                record.identity and record.identity:find(needle, 1, true) then
                found[#found + 1] = {
                    x = record.x,
                    y = record.y,
                }
            end
        end

        return #found > 0 and found or nil
    end

    -- Let veto hooks verify a marker actually joins the map's exit list.
    function api:has_exit(point)
        for _, exit in ipairs(placed.exits) do
            if exit.x == point.x and exit.y == point.y then
                return true
            end
        end

        return false
    end

    for _, record in ipairs(placed.records) do
        if record.kind == effects.VETO and
            hooks.run(placed, record.method, api) then
            error(string.format("%s:%d: vault %s: veto %s rejected placement",
                placed.path, record.line or 0, placed.id, record.method))
        end
    end
end

-- Every source exit must join ordinary Dungeon floor before the level can be accepted.
function connect.finish(ctx, builder, placed, required)
    check_vetoes(ctx, builder, placed)

    -- Decorative no_exits maps can be fully solid and have no route to
    -- connect. Their terrain is already placed on the shared grid.
    if placed.tags and placed.tags.no_exits then
        return placed
    end

    local carved = {}
    local path = {}
    local connectors = {}

    for _, exit in ipairs(placed.exits) do
        if exit.source == "@" or exit.source == "+" or exit.source == "=" then
            connectors[#connectors + 1] = exit
        end
    end

    if #connectors == 0 then
        connectors[1] = placed.entry
    end

    for _, from in ipairs(connectors) do
        local edge = closest_edge(from, placed.bounds)
        local target = nearest_outside_floor(builder, placed.bounds, edge)

        if not target then
            error(string.format("%s: vault %s: no ordinary Dungeon floor to connect",
                placed.path, placed.id))
        end

        carve(builder, from, edge, carved, path)
        carve(builder, edge, target, carved, path)
    end

    local points = { placed.entry }

    for _, exit in ipairs(placed.exits) do
        points[#points + 1] = exit
    end

    for _, point in ipairs(required or {}) do
        points[#points + 1] = point
        path[key(point.x, point.y)] = true
    end

    local connected, previous = reachable(builder, connectors[1])

    for _, point in ipairs(points) do
        if not connected[key(point.x, point.y)] then
            bridge(builder, point, connected, carved, path)
            connected, previous = reachable(builder, connectors[1])
        end
    end

    -- A stair may have been connected by existing floor, so bridge never
    -- carved it. Keep one actual walkable route before BORDER_FILL turns the
    -- remaining exterior into impassable open sea.
    for _, stair in ipairs(required or {}) do
        local point = stair

        while point do
            local id = key(point.x, point.y)

            path[id] = true
            point = previous[id]
        end
    end

    for _, record in ipairs(placed.records) do
        if record.kind == effects.BORDER_FILL then
            -- The source sea exterior may not drown a generated stair or
            -- the corridor that joins it to the authored finale.
            local keys = {}

            for coordinate in pairs(path) do
                keys[#keys + 1] = coordinate
            end

            table.sort(keys)
            record.arguments.preserve_cells = table.concat(keys, "|")
        end

        if (record.kind == effects.SOURCE_FEATURE or
            record.kind == effects.FEATURE) and
            carved[key(record.x, record.y)] then
            record.overridden = true
        end
    end

    return placed
end

return connect
