-- Gauntlet restore joins each authored timed marker to one ECS clock.
-- The source marker owns the duration; the clock owns when that gate
-- appeared. Checking both directions prevents a forged or missing gate
-- from reopening a spent entrance or changing a run's deadline.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local gauntlet = require("constants.gauntlet")
local portal = require("policy.world.gauntlet.portal")
local terrain = require("constants.terrain")

local saved = {}

-- The saved record index is stable within its floor after MAP transforms.
local function marker_key(level_id, index)
    return level_id .. ":" .. index
end

-- Only realized marker records create clocks. An unused source map in the
-- catalog is not a gate, and an overridden or pending record is inert.
local function authored_markers(levels)
    local expected = {}

    for _, level in ipairs(levels or {}) do
        local placed = {}

        for _, id in ipairs(level.vault_ids or {}) do
            placed[id] = true
        end

        for index, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.MARKER and
                portal.is_marker(record) and
                not record.overridden and not record.pending then
                if not placed[record.source_id] then
                    error("Gauntlet gate marker has no placed source vault")
                end

                expected[marker_key(level.id, index)] = {
                    level = level,
                    record = record,
                    turns = portal.parse(record.identity),
                }
            end
        end
    end

    return expected
end

-- Validate absolute time against the one duration already stored in DES.
-- A spent gate remains a stone arch even if its former deadline passes.
local function validate_clock(ctx, state, authored)
    local record = authored.record
    local now = ctx:aut()
    local expected_feature = state.spent and
        terrain.DNGN_STONE_ARCH or
        terrain.DNGN_ENTER_GAUNTLET

    if state.level_id ~= authored.level.id or
        state.x ~= record.x or state.y ~= record.y or
        state.vault_id ~= record.source_id or
        state.duration_turns ~= authored.turns or
        state.created_aut < 0 or state.created_aut > now or
        state.expires_aut ~= state.created_aut + authored.turns * 10 or
        state.next_notice_aut < state.created_aut +
            gauntlet.FIRST_NOTICE_AUT or
        state.next_notice_aut > state.expires_aut +
            gauntlet.SHORT_NOTICE_AUT or
        ctx:cell(state.level_id, state.x, state.y) ~= expected_feature or
        (not state.spent and now >= state.expires_aut) then
        error("Gauntlet portal changed its marker, cell, or deadline")
    end
end

-- An active visit has one player and one spent outside gate. The return
-- pointer does not rely on whichever Gauntlet exit arch is chosen.
local function validate_visit(ctx, levels, clocks)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_GAUNTLET_VISIT)
    local position = ctx:get(player, component.POSITION)
    local floor

    for _, level in ipairs(levels or {}) do
        if level.branch_id == branches.BRANCH_GAUNTLET then
            floor = level
            break
        end
    end

    if not floor then
        if visit then
            error("Gauntlet visitor has no active floor")
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
            terrain.DNGN_STONE_ARCH then
        error("Gauntlet floor has no valid outside return site")
    end

    for _, clock in pairs(clocks) do
        if clock.level_id == visit.origin_level_id and
            clock.x == visit.origin_x and
            clock.y == visit.origin_y and
            clock.spent then
            return
        end
    end

    error("Gauntlet visitor has no spent entrance marker")
end

-- Save validation runs after dynamic components are restored, so it can
-- inspect real ECS state instead of rebuilding a second Go portal model.
function saved.validate(ctx, input)
    local expected = authored_markers(input.levels)
    local seen = {}
    local clocks = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_GAUNTLET_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_GAUNTLET_PORTAL)
        local key = marker_key(state.level_id, state.record_index)
        local authored = expected[key]

        if not authored or seen[key] then
            error("Gauntlet portal has no unique authored marker")
        end

        validate_clock(ctx, state, authored)
        seen[key] = true
        clocks[key] = state
    end

    for key in pairs(expected) do
        if not seen[key] then
            error("Gauntlet source marker lacks an ECS portal")
        end
    end

    validate_visit(ctx, input.levels, clocks)

    return {}
end

register.policy({
    id = "save.validate_gauntlet_portals",
    run = saved.validate,
})

return saved
