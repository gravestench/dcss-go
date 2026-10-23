-- Restore joins every realized source gate marker to exactly one saved
-- ECS clock. The two records protect one another: a changed deadline,
-- altered outside cell, or invented Desolation visit is rejected on load.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local portal = require("policy.world.desolation.portal")
local desolation_rules = require("constants.desolation")
local terrain = require("constants.terrain")

local desolation = {}

-- Level and record index identify a marker after map transforms, without
-- assuming that two gates cannot share a coordinate in source text.
local function key(level_id, index)
    return level_id .. ":" .. index
end

-- Population creates clocks only for realized records. Pending records
-- remain declarative and may never acquire an ECS portal owner.
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
                    error("Desolation marker has no placed source vault")
                end

                expected[key(level.id, index)] = {
                    level = level,
                    record = record,
                    turns = portal.parse(record.identity),
                }
            end
        end
    end

    return expected
end

-- The fixed source draw is present in the DES marker. Restoring a timer
-- checks exact arithmetic rather than merely an allowed duration range.
local function validate_clock(ctx, state, expected)
    local record = expected.record
    local now = ctx:aut()

    if state.level_id ~= expected.level.id or
        state.x ~= record.x or state.y ~= record.y or
        state.vault_id ~= record.source_id or
        state.duration_turns ~= expected.turns or
        state.created_aut < 0 or state.created_aut > now or
        state.expires_aut ~= state.created_aut +
            expected.turns * 10 or
        state.next_notice_aut < state.created_aut +
            desolation_rules.FIRST_NOTICE_AUT or
        state.next_notice_aut > state.expires_aut +
            desolation_rules.SHORT_NOTICE_AUT or
        (state.final_warning and
            (not state.announced or
                now < state.expires_aut -
                    desolation_rules.FINAL_WARNING_AUT)) then
        error("Desolation portal changed its authored marker or deadline")
    end

    local feature = ctx:cell(state.level_id, state.x, state.y)
    local expected_feature = state.spent and
        terrain.DNGN_EXPIRED_PORTAL or
        terrain.DNGN_ENTER_DESOLATION

    if feature ~= expected_feature or
        (not state.spent and now >= state.expires_aut) then
        error("Desolation portal state disagrees with its gate cell")
    end
end

-- A live Desolation floor belongs to the one player visit that entered it.
-- Its spent outside gate is the return pointer's reciprocal witness.
local function validate_visit(ctx, input, markers)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_DESOLATION_VISIT)
    local position = ctx:get(player, component.POSITION)
    local floor

    for _, level in ipairs(input.levels or {}) do
        if level.branch_id == branches.BRANCH_DESOLATION then
            floor = level
            break
        end
    end

    if not floor then
        if visit then
            error("Desolation visitor has no active floor")
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
        error("Desolation floor has no valid outside return site")
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
        error("Desolation visitor has no spent entrance marker")
    end
end

-- Check both directions of the source-to-ECS join, then the player's
-- reciprocal visit. Extra or missing clocks are invalid saves.
function desolation.validate(ctx, input)
    local expected = expected_markers(input.levels)
    local seen = {}
    local markers = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_DESOLATION_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_DESOLATION_PORTAL)
        local identity = key(state.level_id, state.record_index)
        local authored = expected[identity]

        if not authored or seen[identity] then
            error("Desolation portal has no unique authored marker")
        end

        validate_clock(ctx, state, authored)
        seen[identity] = true
        markers[identity] = state
    end

    for identity in pairs(expected) do
        if not seen[identity] then
            error("Desolation source marker lacks an ECS portal")
        end
    end

    validate_visit(ctx, input, markers)

    return {}
end

register.policy({
    id = "save.validate_desolation_portals",
    run = desolation.validate,
})

return desolation
