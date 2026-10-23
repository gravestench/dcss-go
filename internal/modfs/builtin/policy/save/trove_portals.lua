-- Theory of operation: restore joins a placed source Trove marker to one
-- Akara gate and compares its canonical price witness, state, receipt, and
-- grid feature. An active reward floor also needs the player's reciprocal
-- visit and that same spent outside gate. Validation never rerolls content.
-- Example: changing a modded gate price without replacing the saved marker
-- is rejected before the character can enter the game.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local generation = require("policy.generation.trove.level")
local levels = require("policy.generation.branch_levels")
local portal = require("policy.world.trove.portal")
local terrain = require("constants.terrain")
local toll = require("policy.world.trove.toll")
local trove = require("constants.trove")
local price_policies = require("policy.world.trove.prices.catalog")
local vaults = require("policy.generation.vaults.catalog")

local save = {}

-- Level plus source-record index is stable across transforms and avoids
-- treating two records at the same cell as one gateway.
local function key(level_id, index)
    return level_id .. ":" .. index
end

-- Every placed Trove entrance must expose one live, priced source marker.
-- This catches a mod-added entry that forgot its O toll before restore.
local function expected_markers(levels)
    local expected = {}
    local ordinary = {}

    -- Saved Dungeon history also includes Temple and altar definitions.
    -- Their own save validators resolve those catalogs; only ordinary
    -- vault IDs can be source Trove entrances in this owner.
    vaults.load()

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        ordinary[id] = true
    end

    for _, level in ipairs(levels or {}) do
        local counts = {}

        for _, id in ipairs(level.vault_ids or {}) do
            if ordinary[id] then
                local definition = vaults.get(id)

                if definition.family == trove.ENTRY_FAMILY then
                    counts[id] = 0
                end
            end
        end

        for index, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.MARKER and
                portal.is_marker(record) then
                if not counts[record.source_id] or
                    record.overridden or record.pending then
                    error("Trove marker has no realized source entrance")
                end

                counts[record.source_id] = counts[record.source_id] + 1
                expected[key(level.id, index)] = {
                    level = level,
                    record = record,
                }
            end
        end

        for id, count in pairs(counts) do
            if count ~= 1 then
                error("Trove entrance " .. id ..
                    " does not have exactly one toll marker")
            end
        end
    end

    return expected
end

-- A receipt must match the immutable price class and amount. The piety
-- delta can vary with worship at entry but cannot be negative.
local function valid_receipt(state)
    if not state.spent then
        return state.receipt_kind == "" and
            state.receipt_item_id == "" and
            state.receipt_quantity == 0 and
            state.destination_id == ""
    end

    if state.receipt_kind ~= state.price_kind or
        state.destination_id == "" then
        return false
    end

    local custom = price_policies.get(state.price_kind)

    if custom then
        return custom.valid_receipt(state)
    end

    if state.price_kind == trove.PRICE_NO_PIETY then
        return state.receipt_item_id == "" and
            state.receipt_quantity >= 0 and
            state.receipt_quantity <=
                trove.MAX_PIETY - trove.PIETY_AFTER_PAYMENT
    end

    if state.receipt_item_id ~= state.item_id then
        return false
    end

    if state.price_kind == trove.PRICE_RUNE then
        return state.receipt_quantity == 0
    end

    return state.receipt_quantity == state.quantity
end

-- Recompute the canonical witness from fields, then compare the typed
-- source record and the exact live or expired grid feature.
local function validate_gate(ctx, state, expected)
    local record = expected.record
    local price = {
        kind = state.price_kind,
        item_id = state.item_id,
        quantity = state.quantity,
        minimum_plus = state.minimum_plus,
        ego_id = state.ego_id,
        artefact_name = state.artefact_name,
        source_rune_index = state.source_rune_index,
    }

    if state.level_id ~= expected.level.id or
        state.x ~= record.x or state.y ~= record.y or
        state.vault_id ~= record.source_id or
        record.arguments.price ~= state.price_witness or
        toll.encode(price) ~= state.price_witness or
        not valid_receipt(state) or
        (state.spent and
            state.closure_reason ~= trove.CLOSURE_PAID) or
        (not state.spent and
            state.closure_reason ~= trove.CLOSURE_NONE) then
        error("Trove gate changed its source marker or price")
    end

    local expected_feature = state.spent and
        terrain.DNGN_EXPIRED_PORTAL or terrain.DNGN_ENTER_TROVE

    if ctx:cell(state.level_id, state.x, state.y) ~= expected_feature then
        error("Trove gate state disagrees with its grid feature")
    end

    if state.spent and
        vaults.get(state.destination_id).family ~= trove.DESTINATION_FAMILY then
        error("Trove gate has an invalid reward layout")
    end

    if not state.spent and #generation.candidates({}) == 0 then
        error("Trove gate has no eligible reward layout")
    end
end

-- A live reward floor has exactly one visitor, a spent outside gate, and
-- the selected source NAME saved in both the visit and gate.
local function validate_visit(ctx, input, gates)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_TROVE_VISIT)
    local position = ctx:get(player, component.POSITION)
    local floor

    for _, level in ipairs(input.levels or {}) do
        if level.branch_id == branches.BRANCH_TROVE then
            if floor then
                error("Trove save has multiple active reward floors")
            end

            floor = level
        end
    end

    if not floor then
        if visit then
            error("Trove visitor has no active reward floor")
        end

        return
    end

    if not visit or not position or
        position.level_id ~= floor.id or
        floor.id ~= levels.id(branches.BRANCH_TROVE, 1) or
        floor.local_depth ~= 1 or
        floor.height ~= 70 or floor.width ~= 80 or
        floor.stair_count ~= 0 or floor.initial_monsters ~= 0 or
        floor.trove_exits < 1 or
        visit.level_id ~= floor.id or
        visit.vault_id ~= floor.vault_id or
        not ctx:level_size(visit.origin_level_id) or
        ctx:cell(visit.origin_level_id,
            visit.origin_x, visit.origin_y) ~=
            terrain.DNGN_EXPIRED_PORTAL or
        vaults.get(floor.vault_id).family ~=
            trove.DESTINATION_FAMILY then
        error("Trove floor has no valid visitor return site")
    end

    local found = false

    for _, gate in pairs(gates) do
        if gate.level_id == visit.origin_level_id and
            gate.x == visit.origin_x and
            gate.y == visit.origin_y and
            gate.spent and
            gate.destination_id == visit.vault_id then
            found = true
            break
        end
    end

    if not found then
        error("Trove visitor has no spent outside gate")
    end
end

-- Check both directions of the marker-to-ECS join before play resumes.
-- Extra or missing gate entities make the saved world inconsistent.
function save.validate(ctx, input)
    local expected = expected_markers(input.levels)
    local seen = {}
    local gates = {}

    for _, entity in ipairs(ctx:query({ component.WORLD_TROVE_PORTAL })) do
        local state = ctx:get(entity, component.WORLD_TROVE_PORTAL)
        local identity = key(state.level_id, state.record_index)
        local authored = expected[identity]

        if not authored or seen[identity] then
            error("Trove gate has no unique authored marker")
        end

        validate_gate(ctx, state, authored)
        seen[identity] = true
        gates[identity] = state
    end

    for identity in pairs(expected) do
        if not seen[identity] then
            error("Trove source marker lacks an ECS gate")
        end
    end

    validate_visit(ctx, input, gates)

    return {}
end

register.policy({
    id = "save.validate_trove_portals",
    run = save.validate,
})

return save
