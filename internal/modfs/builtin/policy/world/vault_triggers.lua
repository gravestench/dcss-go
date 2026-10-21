-- Source vault markers can invoke named Lua policy when the player moves
-- onto their cell. The level owns immutable source intent; one ECS entity
-- owns whether that particular callback is still armed.
local component = require("constants.component")
local trigger_ids = require("constants.vault_triggers")

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

-- Create the saved trigger after DES orientation fixes its final cell.
function triggers.materialize(ctx, level, record)
    local module_name, method_name = callback(record.identity)
    local target = shared_target(level, record)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_VAULT_TRIGGER, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        callback_module = module_name,
        callback_method = method_name,
        target_x = target and target.x or 0,
        target_y = target and target.y or 0,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
end

-- The Lady's two source glyph types share one TriggerableFunction. Ordinary
-- callbacks own only their own marker entity, even in the same vault.
local function same_trigger_group(fired, other, identity)
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

        if state.level_id == position.level_id and
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

return triggers
