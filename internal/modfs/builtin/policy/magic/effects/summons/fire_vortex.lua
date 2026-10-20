local component = require("constants.component")
local intent_ids = require("constants.intent")
local targets = require("policy.ai.targets")

local vortex = {}

local offsets = {
    { -1, -1 }, { 0, -1 }, { 1, -1 },
    { -1, 0 }, { 1, 0 },
    { -1, 1 }, { 0, 1 }, { 1, 1 },
}

-- Confused movement may step toward a foe, but never into blocked terrain or another ally.
local function random_step(ctx, entity, origin)
    local choices = {}

    for _, offset in ipairs(offsets) do
        local x = origin.x + offset[1]
        local y = origin.y + offset[2]
        local occupant = ctx:actor_at(origin.level_id, x, y)

        if ctx:walkable(origin.level_id, x, y) and
            (not occupant or targets.enemy(ctx, entity, occupant)) then
            choices[#choices + 1] = offset
        end
    end

    if #choices == 0 then
        return { kind = intent_ids.MONSTER_WAIT }
    end

    local step = choices[ctx:random("spell", #choices) + 1]

    return { kind = intent_ids.MONSTER_MOVE, dx = step[1], dy = step[2] }
end

-- Source: mon-data.h:MONS_FIRE_VORTEX has M_CONFUSED; mon-act.cc randomly
-- redirects two in three moves. Contact is resolved by summon_melee.
function vortex.act(ctx, entity, origin)
    local target, distance = targets.nearest(ctx, entity, origin, 7)

    if not target or ctx:random("spell", 3) ~= 0 then
        return random_step(ctx, entity, origin)
    end

    local destination = ctx:get(target, component.POSITION)

    if distance == 1 then
        return {
            kind = intent_ids.MONSTER_MELEE,
            dx = destination.x - origin.x,
            dy = destination.y - origin.y,
        }
    end

    local dx, dy, found = ctx:route_step(origin.level_id,
        origin.x, origin.y, destination.x, destination.y, target)

    if found and ctx:walkable(origin.level_id, origin.x + dx, origin.y + dy) then
        return { kind = intent_ids.MONSTER_MOVE, dx = dx, dy = dy }
    end

    return random_step(ctx, entity, origin)
end

return vortex
