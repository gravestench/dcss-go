-- decks.cc:_damaging_card fires one aimed IOOD only at tier one.
-- Tiers zero and two launch the source three-to-seven-orb burst.
local iood = require("policy.magic.effects.zaps.iood")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local nearby = require("policy.religion.cards.effects.nearby")
local streams = require("constants.rng_streams")
local targeted = require("policy.religion.cards.effects.targeted")
local targets = require("policy.ai.targets")

local orb = {}

orb.uses_tier = true

-- mon-project.cc:_burst_iood_target prefers the aimed monster in each
-- 120-degree cone, then the closest hostile non-firewood monster there.
local function burst_target(ctx, caster, origin, vx, vy, preferred)
    local closest = nil
    local distance = math.huge

    for _, candidate in ipairs(nearby.monsters(ctx, caster)) do
        local dx = candidate.position.x - origin.x
        local dy = candidate.position.y - origin.y
        local length = math.sqrt(dx * dx + dy * dy)
        local forward = (dx * vx + dy * vy) / length

        if forward > 0.5 then
            if candidate.entity == preferred then
                return preferred
            end

            local firewood = false

            for _, flag in ipairs(candidate.definition.flags or {}) do
                firewood = firewood or flag == flags.NO_THREAT
            end

            local range = math.max(math.abs(dx), math.abs(dy))

            if targets.enemy(ctx, caster, candidate.entity) and
                not firewood and range < distance then
                closest = candidate.entity
                distance = range
            end
        end
    end

    return closest or preferred
end

-- mon-project.cc:cast_iood_burst starts three to seven evenly spaced
-- trajectories at one random angle. Each launch keeps its own saved orb
-- state and chooses a foe within its cone instead of following the cursor.
function orb.burst(ctx, caster, dx, dy, power, stream)
    local origin = ctx:get(caster, component.POSITION)
    local preferred = ctx:actor_at(origin.level_id,
        origin.x + dx, origin.y + dy)
    local count = 3 + ctx:random(stream, 5)
    local angle = ctx:random(stream, 2097152) *
        math.pi * 2 / 2097152

    for index = 0, count - 1 do
        local direction = angle + index * math.pi * 2 / count
        local vx = math.sin(direction)
        local vy = math.cos(direction)
        local foe = burst_target(ctx, caster, origin, vx, vy,
            preferred)

        iood.launch(ctx, caster, vx, vy, power, foe or false, stream)
    end
end

-- The target prompt is postcommit for every tier. An accepted direction
-- sends card power divided by six to the existing persistent orb owner.
function orb.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Orb requires a source power tier")
    end

    local dx, dy, prompt = targeted.aim(ctx, player, request,
        "the Orb")

    if prompt then
        return prompt
    end

    local power = targeted.zap_power(request)

    if tier == 1 then
        iood.launch(ctx, player, dx, dy, power,
            nil, streams.CARDS)
    else
        orb.burst(ctx, player, dx, dy, power, streams.CARDS)
    end
end

return orb
