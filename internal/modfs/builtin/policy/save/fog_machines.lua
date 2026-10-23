-- A saved fog entity must still describe exactly one realized DES marker.
-- Reparse the committed definition so altered clocks cannot smuggle in a
-- different cloud kind, location, or rule after restoration.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local definitions = require("policy.world.fog_machine_definitions")

local fog = {}

-- Use the authored record's stable level and index, not query order or a
-- generated entity ID, to join immutable map input with saved ECS state.
local function marker_key(level_id, index)
    return level_id .. ":" .. index
end

-- Build the set of fog markers that population already realized. An
-- overridden or still pending record cannot own a running machine.
local function expected_markers(input)
    local expected = {}

    for _, level in ipairs(input.levels or {}) do
        for index, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.MARKER and
                definitions.is_marker(record.identity) and
                not record.overridden and not record.pending then
                local rule, members = definitions.group(
                    level.vault_records, record)

                if members[1] == record then
                    local key = marker_key(level.id, index)

                    expected[key] = {
                        level = level,
                        record = record,
                        rule = rule,
                        members = members,
                    }
                end
            end
        end
    end

    return expected
end

-- Saved numeric rule fields must still equal their source constructor;
-- only countdown and buildup are allowed to change as the player acts.
local function validate_rule(state, expected)
    for name, value in pairs(expected.rule) do
        if state[name] ~= value then
            error("fog machine changed authored " .. name)
        end
    end

    if state.level_id ~= expected.level.id or
        state.x ~= expected.record.x or
        state.y ~= expected.record.y or
        state.vault_id ~= expected.record.source_id then
        error("fog machine moved away from its source marker")
    end

    if #state.record_indices ~= #expected.members or
        #state.positions_x ~= #expected.members or
        #state.positions_y ~= #expected.members then
        error("fog machine changed its chained source locations")
    end

    for index, record in ipairs(expected.members) do
        local source_index

        for position, candidate in ipairs(
            expected.level.vault_records) do
            if candidate == record then
                source_index = position
                break
            end
        end

        if state.record_indices[index] ~= source_index or
            state.positions_x[index] ~= record.x or
            state.positions_y[index] ~= record.y then
            error("fog machine changed its chained source locations")
        end
    end

    if state.countdown_aut < 0 or
        state.countdown_aut > state.delay_max or
        state.buildup_aut < 0 or
        state.buildup_aut > state.size_buildup_time then
        error("fog machine has invalid saved timing")
    end
end

-- Validate both directions of ownership: no duplicate entity may claim a
-- marker, and no realized source marker may disappear from saved ECS state.
function fog.validate(ctx, input)
    local expected = expected_markers(input)

    for _, entity in ipairs(ctx:query({ component.FOG_MACHINE })) do
        local state = ctx:get(entity, component.FOG_MACHINE)
        local key = marker_key(state.level_id, state.record_index)
        local entry = expected[key]

        if not entry then
            error("fog machine has no realized source marker " .. key)
        end

        validate_rule(state, entry)
        expected[key] = nil
    end

    if next(expected) then
        error("realized fog marker has no machine entity")
    end

    return {}
end

register.policy({
    id = "save.validate_fog_machines",
    run = fog.validate,
})

return fog
