-- Source: beam.cc:BEAM_CHARM and mass_enchantment, monster.cc:go_frenzy,
-- mon-ench.cc:calc_duration and frenzy expiry.
local component = require("constants.component")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local roll = require("policy.combat.roll")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")

local allegiance = {}

local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function state(ctx, target)
    return ctx:get(target, component.MONSTER_ALLEGIANCE)
end

local function save(ctx, target, value)
    if state(ctx, target) then
        ctx:set(target, component.MONSTER_ALLEGIANCE, value)
    else
        ctx:add(target, component.MONSTER_ALLEGIANCE, value)
    end
end

local function ensure(ctx, target)
    return state(ctx, target) or {
        charm_aut = 0,
        frenzy_aut = 0,
        fatigue_aut = 0,
    }
end

local function charm_duration(ctx, target, definition)
    local actor = ctx:get(target, component.ACTOR)
    local speed = math.max(1, actor.speed)
    local scaled_hd = math.max(1,
        math.floor((definition.hd + 10) * 10 / speed))
    local centiturns = math.max(2, math.floor(500 / scaled_hd))
    local raw = centiturns * roll.random_divide(ctx, 100, speed)
    local low = math.floor(raw * 60 / 100)
    local high = math.floor(raw * 40 / 100)
    local fuzz = roll.average_two(ctx, "melee", low + high + 1)

    return math.max(15, raw + fuzz - low)
end

local function average_two(ctx, bound)
    return math.floor((ctx:random("spell", bound) +
        ctx:random("spell", bound + 1)) / 2)
end

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

function allegiance.can_target_charm(ctx, player, spell)
    return can_target(ctx, player, spell)
end

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

    if will.resists(ctx, definition, power) then
        ctx:emit("spell", "The " .. definition.name .. " resists charm.")
        return
    end

    local value = ensure(ctx, target)
    value.charm_aut = value.charm_aut + charm_duration(ctx, target, definition)
    save(ctx, target, value)
    ctx:emit("spell", "The " .. definition.name .. " is charmed.")
end

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

                    if will.resists(ctx, definition, enchant_power) then
                        ctx:emit("spell", "The " .. definition.name .. " resists.")
                    else
                        local value = ensure(ctx, target)
                        local lasting = (16 + average_two(ctx, 13)) * 10
                        value.frenzy_aut = lasting
                        value.fatigue_aut = 0
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

function allegiance.charmed(ctx, target)
    local current = state(ctx, target)

    return current ~= nil and current.charm_aut > 0
end

function allegiance.frenzied(ctx, target)
    local current = state(ctx, target)

    return current ~= nil and current.frenzy_aut > 0
end

function allegiance.frenzy_melee_damage(ctx, target, damage)
    if allegiance.frenzied(ctx, target) then
        return math.floor(damage * 3 / 2)
    end

    return damage
end

local function random_round(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("speed", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

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

function allegiance.tick(ctx, target)
    local current = state(ctx, target)

    if not current then
        return
    end

    current.charm_aut = math.max(0, current.charm_aut - 10)

    if current.frenzy_aut > 0 then
        current.frenzy_aut = math.max(0, current.frenzy_aut - 10)

        if current.frenzy_aut == 0 then
            current.fatigue_aut = 70 + ctx:random("spell", 61)
            local actor = ctx:get(target, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)
            ctx:emit("monster", "The " .. definition.name ..
                " is no longer in an insane frenzy.")
        end
    elseif current.fatigue_aut > 0 then
        current.fatigue_aut = math.max(0, current.fatigue_aut - 10)
    end

    if current.charm_aut > 0 or current.frenzy_aut > 0 or
        current.fatigue_aut > 0 then
        ctx:set(target, component.MONSTER_ALLEGIANCE, current)
    else
        ctx:remove(target, component.MONSTER_ALLEGIANCE)
    end
end

return allegiance
