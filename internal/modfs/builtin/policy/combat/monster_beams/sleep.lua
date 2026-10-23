local beam_power = require("policy.combat.monster_beams.power")
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local component = require("constants.component")
local hex = require("policy.combat.monster_spells.hex")
local holiness = require("constants.monster_holiness")
local monster_flags = require("constants.monster_flags")
local player_resistance = require("policy.combat.player_resistance")
local rage = require("policy.character.rage")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local undead_states = require("constants.undead_states")
local will = require("policy.magic.effects.zaps.will")
local senses = require("policy.character.senses")

local sleep = {}

local sleepless = {
    [holiness.UNDEAD] = true,
    [holiness.NONLIVING] = true,
    [holiness.PLANT] = true,
}

-- Check holiness and clarity flags before an enchantment attempts to induce sleep.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Example: sleep.skip_damage() with sleep enchantment -> true to suppress direct HP damage
-- Sleep is a state-changing enchantment; shared beam contact must not roll HP damage.
function sleep.skip_damage()
    return true
end

-- Existing sleep or immunity time prevents refresh; undead state, Clarity,
-- rage, and paralysis also bar the player enchantment.
local function player_can_sleep(ctx, target)
    local state = ctx:get(target, component.PLAYER_SLEEP)

    if state and (state.remaining_aut > 0 or
        state.immunity_aut > 0) then
        return false
    end

    -- player::put_to_sleep rejects either phase of petrification before
    -- writing a sleep timer, even when the sleep source bypasses Will.
    local petrification = ctx:get(target,
        component.PLAYER_PETRIFICATION)

    if petrification and (petrification.petrifying_aut > 0 or
        petrification.petrified_aut > 0) then
        return false
    end

    local choice = ctx:get(target, component.PLAYER)
    local species = catalog.get("species", choice.species_id)

    return species.undead_type ~= undead_states.UNDEAD and
        not player_resistance.clarity(ctx, target) and
        not rage.active(ctx, target) and
        not ctx:has(target, component.PLAYER_PARALYSIS)
end

-- Five spell-stream draws average enchantment power into a duration in AUT.
local function player_duration(ctx, power)
    local size = math.max(1, math.floor(power / 10))
    local total = 0

    for _ = 1, 5 do
        total = total + ctx:random("monster_spell", size)
    end

    return 10 * (5 + math.floor(total / 5))
end

-- Player sleep uses the beam's will check and stores a separate immunity window.
local function sleep_player(ctx, caster, target, profile)
    if not player_can_sleep(ctx, target) then
        return
    end

    if hex.resisted(ctx, caster, target, profile) then
        ctx:emit("combat", "You resist sleep.")
        return
    end

    local power = beam_power.caster_power(ctx, caster, profile)
    local enchantment = calculators.enchantment_power(profile, power)

    sleep.apply_unresisted(ctx, target, enchantment)
end

-- Monster biological eligibility precedes the separate willpower roll.
local function monster_can_sleep(ctx, target, definition)
    for _, kind in ipairs(definition.holiness or {}) do
        if sleepless[kind] then
            return false
        end
    end

    return not has(definition.flags, monster_flags.CLARITY) and
        not stasis.hibernating(ctx, target)
end

-- Dream Dust has already rolled its own sleep power and does not make a
-- second beam will contest. Share eligibility and saved sleep duration with
-- ordinary Sleep so the two effects cannot disagree about immunity.
function sleep.apply_unresisted(ctx, target, power)
    if ctx:has(target, component.PLAYER) then
        if not player_can_sleep(ctx, target) then
            return false
        end

        ctx:add(target, component.PLAYER_SLEEP, {
            remaining_aut = player_duration(ctx, power),
            immunity_aut = 0,
        })
        ctx:emit("combat", "You fall asleep.")

        return true
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if not monster_can_sleep(ctx, target, definition) then
        return false
    end

    return stasis.sleep(ctx, target)
end

-- Monsters need a fresh will check and hibernation state after the beam contacts them.
local function sleep_monster(ctx, caster, target, profile)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if not monster_can_sleep(ctx, target, definition) then
        return
    end

    local power = beam_power.caster_power(ctx, caster, profile)
    local enchantment = calculators.enchantment_power(profile, power)

    if will.resists(ctx, definition, enchantment, target) then
        return
    end

    stasis.sleep(ctx, target)
    if senses.player_sees_actor(ctx, target) then
        ctx:emit("combat", "The " .. definition.name .. " falls asleep!")
    end
end

-- beam.cc:BEAM_SLEEP is an enchantment: no HP roll, with willpower and
-- biological eligibility checked at contact rather than during tracing.
function sleep.after_hit(ctx, caster, defender, profile)
    if ctx:has(defender, component.PLAYER) then
        sleep_player(ctx, caster, defender, profile)
    else
        sleep_monster(ctx, caster, defender, profile)
    end
end

return sleep
