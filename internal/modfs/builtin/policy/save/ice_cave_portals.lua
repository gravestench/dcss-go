-- Restore joins each realized source marker to exactly one Akara clock.
-- The marker witnesses difficulty and duration; the saved grid witnesses
-- whether that particular entrance remains live or has closed.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local generation = require("policy.generation.ice_cave.level")
local ice_cave = require("constants.ice_cave")
local difficulty = require("policy.world.ice_cave.difficulty")
local portal = require("policy.world.ice_cave.portal")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local save = {}

-- Level plus record index remains stable after map transforms and avoids
-- relying on the first marker with a matching cell.
local function key(level_id, index)
    return level_id .. ":" .. index
end

-- Pending records have not been populated and therefore own no clock.
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
                    error("Ice Cave marker has no placed source vault")
                end

                local turns, hard = portal.parse(record.identity)

                expected[key(level.id, index)] = {
                    level = level,
                    record = record,
                    turns = turns,
                    hard = hard,
                }
            end
        end
    end

    return expected
end

-- Exact arithmetic catches a forged deadline even when it remains inside
-- the legal 600–800-turn source range. The hard bit must match the marker.
local function validate_clock(ctx, state, expected)
    local record = expected.record
    local now = ctx:aut()

    if state.level_id ~= expected.level.id or
        state.x ~= record.x or state.y ~= record.y or
        state.vault_id ~= record.source_id or
        state.duration_turns ~= expected.turns or
        state.hard ~= expected.hard or
        state.hard ~= difficulty.hard(expected.level.branch_id,
            expected.level.local_depth) or
        (not state.spent and
            state.closure_reason ~= ice_cave.CLOSURE_NONE) or
        (state.spent and
            state.closure_reason ~= ice_cave.CLOSURE_ENTRY and
            state.closure_reason ~= ice_cave.CLOSURE_EXPIRY) or
        (state.closure_reason == ice_cave.CLOSURE_EXPIRY and
            now < state.expires_aut) or
        state.created_aut < 0 or state.created_aut > now or
        state.expires_aut ~= state.created_aut +
            expected.turns * 10 or
        state.next_notice_aut < state.created_aut +
            ice_cave.FIRST_NOTICE_AUT or
        state.next_notice_aut > state.expires_aut +
            ice_cave.SHORT_NOTICE_AUT or
        (state.final_warning and
            (not state.announced or
                now < state.expires_aut -
                    ice_cave.FINAL_WARNING_AUT)) then
        error("Ice Cave portal changed its authored marker or deadline")
    end

    local feature = ctx:cell(state.level_id, state.x, state.y)
    local expected_feature = state.spent and
        terrain.DNGN_EXPIRED_PORTAL or terrain.DNGN_ENTER_ICE_CAVE

    if feature ~= expected_feature or
        (not state.spent and now >= state.expires_aut) then
        error("Ice Cave portal state disagrees with its gate cell")
    end

    if not state.spent and #generation.candidates({}) == 0 then
        error("Ice Cave portal has no eligible destination")
    end
end

-- A live cave floor needs the player's reciprocal pointer and a spent
-- outside gate with the same saved hard choice.
local function validate_visit(ctx, input, markers)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_ICE_CAVE_VISIT)
    local position = ctx:get(player, component.POSITION)
    local floor

    for _, level in ipairs(input.levels or {}) do
        if level.branch_id == branches.BRANCH_ICE_CAVE then
            floor = level
            break
        end
    end

    if not floor then
        if visit then
            error("Ice Cave visitor has no active floor")
        end

        return
    end

    if not visit or not position or
        position.level_id ~= floor.id or
        visit.level_id ~= floor.id or
        visit.vault_id ~= floor.vault_id or
        not ctx:level_size(visit.origin_level_id) or
        ctx:cell(visit.origin_level_id,
            visit.origin_x, visit.origin_y) ~=
            terrain.DNGN_EXPIRED_PORTAL then
        error("Ice Cave floor has no valid outside return site")
    end

    if vaults.get(floor.vault_id).family ~=
        ice_cave.DESTINATION_FAMILY then
        error("Ice Cave floor has no valid source destination")
    end

    local found = false

    for _, state in pairs(markers) do
        if state.level_id == visit.origin_level_id and
            state.x == visit.origin_x and
            state.y == visit.origin_y and
            state.spent and
            state.closure_reason == ice_cave.CLOSURE_ENTRY and
            state.hard == visit.hard then
            found = true
            break
        end
    end

    if not found then
        error("Ice Cave visitor has no spent entrance marker")
    end
end

-- Validate marker-to-clock and clock-to-marker directions, then the one
-- possible active visitor. Extra or missing clocks make the save invalid.
function save.validate(ctx, input)
    local expected = expected_markers(input.levels)
    local seen = {}
    local markers = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_ICE_CAVE_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_ICE_CAVE_PORTAL)
        local identity = key(state.level_id, state.record_index)
        local authored = expected[identity]

        if not authored or seen[identity] then
            error("Ice Cave portal has no unique authored marker")
        end

        validate_clock(ctx, state, authored)
        seen[identity] = true
        markers[identity] = state
    end

    for identity in pairs(expected) do
        if not seen[identity] then
            error("Ice Cave source marker lacks an ECS portal")
        end
    end

    validate_visit(ctx, input, markers)

    return {}
end

register.policy({
    id = "save.validate_ice_cave_portals",
    run = save.validate,
})

return save
