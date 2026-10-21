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
local function selected_regions(builder, include_stairless)
    local visited = {}
    local selected
    local authored_regions = {}
    local all_regions = {}

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local point = { x = x, y = y }

            if not visited[key(point)] and passable(builder:cell(x, y)) then
                local region = region_from(builder, point, visited)
                local authored = #region.up + #region.down > 0

                all_regions[#all_regions + 1] = region

                if authored then
                    authored_regions[#authored_regions + 1] = region
                end

                if not selected or #region.floor > #selected.floor then
                    selected = region
                end
            end
        end
    end

    if include_stairless then
        return all_regions
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
local function complete_region(builder, region, up_count, down_count, serials)
    local missing = up_count + down_count - #region.up - #region.down

    if #region.floor < missing then
        error("layout has too few connected floor cells for stairs")
    end

    table.sort(region.floor, before)

    while #region.up < up_count do
        local point = take_floor(builder, region)
        local glyph = new_up[(serials.up % #new_up) + 1]

        builder:set(point.x, point.y, glyph)
        region.up[#region.up + 1] = point
        serials.up = serials.up + 1
    end

    while #region.down < down_count do
        local point = take_floor(builder, region)
        local glyph = new_down[(serials.down % #new_down) + 1]

        builder:set(point.x, point.y, glyph)
        region.down[#region.down + 1] = point
        serials.down = serials.down + 1
    end

    table.sort(region.up, before)
    table.sort(region.down, before)

    local pairs = {}

    for index = 1, math.max(#region.up, #region.down) do
        pairs[index] = {
            up = region.up[index],
            down = region.down[index],
        }
    end

    return pairs
end

-- Each profile states the minimum exits the branch needs in addition to
-- authored exits. Terminal floors request no new down exits, while a
-- branch entry requests only one return exit to its parent.
function stairs.complete(builder, profile)
    profile = profile or { up = 3, down = 3 }
    local regions = selected_regions(builder)

    if #regions == 0 then
        error("layout has no playable floor for stairs")
    end

    local up_count = 0
    local down_count = 0
    local serials = {
        up = 0,
        down = 0,
    }

    for _, region in ipairs(regions) do
        -- Ordinary floors pair every authored exit within its region.
        -- A branch entry or bottom uses only the exits actually required.
        local paired = math.max(1, #region.up, #region.down)

        up_count = up_count + (profile.up >= 3 and paired or #region.up)
        down_count = down_count +
            (profile.down >= 3 and paired or #region.down)
        serials.up = serials.up + #region.up
        serials.down = serials.down + #region.down
    end

    local pairs = {}

    for index, region in ipairs(regions) do
        local paired = math.max(1, #region.up, #region.down)
        local needed_up = profile.up >= 3 and paired or #region.up
        local needed_down = profile.down >= 3 and paired or #region.down

        if index == 1 then
            needed_up = needed_up + math.max(0, profile.up - up_count)
            needed_down = needed_down + math.max(0,
                profile.down - down_count)
        end

        for _, pair in ipairs(complete_region(builder,
            region, needed_up, needed_down, serials)) do
            pairs[#pairs + 1] = pair
        end
    end

    return pairs
end

-- A source encompassing MAP can intentionally put a one-way authored exit
-- in a tiny side region. Keep that exit instead of trying to fabricate its
-- opposite on a cell that does not exist. Complete the branch minimum in
-- the largest playable region, which also supplies the entry landing.
function stairs.complete_encompass(builder, profile)
    local regions = selected_regions(builder, true)

    if #regions == 0 then
        error("encompassing map has no playable floor for stairs")
    end

    local main = regions[1]
    local authored_up = 0
    local authored_down = 0

    for _, region in ipairs(regions) do
        authored_up = authored_up + #region.up
        authored_down = authored_down + #region.down

        if #region.floor > #main.floor then
            main = region
        end
    end

    local add_up = math.max(0, profile.up - authored_up,
        1 - #main.up)
    local add_down = math.max(0, profile.down - authored_down)

    if profile.down > 0 then
        add_down = math.max(add_down, 1 - #main.down)
    end

    if #main.floor < add_up + add_down then
        error("encompassing map has too few main-region floor cells for stairs")
    end

    table.sort(main.floor, before)

    for index = 1, add_up do
        local point = take_floor(builder, main)
        local glyph = new_up[((authored_up + index - 1) % #new_up) + 1]

        builder:set(point.x, point.y, glyph)
        main.up[#main.up + 1] = point
    end

    for index = 1, add_down do
        local point = take_floor(builder, main)
        local glyph = new_down[((authored_down + index - 1) % #new_down) + 1]

        builder:set(point.x, point.y, glyph)
        main.down[#main.down + 1] = point
    end

    local pairs = {}

    -- The first pair supplies the live floor entry, so emit the main region
    -- first even when a smaller side region appeared earlier in the MAP.
    local function append_region(region)
        table.sort(region.up, before)
        table.sort(region.down, before)

        for index = 1, math.max(#region.up, #region.down) do
            pairs[#pairs + 1] = {
                up = region.up[index],
                down = region.down[index],
            }
        end
    end

    append_region(main)

    for _, region in ipairs(regions) do
        if region ~= main then
            append_region(region)
        end
    end

    return pairs
end

return stairs
