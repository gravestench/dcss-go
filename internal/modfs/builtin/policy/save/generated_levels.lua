local generated = {}
local abyss = require("policy.world.abyss")
local branches = require("ids.branches")
local glyphs = require("constants.vault_glyphs")

local up_features = {}
local down_features = {}

for glyph in pairs(glyphs.up) do
    up_features[glyphs.terrain[glyph]] = true
end

for glyph in pairs(glyphs.down) do
    down_features[glyphs.terrain[glyph]] = true
end

-- Convert zero-based world coordinates to Lua cell array indices.
local function feature(level, x, y)
    return level.cells[y + 1][x + 1]
end

-- Find the reciprocal stair by cell, not merely by destination floor.
local function stair_at(level, x, y)
    for _, stair in ipairs(level.stairs) do
        if stair.x == x and stair.y == y then
            return stair
        end
    end

    return nil
end

-- Source stairs and added landings may use different glyphs. Their direction
-- and saved cell coordinates, rather than their glyph suffix, must agree.
local function reciprocal(levels, depth, link, upward)
    local destination = upward and depth - 1 or depth + 1
    local target = levels[destination]

    if not target or link.unavailable ~= "" or
        link.to_level_id ~= destination then
        return false
    end

    local other = stair_at(target, link.to_x, link.to_y)

    if not other or other.unavailable ~= "" or
        other.to_level_id ~= depth or
        other.to_x ~= link.x or other.to_y ~= link.y then
        return false
    end

    local target_feature = feature(target, link.to_x, link.to_y)

    if upward then
        return down_features[target_feature]
    end

    return up_features[target_feature]
end

-- Every generated Dungeon floor and each visible stair must survive restore.
-- Boundary exits explain the unavailable next branch; internal links pair
-- exact cells on adjacent floors in both directions.
function generated.validate(levels, by_id)
    local bottom = register.get("branches", branches.BRANCH_DUNGEON).depth

    if #levels ~= bottom + 1 or not by_id[abyss.level_id] then
        error("generated Dungeon save needs all Dungeon floors and the Abyss")
    end

    for depth = 1, bottom do
        local level = by_id[depth]

        if not level or #level.cells ~= 70 or
            #level.cells[1] ~= 80 or #level.stairs < 6 then
            error("generated Dungeon:" .. depth ..
                " has invalid geometry or stair count")
        end

        local maximum = depth == 1 and 36 or 30

        if level.initial_monsters < 3 or
            level.initial_monsters > maximum then
            error("generated Dungeon:" .. depth ..
                " has invalid monster budget")
        end

        local up_count = 0
        local down_count = 0

        for _, link in ipairs(level.stairs) do
            local stair_feature = feature(level, link.x, link.y)
            local upward = up_features[stair_feature]
            local downward = down_features[stair_feature]

            if upward then
                up_count = up_count + 1
            elseif downward then
                down_count = down_count + 1
            else
                error("generated Dungeon:" .. depth ..
                    " has a link on non-stair terrain")
            end

            local boundary = (depth == 1 and upward) or
                (depth == bottom and downward)

            if boundary then
                if link.unavailable == "" or link.to_level_id ~= 0 then
                    error("generated Dungeon:" .. depth ..
                        " has an invalid boundary exit")
                end
            elseif not reciprocal(by_id, depth, link, upward) then
                error("generated Dungeon:" .. depth ..
                    " has an unpaired stair")
            end
        end

        if up_count < 3 or down_count < 3 then
            error("generated Dungeon:" .. depth ..
                " has too few stair links")
        end
    end
end

return generated
