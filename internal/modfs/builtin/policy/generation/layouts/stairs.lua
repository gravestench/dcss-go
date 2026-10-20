-- Theory of operation: source layouts carve terrain and may place some or
-- all exits. The source builder then places any missing stone stairs. This
-- Lua postpass keeps that ownership split while ensuring every saved exit
-- belongs to one region the player can actually traverse.
local grid = require("policy.generation.grid")
local glyphs = require("constants.vault_glyphs")

local stairs = {}

local directions = {
    { x = 1, y = 0 },
    { x = -1, y = 0 },
    { x = 0, y = 1 },
    { x = 0, y = -1 },
}

local new_up = { "{", "(", "[" }
local new_down = { "}", ")", "]" }

-- These glyphs can connect two stair cells for a human character. Lava and
-- deep water cannot prove an ordinary Dungeon exit is reachable.
local function passable(glyph)
    return glyph == "." or glyph == "W" or glyph == "+" or
        glyph == "~" or
        glyph == "=" or glyphs.up[glyph] or glyphs.down[glyph]
end

-- A compact coordinate key prevents rescanning a region while leaving the
-- authoritative map in the shared grid builder.
local function key(point)
    return point.x .. ":" .. point.y
end

-- Flood one connected region and retain only plain floor as a candidate
-- for new stairs. Existing authored stair cells are never overwritten.
local function region_from(builder, start, visited)
    local region = {
        floor = {},
        up = {},
        down = {},
    }
    local queue = { start }
    local first = 1

    visited[key(start)] = true

    while first <= #queue do
        local point = queue[first]
        local glyph = builder:cell(point.x, point.y)

        first = first + 1

        if glyph == "." then
            region.floor[#region.floor + 1] = point
        elseif glyphs.up[glyph] then
            region.up[#region.up + 1] = point
        elseif glyphs.down[glyph] then
            region.down[#region.down + 1] = point
        end

        for _, direction in ipairs(directions) do
            local next_point = {
                x = point.x + direction.x,
                y = point.y + direction.y,
            }
            local next_key = key(next_point)

            if builder:inside(next_point) and
                not visited[next_key] and
                passable(builder:cell(next_point.x, next_point.y)) then
                visited[next_key] = true
                queue[#queue + 1] = next_point
            end
        end
    end

    return region
end

-- Preserve every region that owns a source stair. A cave may deliberately
-- distribute its down exits among separate bubbles; choosing only one
-- would either discard source exits or make branch travel irreversible.
-- Layouts with no authored stairs still use their largest playable region.
local function selected_regions(builder)
    local visited = {}
    local selected
    local authored_regions = {}

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local point = { x = x, y = y }

            if not visited[key(point)] and passable(builder:cell(x, y)) then
                local region = region_from(builder, point, visited)
                local authored = #region.up + #region.down > 0

                if authored then
                    authored_regions[#authored_regions + 1] = region
                end

                if not selected or #region.floor > #selected.floor then
                    selected = region
                end
            end
        end
    end

    if #authored_regions > 0 then
        table.sort(authored_regions, function(left, right)
            if (#left.up > 0) ~= (#right.up > 0) then
                return #left.up > 0
            end

            return #left.floor > #right.floor
        end)

        return authored_regions
    end

    return selected and { selected } or {}
end

-- Sort by map coordinates before pairing, independent of the order in
-- which a layout script happened to add its authored exits.
local function before(left, right)
    if left.y ~= right.y then
        return left.y < right.y
    end

    return left.x < right.x
end

-- Draw one eligible floor cell and remove it before the next choice so no
-- exit can overwrite another exit in the same postpass.
local function take_floor(builder, region)
    local index = builder:roll(#region.floor) + 1
    local point = table.remove(region.floor, index)

    if not point then
        error("layout has too few connected floor cells for stairs")
    end

    return point
end

-- Complete one region before moving to the next, so an up/down pair never
-- spans a solid wall. Global serials keep new source stair glyph variants
-- distinct across otherwise disconnected cave bubbles.
local function complete_region(builder, region, count, serials)
    local missing = count * 2 - #region.up - #region.down

    if #region.floor < missing then
        error("layout has too few connected floor cells for stairs")
    end

    table.sort(region.floor, before)

    while #region.up < count do
        local point = take_floor(builder, region)
        local glyph = new_up[(serials.up % #new_up) + 1]

        builder:set(point.x, point.y, glyph)
        region.up[#region.up + 1] = point
        serials.up = serials.up + 1
    end

    while #region.down < count do
        local point = take_floor(builder, region)
        local glyph = new_down[(serials.down % #new_down) + 1]

        builder:set(point.x, point.y, glyph)
        region.down[#region.down + 1] = point
        serials.down = serials.down + 1
    end

    table.sort(region.up, before)
    table.sort(region.down, before)

    local pairs = {}

    for index = 1, count do
        pairs[index] = {
            up = region.up[index],
            down = region.down[index],
        }
    end

    return pairs
end

-- Return ordinary up/down pairs after filling missing endpoints in each
-- authored region. Three pairs remain the minimum for a normal floor;
-- extra pairs belong to the first region, which owns the first authored up.
function stairs.complete(builder)
    local regions = selected_regions(builder)

    if #regions == 0 then
        error("layout has no playable floor for stairs")
    end

    local count = 0
    local serials = {
        up = 0,
        down = 0,
    }

    for _, region in ipairs(regions) do
        count = count + math.max(1, #region.up, #region.down)
        serials.up = serials.up + #region.up
        serials.down = serials.down + #region.down
    end

    local pairs = {}

    for index, region in ipairs(regions) do
        local needed = math.max(1, #region.up, #region.down)

        if index == 1 then
            needed = needed + math.max(0, 3 - count)
        end

        for _, pair in ipairs(complete_region(builder,
            region, needed, serials)) do
            pairs[#pairs + 1] = pair
        end
    end

    return pairs
end

return stairs
