-- Saved AI is checked here because target memory and behavior are one
-- invariant, whether the actor came from a vault, a summon, or a band.
local flags = require("constants.monster_flags")
local behaviors = require("constants.ai_behaviors")

local validation = {}

-- Read source flag arrays without depending on a catalog set conversion.
local function has_flag(definition, id)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == id then
            return true
        end
    end

    return false
end

-- A sleeper has no target or memory; awake roles retain their existing
-- bounded target/deadline contract so restore resumes the same pursuit.
function validation.validate(ctx, entity, ai, position, definition,
    current_aut)
    local retreat_limit = math.max(2,
        math.floor((definition.speed or 0) / 10)) - 1

    if ai.bat_retreat_actions < 0 or
        ai.bat_retreat_actions > retreat_limit or
        (ai.bat_retreat_actions > 0 and
            (not has_flag(definition, flags.BATTY) or
                ai.behavior ~= behaviors.WANDER)) then
        error("monster " .. ctx:id(entity) ..
            " has invalid bat retreat state")
    end

    if ai.behavior == behaviors.SLEEP or
        ai.behavior == behaviors.LEGACY_CHASE then
        if ai.target_x ~= 0 or ai.target_y ~= 0 or
            ai.memory_until_aut ~= 0 then
            error("sleeping or legacy monster " .. ctx:id(entity) ..
                " has a target or memory")
        end
    elseif ai.behavior == behaviors.WANDER then
        if ai.memory_until_aut ~= 0 or
            ((ai.target_x ~= 0 or ai.target_y ~= 0) and
                not ctx:walkable(position.level_id,
                    ai.target_x, ai.target_y)) then
            error("wandering monster " .. ctx:id(entity) ..
                " has invalid target or memory")
        end
    elseif ai.behavior == behaviors.SEEK then
        if not ctx:walkable(position.level_id, ai.target_x, ai.target_y) or
            ai.memory_until_aut < 0 or
            ai.memory_until_aut > current_aut + 550 then
            error("monster " .. ctx:id(entity) ..
                " has invalid remembered target")
        end
    else
        error("monster " .. ctx:id(entity) ..
            " has invalid behavior " .. tostring(ai.behavior))
    end
end

return validation
