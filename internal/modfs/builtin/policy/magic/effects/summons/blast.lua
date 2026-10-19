local component = require("constants.component")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local defense = require("policy.combat.monster_defense")
local fighter = require("policy.combat.fighter")
local player_health = require("policy.combat.player_health")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")
local monster_health = require("policy.combat.monster_health")

local blast = {}

-- Area and target reach use eight-direction grid distance, including diagonal cells.
local function distance(left, right)
    return math.max(math.abs(left.x - right.x), math.abs(left.y - right.y))
end

-- Summoned constructs search visible hostile actors before choosing where to explode.
function blast.nearest_hostile(ctx, source, origin, reach)
    local chosen, closest

    for _, entity in ipairs(ctx:query({ component.ACTOR, component.POSITION, component.HEALTH })) do
        if targets.enemy(ctx, source, entity) then
            local position = ctx:get(entity, component.POSITION)
            local health = ctx:get(entity, component.HEALTH)
            local radius = distance(origin, position)

            if position.level_id == origin.level_id and health.current > 0 and
                radius <= reach and (not closest or radius < closest) and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    reach, position.x, position.y) then
                chosen, closest = entity, radius
            end
        end
    end

    return chosen, closest
end

-- Example: blast.hit(ctx, monster, 12, "MR_RES_FIRE", construct) applies
-- elemental resistance before damage and kill attribution.
function blast.hit(ctx, target, raw, resistance_id, source, stream)
    local definition
    local ac = 0

    if target == ctx:player() then
        ac = fighter.defense(ctx).ac
    else
        local actor = ctx:get(target, component.ACTOR)
        definition = catalog.get("monsters", actor.kind_id)
        ac = defense.armour(ctx, target, definition)
    end

    -- The old player path did not draw RNG against zero armour. Keep that
    -- sequence while letting monster-owned constructs use their own stream.
    local blocked = 0

    if ac > 0 then
        blocked = ctx:random(stream or "spell", ac + 1)
    end

    local amount = math.max(0, raw - blocked)

    if resistance_id and definition then
        amount = damage.monster_elemental(ctx, target, amount, resistance_id)
    elseif resistance_id then
        amount = damage.player_elemental(ctx, target, amount, resistance_id)
    end

    local health = ctx:get(target, component.HEALTH)

    if health and health.current > 0 then
        if target == ctx:player() then
            local _, dealt = player_health.damage(ctx, target, amount,
                false, source)

            return dealt
        end

        local dealt

        health, dealt = monster_health.damage(ctx, target, amount,
            source)

        if health.current == 0 and target ~= ctx:player() and
            not ctx:has(target, component.SUMMON) and
            targets.allied(ctx, source) then
            ctx:signal("player_kill", target)
        end

        return dealt
    end
end

-- Roll area damage per target to preserve the source distribution and avoid
-- one shared hit determining every actor's outcome. A caller may react to
-- positive post-armour damage without duplicating the explosion traversal.
function blast.area(ctx, source, radius, dice, sides, resistance_id,
    on_hit)
    local origin = ctx:get(source, component.POSITION)

    for _, target in ipairs(ctx:query({ component.POSITION, component.HEALTH })) do
        local position = ctx:get(target, component.POSITION)

        if target ~= source and position.level_id == origin.level_id and
            distance(origin, position) <= radius and
            ctx:visible(origin.level_id, origin.x, origin.y,
                radius, position.x, position.y) then
            local raw = 0

            for _ = 1, dice do
                raw = raw + 1 + summons.roll(ctx, math.max(1, sides))
            end

            local dealt = blast.hit(ctx, target, raw,
                resistance_id, source)

            if on_hit and dealt and dealt > 0 then
                on_hit(ctx, target, dealt)
            end
        end
    end
end

-- Mark a construct as finished in components so turn processing and save/restore agree.
function blast.finish(ctx, entity, marker)
    local state = ctx:get(entity, component.SUMMON_CONSTRUCT)
    local summon = ctx:get(entity, component.SUMMON)

    state.charge = marker
    summon.expires_aut = ctx:aut()
    ctx:set(entity, component.SUMMON_CONSTRUCT, state)
    ctx:set(entity, component.SUMMON, summon)
end

return blast
