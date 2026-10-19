-- Chain of Chaos chooses one new body after each arc. It deliberately does
-- not remember previous victims: the next jump can return to the caster or
-- revisit a foe. The spell's impact policy receives each chosen arc before
-- the next target is searched, since an effect may move or kill that body.
-- Source: spl-damage.cc:cast_chain_spell.
-- Example: chain.resolve(ctx, caster, power, strike) can strike a nearby foe
-- and then produce a harmless visual arc back to the original caster.
local component = require("constants.component")
local streams = require("constants.rng_streams")

local chain = {}
local SIGHT_RADIUS = 7
local INITIAL_DISTANCE = SIGHT_RADIUS - 1
local POWER_LOSS_BASE = 8
local POWER_LOSS_SPAN = 13

-- DCSS uses Chebyshev distance so diagonal and orthogonal steps count alike.
local function distance(first, second)
    return math.max(math.abs(first.x - second.x),
        math.abs(first.y - second.y))
end

-- Actor handles are discovered in stable ECS order, while the player is
-- tested separately after monsters to preserve the source tie behavior.
local function live_monsters(ctx, level_id)
    local found = {}

    for _, actor in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if not ctx:has(actor, component.PLAYER) then
            local position = ctx:get(actor, component.POSITION)
            local health = ctx:get(actor, component.HEALTH)

            if position.level_id == level_id and
                health.current > 0 then
                found[#found + 1] = {
                    actor = actor,
                    position = position,
                }
            end
        end
    end

    return found
end

-- Jitter makes bodies a few feet apart effectively tied. The source gives
-- a newly closer monster a one-in-ten chance *not* to replace the current
-- winner, then reservoir-samples equal-distance monsters.
local function choose_monster(ctx, caster_position, source,
    monsters, stream)
    local minimum = INITIAL_DISTANCE
    local count = 0
    local selected

    for _, entry in ipairs(monsters) do
        local position = entry.position
        local actual = distance(source, position)

        if actual > 0 then
            local jittered = actual + ctx:random(stream, 3) - 1

            if jittered <= minimum and
                ctx:visible(source.level_id, source.x, source.y,
                    SIGHT_RADIUS, position.x, position.y) and
                ctx:visible_no_trans(caster_position.level_id,
                    caster_position.x, caster_position.y,
                    SIGHT_RADIUS, position.x, position.y) and
                ctx:projectile_clear(source.level_id,
                    source.x, source.y,
                    position.x, position.y) then
                count = count + 1

                if jittered < minimum then
                    if ctx:random(stream, 10) ~= 0 then
                        minimum = jittered
                        selected = entry
                        count = 0
                    end
                elseif not selected or
                    ctx:random(stream, count) == 0 then
                    selected = entry
                end
            end
        end
    end

    return selected, minimum, count
end

-- The player is considered last. Unlike monster candidates, source DCSS
-- does not reject the player merely because another actor is on the ray.
local function choose_player(ctx, source, selected,
    minimum, count, stream)
    local player = ctx:player()
    local position = player and ctx:get(player, component.POSITION)
    local health = player and ctx:get(player, component.HEALTH)

    if not position or not health or health.current <= 0 or
        position.level_id ~= source.level_id then
        return selected
    end

    local actual = distance(source, position)

    if actual == 0 then
        return selected
    end

    local jittered = actual + ctx:random(stream, 3) - 1
    local closer = not selected or jittered < minimum
    local tied = selected and jittered == minimum and
        ctx:random(stream, count + 1) == 0

    if (closer or tied) and
        ctx:visible(source.level_id, source.x, source.y,
            SIGHT_RADIUS, position.x, position.y) then
        return {
            actor = player,
            position = position,
        }
    end

    return selected
end

-- Recheck live victims after every impact. Power loss is paid after the
-- strike, even when that strike is only a visual return to the caster.
function chain.resolve(ctx, caster, power, strike, stream)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        return false
    end

    stream = stream or streams.MONSTER_SPELL

    local source = origin
    local struck = false

    while power > 0 do
        local monsters = live_monsters(ctx, source.level_id)
        local selected, minimum, count = choose_monster(ctx,
            origin, source, monsters, stream)

        selected = choose_player(ctx, source, selected,
            minimum, count, stream)

        if not selected then
            break
        end

        local target = selected.actor
        local target_position = selected.position
        local visual = target == caster

        strike(ctx, source, target, power, visual)

        struck = true
        source = target_position
        power = power - POWER_LOSS_BASE -
            ctx:random(stream, POWER_LOSS_SPAN)
    end

    return struck
end

return chain
