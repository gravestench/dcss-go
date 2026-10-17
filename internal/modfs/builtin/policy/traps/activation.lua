local catalog = require("policy.catalog")
local component = require("constants.component")
local vision = require("policy.character.vision")

local activation = {}

local function at(ctx, position)
    for _, entity in ipairs(ctx:query({ component.WORLD_TRAP })) do
        local state = ctx:get(entity, component.WORLD_TRAP)

        if state.level_id == position.level_id and
            state.x == position.x and state.y == position.y then
            return entity, state
        end
    end

    return nil, nil
end

function activation.enter(ctx, actor, old_position, new_position)
    if old_position.level_id == new_position.level_id and
        old_position.x == new_position.x and
        old_position.y == new_position.y then
        return
    end

    local entity, state = at(ctx, new_position)

    if not entity then
        return
    end

    -- Source traps.cc:trap_def::trigger ignores traps outside the player's
    -- unobstructed sight, including monster-triggered traps behind glass.
    local player = ctx:player()
    local player_position = ctx:get(player, component.POSITION)

    if not player_position or player_position.level_id ~= new_position.level_id or
        not ctx:visible(new_position.level_id,
            player_position.x, player_position.y,
            vision.radius(ctx, player), new_position.x, new_position.y) then
        return
    end

    local definition = catalog.get("traps", state.kind_id)
    local effect = require(definition.effect)

    if type(effect.trigger) ~= "function" then
        error("trap " .. state.kind_id .. " has no trigger method")
    end

    if definition.one_shot then
        state.charges = state.charges - 1

        if state.charges == 0 then
            ctx:destroy(entity)
        else
            ctx:set(entity, component.WORLD_TRAP, state)
        end
    end

    local consumed = effect.trigger(ctx, entity, actor, state)

    if consumed then
        ctx:destroy(entity)
    end
end

return activation
