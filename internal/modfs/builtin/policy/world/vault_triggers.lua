-- Source vault markers can invoke named Lua policy when the player moves
-- onto their cell. The level owns immutable source intent; one ECS entity
-- owns whether that particular callback is still armed.
local component = require("constants.component")
local trigger_ids = require("constants.vault_triggers")
local death_hooks = require("policy.combat.death_hooks")

local triggers = {}

-- Other DES markers remain data for their own systems. A malformed
-- trigger identity is rejected when its level tries to materialize it.
function triggers.is_record(identity)
    return type(identity) == "string" and
        identity:sub(1, #trigger_ids.PREFIX) == trigger_ids.PREFIX
end

-- Resolve a short callback ID inside the layered Lua callback directory.
-- Checking the method here reports a broken mod while opening the floor.
local function callback(identity)
    local module_name, method_name = identity:match(
        "^vault_trigger:([a-z][a-z0-9_]*)%.([a-z][a-z0-9_]*)$")

    if not module_name then
        error("invalid vault trigger callback " .. tostring(identity))
    end

    local module = require(
        "policy.world.vault_trigger_callbacks." .. module_name)
    local method = module[method_name]

    if type(method) ~= "function" then
        error("missing vault trigger method " .. identity)
    end

    return module_name, method_name, method
end

-- The Lady's entrance markers share one authored spawn target. Resolve it
-- from the complete level record set after map orientation is final.
local function shared_target(level, record)
    if record.identity ~= trigger_ids.LADY_OF_LAKE_SPAWN then
        return nil
    end

    local found

    for _, candidate in ipairs(level.vault_records or {}) do
        if candidate.source_id == record.source_id and
            candidate.identity == trigger_ids.MERFOLK_AVATAR_TARGET then
            if found then
                error("Lady of the Lake has multiple avatar targets")
            end

            found = candidate
        end
    end

    if not found then
        error("Lady of the Lake has no avatar target")
    end

    return found
end

-- A named marker group links source trigger cells to its authored wall
-- records after orientation. The level record indexes are durable save
-- identities, while the final coordinates let a callback act directly.
local function linked_group(level, record)
    local arguments = record.arguments or {}
    local name = arguments.group

    if not name then
        return "", {}, {}, {}
    end

    local group_id = level.id .. ":" .. record.source_id .. ":" .. name
    local indices = {}
    local wall_x = {}
    local wall_y = {}

    for _, candidate in ipairs(level.vault_records or {}) do
        local member = candidate.arguments or {}

        if candidate.source_id == record.source_id and
            member.group == name and member.role == "wall" then
            indices[#indices + 1] = candidate.index
            wall_x[#wall_x + 1] = candidate.x
            wall_y[#wall_y + 1] = candidate.y
        end
    end

    return group_id, indices, wall_x, wall_y
end

-- Create the saved trigger after DES orientation fixes its final cell.
function triggers.materialize(ctx, level, record)
    local module_name, method_name = callback(record.identity)
    local target = shared_target(level, record)
    local group_id, wall_indices, wall_x, wall_y =
        linked_group(level, record)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_VAULT_TRIGGER, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        callback_module = module_name,
        callback_method = method_name,
        event = record.arguments and record.arguments.event or
            trigger_ids.ENTER_EVENT,
        target_x = target and target.x or 0,
        target_y = target and target.y or 0,
        group_id = group_id,
        wall_record_indices = wall_indices,
        wall_x = wall_x,
        wall_y = wall_y,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- The Lady's two source glyph types share one TriggerableFunction. Ordinary
-- callbacks own only their own marker entity, even in the same vault.
local function same_trigger_group(fired, other, identity)
    if fired.group_id and fired.group_id ~= "" then
        return other.group_id == fired.group_id
    end

    return identity == trigger_ids.LADY_OF_LAKE_SPAWN and
        other.level_id == fired.level_id and
        other.vault_id == fired.vault_id and
        other.callback_module == fired.callback_module and
        other.callback_method == fired.callback_method
end

-- Remove a successful one-shot marker and any source siblings it owns.
local function consume(ctx, entity, state, identity)
    for _, sibling in ipairs(ctx:query({
        component.WORLD_VAULT_TRIGGER,
    })) do
        local other = ctx:get(sibling, component.WORLD_VAULT_TRIGGER)

        if sibling == entity or
            same_trigger_group(state, other, identity) then
            ctx:destroy(sibling)
        end
    end
end

-- Source TriggerableFunction fires once on player_move at its own cell.
-- Destroying the ECS entity after the callback keeps save/restore honest.
function triggers.enter(ctx, actor, position)
    if actor ~= ctx:player() then
        return
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_TRIGGER })) do
        local state = ctx:get(entity, component.WORLD_VAULT_TRIGGER)

        if state.event == trigger_ids.ENTER_EVENT and
            state.level_id == position.level_id and
            state.x == position.x and state.y == position.y then
            local identity = trigger_ids.PREFIX .. state.callback_module ..
                "." .. state.callback_method
            local _, _, method = callback(identity)

            local consumed = method(ctx, state)

            if consumed ~= false then
                consume(ctx, entity, state, identity)
            end

            return
        end
    end
end

-- A player-LOS source marker watches its final transformed cell after a
-- committed move. The ECS component owns armed state; destroying it after
-- success keeps save/restore from replaying the callback on re-entry.
function triggers.player_los(ctx, actor, position)
    if actor ~= ctx:player() then
        return
    end

    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_TRIGGER })) do
        local state = ctx:get(entity, component.WORLD_VAULT_TRIGGER)

        if state and state.event == trigger_ids.PLAYER_LOS_EVENT and
            state.level_id == position.level_id and
            ctx:visible(state.level_id, position.x, position.y, 7,
                state.x, state.y) then
            local identity = trigger_ids.PREFIX .. state.callback_module ..
                "." .. state.callback_method
            local _, _, method = callback(identity)

            if method(ctx, state) ~= false then
                consume(ctx, entity, state, identity)
            end
        end
    end
end

-- Source monster_on_death markers persist until their callback recognizes
-- the killed monster. Each armed marker is an ECS entity, so save/restore
-- preserves which statues have already awakened.
function triggers.monster_death(ctx, _, definition, position)
    for _, entity in ipairs(ctx:query({ component.WORLD_VAULT_TRIGGER })) do
        local state = ctx:get(entity, component.WORLD_VAULT_TRIGGER)

        if state.event == trigger_ids.MONSTER_DEATH_EVENT and
            state.level_id == position.level_id then
            local identity = trigger_ids.PREFIX .. state.callback_module ..
                "." .. state.callback_method
            local _, _, method = callback(identity)

            if method(ctx, state, definition) ~= false then
                consume(ctx, entity, state, identity)
            end
        end
    end
end

death_hooks.add("vault.monster_death", triggers.monster_death)

return triggers
