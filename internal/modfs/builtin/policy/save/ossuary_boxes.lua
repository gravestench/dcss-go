-- Theory of operation: the boxes vault has several authored trigger cells
-- and several stone walls, but one atomic event opens every wall and
-- consumes every trigger. The level records describe the immutable group;
-- ECS trigger components and live terrain show whether it has fired.
-- Restore must reject any mixture that no legal event could produce.
local branches = require("ids.branches")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local terrain = require("constants.terrain")
local trigger_ids = require("constants.vault_triggers")

local boxes = {}

-- Build one expected group from the saved source records, using their
-- final oriented coordinates and list positions as durable identities.
local function source_group(level)
    local group = {
        id = level.id .. ":" .. level.vault_id .. ":" ..
            trigger_ids.OSSUARY_BOXES_GROUP,
        level_id = level.id,
        vault_id = level.vault_id,
        triggers = {},
        wall_indices = {},
        wall_x = {},
        wall_y = {},
    }

    for index, record in ipairs(level.vault_records or {}) do
        local arguments = record.arguments or {}

        if record.source_id == level.vault_id and
            not record.overridden and
            arguments.group == trigger_ids.OSSUARY_BOXES_GROUP then
            if record.kind ~= effects.MARKER then
                error("Ossuary boxes have a non-marker group member")
            end

            if record.identity == trigger_ids.OSSUARY_BOXES_OPEN and
                arguments.role == "trigger" then
                group.triggers[index] = record
            elseif record.identity == trigger_ids.OSSUARY_BOXES_WALL and
                arguments.role == "wall" then
                group.wall_indices[#group.wall_indices + 1] = index
                group.wall_x[#group.wall_x + 1] = record.x
                group.wall_y[#group.wall_y + 1] = record.y
            else
                error("Ossuary boxes have an unknown group member")
            end
        end
    end

    if next(group.triggers) == nil then
        if #group.wall_indices > 0 then
            error("Ossuary box walls have no source trigger")
        end

        return nil
    end

    if #group.wall_indices == 0 then
        error("Ossuary boxes have no linked source walls")
    end

    return group
end

-- Compare the saved link vector against source order. This catches a
-- forged record index or coordinate even when it names another valid wall.
local function matching_links(state, group)
    if #state.wall_record_indices ~= #group.wall_indices or
        #state.wall_x ~= #group.wall_x or
        #state.wall_y ~= #group.wall_y then
        return false
    end

    for index, source_index in ipairs(group.wall_indices) do
        if state.wall_record_indices[index] ~= source_index or
            state.wall_x[index] ~= group.wall_x[index] or
            state.wall_y[index] ~= group.wall_y[index] then
            return false
        end
    end

    return true
end

-- The callback changes every stone wall to floor before consuming the
-- group. Mixed terrain is impossible even if all ECS markers are absent.
local function opened_walls(ctx, group)
    local opened = 0

    for index, x in ipairs(group.wall_x) do
        local feature = ctx:cell(group.level_id, x, group.wall_y[index])

        if feature == terrain.DNGN_FLOOR then
            opened = opened + 1
        elseif feature ~= terrain.DNGN_STONE_WALL then
            error("Ossuary box wall has unexpected terrain")
        end
    end

    if opened > 0 and opened < #group.wall_x then
        error("Ossuary box walls were only partly opened")
    end

    return opened == #group.wall_x
end

-- Every armed marker must match its exact source record and carry the
-- complete wall vector. Once any wall opens, none may remain armed.
local function validate_triggers(group, opened, states)
    local seen = {}

    for _, state in ipairs(states) do
        local source = group.triggers[state.record_index]

        if opened or not source or seen[state.record_index] or
            state.level_id ~= group.level_id or
            state.vault_id ~= group.vault_id or
            state.x ~= source.x or state.y ~= source.y or
            state.group_id ~= group.id or
            state.callback_module ~= "ossuary_boxes" or
            state.callback_method ~= "open" or
            not matching_links(state, group) then
            error("Ossuary box trigger differs from source group")
        end

        seen[state.record_index] = true
    end

    if not opened then
        for index in pairs(group.triggers) do
            if not seen[index] then
                error("Ossuary box trigger is missing")
            end
        end
    end
end

-- A group exists only on its active source floor. An extra component
-- cannot invent a trigger on another level or after that floor retires.
function boxes.validate(ctx, input)
    local groups = {}
    local states = {}

    for _, level in ipairs(input.levels or {}) do
        if level.branch_id == branches.BRANCH_OSSUARY then
            local group = source_group(level)

            if group then
                groups[group.id] = group
            end
        end
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_TRIGGER })) do
        local state = ctx:get(entity, component.WORLD_VAULT_TRIGGER)

        if state.callback_module == "ossuary_boxes" then
            local group = groups[state.group_id]

            if not group then
                error("Ossuary box trigger has no source group")
            end

            states[group.id] = states[group.id] or {}
            states[group.id][#states[group.id] + 1] = state
        end
    end

    for id, group in pairs(groups) do
        local opened = opened_walls(ctx, group)

        validate_triggers(group, opened, states[id] or {})
    end

    return {}
end

register.policy({
    id = "save.validate_ossuary_boxes",
    run = boxes.validate,
})

return boxes
