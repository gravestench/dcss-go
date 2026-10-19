local component = require("constants.component")

local lowered_will = {}

-- An expired will debuff must stop affecting spell resistance before component cleanup.
function lowered_will.active(ctx, target)
    local status = ctx:get(target, component.MONSTER_LOWERED_WILL)

    return status ~= nil and status.remaining_aut > 0
end

-- Source: mon-ench.cc:monster::add_ench. Reapplication extends duration.
function lowered_will.apply(ctx, target, duration_aut)
    local status = ctx:get(target, component.MONSTER_LOWERED_WILL)

    if status then
        status.remaining_aut = status.remaining_aut + duration_aut
        ctx:set(target, component.MONSTER_LOWERED_WILL, status)
    else
        ctx:add(target, component.MONSTER_LOWERED_WILL, {
            remaining_aut = duration_aut,
        })
    end
end

-- Example: A ten-aut lowered-will mark disappears at the next monster tick.
-- Remove the debuff after ten aut of decay so later resistance checks read no stale status.
function lowered_will.tick(ctx, target)
    local status = ctx:get(target, component.MONSTER_LOWERED_WILL)

    if not status then
        return
    end

    status.remaining_aut = status.remaining_aut - 10

    if status.remaining_aut > 0 then
        ctx:set(target, component.MONSTER_LOWERED_WILL, status)
    else
        ctx:remove(target, component.MONSTER_LOWERED_WILL)
    end
end

return lowered_will
