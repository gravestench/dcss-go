-- Source: beam.cc:BEAM_CHARM and mass_enchantment, monster.cc:go_frenzy,
-- mon-ench.cc:calc_duration and frenzy expiry.
local component = require("constants.component")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local roll = require("policy.combat.roll")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")
local monster_stats = require("policy.combat.monster_stats")
local monster_slow = require("policy.combat.monster_slow")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local frenzy_health = require("policy.magic.effects.statuses.monster_frenzy_health")
local holiness = require("constants.monster_holiness")
local monster_stasis = require("policy.monsters.stasis")

local allegiance = {}

-- Read source flag arrays without assuming a keyed set from modded monsters.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- One saved record owns charm, frenzy, and fatigue for this monster.
local function state(ctx, target)
    return ctx:get(target, component.MONSTER_ALLEGIANCE)
end

-- Charm, frenzy, and post-frenzy fatigue share one component so a new status
-- cannot discard the other two timers.
local function save(ctx, target, value)
    if state(ctx, target) then
        ctx:set(target, component.MONSTER_ALLEGIANCE, value)
    else
        ctx:add(target, component.MONSTER_ALLEGIANCE, value)
    end
end

-- New allegiance records start with all timers at zero so later expiry can
-- remove the component only when every effect has ended.
local function ensure(ctx, target)
    return state(ctx, target) or {
        charm_aut = 0,
        frenzy_aut = 0,
        fatigue_aut = 0,
        berserk_hp = false,
    }
end

-- Scale charm by effective HD and actor speed, then fuzz the source duration
-- on the melee stream before adding it to an existing charm.
local function charm_duration(ctx, target, definition, stream)
    local actor = ctx:get(target, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local scaled_hd = math.max(1,
        math.floor((monster_stats.hit_dice(ctx, target, definition) + 10) *
            10 / speed))
    local centiturns = math.max(2, math.floor(500 / scaled_hd))
    local raw = centiturns * roll.random_divide(ctx, 100, speed,
        stream)
    local low = math.floor(raw * 60 / 100)
    local high = math.floor(raw * 40 / 100)
    local fuzz = roll.average_two(ctx, stream or "melee",
        low + high + 1)

    return math.max(15, raw + fuzz - low)
end

-- Direct divine enchantments and Charm spells must save the same loyalty
-- timer and clear the same patrol order. The spell owns its aim and will
-- check; this function owns the status once a target has been accepted.
function allegiance.apply_charm(ctx, target, stream)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local value = ensure(ctx, target)

    value.charm_aut = value.charm_aut +
        charm_duration(ctx, target, definition, stream)
    save(ctx, target, value)

    if ctx:has(target, component.MONSTER_PATROL) then
        ctx:remove(target, component.MONSTER_PATROL)
    end

    ctx:emit("spell", "The " .. definition.name .. " is charmed.")

    return true
end

-- Discord averages adjacent spell bounds to mimic the source duration roll.
local function average_two(ctx, bound)
    return math.floor((ctx:random("spell", bound) +
        ctx:random("spell", bound + 1)) / 2)
end

-- Discord skips actors already frenzied or fatigued, nonattackers, and those
-- unable to act; otherwise an invalid target would still consume will RNG.
local function can_frenzy(ctx, target, definition)
    local current = state(ctx, target)
    local attack = definition.attacks and definition.attacks[1]

    if current and (current.frenzy_aut > 0 or current.fatigue_aut > 0) then
        return false
    end

    if not attack or attack.type_id == "AT_NONE" or attack.damage <= 0 then
        return false
    end

    if definition.intelligence_id == "I_BRAINLESS" and
        not has(definition.holiness, "MH_NATURAL") then
        return false
    end

    local stasis = ctx:get(target, component.MONSTER_STASIS)

    return not ctx:has(target, component.PARALYSIS) and
        (not stasis or stasis.petrifying_aut <= 0 and
            stasis.petrified_aut <= 0)
end

-- Divine wrath and direct monster effects need the body's Berserk gate,
-- without the AI spell's extra close-foe and teleport preconditions.
function allegiance.can_berserk(ctx, target)
    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local living = has(definition.holiness, holiness.NATURAL) or
        has(definition.holiness, holiness.DEMONIC) or
        has(definition.holiness, holiness.HOLY)

    return living and not monster_stasis.intrinsic(definition) and
        can_frenzy(ctx, target, definition)
end

-- monster::needs_berserk(false) filters physical incapacity, Teleport,
-- and distant foes before the AI spends its Rage spell slot. The spell
-- resolver checks its separate Haste owner before calling this predicate.
function allegiance.needs_berserk(ctx, target, foe)
    if not foe then
        return false
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)

    if not definition or not can_frenzy(ctx, target, definition) or
        ctx:has(target, component.TELEPORT) or
        monster_stasis.intrinsic(definition) then
        return false
    end

    local living = has(definition.holiness, holiness.NATURAL) or
        has(definition.holiness, holiness.DEMONIC) or
        has(definition.holiness, holiness.HOLY)
    local origin = ctx:get(target, component.POSITION)
    local destination = ctx:get(foe, component.POSITION)

    if not living or not origin or not destination or
        origin.level_id ~= destination.level_id then
        return false
    end

    return math.max(math.abs(origin.x - destination.x),
        math.abs(origin.y - destination.y)) <= 3
end

-- Intentional Berserker Rage uses the existing saved frenzy/fatigue owner.
-- The source enchant's 16 + random2avg(13, 2) turns are spent on later actions.
function allegiance.start_berserk(ctx, target, stream)
    local current = ensure(ctx, target)

    if current.frenzy_aut > 0 then
        error("monster is already frenzied")
    end

    monster_slow.remove(ctx, target)
    mass.clear_fear(ctx, target)
    frenzy_health.scale(ctx, target, 3, 2)

    current.frenzy_aut = (16 +
        roll.average_two(ctx, stream or "monster_spell", 13)) * 10
    current.fatigue_aut = 0
    current.berserk_hp = true
    save(ctx, target, current)

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    ctx:emit("spell", "The " .. definition.name .. " goes berserk!")
end

-- Charm's menu predicate requires a visible living actor and a clear
-- projectile path before the player can commit a target direction.
local function can_target(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and position.level_id == origin.level_id and
                distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                return true
            end
        end
    end

    return false
end

-- The registry calls this predicate before offering Charm at the prompt.
function allegiance.can_target_charm(ctx, player, spell)
    return can_target(ctx, player, spell)
end

-- Example: cast_charm(ctx, player, intent, spell, 80) traces the chosen ray;
-- the first contacted monster must fail willpower before charm time is saved.
function allegiance.cast_charm(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "The charming magic dissipates.")
        return
    end

    local target = contact.actor
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if will.resists(ctx, definition, power,
        target, nil, player) then
        ctx:emit("spell", "The " .. definition.name .. " resists charm.")
        return
    end

    allegiance.apply_charm(ctx, target)
end

-- Discord visits each visible eligible monster once, then rolls resistance
-- and a spell-stream frenzy duration for each accepted target.
function allegiance.cast_discord(ctx, player, power)
    local origin = ctx:get(player, component.POSITION)
    local enchant_power = math.min(200, math.floor(power * 3 / 2))
    local messaged = false

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.POSITION, component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)

            if health.current > 0 and position.level_id == origin.level_id and
                ctx:visible(origin.level_id, origin.x, origin.y, 7,
                    position.x, position.y) then
                local actor = ctx:get(target, component.ACTOR)
                local definition = catalog.get("monsters", actor.kind_id)

                if can_frenzy(ctx, target, definition) then
                    messaged = true

                    if will.resists(ctx, definition, enchant_power,
                        target, nil, player) then
                        ctx:emit("spell", "The " .. definition.name .. " resists.")
                    else
                        local value = ensure(ctx, target)
                        local lasting = (16 + average_two(ctx, 13)) * 10
                        value.frenzy_aut = lasting
                        value.fatigue_aut = 0
                        value.berserk_hp = false
                        save(ctx, target, value)
                        ctx:emit("spell", "The " .. definition.name ..
                            " flies into a frenzy!")
                    end
                end
            end
        end
    end

    if not messaged then
        ctx:emit("spell", "Nothing happens.")
    end
end

-- AI allegiance changes only while the charm timer is positive.
function allegiance.charmed(ctx, target)
    local current = state(ctx, target)

    return current ~= nil and current.charm_aut > 0
end

-- Religious desertion and No Love remove the same temporary charm. Keep
-- independent frenzy, fatigue, and berserk health on the actor.
function allegiance.clear_charm(ctx, target)
    local current = state(ctx, target)

    if not current or current.charm_aut <= 0 then
        return false
    end

    current.charm_aut = 0

    if current.frenzy_aut > 0 or current.fatigue_aut > 0 or
        current.berserk_hp then
        ctx:set(target, component.MONSTER_ALLEGIANCE, current)
    else
        ctx:remove(target, component.MONSTER_ALLEGIANCE)
    end

    return true
end

-- Combat speed and damage consult this timer, not fatigue or charm.
function allegiance.frenzied(ctx, target)
    local current = state(ctx, target)

    return current ~= nil and current.frenzy_aut > 0
end

-- Frenzy multiplies melee damage by 3/2 before later armour processing.
function allegiance.frenzy_melee_damage(ctx, target, damage)
    if allegiance.frenzied(ctx, target) then
        return math.floor(damage * 3 / 2)
    end

    return damage
end

-- Speed random rounding uses its own stream so action scheduling cannot
-- consume a spell-duration draw.
local function random_round(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("speed", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Speed uses a separate random-rounding stream during frenzy and fatigue so
-- action order does not perturb spell effects.
function allegiance.frenzy_speed(ctx, target, base_speed)
    local current = state(ctx, target)

    if not current then
        return base_speed
    end

    if current.frenzy_aut > 0 then
        return random_round(ctx, base_speed * 3, 2)
    end

    if current.fatigue_aut > 0 then
        return random_round(ctx, base_speed * 2, 3)
    end

    return base_speed
end

-- A finished frenzy becomes 70-130 AUT of fatigue; remove shared state only
-- after charm, frenzy, and fatigue all reach zero.
function allegiance.tick(ctx, target, elapsed_aut)
    local current = state(ctx, target)

    if not current then
        return
    end

    elapsed_aut = elapsed_aut or 10
    current.charm_aut = math.max(0,
        current.charm_aut - elapsed_aut)

    if current.frenzy_aut > 0 then
        current.frenzy_aut = math.max(0,
            current.frenzy_aut - elapsed_aut)

        if current.frenzy_aut == 0 then
            if current.berserk_hp then
                frenzy_health.scale(ctx, target, 2, 3)
                current.berserk_hp = false
            end

            current.fatigue_aut = 70 + ctx:random("spell", 61)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            ctx:emit("monster", "The " .. definition.name ..
                " is no longer in an insane frenzy.")
        end
    elseif current.fatigue_aut > 0 then
        current.fatigue_aut = math.max(0,
            current.fatigue_aut - elapsed_aut)
    end

    if current.charm_aut > 0 or current.frenzy_aut > 0 or
        current.fatigue_aut > 0 then
        ctx:set(target, component.MONSTER_ALLEGIANCE, current)
    else
        ctx:remove(target, component.MONSTER_ALLEGIANCE)
    end
end

return allegiance
