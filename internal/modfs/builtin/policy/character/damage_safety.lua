local component = require("constants.component")
local restrictions = require("constants.safety_restrictions")

local safety = {}
local MAX_DURATION_AUT = 300

local recovery_messages = {
    [restrictions.POTIONS] = "You can drink potions again.",
    [restrictions.SCROLLS] = "You can read scrolls again.",
}

function safety.remaining(ctx, player, restriction)
    local state = ctx:get(player, component.DAMAGE_SAFETY)

    return state and state[restriction] or 0
end

function safety.active(ctx, player, restriction)
    return safety.remaining(ctx, player, restriction) > 0
end

function safety.add_duration(ctx, player, restriction, turns,
    maximum_turns)
    local state = ctx:get(player, component.DAMAGE_SAFETY)
    local created = not state

    if created then
        state = {
            [restrictions.POTIONS] = 0,
            [restrictions.SCROLLS] = 0,
        }
    end

    state[restriction] = math.min(maximum_turns * 10,
        state[restriction] + turns * 10)

    if created then
        ctx:add(player, component.DAMAGE_SAFETY, state)
    else
        ctx:set(player, component.DAMAGE_SAFETY, state)
    end
end

-- Source: ouch.cc:ouch increases the status by 1+random2(damage) turns,
-- capped at 30 turns, and warns only on its first activation.
function safety.apply(ctx, player, restriction, damage, warning)
    local state = ctx:get(player, component.DAMAGE_SAFETY)
    local created = not state

    if created then
        state = {
            [restrictions.POTIONS] = 0,
            [restrictions.SCROLLS] = 0,
        }
    end

    if state[restriction] == 0 then
        ctx:emit("mutation", warning)
    end

    local added = (1 + ctx:random("mutation", damage)) * 10
    state[restriction] = math.min(MAX_DURATION_AUT,
        state[restriction] + added)

    if created then
        ctx:add(player, component.DAMAGE_SAFETY, state)
    else
        ctx:set(player, component.DAMAGE_SAFETY, state)
    end
end

function safety.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local state = ctx:get(player, component.DAMAGE_SAFETY)

    if not state then
        return
    end

    for _, restriction in ipairs({
        restrictions.POTIONS,
        restrictions.SCROLLS,
    }) do
        local before = state[restriction]

        if before > 0 then
            state[restriction] = math.max(0, before - aut)

            if state[restriction] == 0 then
                ctx:emit("recovery", recovery_messages[restriction])
            end
        end
    end

    ctx:set(player, component.DAMAGE_SAFETY, state)
end

return safety
