-- Dream Sheep in sight of the target collectively roll one sleep attempt.
-- Source: mon-cast.cc:_dream_sheep_sleep and actor::put_to_sleep.
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local monsters = require("ids.monsters")
local sleep = require("policy.combat.monster_beams.sleep")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}
local SIGHT_RADIUS = 7
local POWER_PER_SHEEP = 25
local MIN_SUCCESS_POWER = 25
local MAX_POWER = 150

-- Count every living Dream Sheep around the foe, including the caster.
-- Source LOS_NO_TRANS lets sheep coordinate through actors but not walls.
local function sheep_near(ctx, foe)
    local origin = ctx:get(foe, component.POSITION)

    if not origin then
        return 0
    end

    local count = 0

    for _, sheep in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        local actor = ctx:get(sheep, component.ACTOR)
        local position = ctx:get(sheep, component.POSITION)
        local health = ctx:get(sheep, component.HEALTH)
        local distance = math.max(math.abs(position.x - origin.x),
            math.abs(position.y - origin.y))

        if actor.kind_id == monsters.MONS_DREAM_SHEEP and
            health.current > 0 and
            position.level_id == origin.level_id and
            distance <= SIGHT_RADIUS and
            ctx:visible_no_trans(origin.level_id,
                origin.x, origin.y, SIGHT_RADIUS,
                position.x, position.y) then
            count = count + 1
        end
    end

    return count
end

-- A direct visible foe and at least one sheep are needed before the AI
-- spends its breath; the power draw belongs only to resolution.
function effect.plan(ctx, caster, foe)
    local plan = direct.plan(ctx, caster, foe,
        spells.SPELL_DREAM_DUST)

    if plan and sheep_near(ctx, foe) > 0 then
        return plan
    end

    return nil
end

-- A single sheep succeeds only on its highest of twenty-five rolls.
-- The existing sleep owner then applies body immunity and saved timers.
-- Example: three sheep can roll strong enough for a longer player sleep.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    local count = sheep_near(ctx, foe)
    local power = 0

    if count > 0 then
        power = math.min(MAX_POWER,
            ctx:random(streams.MONSTER_SPELL,
                count * POWER_PER_SHEEP) + 1)
    end

    if power < MIN_SUCCESS_POWER then
        if ctx:has(foe, component.PLAYER) then
            ctx:emit("spell", "Motes of dream dust float around you, to no effect.")
        end

        return
    end

    sleep.apply_unresisted(ctx, foe, power)
end

return effect
