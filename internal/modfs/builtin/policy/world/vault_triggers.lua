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

-- Create the saved trigger after DES orientation fixes its final cell.
function triggers.materialize(ctx, level, record)
    local module_name, method_name = callback(record.identity)
    local entity = ctx:create()

    ctx:add(entity, component.WORLD_VAULT_TRIGGER, {
        level_id = level.id,
        x = record.x,
        y = record.y,
        vault_id = record.source_id,
        record_index = record.index,
        callback_module = module_name,
        callback_method = method_name,
    })

    return {
        level_id = level.id,
        index = record.index,
    }
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

            method(ctx, state)
            ctx:destroy(entity)
        end
    end
end

return triggers
