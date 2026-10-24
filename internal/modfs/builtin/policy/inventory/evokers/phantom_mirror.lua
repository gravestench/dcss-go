-- Phantom Mirror copies a live monster body beside its original, then
-- drains the temporary clone. The item's XP debt is spent only when the
-- clone actually finds room; failed placement still uses a turn.
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.inventory.evokers.effects")
local ids = require("ids.items")
local mirror_spawn = require("policy.combat.monster_summons.mirror")
local monster_stats = require("policy.combat.monster_stats")
local power = require("policy.magic.power")
local senses = require("policy.character.senses")
local skills = require("ids.skills")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local will = require("policy.magic.effects.zaps.will")

local mirror = {}
local SIGHT_RADIUS = 7
local PERMANENT_DRAIN_AUT = 1000000000

-- Recheck the selected cell against live sight and clone eligibility.
-- A mirrored clone can be reflected again, matching the source exception.
local function target_at(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)

    if not origin or math.max(math.abs(dx), math.abs(dy)) >
        SIGHT_RADIUS then
        return nil
    end

    local x, y = origin.x + dx, origin.y + dy
    local target = ctx:actor_at(origin.level_id, x, y)

    if not target or target == player then
        return nil
    end

    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 or
        not ctx:visible(origin.level_id, origin.x, origin.y,
            SIGHT_RADIUS, x, y) or
        not senses.player_sees_actor(ctx, target) then
        return nil
    end

    if not ctx:has(target, component.SUMMON_MIRROR) and
        not mirror_spawn.eligible_illusion(ctx, target) then
        return nil
    end

    return target
end

-- A target refusal occurs before command timing and leaves the mirror's
-- charge untouched. Self and unseen cells are never cloneable.
function mirror.prepare(ctx, player, dx, dy)
    if not target_at(ctx, player, dx, dy) then
        return "You can't see anything there to clone."
    end
end

-- Source div_rand_round makes a clone lose roughly one third of its HD,
-- while a whole-HD boundary consumes no random draw.
local function drain_degree(ctx, hd)
    local whole = math.floor(hd / 3)
    local remainder = hd % 3

    if remainder > 0 and ctx:random(streams.EVOKER, 3) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Clone before rolling duration: a failed placement should not consume
-- the willpower RNG used only by a successfully reflected monster.
function mirror.resolve(ctx, player, chosen)
    local target = target_at(ctx, player, chosen.dx, chosen.dy)

    if not target then
        return {
            charge = false,
            practice = 0,
        }
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local clone = mirror_spawn.spawn(ctx, player, target,
        spells.SPELL_PHANTOM_MIRROR, 100, nil, {
            duration = 1,
            untangle = false,
            swap = false,
        })

    if not clone then
        ctx:emit("evoke", "Nothing happens.")

        return {
            charge = false,
            practice = 1,
        }
    end

    local skill = power.training(ctx, player, skills.SK_EVOCATIONS, 1)
    local strength = 5 + power.training(ctx, player,
        skills.SK_EVOCATIONS, 3)
    local resistance = will.margin(ctx, definition,
        strength, target, streams.EVOKER, player)
    local duration = math.min(6, math.max(1,
        math.floor((math.floor(skill / 4) + 1) *
            (100 - resistance) / 100)))
    local summon = ctx:get(clone, component.SUMMON)

    summon.expires_aut = ctx:aut() +
        summons.player_duration_aut(duration)
    ctx:set(clone, component.SUMMON, summon)

    local hd = monster_stats.hit_dice(ctx, target, definition)
    local copied = ctx:get(clone, component.MONSTER_DRAINED) or {
        degree = 0,
        remaining_aut = 0,
    }

    copied.degree = copied.degree + drain_degree(ctx, hd)
    copied.remaining_aut = PERMANENT_DRAIN_AUT

    if ctx:has(clone, component.MONSTER_DRAINED) then
        ctx:set(clone, component.MONSTER_DRAINED, copied)
    else
        ctx:add(clone, component.MONSTER_DRAINED, copied)
    end

    ctx:emit("evoke", "You reflect the " .. definition.name ..
        " with the mirror!")

    return {
        charge = true,
        practice = 1,
    }
end

effects.add(ids.MISC_PHANTOM_MIRROR, mirror)

return mirror
