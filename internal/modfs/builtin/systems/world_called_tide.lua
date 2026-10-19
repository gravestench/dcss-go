-- Theory of operation: Shoals owns a persistent tide clock and elevation
-- grid. Every elapsed baseline turn moves the ordinary sea. Call Tide adds a
-- temporary surge around its caster without rewriting those elevations.
-- When a call ends, the ordinary tide continues instead of reverting the
-- whole shoreline to an earlier feature snapshot.
local branches = require("ids.branches")
local component = require("constants.component")
local tide = require("policy.world.shoals_tide")

local system = {}
local STATE = "world.called_tide"
local AUT_PER_TURN = 10

-- Return a live caller when present. Keep an expired call's timing long
-- enough to replay its earlier steps during a long save or level catch-up.
local function current_caller(ctx, level_id)
    local expired_position
    local expired_state

    for _, caster in ipairs(ctx:query({ STATE })) do
        local state = ctx:get(caster, STATE)
        local position = ctx:get(caster, component.POSITION)

        if ctx:aut() >= state.expires_aut then
            ctx:remove(caster, STATE)

            if position and position.level_id == level_id then
                expired_position = position
                expired_state = state
            end
        elseif position and position.level_id == level_id then
            return position, state, false
        end
    end

    return expired_position, expired_state, expired_state ~= nil
end

-- Active updates may be visited for many actors. The player advances the
-- natural clock; a just-cast caller may also force an immediate local wave.
function system.update(ctx, actor)
    if actor ~= ctx:player() and not ctx:has(actor, STATE) then
        return
    end

    local player_position = ctx:get(ctx:player(), component.POSITION)

    if not player_position or
        ctx:level_branch(player_position.level_id) ~= branches.BRANCH_SHOALS then
        return
    end

    local level_id = player_position.level_id
    local height, velocity, last_aut = ctx:shoals_tide_clock(level_id)

    if not height then
        return
    end

    local position, state, expired = current_caller(ctx, level_id)
    local caller = not expired and position or nil
    local turns = math.max(0,
        math.floor((ctx:aut() - last_aut) / AUT_PER_TURN))
    local old_height = height

    for step = 1, turns do
        local step_aut = last_aut + step * AUT_PER_TURN
        local calling = position and state and
            step_aut >= state.start_aut and
            step_aut < state.expires_aut

        height, velocity = tide.advance(height, velocity, calling)
    end

    if turns == 0 and not caller and not expired then
        return
    end

    local called_turns = 0

    if state then
        called_turns = math.max(1,
            math.floor((ctx:aut() - state.start_aut) / AUT_PER_TURN))
    end

    local rising = caller ~= nil or height > old_height

    -- Releasing a call forces a falling pass even if the ordinary sea's
    -- height did not change on this exact turn.
    if expired and not caller then
        rising = false
    end

    tide.apply(ctx, level_id, height, caller, called_turns, rising)
    ctx:set_shoals_tide_clock(level_id, height, velocity,
        last_aut + turns * AUT_PER_TURN)
end

register.system({
    id = "world.called_tide.tick",
    scope = "active",
    query = {},
    before = { "monster.decision" },
    update = system.update,
})

return system
