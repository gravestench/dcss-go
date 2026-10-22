-- Source Bazaar markers remain on the level after their gate is spent.
-- Restore joins each typed marker to exactly one ECS clock and checks that
-- a live Bazaar floor has one reciprocal player return pointer.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local portal = require("policy.world.bazaar.portal")
local terrain = require("constants.terrain")

local bazaar = {}

-- Stable level and record index identify a marker even if source map
-- geometry was rotated before it was placed in the saved Dungeon grid.
local function key(level_id, index)
    return level_id .. ":" .. index
end

-- A realized marker must keep its source record. Pending instructions do
-- not own an active timer and must not have an ECS portal entity.
local function expected_markers(levels)
    local expected = {}

    for _, level in ipairs(levels or {}) do
        local used = {}

        for _, id in ipairs(level.vault_ids or {}) do
            used[id] = true
        end

        for index, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.MARKER and
                portal.is_marker(record) and
                not record.overridden and not record.pending then
                if not used[record.source_id] then
                    error("Bazaar marker has no placed source vault")
                end

                expected[key(level.id, index)] = {
                    level = level,
                    record = record,
                    rule = portal.parse(record.identity),
                }
            end
        end
    end

    return expected
end

-- Deadline arithmetic is checked against the immutable DES bounds, so a
-- save cannot extend an entrance by altering only its ECS countdown.
local function validate_clock(ctx, state, expected)
    local rule = expected.rule
    local record = expected.record
    local now = ctx:aut()

    if state.level_id ~= expected.level.id or
        state.x ~= record.x or state.y ~= record.y or
        state.vault_id ~= record.source_id or
        state.low ~= rule.low or state.high ~= rule.high or
        state.timed ~= rule.timed or state.created_aut < 0 or
        state.created_aut > now then
        error("Bazaar portal changed its authored marker")
    end

    if state.timed then
        local duration = state.expires_aut - state.created_aut

        if duration < rule.low * 10 or duration > rule.high * 10 or
            duration % 10 ~= 0 then
            error("Bazaar portal has invalid saved duration")
        end
    elseif state.expires_aut ~= 0 then
        error("permanent Bazaar portal has a deadline")
    end

    local feature = ctx:cell(state.level_id, state.x, state.y)
    local expected_feature = state.spent and terrain.DNGN_STONE_ARCH or
        terrain.DNGN_ENTER_BAZAAR

    if feature ~= expected_feature or
        (state.timed and not state.spent and now >= state.expires_aut) then
        error("Bazaar portal state disagrees with its gate cell")
    end
end

-- A visit can exist only on its chosen live Bazaar floor. The outside
-- marker is already spent, but stays in ECS to prove the return location.
local function validate_visit(ctx, input, markers)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_BAZAAR_VISIT)
    local position = ctx:get(player, component.POSITION)
    local floor

    for _, level in ipairs(input.levels or {}) do
        if level.branch_id == branches.BRANCH_BAZAAR then
            floor = level
            break
        end
    end

    if not floor then
        if visit then
            error("Bazaar visitor has no active market")
        end

        return
    end

    if not visit or not position or
        position.level_id ~= floor.id or
        visit.level_id ~= floor.id or
        visit.vault_id ~= floor.vault_id or
        not ctx:level_size(visit.origin_level_id) or
        ctx:cell(visit.origin_level_id,
            visit.origin_x, visit.origin_y) ~= terrain.DNGN_STONE_ARCH then
        error("Bazaar floor has no valid outside return site")
    end

    local found = false

    for _, state in pairs(markers) do
        if state.level_id == visit.origin_level_id and
            state.x == visit.origin_x and state.y == visit.origin_y and
            state.spent then
            found = true
            break
        end
    end

    if not found then
        error("Bazaar visitor has no spent entrance marker")
    end
end

-- Check both directions: no forged extra marker and no authored marker
-- missing its saved ECS owner after the level's population completed.
function bazaar.validate(ctx, input)
    local expected = expected_markers(input.levels)
    local seen = {}
    local markers = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_BAZAAR_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_BAZAAR_PORTAL)
        local identity = key(state.level_id, state.record_index)
        local authored = expected[identity]

        if not authored or seen[identity] then
            error("Bazaar portal has no unique authored marker")
        end

        validate_clock(ctx, state, authored)
        seen[identity] = true
        markers[identity] = state
    end

    for identity in pairs(expected) do
        if not seen[identity] then
            error("Bazaar source marker lacks an ECS portal")
        end
    end

    validate_visit(ctx, input, markers)

    return {}
end

register.policy({
    id = "save.validate_bazaar_portals",
    run = bazaar.validate,
})

return bazaar
