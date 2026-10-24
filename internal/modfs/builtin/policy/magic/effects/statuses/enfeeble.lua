-- Source: spl-monench.cc:enfeeble_monster, beam.cc:BEAM_ENFEEBLE,
-- melee-attack.cc:apply_damage_modifiers, mon-cast.cc and mon-act.cc.
local component = require("constants.component")
local catalog = require("policy.catalog")
local range = require("policy.magic.range")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")
local monster_stats = require("policy.combat.monster_stats")
local monster_spellbook = require("policy.combat.monster_spellbook")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local spell_flags = require("constants.monster_spell_flags")

local enfeeble = {}

-- Missing spell flags or monster traits count as absent, preventing nil catalog lists from changing eligibility.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Read this actor's active slots: generated lords, vault overrides, and
-- summoned casters can differ from the static monster catalog book.
local function spell_sensitive(ctx, target)
    local book = monster_spellbook.for_actor(ctx, target)

    for _, slot in ipairs(book and book.slots or {}) do
        if has(slot.flags, spell_flags.MAGICAL) or
            has(slot.flags, spell_flags.WIZARD) then
            return true
        end
    end

    return false
end

-- Weakness matters only if the monster has a damaging melee attack to reduce.
local function has_attacks(definition)
    for _, attack in ipairs(definition.attacks or {}) do
        if attack.type_id ~= "AT_NONE" and attack.damage > 0 then
            return true
        end
    end

    return false
end

-- A new status record starts with all four timers so each effect can extend independently.
local function status(ctx, target)
    local current = ctx:get(target, component.MONSTER_ENFEEBLE)

    return current or {
        weak_aut = 0,
        antimagic_aut = 0,
        blind_aut = 0,
        dazed_aut = 0,
    }, current ~= nil
end

-- Retain other Enfeeble timers when one duration changes, adding a record only on first use.
local function save_status(ctx, target, value, existed)
    if existed then
        ctx:set(target, component.MONSTER_ENFEEBLE, value)
    else
        ctx:add(target, component.MONSTER_ENFEEBLE, value)
    end
end

-- Randomized rounding preserves fractional power without systematic duration bias.
local function divide_randomly(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Three spell-stream draws fuzz Enfeeble duration after power is scaled to turns.
local function duration(ctx, power)
    local extra = divide_randomly(ctx, power, 40)

    if extra <= 0 then
        return 50
    end

    local rolled = ctx:random("spell", extra) +
        ctx:random("spell", extra + 1) +
        ctx:random("spell", extra + 1)

    return (5 + math.floor(rolled / 3)) * 10
end

-- Weakness and antimagic can land despite a resisted blind/daze roll; each timer only extends.
local function apply(ctx, player, target, definition, power)
    local weak = has_attacks(definition)
    local antimagic = spell_sensitive(ctx, target)
    local resisted = will.resists(ctx, definition, power,
        target, nil, player)
    local blind = not resisted and not has(definition.flags, "M_UNBLINDABLE")
    local dazed = not resisted

    if not weak and not antimagic and not blind and not dazed then
        ctx:emit("spell", "The " .. definition.name .. " resists.")
        return
    end

    local lasting = duration(ctx, power)
    local next_state, existed = status(ctx, target)

    if weak then
        next_state.weak_aut = math.max(next_state.weak_aut, lasting)
    end

    if antimagic then
        next_state.antimagic_aut = math.max(next_state.antimagic_aut, lasting)
    end

    if blind then
        next_state.blind_aut = math.max(next_state.blind_aut, lasting)
    end

    if dazed then
        next_state.dazed_aut = math.max(next_state.dazed_aut, lasting)
    end

    save_status(ctx, target, next_state, existed)

    if resisted then
        ctx:emit("spell", "The " .. definition.name .. " partially resists.")
    end

    ctx:emit("spell", "The " .. definition.name .. " is enfeebled!")
end

-- Chaos and Black Mark share the spellbook test with Enfeeble itself.
function enfeeble.antimagic_susceptible(ctx, target)
    return spell_sensitive(ctx, target)
end

-- Other policies query the same melee eligibility used for Enfeeble weakness.
function enfeeble.has_attacks(definition)
    return has_attacks(definition)
end

-- Source: beam.cc:BEAM_DRAIN_MAGIC. Power is damage dealt times eight for
-- Black Mark; the saved antimagic duration disrupts later wizard magic.
function enfeeble.apply_antimagic(ctx, target, definition, power)
    if not spell_sensitive(ctx, target) then
        return false
    end

    local hd = monster_stats.hit_dice(ctx, target, definition)
    local upper = roll.random_divide(ctx, power, hd)
    local duration = roll.melee(ctx, upper + 1) * 10

    if duration <= 0 then
        return false
    end

    local next_state, existed = status(ctx, target)

    next_state.antimagic_aut = next_state.antimagic_aut + duration
    save_status(ctx, target, next_state, existed)
    ctx:emit("combat", "The " .. definition.name ..
        "'s magic leaks into the air.")

    return true
end

-- Ru supplies an already rolled enchantment duration. Store it in the
-- shared antimagic field without Enfeeble's damage-scaled second roll.
function enfeeble.apply_fixed_antimagic(ctx, target, duration_aut)
    if not spell_sensitive(ctx, target) then
        return false
    end

    local next_state, existed = status(ctx, target)

    next_state.antimagic_aut = next_state.antimagic_aut +
        duration_aut
    save_status(ctx, target, next_state, existed)

    return true
end

-- Source: beam.cc:BEAM_DRAIN_MAGIC uses enchantment power per target HD,
-- then rolls the antimagic duration in baseline delays.
function enfeeble.apply_drain_magic(ctx, target, definition, power)
    if not spell_sensitive(ctx, target) then
        return 0
    end

    local hd = monster_stats.hit_dice(ctx, target, definition)
    local upper = roll.random_divide(ctx, power, hd, "monster_spell")
    local duration = roll.spell(ctx, upper + 1) * 10

    if duration <= 0 then
        return 0
    end

    local next_state, existed = status(ctx, target)

    next_state.antimagic_aut = next_state.antimagic_aut + duration
    save_status(ctx, target, next_state, existed)
    ctx:emit("combat", "The " .. definition.name ..
        "'s magic leaks into the air.")

    return duration
end

-- Source monster::weaken stacks its timer regardless of attack shape.
-- Black Mark checks attack viability before calling; a monster gaze does
-- not. Both share this owner and choose the caster's saved RNG stream.
function enfeeble.apply_weak(ctx, target, definition, power, stream)
    local next_state, existed = status(ctx, target)
    local was_weak = next_state.weak_aut > 0
    local duration = (power + ctx:random(stream or streams.MUTATION,
        power + 3)) * 10

    next_state.weak_aut = next_state.weak_aut + duration
    save_status(ctx, target, next_state, existed)

    if not was_weak then
        ctx:emit("combat", "The " .. definition.name .. " looks weaker.")
    end

    return true
end

-- Offer the spell only when a living actor is visible along a clear in-range ray.
function enfeeble.can_target(ctx, player, spell)
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

-- Resolve the first ray contact rather than the aimed cell, then reject dead or missing actors.
function enfeeble.cast(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        ctx:emit("spell", "The enfeebling magic dissipates.")
        return
    end

    local actor = ctx:get(contact.actor, component.ACTOR)
    local health = ctx:get(contact.actor, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return
    end

    apply(ctx, player, contact.actor,
        catalog.get("monsters", actor.kind_id), power)
end

-- Sight penalties require an active blind timer, not just a saved Enfeeble record.
function enfeeble.blinded(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    return current ~= nil and current.blind_aut > 0
end

-- An active daze has a one-in-four melee-stream chance to waste a monster action.
function enfeeble.dazed(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if not current or current.dazed_aut <= 0 or
        ctx:random("melee", 4) ~= 0 then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    ctx:emit("monster", "The " .. definition.name .. " is lost in a daze.")

    return true
end

-- Weakness reduces raw melee damage to two thirds while its timer is active.
function enfeeble.melee_damage(ctx, monster, damage)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if current and current.weak_aut > 0 then
        return math.floor(damage * 2 / 3)
    end

    return damage
end

-- Only magical or wizard slots can falter; longer antimagic duration raises the chance.
function enfeeble.antimagic(ctx, monster, slot_flags)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if not current or current.antimagic_aut <= 0 or
        not (has(slot_flags, "MON_SPELL_MAGICAL") or
            has(slot_flags, "MON_SPELL_WIZARD")) or
        ctx:random("monster_spell", 40 + current.antimagic_aut) < 40 then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    ctx:emit("monster", "The " .. definition.name .. " falters for a moment.")

    return true
end

-- Sap Magic feeds an existing antimagic component after a wizard cast.
-- This uses a fixed six-turn source duration, rather than Enfeeble's
-- power-dependent duration calculation.
function enfeeble.apply_sap_antimagic(ctx, monster)
    local next_state, existed = status(ctx, monster)

    next_state.antimagic_aut = next_state.antimagic_aut + 60

    save_status(ctx, monster, next_state, existed)
end

-- Example: A monster with only ten aut of blind remaining loses its Enfeeble record on the next tick.
-- Decay all four independent timers before deleting the shared record when its last effect ends.
function enfeeble.tick(ctx, monster)
    local current = ctx:get(monster, component.MONSTER_ENFEEBLE)

    if not current then
        return
    end

    local active = false

    for _, field in ipairs({
        "weak_aut", "antimagic_aut", "blind_aut", "dazed_aut",
    }) do
        current[field] = math.max(0, current[field] - 10)
        active = active or current[field] > 0
    end

    if active then
        ctx:set(monster, component.MONSTER_ENFEEBLE, current)
    else
        ctx:remove(monster, component.MONSTER_ENFEEBLE)
    end
end

return enfeeble
