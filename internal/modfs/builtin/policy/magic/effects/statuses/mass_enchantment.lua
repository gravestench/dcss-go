-- Source: beam.cc:mass_enchantment and mon-ench.cc:calc_duration.
local spells = require("ids.spells")
local component = require("constants.component")
local catalog = require("policy.catalog")
local roll = require("policy.combat.roll")
local will = require("policy.magic.effects.zaps.will")
local monster_stats = require("policy.combat.monster_stats")

local mass = {}

-- Catalog flags and holiness may be absent, which grants no matching enchantment trait.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Convert source turn durations to the monster's current action speed.
local function scaled_speed(value, speed)
    return math.max(1, math.floor(value * 10 / speed))
end

-- Fear scales with HD while Anguish uses fixed base; both receive speed fuzz.
local function duration(ctx, monster, definition, kind)
    local actor = ctx:get(monster, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local centiturns

    if kind == "fear_aut" then
        centiturns = math.floor(150 /
            (1 + scaled_speed(
                monster_stats.hit_dice(ctx, monster, definition) + 5,
                speed)))
    else
        centiturns = math.floor(1000 / scaled_speed(25, speed))
    end

    centiturns = math.max(2, centiturns)
    local raw = centiturns * roll.random_divide(ctx, 100, speed)
    local low = math.floor(raw * 60 / 100)
    local high = math.floor(raw * 40 / 100)
    local fuzz = roll.average_two(ctx, "melee", low + high + 1)

    return math.max(15, raw + fuzz - low)
end

-- Immobile no-threat objects and nonliving holiness cannot be frightened.
local function can_fear(definition)
    if has(definition.flags, "M_STATIONARY") and
        has(definition.flags, "M_NO_THREAT") then
        return false
    end

    return has(definition.holiness, "MH_NATURAL") or
        has(definition.holiness, "MH_DEMONIC") or
        has(definition.holiness, "MH_HOLY")
end

-- Anguish needs a mind; Fear further requires a creature capable of fleeing.
local function susceptible(definition, kind)
    if has(definition.flags, "M_STATIONARY") and
        has(definition.flags, "M_NO_THREAT") then
        return false
    end

    if kind == "fear_aut" then
        return can_fear(definition)
    end

    return definition.intelligence_id ~= "I_BRAINLESS"
end

-- Skip an already active effect before the will roll, then save only a successful new timer.
local function apply(ctx, target, definition, kind, power)
    if not susceptible(definition, kind) then
        return false
    end

    local current = ctx:get(target, component.MONSTER_MASS_ENCHANT)

    if current and current[kind] > 0 then
        return false
    end

    if will.resists(ctx, definition, power, target) then
        ctx:emit("spell", "The " .. definition.name .. " resists.")
        return true
    end

    local next_state = current or { fear_aut = 0, anguish_aut = 0 }
    next_state[kind] = duration(ctx, target, definition, kind)

    if current then
        ctx:set(target, component.MONSTER_MASS_ENCHANT, next_state)
    else
        ctx:add(target, component.MONSTER_MASS_ENCHANT, next_state)
    end

    ctx:emit("spell", "The " .. definition.name ..
        (kind == "fear_aut" and " looks frightened!" or
            " is haunted by guilt!"))

    return true
end

-- Innate fear bypasses spell willpower but uses the same saved fear duration.
function mass.apply_innate_fear(ctx, target, definition)
    if not can_fear(definition) then
        return false
    end

    local current = ctx:get(target, component.MONSTER_MASS_ENCHANT) or {
        fear_aut = 0,
        anguish_aut = 0,
    }

    current.fear_aut = duration(ctx, target, definition, "fear_aut")

    if ctx:has(target, component.MONSTER_MASS_ENCHANT) then
        ctx:set(target, component.MONSTER_MASS_ENCHANT, current)
    else
        ctx:add(target, component.MONSTER_MASS_ENCHANT, current)
    end

    ctx:emit("mutation", "The " .. definition.name .. " looks frightened!")

    return true
end

-- Apply capped enchantment power to each living visible actor in the radius.
function mass.cast(ctx, player, spell_id, power)
    local kind = spell_id == spells.SPELL_CAUSE_FEAR and "fear_aut" or
        spell_id == spells.SPELL_ANGUISH and "anguish_aut" or nil

    if not kind then
        error("unknown mass enchantment " .. tostring(spell_id))
    end

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

                if apply(ctx, target, definition, kind, enchant_power) then
                    messaged = true
                end
            end
        end
    end

    if not messaged then
        ctx:emit("spell", "Nothing happens.")
    end
end

-- AI flee decisions depend on a positive timer, not component presence alone.
function mass.fear_active(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_MASS_ENCHANT)

    return current ~= nil and current.fear_aut > 0
end

-- Source: ouch.cc:_maybe_inflict_anguish and fineff.cc:anguish_fineff.
-- Call only after actual damage is applied to the player, with its source.
function mass.anguish_reflect(ctx, monster, damage_dealt)
    local current = ctx:get(monster, component.MONSTER_MASS_ENCHANT)
    local health = ctx:get(monster, component.HEALTH)

    if not current or current.anguish_aut <= 0 or not health or
        health.current <= 0 or damage_dealt <= 0 then
        return false
    end

    local before = health.current
    health.current = math.max(0, before - damage_dealt)
    ctx:set(monster, component.HEALTH, health)

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    ctx:emit("combat", "The " .. definition.name .. " is wracked by anguish!")

    if before > 0 and health.current == 0 then
        ctx:signal("player_kill", monster)
    end

    return true
end

-- Example: A monster keeps its mass-enchantment record while either fear or anguish time remains.
-- Expire fear and anguish independently, removing the record only when both reach zero.
function mass.tick(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_MASS_ENCHANT)

    if not current then
        return
    end

    current.fear_aut = math.max(0, current.fear_aut - 10)
    current.anguish_aut = math.max(0, current.anguish_aut - 10)

    if current.fear_aut == 0 and current.anguish_aut == 0 then
        ctx:remove(monster, component.MONSTER_MASS_ENCHANT)
    else
        ctx:set(monster, component.MONSTER_MASS_ENCHANT, current)
    end
end

-- Berserker Rage shakes off fear without discarding an independent Anguish.
function mass.clear_fear(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_MASS_ENCHANT)

    if not current or current.fear_aut == 0 then
        return false
    end

    current.fear_aut = 0

    if current.anguish_aut == 0 then
        ctx:remove(monster, component.MONSTER_MASS_ENCHANT)
    else
        ctx:set(monster, component.MONSTER_MASS_ENCHANT, current)
    end

    return true
end

return mass
