local component = require("constants.component")
local spells = require("ids.spells")
local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local health_policy = require("policy.combat.player_health")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local player_contact = require("policy.combat.player_contact")

local vampiric_draining = {}

-- Search optional holiness and flag lists while deciding whether a body has drainable life.
local function has_value(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Exclude nonliving or harmless firewood targets before life transfer.
local function susceptible(ctx, target, definition)
    local living = has_value(definition.holiness, "MH_NATURAL") or
        has_value(definition.holiness, "MH_PLANT")
    local firewood = definition.speed == 0 and
        has_value(definition.flags, "M_NO_THREAT")

    return living and not firewood and not ctx:has(target, component.SUMMON)
end

-- Example: A living adjacent monster makes Vampiric Draining targetable; a nonliving one does not.
-- Exclude summons, resistant bodies, and blocked paths before offering the life-drain cast.
function vampiric_draining.can_target(ctx, player, spell)
    local source = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local definition, health = damage.monster(ctx, target)
            local distance = math.max(math.abs(position.x - source.x),
                math.abs(position.y - source.y))

            if health.current > 0 and distance <= reach and
                position.level_id == source.level_id and
                susceptible(ctx, target, definition) and
                damage.monster_resistance(ctx, target,
                    resistances.NEGATIVE_ENERGY) < 3 and
                ctx:visible(source.level_id, source.x, source.y, reach,
                    position.x, position.y) and
                ctx:projectile_clear(source.level_id, source.x, source.y,
                    position.x, position.y) then
                return true
            end
        end
    end

    return false
end

-- Roll two source dice with a power-capped side count on the spell stream.
local function roll_damage(ctx, power)
    -- zap-data.h:ZAP_VAMPIRIC_DRAINING: dicedef<2,6,1,14>, cap 200.
    local sides = 6 + math.floor(math.min(power, 200) / 14)

    return 2 + ctx:random("spell", sides) + ctx:random("spell", sides)
end

-- Keep the source negative-energy resistance fractions when reducing raw drain.
local function resist_damage(raw, resistance)
    -- fight.cc:resist_adjust_damage uses special negative-energy fractions.
    if resistance >= 3 then
        return 0
    elseif resistance > 0 then
        return math.floor(raw / (resistance * 2))
    elseif resistance < 0 then
        return math.floor(raw * 3 / 2)
    end

    return raw
end

-- Trace first contact and heal the caster only from damage actually drained.
function vampiric_draining.resolve(ctx, player, intent, spell, power)
    local source = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, source.level_id, source.x, source.y,
        source.x + intent.dx, source.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "Vampiric Draining finds no target.")
        return
    end

    local target = contact.actor
    local definition, health = damage.monster(ctx, target)

    if not definition then
        error("Vampiric Draining struck an actor without health")
    end

    player_contact.report(ctx, target, definition)

    local negative = damage.monster_resistance(ctx, target,
        resistances.NEGATIVE_ENERGY)

    if not susceptible(ctx, target, definition) or negative >= 3 then
        ctx:emit("spell", "The " .. definition.name .. " is unaffected.")
        return
    end

    local amount = resist_damage(roll_damage(ctx, power), negative)
    local drained = math.min(health.current, amount)

    if drained <= 0 then
        return
    end

    damage.apply(ctx, target, amount)
    ctx:emit("spell", "You draw life force from the " .. definition.name .. ".")

    local player_health = ctx:get(player, component.HEALTH)
    if player_health.current < player_health.max and
        health_policy.can_heal(ctx, player) then
        -- beam.cc:_vampiric_draining_effect heals div_rand_round(drain, 2).
        local gained = math.floor(drained / 2)

        if drained % 2 == 1 and ctx:random("spell", 2) == 0 then
            gained = gained + 1
        end

        if gained > 0 then
            player_health.current = math.min(player_health.max,
                player_health.current + gained)
            ctx:set(player, component.HEALTH, player_health)
            ctx:emit("spell", "You feel life coursing into your body.")
        end
    end
end

registry.add(spells.SPELL_VAMPIRIC_DRAINING, vampiric_draining)

return vampiric_draining
