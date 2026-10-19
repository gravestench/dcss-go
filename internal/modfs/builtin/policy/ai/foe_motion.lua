-- Foe motion is observed on a monster's own action. Comparing the foe's
-- old and new cells from the monster's current cell distinguishes an
-- approaching foe from the monster's own movement since its last action.
local component = require("constants.component")
local targets = require("policy.ai.targets")

local motion = {}

-- Source FOE_APPROACHING_KEY applies to the current foe only. Switching
-- foes starts a new observation and does not borrow the old foe's path.
function motion.observe(ctx, monster)
    local origin = ctx:get(monster, component.POSITION)

    if not origin then
        return
    end

    local foe = targets.nearest(ctx, monster, origin, 7)

    if not foe then
        if ctx:has(monster, component.MONSTER_FOE_MOTION) then
            ctx:remove(monster, component.MONSTER_FOE_MOTION)
        end

        return
    end

    local position = ctx:get(foe, component.POSITION)
    local previous = ctx:get(monster, component.MONSTER_FOE_MOTION)
    local approaching = false

    if previous and previous.foe_id == ctx:id(foe) then
        local old = math.max(math.abs(previous.x - origin.x),
            math.abs(previous.y - origin.y))
        local current = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))

        approaching = current < old
    end

    local state = {
        foe_id = ctx:id(foe),
        x = position.x,
        y = position.y,
        approaching = approaching,
    }

    if previous then
        ctx:set(monster, component.MONSTER_FOE_MOTION, state)
    else
        ctx:add(monster, component.MONSTER_FOE_MOTION, state)
    end
end

-- A caster with no observed approach raises its escape-blocking arc.
function motion.approaching(ctx, monster, foe)
    local state = ctx:get(monster, component.MONSTER_FOE_MOTION)

    return state and state.foe_id == ctx:id(foe) and
        state.approaching or false
end

return motion
