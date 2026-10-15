local generated = {}
local abyss = require("policy.world.abyss")

local function feature(level, x, y)
    return level.cells[y + 1][x + 1]
end

local function stair_at(level, x, y)
    for _, stair in ipairs(level.stairs) do
        if stair.x == x and stair.y == y then
            return stair
        end
    end

    return nil
end

local function reciprocal(levels, depth, link)
    local target = levels[link.to_level_id]

    if not target or link.unavailable ~= "" or link.to_level_id ~= 3 - depth then
        return false
    end

    local other = stair_at(target, link.to_x, link.to_y)

    if not other or other.to_level_id ~= depth or
        other.to_x ~= link.x or other.to_y ~= link.y then
        return false
    end

    local from_feature = feature(levels[depth], link.x, link.y)
    local to_feature = feature(target, link.to_x, link.to_y)

    return (depth == 1 and from_feature == "DNGN_STONE_STAIRS_DOWN_I" and
        to_feature == "DNGN_STONE_STAIRS_UP_I") or
        (depth == 2 and from_feature == "DNGN_STONE_STAIRS_UP_I" and
        to_feature == "DNGN_STONE_STAIRS_DOWN_I")
end

function generated.validate(levels, by_id)
    if #levels ~= 3 or not by_id[1] or not by_id[2] or
        not by_id[abyss.level_id] then
        error("generated Dungeon save needs D:1-2 and the Abyss")
    end

    for depth = 1, 2 do
        local level = by_id[depth]

        if #level.cells[1] ~= 80 or #level.cells ~= 70 or #level.stairs ~= 6 then
            error("generated Dungeon:" .. depth .. " has invalid geometry or stair count")
        end

        local maximum = depth == 2 and 30 or 36

        if level.initial_monsters < 3 or level.initial_monsters > maximum then
            error("generated Dungeon:" .. depth .. " has invalid monster budget")
        end

        local up_count = 0
        local down_count = 0

        for _, link in ipairs(level.stairs) do
            local stair_feature = feature(level, link.x, link.y)

            if stair_feature == "DNGN_STONE_STAIRS_UP_I" then
                up_count = up_count + 1
            else
                down_count = down_count + 1
            end

            if depth == 1 and stair_feature == "DNGN_STONE_STAIRS_UP_I" then
                if link.unavailable == "" then
                    error("generated Dungeon:1 has an invalid exit")
                end
            elseif depth == 2 and stair_feature == "DNGN_STONE_STAIRS_DOWN_I" then
                if link.unavailable == "" then
                    error("generated Dungeon:2 has an invalid exit")
                end
            elseif not reciprocal(by_id, depth, link) then
                error("generated Dungeon:" .. depth .. " has an unpaired stair")
            end
        end

        if up_count ~= 3 or down_count ~= 3 then
            error("generated Dungeon:" .. depth .. " needs three stair pairs")
        end
    end
end

return generated
