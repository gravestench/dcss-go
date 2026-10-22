local generated = {}
local abyss = require("policy.world.abyss")
local branches = require("ids.branches")
local glyphs = require("constants.vault_glyphs")
local branch_schedule = require("policy.generation.branch_schedule")
local branch_levels = require("policy.generation.branch_levels")
local availability = require("policy.generation.floor_availability")
local temple_catalog = require("policy.generation.temple.catalog")
local pan_levels = require("policy.save.pan_levels")
local hell_levels = require("policy.save.hell_levels")
local bazaar_levels = require("policy.save.bazaar_levels")
local sewer_levels = require("policy.save.sewer_levels")
local hell_size = require("policy.generation.hell.size")

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

-- A source-labelled entrance has one stable child ID even before that child
-- exists. Once built, both exact cells must point back to each other.
local function valid_branch_entry(levels, parent, link, expected)
    local destination = branch_levels.id(expected.branch_id, 1)
    local child = levels[destination]

    if link.target_branch_id ~= expected.branch_id or
        link.source_feature ~= expected.entry_feature then
        return false
    end

    local available = expected.branch_id == branches.BRANCH_TEMPLE and
        #temple_catalog.main_ids() > 0 or
        availability.can_build(expected.branch_id, 1)

    if not available then
        return not child and not link.pending and
            link.unavailable ~= "" and link.to_level_id == 0 and
            link.to_x == 0 and link.to_y == 0
    end

    if link.to_level_id ~= destination or link.unavailable ~= "" then
        return false
    end

    if not child then
        return link.pending and link.to_x == 0 and link.to_y == 0
    end

    if link.pending or child.branch_id ~= expected.branch_id or
        child.local_depth ~= 1 then
        return false
    end

    local back = stair_at(child, link.to_x, link.to_y)

    return back and back.unavailable == "" and
        back.to_level_id == parent.id and
        back.to_x == link.x and back.to_y == link.y and
        up_features[feature(child, link.to_x, link.to_y)]
end

-- Internal branch stairs use the same exact reciprocal-cell rule as the
-- Dungeon, but their stable IDs are catalog IDs instead of local depths.
local function linked(levels, level, link, destination, upward)
    local target = levels[destination]

    if not target or link.pending or link.unavailable ~= "" or
        link.to_level_id ~= destination then
        return false
    end

    local back = stair_at(target, link.to_x, link.to_y)

    if not back or back.pending or back.unavailable ~= "" or
        back.to_level_id ~= level.id or
        back.to_x ~= link.x or back.to_y ~= link.y then
        return false
    end

    local target_feature = feature(target, link.to_x, link.to_y)

    return upward and down_features[target_feature] or
        up_features[target_feature]
end

-- Only floors the player has reached exist in a fresh generated save. Every
-- earlier stair is paired; the current frontier alone may point to a floor
-- that will be built on first entry. Fully built saves remain valid too.
function generated.validate(levels, by_id, chosen_schedule, pan_state,
    hell_state)
    branch_schedule.validate(chosen_schedule)
    pan_levels.validate(levels, pan_state)
    hell_levels.validate(by_id, hell_state)
    bazaar_levels.validate(levels)
    sewer_levels.validate(levels)
    local bottom = register.get("branches", branches.BRANCH_DUNGEON).depth
    local floors = 0

    for _, level in ipairs(levels) do
        if level.branch_id == branches.BRANCH_DUNGEON then
            floors = floors + 1
        end
    end

    if floors < 1 or floors > bottom or not by_id[abyss.level_id] then
        error("generated Dungeon save needs a Dungeon prefix and the Abyss")
    end

    for depth = 1, floors do
        local level = by_id[depth]

        if not level or level.branch_id ~= branches.BRANCH_DUNGEON or
            level.local_depth ~= depth or #level.cells ~= 70 or
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
        local expected_entries = {}
        local seen_entries = {}

        for _, entry in ipairs(branch_schedule.entries(chosen_schedule,
            branches.BRANCH_DUNGEON, depth)) do
            expected_entries[entry.branch_id] = entry
        end

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

            local branch_entry = link.target_branch_id and
                link.target_branch_id ~= ""
            local boundary = (depth == 1 and upward) or
                (depth == bottom and downward)

            if branch_entry then
                local expected = expected_entries[link.target_branch_id]

                if not expected or seen_entries[link.target_branch_id] or
                    not downward or not valid_branch_entry(by_id,
                        level, link, expected) then
                    error("generated Dungeon:" .. depth ..
                        " has an invalid branch entrance")
                end

                seen_entries[link.target_branch_id] = true
            elseif boundary then
                local dungeon_exit = depth == 1 and upward

                if link.to_level_id ~= 0 or
                    (dungeon_exit and
                        (not link.exit or link.unavailable ~= "")) or
                    (not dungeon_exit and
                        (link.exit or link.unavailable == "")) then
                    error("generated Dungeon:" .. depth ..
                        " has an invalid boundary exit")
                end
            elseif link.pending then
                if not downward or depth ~= floors or
                    link.to_level_id ~= depth + 1 or
                    link.to_x ~= 0 or link.to_y ~= 0 then
                    error("generated Dungeon:" .. depth ..
                        " has an invalid pending stair")
                end
            elseif not reciprocal(by_id, depth, link, upward) then
                error("generated Dungeon:" .. depth ..
                    " has an unpaired stair")
            end
        end

        for branch_id in pairs(expected_entries) do
            if not seen_entries[branch_id] then
                error("generated Dungeon:" .. depth ..
                    " lacks scheduled " .. branch_id .. " entrance")
            end
        end

        if up_count < 3 or down_count < 3 then
            error("generated Dungeon:" .. depth ..
                " has too few stair links")
        end
    end

    -- A branch floor can exist only after its scheduled parent entrance
    -- (or preceding floor) exists. Validate all generated branches as a
    -- graph rather than counting them as part of the Dungeon prefix.
    for _, level in ipairs(levels) do
        if level.branch_id ~= branches.BRANCH_DUNGEON and
            level.branch_id ~= branches.BRANCH_PANDEMONIUM and
            level.branch_id ~= branches.BRANCH_VESTIBULE and
            level.branch_id ~= branches.BRANCH_BAZAAR and
            level.branch_id ~= branches.BRANCH_SEWER and
            not hell_size.is_subbranch(register.get("branches",
                level.branch_id)) and
            level.id ~= abyss.level_id then
            local depth = level.local_depth
            local scheduled = chosen_schedule.entries[level.branch_id]

            if not scheduled or
                level.id ~= branch_levels.id(level.branch_id, depth) or
                #level.cells ~= 70 or #level.cells[1] ~= 80 or
                #level.stairs < 1 or
                not availability.can_build(level.branch_id, depth) then
                error("generated branch level has invalid identity or geometry")
            end

            local parent_id

            if depth == 1 then
                parent_id = branch_levels.id(scheduled.parent_id,
                    scheduled.parent_depth)
            else
                parent_id = branch_levels.id(level.branch_id, depth - 1)
            end

            if not by_id[parent_id] then
                error("generated " .. level.branch_id ..
                    " lacks its parent floor")
            end

            local expected_entries = {}
            local seen_entries = {}

            for _, entry in ipairs(branch_schedule.entries(chosen_schedule,
                level.branch_id, depth)) do
                expected_entries[entry.branch_id] = entry
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
                    error("generated " .. level.branch_id ..
                        " has a link on non-stair terrain")
                end

                local entry = expected_entries[link.target_branch_id]

                if entry then
                    if not downward or seen_entries[entry.branch_id] or
                        not valid_branch_entry(by_id, level, link, entry) then
                        error("generated " .. level.branch_id ..
                            " has an invalid branch entrance")
                    end

                    seen_entries[entry.branch_id] = true
                elseif link.target_branch_id and
                    link.target_branch_id ~= "" then
                    error("generated " .. level.branch_id ..
                        " has an unscheduled branch entrance")
                elseif upward then
                    if link.unavailable == "" and
                        not linked(by_id, level, link, parent_id, true) then
                        error("generated " .. level.branch_id ..
                            " has an unpaired up stair")
                    end
                elseif not availability.can_build(level.branch_id,
                    depth + 1) then
                    if link.unavailable == "" or link.to_level_id ~= 0 then
                        error("generated " .. level.branch_id ..
                            " has an invalid unavailable stair")
                    end
                elseif level.branch_id == branches.BRANCH_VAULTS and
                    depth == 4 and not link.pending and
                    link.unavailable ==
                    "Vaults:5 awaits its end vault in the Go port." and
                    link.to_level_id == 0 and link.to_x == 0 and
                    link.to_y == 0 and not by_id[branch_levels.id(
                        level.branch_id, depth + 1)] then
                    -- Saves made before Vaults:5 existed keep their exact
                    -- visible boundary. New games always create pending
                    -- links through the authored end layout instead.
                elseif link.pending then
                    local next_id = branch_levels.id(level.branch_id,
                        depth + 1)

                    if link.to_level_id ~= next_id or
                        by_id[next_id] or link.to_x ~= 0 or link.to_y ~= 0 then
                        error("generated " .. level.branch_id ..
                            " has an invalid pending stair")
                    end
                elseif not linked(by_id, level, link,
                    branch_levels.id(level.branch_id, depth + 1), false) then
                    error("generated " .. level.branch_id ..
                        " has an unpaired down stair")
                end
            end

            for branch_id in pairs(expected_entries) do
                if not seen_entries[branch_id] then
                    error("generated " .. level.branch_id ..
                        " lacks scheduled " .. branch_id .. " entrance")
                end
            end

            if up_count < 1 or
                (availability.can_build(level.branch_id,
                    depth + 1) and down_count < 3) then
                error("generated " .. level.branch_id ..
                    " has too few stair links")
            end
        end
    end
end

return generated
