local resistance = require("policy.combat.player_resistance")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local monster_health = require("policy.combat.monster_health")
local component = require("constants.component")
local catalog = require("policy.catalog")
local will = require("policy.magic.effects.zaps.will")
local beam_power = require("policy.combat.monster_beams.power")
local calculators = require("policy.combat.monster_beams.calculators")
local senses = require("policy.character.senses")

local hex = {}

-- Caster power is stepped down by the profile before a willpower contest.
function hex.enchantment_power(ctx, caster, profile, arc_power)
    -- A chained beam has already lost power on earlier jumps. Its current
    -- power is authoritative; recalculating caster HD would reset it.
    if arc_power ~= nil then
        return math.min(profile.cap or arc_power, arc_power)
    end

    local power = beam_power.caster_power(ctx, caster, profile)

    return math.min(profile.cap or power,
        calculators.enchantment_power(profile, power))
end

-- Source: beam.cc:ench_power_stepdown and actor.cc:check_willpower.
-- A source zap profile supplies the spell's actual monster power factor.
-- Example: hex.resisted(ctx, caster, target, profile) with successful player will save -> resisted result
-- Player will uses two monster-spell draws; a resisted hex may retaliate through Demonic Will.
function hex.resisted(ctx, caster, target, profile, arc_power)
    local enchant_power = hex.enchantment_power(ctx, caster,
        profile, arc_power)

    if not ctx:has(target, component.PLAYER) then
        local actor = ctx:get(target, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        return will.resists(ctx, definition, enchant_power, target,
            profile.rng_stream, caster)
    end

    local adjusted = math.floor(35 * math.log(1 + enchant_power / 35) /
        math.log(2) + 0.5)
    local threshold = 100 + resistance.willpower(ctx, target) - adjusted
    local roll = ctx:random("monster_spell", 100) +
        ctx:random("monster_spell", 101)

    if threshold <= roll then
        return false
    end

    if levels.effective(ctx, target, mutations.MUT_DEMONIC_WILL) > 0 then
        local health = ctx:get(caster, component.HEALTH)

        if health and health.current > 0 then
            local rounded = math.floor(enchant_power / 10)
            local remainder = enchant_power % 10

            if remainder > 0 and ctx:random("monster_spell", 10) <
                remainder then
                rounded = rounded + 1
            end

            local amount = 3 + ctx:random("monster_spell", 1 + rounded)
            local actor = ctx:get(caster, component.ACTOR)
            local definition = catalog.get("monsters", actor.kind_id)

            monster_health.damage(ctx, caster, amount, target)

            -- The player feels the backlash, but an invisible caster must
            -- not be named merely because its hex was resisted.
            if senses.player_sees_actor(ctx, caster) then
                ctx:emit("combat", "Your will lashes out at the " ..
                    definition.name .. "!")
            else
                ctx:emit("combat", "Your will lashes out at something!")
            end
        end
    end

    return true
end

return hex
