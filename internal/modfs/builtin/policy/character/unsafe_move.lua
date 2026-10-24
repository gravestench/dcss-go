-- Theory of operation: a nonphysical change of position breaks the two
-- source ice defenses. When a hostile actor is visible, ask first; on a
-- successful movement, remove those defenses through their state owners.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local ramparts = require("policy.magic.effects.translocation.frozen_ramparts")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local movement = {}

-- Source i_feel_safe suppresses the warning outside combat. A living,
-- visible hostile actor makes loss of either defense worth confirming.
local function threatened(ctx, player)
    local origin = ctx:get(player, component.POSITION)

    for _, entity in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
    })) do
        if entity ~= player and
            targets.attitude(ctx, entity) == attitudes.HOSTILE then
            local health = ctx:get(entity, component.HEALTH)
            local position = ctx:get(entity, component.POSITION)

            if health and health.current > 0 and
                position.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    vision.radius(ctx, player),
                    position.x, position.y) then
                return true
            end
        end
    end

    return false
end

-- Prepare uses this exact text for both the command reply and the
-- terminal confirmation view, avoiding two versions of the warning.
function movement.warning(ctx, player)
    local state = ctx:get(player, component.PLAYER_STATUS)
    local icy = state and state.ice_armour_aut > 0
    local frozen = ctx:has(player, component.FROZEN_RAMPARTS)

    if not icy and not frozen or not threatened(ctx, player) then
        return nil
    end

    local names

    if icy and frozen then
        names = "icy armour and frozen ramparts"
    elseif icy then
        names = "icy armour"
    else
        names = "frozen ramparts"
    end

    return "Your " .. names ..
        " will break if you move. Continue?"
end

-- Invoke only after the world has accepted the movement. A failed
-- blink or failed invocation retains the player's active defenses.
function movement.break_ice(ctx, player)
    local state = ctx:get(player, component.PLAYER_STATUS)

    if state and state.ice_armour_aut > 0 then
        state.ice_armour_aut = 0
        state.ice_armour_power = 0
        ctx:set(player, component.PLAYER_STATUS, state)
        ctx:emit("duration", "Your icy armour cracks and falls away as you move.")
    end

    if ctx:has(player, component.FROZEN_RAMPARTS) then
        ramparts.end_effect(ctx, player, true)
    end
end

return movement
