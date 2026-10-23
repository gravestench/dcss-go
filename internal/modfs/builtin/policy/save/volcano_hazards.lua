-- Theory of operation: authored DES records witness all event locations;
-- Akara owns clocks, remaining doors, and converted lava; the saved level
-- grid witnesses terrain changes. Restore joins all three before play.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local terrain = require("constants.terrain")
local volcano = require("constants.volcano")

local save = {}

-- One temporary floor and source NAME identify a hazard independently of
-- ECS entity allocation order or VFS file enumeration.
local function key(level_id, source_id)
    return level_id .. ":" .. source_id
end

-- Rebuild the immutable marker groups from realized source records. A
-- pending or overridden marker cannot justify a running event component.
local function source_groups(levels)
    local caves = {}
    local overflows = {}

    for _, level in ipairs(levels or {}) do
        for index, record in ipairs(level.vault_records or {}) do
            if record.kind == effects.MARKER and
                not record.pending and not record.overridden then
                local identity = record.identity or ""
                local source_key = key(level.id, record.source_id)

                if identity == volcano.COLLAPSE_MARKER then
                    local group = caves[source_key]

                    if not group then
                        group = {
                            level = level,
                            vault_id = record.source_id,
                            members = {},
                        }
                        caves[source_key] = group
                    end

                    group.members[#group.members + 1] = {
                        index = index,
                        x = record.x,
                        y = record.y,
                    }
                elseif identity == volcano.OVERFLOW_CLOCK_MARKER then
                    local group = overflows[source_key]

                    if not group then
                        group = {
                            level = level,
                            vault_id = record.source_id,
                            members = {},
                        }
                        overflows[source_key] = group
                    end

                    if group.clock_index then
                        error("Volcano overflow has duplicate source clocks")
                    end

                    group.clock_index = index
                else
                    local phase = identity:match("^" ..
                        volcano.OVERFLOW_CELL_PREFIX .. "([246])$")

                    if phase then
                        local group = overflows[source_key]

                        if not group then
                            group = {
                                level = level,
                                vault_id = record.source_id,
                                members = {},
                            }
                            overflows[source_key] = group
                        end

                        group.members[#group.members + 1] = {
                            index = index,
                            phase = tonumber(phase),
                            x = record.x,
                            y = record.y,
                        }
                    end
                end
            end
        end
    end

    return caves, overflows
end

-- The remaining cave list is an ordered subset of source marker indices.
-- Every consumed doorway must now be a stone wall on the same level grid.
local function validate_cave(ctx, state, source)
    if state.level_id ~= source.level.id or
        state.vault_id ~= source.vault_id or
        #state.record_indices ~= #state.positions_x or
        #state.record_indices ~= #state.positions_y or
        (state.countdown_aut == 0) ~=
            (#state.record_indices == 0) or
        state.countdown_aut < 0 or
        state.countdown_aut > volcano.COLLAPSE_MAX_AUT then
        error("Volcano cave clock or source identity is invalid")
    end

    local next_remaining = 1

    for _, marker in ipairs(source.members) do
        local current = state.record_indices[next_remaining]

        if current == marker.index then
            if state.positions_x[next_remaining] ~= marker.x or
                state.positions_y[next_remaining] ~= marker.y or
                ctx:cell(source.level.id, marker.x, marker.y) ==
                    terrain.DNGN_STONE_WALL then
                error("Volcano cave doorway moved")
            end

            next_remaining = next_remaining + 1
        elseif ctx:cell(source.level.id, marker.x, marker.y) ~=
            terrain.DNGN_STONE_WALL then
            error("Volcano cave consumed doorway is not collapsed")
        end
    end

    if next_remaining ~= #state.record_indices + 1 then
        error("Volcano cave has an unknown doorway index")
    end
end

-- The source index arrays cannot be rewritten to move a lava group. The
-- converted subset must be unique and agree with current lava terrain.
local function validate_overflow(ctx, state, source)
    if not source.clock_index or #source.members == 0 or
        state.level_id ~= source.level.id or
        state.vault_id ~= source.vault_id or
        state.clock_index ~= source.clock_index or
        #state.record_indices ~= #source.members or
        #state.groups ~= #source.members or
        #state.positions_x ~= #source.members or
        #state.positions_y ~= #source.members or
        state.phase < 0 or state.phase > 9 or
        (state.phase == 9 and state.countdown_aut ~= 0) or
        (state.phase < 9 and
            (state.countdown_aut < 1 or
                state.countdown_aut > volcano.OVERFLOW_MAX_AUT)) then
        error("Volcano overflow clock or phase is invalid")
    end

    local converted = {}

    for _, index in ipairs(state.converted_indices) do
        if converted[index] then
            error("Volcano overflow has a duplicate converted cell")
        end

        converted[index] = true
    end

    for position, marker in ipairs(source.members) do
        if state.record_indices[position] ~= marker.index or
            state.groups[position] ~= marker.phase or
            state.positions_x[position] ~= marker.x or
            state.positions_y[position] ~= marker.y then
            error("Volcano overflow source positions changed")
        end

        local is_lava = ctx:cell(source.level.id,
            marker.x, marker.y) == terrain.DNGN_LAVA
        local marked = converted[marker.index] or false

        if is_lava ~= marked or
            (marked and state.phase < marker.phase) then
            error("Volcano overflow phase disagrees with lava terrain")
        end

        converted[marker.index] = nil
    end

    if next(converted) then
        error("Volcano overflow has an unknown converted cell")
    end
end

-- Validate each expected event exactly once in both directions. Retired
-- floors cannot leave a clock behind, and a live source cannot lose one.
function save.validate(ctx, input)
    local caves, overflows = source_groups(input.levels)

    for _, entity in ipairs(ctx:query({
        component.WORLD_VOLCANO_COLLAPSE,
    })) do
        local state = ctx:get(entity,
            component.WORLD_VOLCANO_COLLAPSE)
        local identity = key(state.level_id, state.vault_id)
        local source = caves[identity]

        if not source then
            error("Volcano cave has no realized source markers")
        end

        validate_cave(ctx, state, source)
        caves[identity] = nil
    end

    for _, entity in ipairs(ctx:query({
        component.WORLD_VOLCANO_OVERFLOW,
    })) do
        local state = ctx:get(entity,
            component.WORLD_VOLCANO_OVERFLOW)
        local identity = key(state.level_id, state.vault_id)
        local source = overflows[identity]

        if not source then
            error("Volcano overflow has no realized source markers")
        end

        validate_overflow(ctx, state, source)
        overflows[identity] = nil
    end

    if next(caves) or next(overflows) then
        error("Volcano source event has no Akara clock")
    end

    return {}
end

register.policy({
    id = "save.validate_volcano_hazards",
    run = save.validate,
})

return save
