-- Source: spl-selfench.cc, player-reacts.cc, duration-data.h, player.cc,
-- mon-death.cc, and areas.cc at crawl-ref e60ba356.
local statuses = {}
local spells = require("ids.spells")
local component = require("constants.component")
local confusing_touch = require("policy.magic.effects.statuses.confusing_touch")
local mass = require("policy.magic.effects.statuses.mass_enchantment")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local stasis = require("policy.magic.effects.statuses.monster_stasis")
local allegiance = require("policy.magic.effects.statuses.monster_allegiance")
local resources = require("policy.magic.resources")
local player_slow = require("policy.character.slow")
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")

local function roll(ctx, bound)
    if bound <= 0 then
        return 0
    end

    return ctx:random("spell", bound)
end

local function average(ctx, bound, count)
    if bound <= 0 then
        return 0
    end

    local total = roll(ctx, bound)

    for _ = 2, count do
        total = total + roll(ctx, bound + 1)
    end

    return math.floor(total / count)
end

local function state(ctx, player)
    return ctx:get(player, component.PLAYER_STATUS)
end

local function ensure(ctx, player)
    return state(ctx, player) or {
        swift_aut = 0,
        swift_return_aut = 0,
        swift_phase = 0,
        wereblood_aut = 0,
        wereblood_bonus = 0,
        silence_aut = 0,
        lowered_will_aut = 0,
        ice_armour_aut = 0,
        ice_armour_power = 0,
        death_door_aut = 0,
        death_door_hp = 0,
        death_door_cooldown_aut = 0,
        blink_cooldown_aut = 0,
        confusing_touch_aut = 0,
        confusing_touch_power = 0,
        portal_projectile_aut = 0,
        portal_projectile_power = 0,
        disjunction_aut = 0,
        vertigo_aut = 0,
    }
end

statuses.ensure = ensure

-- This is the successful-cast hook. The spell registry must call it only
-- after common miscast and resource handling have completed.
function statuses.cast(ctx, player, spell_id, power, liquid_name)
    local value = ensure(ctx, player)

    if spell_id == spells.SPELL_SWIFTNESS then
        if liquid_name then
            ctx:emit("spell", "The " .. liquid_name .. " foams!")
        end

        value.swift_aut = math.min(30, 12 + math.floor(roll(ctx, power) / 2)) * 10
        value.swift_return_aut = value.swift_aut
        value.swift_phase = 1
        ctx:emit("spell", "You feel quick.")
    elseif spell_id == spells.SPELL_WEREBLOOD then
        if value.wereblood_aut > 0 then
            ctx:emit("spell", "Your blood is freshly infused with primal strength!")
        else
            ctx:emit("spell", "Your blood is infused with primal strength.")
        end

        value.wereblood_aut = (20 + average(ctx, power, 2)) * 10
        value.wereblood_bonus = 0
    elseif spell_id == spells.SPELL_SILENCE then
        ctx:emit("spell", "A profound silence engulfs you.")
        local added = 10 + math.floor(power / 4) + average(ctx, math.floor(power / 2), 2)
        value.silence_aut = math.min(1000, value.silence_aut + added * 10)
    elseif spell_id == spells.SPELL_OZOCUBUS_ARMOUR then
        if value.ice_armour_aut > 0 then
            ctx:emit("spell", "Your icy armour thickens.")
        elseif ctx:get(player, component.PLAYER_FORM) and
            ctx:get(player, component.PLAYER_FORM).form_id == "ice_beast" then
            ctx:emit("spell", "Your icy body feels more resilient.")
        else
            ctx:emit("spell", "A film of ice covers your body!")
        end

        value.ice_armour_aut = math.min(500, value.ice_armour_aut +
            (40 + roll(ctx, 11)) * 10)
        value.ice_armour_power = power
    elseif spell_id == spells.SPELL_DEATHS_DOOR then
        ctx:emit("spell", "You stand defiantly in death's doorway!")
        ctx:emit("sound", "You seem to hear sand running through an hourglass...")
        local duration = 10 + average(ctx, 13, 3) + math.floor(roll(ctx, power) / 10)
        value.death_door_aut = duration * 10

        if value.death_door_aut > 250 then
            value.death_door_aut = (23 + roll(ctx, 5)) * 10
        end

        value.death_door_hp = math.max(1, math.floor(power / 10))
        local health = ctx:get(player, component.HEALTH)
        health.current = math.min(health.max, value.death_door_hp)
        ctx:set(player, component.HEALTH, health)
    elseif spell_id == spells.SPELL_CONFUSING_TOUCH then
        local before = value.confusing_touch_aut
        local rolled = 10 + math.floor(roll(ctx, power) / 5)
        value.confusing_touch_aut = math.min(200, math.max(rolled * 10, before))
        value.confusing_touch_power = power
        ctx:emit("spell", before > 0 and "Your hands begin to glow brighter." or
            "Your hands begin to glow red.")
    elseif spell_id == spells.SPELL_PORTAL_PROJECTILE then
        local before = value.portal_projectile_aut
        local half = math.floor(power / 2)
        local fifth = math.floor(power / 5)
        local added = 3 + roll(ctx, half) + roll(ctx, fifth)
        value.portal_projectile_aut = math.min(500, before + added * 10)
        value.portal_projectile_power = power
        ctx:emit("spell", before > 0 and "You renew your portal." or
            "You begin teleporting projectiles to their destination.")
    else
        error("unknown self-status spell " .. tostring(spell_id))
    end

    if state(ctx, player) then
        ctx:set(player, component.PLAYER_STATUS, value)
    else
        ctx:add(player, component.PLAYER_STATUS, value)
    end
end

local function decay(ctx, value, field, aut, warning, threshold, loss)
    local before = value[field]

    if before <= 0 or aut <= 0 then
        return false
    end

    local remaining = before - aut

    if warning and before > threshold and remaining <= threshold then
        remaining = math.max(1, remaining - loss)
        ctx:emit("duration", warning)
    end

    value[field] = math.max(0, remaining)

    return value[field] == 0
end

-- Called once after each player action. Warning rolls retain the source
-- chance and do not consume RNG before their threshold is crossed.
function statuses.tick(ctx, player, aut)
    local value = state(ctx, player)

    if not value or aut <= 0 then
        return
    end

    local swift_loss = 0

    if value.swift_aut > 0 then
        swift_loss = ctx:random("speed", 2) * 10
    end

    if decay(ctx, value, "swift_aut", aut,
        value.swift_phase == 1 and "You start to feel a little slower." or
            "You start to feel a little faster.", 60,
        swift_loss) then
        if value.swift_phase == 1 then
            value.swift_phase = 2
            value.swift_aut = value.swift_return_aut
            ctx:emit("duration", "You feel sluggish.")
        elseif value.swift_phase == 2 then
            value.swift_phase = 0
            value.swift_return_aut = 0
            ctx:emit("duration", "You no longer feel sluggish.")
        end
    end

    if decay(ctx, value, "wereblood_aut", aut,
        "Your primal bloodlust is almost over.", 60, 0) then
        value.wereblood_bonus = 0
        ctx:emit("duration", "Your primal bloodlust has ended.")
    end

    if decay(ctx, value, "silence_aut", aut, nil, 50, 0) then
        ctx:emit("duration", "Your hearing returns.")
    end

    if decay(ctx, value, "lowered_will_aut", aut, nil, 0, 0) then
        ctx:emit("duration", "Your willpower returns.")
    end

    local ice_loss = 0

    if value.ice_armour_aut > 0 then
        ice_loss = ctx:random("speed", 2) * 10
    end

    if decay(ctx, value, "ice_armour_aut", aut,
        "Your icy armour starts to melt.", 60,
        ice_loss) then
        value.ice_armour_power = 0
        ctx:emit("duration", "Your icy armour evaporates.")
    end

    local door_ended = decay(ctx, value, "death_door_aut", aut,
        "Your time is quickly running out!", 100, 0)
    if door_ended then
        value.death_door_hp = 0
        value.death_door_cooldown_aut = 10 + ctx:random("spell", 21)
        ctx:emit("duration", "Your life is in your own hands again!")
    end

    if not door_ended and decay(ctx, value, "death_door_cooldown_aut", aut, nil, 0, 0) then
        ctx:emit("duration", "You step away from death's doorway.")
    end

    if decay(ctx, value, "blink_cooldown_aut", aut, nil, 0, 0) then
        ctx:emit("duration", "You feel stable enough to blink again.")
    end

    if decay(ctx, value, "confusing_touch_aut", aut, nil, 0, 0) then
        value.confusing_touch_power = 0
        ctx:emit("duration", "Your hands stop glowing.")
    end

    if decay(ctx, value, "portal_projectile_aut", aut, nil, 0, 0) then
        value.portal_projectile_power = 0
        ctx:emit("duration", "You are no longer teleporting projectiles to their destination.")
    end

    decay(ctx, value, "disjunction_aut", aut, nil, 0, 0)

    if decay(ctx, value, "vertigo_aut", aut, nil, 0, 0) then
        ctx:emit("duration", "The world stops spinning.")
    end

    if value.death_door_aut > 0 then
        local health = ctx:get(player, component.HEALTH)

        if health and health.current > value.death_door_hp then
            health.current = value.death_door_hp
            ctx:set(player, component.HEALTH, health)
        end
    end

    ctx:set(player, component.PLAYER_STATUS, value)
end

local function random_round(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("speed", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Source: player.cc:player_movement_speed. Call after base speed modifiers,
-- before the global minimum movement speed is applied.
function statuses.move_delay(ctx, player, base_aut, in_liquid)
    local value = state(ctx, player)

    if not value or value.swift_aut <= 0 or in_liquid then
        return base_aut
    end

    if value.swift_phase == 1 then
        return random_round(ctx, 3 * base_aut, 4)
    end

    if value.swift_phase == 2 and base_aut >= 8 then
        return random_round(ctx, 3 * base_aut, 2)
    end

    if value.swift_phase == 2 and base_aut == 7 then
        return random_round(ctx, 42, 5)
    end

    return base_aut
end

-- Source: player.cc:armour_class_with_specific_items. AC is scaled by 100.
function statuses.ice_armour_bonus_x100(ctx, player, body_penalty)
    local value = state(ctx, player)

    if not value or value.ice_armour_aut <= 0 then
        return 0
    end

    return math.max(0, 500 + value.ice_armour_power * 8 - body_penalty * 50)
end

function statuses.death_door_active(ctx, player)
    local value = state(ctx, player)

    return value ~= nil and value.death_door_aut > 0
end

-- Source: spl-selfench.cc:cast_revivification clears the active duration.
-- The caller owns its message and paralysis effect.
function statuses.clear_death_door(ctx, player)
    local value = state(ctx, player)

    if not value or value.death_door_aut <= 0 then
        return false
    end

    value.death_door_aut = 0
    value.death_door_hp = 0
    ctx:set(player, component.PLAYER_STATUS, value)

    return true
end

function statuses.hp_regen_allowed(ctx, player)
    return not statuses.death_door_active(ctx, player)
end

-- Source: spl-util.cc:spell_uselessness_reason. Return a no-time rejection
-- before the common cast path pays MP.
function statuses.rejection(ctx, player, spell_id)
    if spell_id ~= spells.SPELL_DEATHS_DOOR then
        return nil
    end

    local value = state(ctx, player)

    if value and value.death_door_aut > 0 then
        return "You are already standing in death's doorway."
    end

    if value and value.death_door_cooldown_aut > 0 then
        return "You are still too close to death's doorway."
    end

    return nil
end

function statuses.blink_cooldown(ctx, player)
    local value = state(ctx, player)

    return value and value.blink_cooldown_aut or 0
end

function statuses.confusing_touch_active(ctx, player)
    local value = state(ctx, player)

    return value ~= nil and value.confusing_touch_aut > 0
end

-- Source: melee-attack.cc:post_roll_to_hit_modifiers. The caller rolls
-- maybe_random_div(dex, 2) on the melee RNG stream for main attacks only.
function statuses.confusing_touch_hit_bonus(ctx, player, dexterity)
    if not statuses.confusing_touch_active(ctx, player) then
        return 0
    end

    return math.floor(ctx:random("melee", dexterity + 2) / 2)
end

-- Source: melee-attack.cc:player_apply_final_multipliers. Auxiliary hits
-- retain damage and are never passed through this hook.
function statuses.confusing_touch_damage(ctx, player, damage)
    if statuses.confusing_touch_active(ctx, player) then
        return 0
    end

    return damage
end

function statuses.confusing_touch_contact(ctx, player, target, definition)
    local value = state(ctx, player)

    if not value or value.confusing_touch_aut <= 0 then
        return false
    end

    local affected, immune = confusing_touch.apply(ctx, target, definition,
        value.confusing_touch_power)

    if affected then
        value.confusing_touch_aut = 0
        value.confusing_touch_power = 0
        ctx:set(player, component.PLAYER_STATUS, value)
    elseif immune then
        value.confusing_touch_aut = math.min(value.confusing_touch_aut, 1)
        ctx:set(player, component.PLAYER_STATUS, value)
        ctx:emit("spell", "The " .. definition.name ..
            " is completely immune to your confusing touch!")
    end

    return affected
end

-- Source: throw.cc:is_pproj_active requires at least one resource point.
-- The projectile path calls this before its normal trajectory check.
function statuses.portal_projectile_active(ctx, player)
    local value = state(ctx, player)

    return value ~= nil and value.portal_projectile_aut > 0 and
        resources.cannot_pay(ctx, player, 1) == nil
end

function statuses.portal_projectile_power(ctx, player)
    local value = state(ctx, player)

    return value and value.portal_projectile_aut > 0 and
        value.portal_projectile_power or 0
end

-- Source: ranged-attack.cc:post_roll_to_hit_modifiers, divisor 8.
function statuses.portal_projectile_hit_bonus(ctx, player)
    if not statuses.portal_projectile_active(ctx, player) then
        return 0
    end

    local power = statuses.portal_projectile_power(ctx, player)

    return math.floor(ctx:random("melee", power + 8) / 8)
end

function statuses.portal_projectile_pay(ctx, player)
    if not statuses.portal_projectile_active(ctx, player) then
        return false
    end

    resources.pay(ctx, player, 1)

    return true
end

function statuses.fear_active(ctx, monster)
    return mass.fear_active(ctx, monster)
end

function statuses.anguish_reflect(ctx, monster, damage_dealt)
    return mass.anguish_reflect(ctx, monster, damage_dealt)
end

function statuses.enfeeble_blinded(ctx, monster)
    return enfeeble.blinded(ctx, monster)
end

function statuses.enfeeble_dazed(ctx, monster)
    return enfeeble.dazed(ctx, monster)
end

function statuses.enfeeble_melee_damage(ctx, monster, damage)
    return enfeeble.melee_damage(ctx, monster, damage)
end

function statuses.enfeeble_antimagic(ctx, monster, slot_flags)
    return enfeeble.antimagic(ctx, monster, slot_flags)
end

function statuses.hibernating(ctx, monster)
    return stasis.hibernating(ctx, monster)
end

function statuses.petrifying(ctx, monster)
    return stasis.petrifying(ctx, monster)
end

function statuses.petrified(ctx, monster)
    return stasis.petrified(ctx, monster)
end

function statuses.wake_hibernating(ctx, monster)
    return stasis.wake_hibernating(ctx, monster)
end

function statuses.petrified_damage(ctx, monster, amount)
    return stasis.petrified_damage(ctx, monster, amount)
end

function statuses.charmed(ctx, monster)
    return allegiance.charmed(ctx, monster)
end

function statuses.frenzied(ctx, monster)
    return allegiance.frenzied(ctx, monster)
end

function statuses.frenzy_melee_damage(ctx, monster, damage)
    return allegiance.frenzy_melee_damage(ctx, monster, damage)
end

function statuses.frenzy_speed(ctx, monster, base_speed)
    return allegiance.frenzy_speed(ctx, monster, base_speed)
end

function statuses.vertigo_active(ctx, player)
    local value = state(ctx, player)

    return value ~= nil and value.vertigo_aut > 0
end

-- Source: spl-other.cc:cast_intoxicate, increase_duration(DUR_VERTIGO).
function statuses.add_vertigo(ctx, player, turns, maximum_turns)
    if turns <= 0 then
        return
    end

    local current = state(ctx, player)
    local value = current or ensure(ctx, player)
    value.vertigo_aut = value.vertigo_aut + turns * 10

    if maximum_turns then
        value.vertigo_aut = math.min(value.vertigo_aut,
            maximum_turns * 10)
    end

    if current then
        ctx:set(player, component.PLAYER_STATUS, value)
    else
        ctx:add(player, component.PLAYER_STATUS, value)
    end
end

function statuses.add_silence(ctx, player, turns, maximum_turns)
    local current = state(ctx, player)
    local value = current or ensure(ctx, player)

    value.silence_aut = math.min(maximum_turns * 10,
        value.silence_aut + turns * 10)

    if current then
        ctx:set(player, component.PLAYER_STATUS, value)
    else
        ctx:add(player, component.PLAYER_STATUS, value)
    end
end

-- The caller owns source increase_duration arithmetic and passes the new
-- absolute remaining aut. This writer creates the saved status if absent.
function statuses.set_blink_cooldown(ctx, player, aut)
    if aut < 0 then
        error("negative Blink cooldown")
    end

    local current = state(ctx, player)
    local value = current or ensure(ctx, player)
    value.blink_cooldown_aut = aut

    if current then
        ctx:set(player, component.PLAYER_STATUS, value)
    else
        ctx:add(player, component.PLAYER_STATUS, value)
    end
end

-- fatal_exception is true only for the source's environmental and game-end
-- causes, determined by the caller from its generic damage provenance.
function statuses.death_door_damage(ctx, player, damage, fatal_exception)
    local health = ctx:get(player, component.HEALTH)

    if not health or not statuses.death_door_active(ctx, player) or fatal_exception then
        return damage
    end

    return 0
end

function statuses.wereblood_slay(ctx, player)
    local value = state(ctx, player)

    return value and value.wereblood_aut > 0 and value.wereblood_bonus or 0
end

-- Killer credit and XP eligibility are supplied by the death resolution.
function statuses.wereblood_kill(ctx, player, gives_xp, adjacent, object_monster)
    local value = state(ctx, player)

    if not value or value.wereblood_aut <= 0 or not gives_xp then
        return
    end

    value.wereblood_bonus = math.min(9, value.wereblood_bonus + 1)
    ctx:set(player, component.PLAYER_STATUS, value)

    if not adjacent or object_monster or value.death_door_aut > 0 then
        return
    end

    local health = ctx:get(player, component.HEALTH)

    if health and health.current < health.max then
        local before = health.current
        health.current = math.min(health.max, before + 1 + ctx:random("spell", 3))
        ctx:set(player, component.HEALTH, health)

        if health.current > before then
            ctx:emit("spell", "You feel a bit better.")
        end
    end
end

function statuses.silence_radius(ctx, player)
    local value = state(ctx, player)
    local aura = mutation_effects.sum(ctx, player,
        mutation_capabilities.SILENCE_RADIUS)

    if not value or value.silence_aut <= 0 then
        return aura > 0 and aura or -1
    end

    local turns = math.floor(value.silence_aut / 10)
    local squared = math.max(0, math.min(math.floor(3 * (turns - 5) / 4), 25))

    return math.max(aura, math.floor(math.sqrt(squared)))
end

function statuses.lower_will(ctx, player, duration_aut)
    local value = ensure(ctx, player)
    value.lowered_will_aut = math.max(value.lowered_will_aut,
        duration_aut)

    if state(ctx, player) then
        ctx:set(player, component.PLAYER_STATUS, value)
    else
        ctx:add(player, component.PLAYER_STATUS, value)
    end
end

-- Source: player.cc:player_speed. All slowing effects share one duration.
function statuses.slow_active(ctx, player)
    return player_slow.active(ctx, player)
end

return statuses
