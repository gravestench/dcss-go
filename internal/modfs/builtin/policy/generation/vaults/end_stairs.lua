-- Theory of operation: an encompass finale is the floor's main authored
-- feature. The generic layout pass may have already completed its missing
-- stairs in that footprint. Move only those generated base stairs outside
-- the fixed map, then let the usual connector join them to its exits.
local glyphs = require("constants.vault_glyphs")
local grid = require("policy.generation.grid")

local end_stairs = {}

-- The fixed encompass origin is centered by the same placement rule used
-- for DES MAPs. Transparent padding still belongs to its protected bounds.
local function footprint(vault)
    local width = 0

    for _, row in ipairs(vault.rows) do
        width = math.max(width, #row)
    end

    local height = #vault.rows

    return {
        left = math.floor((grid.width - width) / 2),
        top = math.floor((grid.height - height) / 2),
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

-- Mutate the existing point object: the layout stair pair and the required
-- connector list both reference it, so save and reciprocal travel agree.
function end_stairs.relocate(builder, vault, context)
    if vault.orientation ~= "encompass" then
        return
    end

    local bounds = footprint(vault)
    local protected = context.protected

    for _, point in ipairs(context.required or {}) do
        if inside(bounds, point) then
            local glyph = builder:cell(point.x, point.y)

            if not glyphs.up[glyph] and not glyphs.down[glyph] then
                error("end vault base stair lost its source glyph")
            end

            local next_point = destination(builder, bounds, protected, point)

            if not next_point then
                error("encompass end vault has no outside stair landing")
            end

            protected[point.x .. ":" .. point.y] = nil
            builder:set(point.x, point.y, ".")
            builder:set(next_point.x, next_point.y, glyph)
            point.x = next_point.x
            point.y = next_point.y
            protected[point.x .. ":" .. point.y] = true
        end
    end
end

return end_stairs
