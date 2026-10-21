-- Theory of operation: a fixed primary vault is the floor's main authored
-- feature. The generic layout may have completed stairs or a branch entrance
-- in its footprint. Move those provisional stairs before testing its fit.
local glyphs = require("constants.vault_glyphs")
local grid = require("policy.generation.grid")

local primary_stairs = {}

-- Match placement.preferred_origin for each fixed orientation. Transparent
-- padding is included because placement protects the complete MAP rectangle.
local function footprint(vault)
    local width = 0

    for _, row in ipairs(vault.rows) do
        width = math.max(width, #row)
    end

    local height = #vault.rows

    local left = math.floor((grid.width - width) / 2)
    local top = math.floor((grid.height - height) / 2)
    local side = vault.orientation

    if side:find("west", 1, true) then
        left = 2
    elseif side:find("east", 1, true) then
        left = grid.width - width - 2
    end

    if side:find("north", 1, true) then
        top = 2
    elseif side:find("south", 1, true) then
        top = grid.height - height - 2
    end

    return {
        left = left,
        top = top,
        width = width,
        height = height,
    }
end

-- A stair outside the fixed rectangle does not need to move.
local function inside(bounds, point)
    return point.x >= bounds.left and
        point.x < bounds.left + bounds.width and
        point.y >= bounds.top and
        point.y < bounds.top + bounds.height
end

-- Prefer existing dry land, then shallow water. A floor cell nearest the
-- old stair changes the surrounding procedural layout as little as possible.
local function destination(builder, bounds, protected, original)
    local best
    local score

    for y = 1, grid.height - 2 do
        for x = 1, grid.width - 2 do
            local point = { x = x, y = y }
            local glyph = builder:cell(x, y)

            if not inside(bounds, point) and
                not protected[x .. ":" .. y] and
                (glyph == "." or glyph == "W") then
                local priority = glyph == "." and 0 or 1000
                local distance = math.abs(x - original.x) +
                    math.abs(y - original.y)
                local candidate_score = priority + distance

                if not score or candidate_score < score then
                    best = point
                    score = candidate_score
                end
            end
        end
    end

    return best
end

-- Mutate the original point: both the layout stair pair and the scheduled
-- branch link retain this reference when the map subsequently moves it.
local function relocate_point(builder, bounds, protected, point)
    if not inside(bounds, point) then
        return
    end

    local glyph = builder:cell(point.x, point.y)

    if not glyphs.up[glyph] and not glyphs.down[glyph] then
        error("primary vault provisional stair lost its source glyph")
    end

    local next_point = destination(builder, bounds, protected, point)

    if not next_point then
        error("fixed primary vault has no outside stair landing")
    end

    protected[point.x .. ":" .. point.y] = nil
    builder:set(point.x, point.y, ".")
    builder:set(next_point.x, next_point.y, glyph)
    point.x = next_point.x
    point.y = next_point.y
    protected[point.x .. ":" .. point.y] = true
end

-- Authored entrance maps have their own placed records. Only generated
-- temporary stairs move with a fixed primary map; a floating map can retry.
function primary_stairs.relocate(builder, vault, context)
    if vault.orientation == "float" then
        return
    end

    local bounds = footprint(vault)
    local protected = context.protected

    for _, point in ipairs(context.required or {}) do
        relocate_point(builder, bounds, protected, point)
    end

    for _, link in ipairs(context.provisional_links or {}) do
        relocate_point(builder, bounds, protected, link)
    end
end

return primary_stairs
