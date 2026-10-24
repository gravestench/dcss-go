-- Natural monster hits place familiar statuses through their existing
-- owners. The source attack flavour selects the effect; this module owns
-- the contact-specific chances and leaves every timer in Akara state.
local allegiance = require(
    "policy.magic.effects.statuses.monster_allegiance")
local attack_types = require("constants.monster_attack_types")
local barbs = require("policy.combat.barbs")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local form_ids = require("constants.form_ids")
local confusion = require("policy.magic.player_confusion")
local monster_confusion = require(
    "policy.magic.effects.statuses.confusing_touch")
local monster_flags = require("constants.monster_flags")
local monster_holiness = require("constants.monster_holiness")
local monster_paralysis = require(
    "policy.magic.effects.zaps.paralysis")
local monster_poison = require("policy.combat.monster_poison")
local monster_slow = require("policy.combat.monster_slow")
local monster_stats = require("policy.combat.monster_stats")
local monster_stasis = require("policy.monsters.stasis")
local lowered_will = require(
    "policy.magic.effects.statuses.lowered_will")
local paralysis = require("policy.character.paralysis")
local player_poison = require("policy.combat.player_poison")
local player_resistance = require(
    "policy.combat.player_resistance")
local player_slow = require("policy.character.slow")
local player_status = require(
    "policy.magic.effects.statuses.player")
local rage = require("policy.character.rage")
local roll = require("policy.combat.roll")
local species_ids = require("ids.species")
local streams = require("constants.rng_streams")
local undead_states = require("constants.undead_states")
local vampire = require("policy.character.vampire")
local will = require("policy.magic.effects.zaps.will")

local afflictions = {}

-- Catalogs store lists, so scan rather than assuming a keyed set. This
-- also lets sparse mod definitions omit optional flags and holiness.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Source `is_unbreathing` excludes swimmer status: spores care whether
-- the victim breathes, not whether magical water can drown it.
local function unbreathing(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        local choice = ctx:get(hit.defender, component.PLAYER)
        local species = catalog.get(categories.SPECIES,
            choice.species_id)
        local form = ctx:get(hit.defender, component.PLAYER_FORM)
        local petrification = ctx:get(hit.defender,
            component.PLAYER_PETRIFICATION)

        return species.undead_type == undead_states.UNDEAD or
            choice.species_id == species_ids.SP_GARGOYLE or
            choice.species_id == species_ids.SP_DJINNI or
            vampire.bloodless(ctx, hit.defender) or
            form and (form.form_id == form_ids.TREE or
                form.form_id == form_ids.LICH or
                form.form_id == form_ids.STATUE or
                form.form_id == form_ids.WISP or
                form.form_id == form_ids.STORM) or
            petrification and petrification.petrified_aut > 0
    end

    local definition = hit.defender_definition

    return has(definition.holiness, monster_holiness.UNDEAD) or
        has(definition.holiness, monster_holiness.NONLIVING) or
        has(definition.holiness, monster_holiness.PLANT)
end

-- A deathcap or wandering mushroom spends one HD when its spores reach
-- a breathing body. Save permanent exhaustion separately from temporary
-- Drain; zero HD leaves a corpse for the ordinary death system.
local function spend_spore(ctx, hit)
    local current = ctx:get(hit.attacker,
        component.MONSTER_SPORE_EXHAUSTION)
    local next_state = {
        lost_hd = (current and current.lost_hd or 0) + 1,
    }

    if current then
        ctx:set(hit.attacker,
            component.MONSTER_SPORE_EXHAUSTION, next_state)
    else
        ctx:add(hit.attacker,
            component.MONSTER_SPORE_EXHAUSTION, next_state)
    end

    local actor = ctx:get(hit.attacker, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    if monster_stats.base_hit_dice(ctx, hit.attacker,
        definition) > next_state.lost_hd then
        return
    end

    local health = ctx:get(hit.attacker, component.HEALTH)

    health.current = 0
    ctx:set(hit.attacker, component.HEALTH, health)
end

-- Spores weaken their source before the ordinary one-in-three confusion
-- chance. A monster victim still gets its beam-like will contest; a
-- player instead receives the source strength directly as turns.
function afflictions.confuse(ctx, hit)
    if hit.damage_done <= 0 then
        return false
    end

    local power_hd = hit.hit_dice

    if hit.attack_type == attack_types.SPORE then
        if unbreathing(ctx, hit) then
            return false
        end

        spend_spore(ctx, hit)

        power_hd = math.max(0, power_hd - 1)
    end

    if roll.melee(ctx, 3) ~= 0 then
        return false
    end

    local power = 1 + roll.melee(ctx, 3 + power_hd)

    if ctx:has(hit.defender, component.PLAYER) then
        if player_resistance.clarity(ctx, hit.defender) then
            return false
        end

        confusion.extend(ctx, hit.defender, power)

        return true
    end

    if has(hit.defender_definition.flags,
        monster_flags.CLARITY) then
        return false
    end

    return monster_confusion.apply(ctx, hit.defender,
        hit.defender_definition, power, hit.attacker,
        streams.MELEE)
end

-- Melee Barbs use the same saved wound and movement harm as Throw Barbs,
-- but spend their duration draws on the melee RNG stream.
function afflictions.barbs(ctx, hit)
    return barbs.lodge(ctx, hit.attacker, hit.defender,
        hit.damage_done, streams.MELEE)
end

-- Moth of Wrath Rage respects each victim's current Berserk gate. The
-- monster path uses the frenzy owner; the player path handles HP scaling.
function afflictions.rage(ctx, hit)
    if hit.damage_done <= 0 or roll.melee(ctx, 3) ~= 0 then
        return false
    end

    if ctx:has(hit.defender, component.PLAYER) then
        return rage.begin(ctx, hit.defender, streams.MELEE)
    end

    if not allegiance.can_berserk(ctx, hit.defender) then
        return false
    end

    allegiance.start_berserk(ctx, hit.defender, streams.MELEE)

    return true
end

-- A vulnerability hit adds player duration up to forty turns; monster
-- enchantments stack through the shared lowered-will status owner.
function afflictions.vulnerability(ctx, hit)
    if hit.damage_done <= 0 or roll.melee(ctx, 3) ~= 0 then
        return false
    end

    if not ctx:has(hit.defender, component.PLAYER) and
        will.invulnerable(hit.defender_definition) then
        return false
    end

    local duration = (20 + roll.melee(ctx, 20)) * 10

    if ctx:has(hit.defender, component.PLAYER) then
        player_status.extend_lower_will(ctx, hit.defender,
            duration)
    else
        lowered_will.apply(ctx, hit.defender, duration)
    end

    return true
end

-- Read poison resistance once before any chance rolls. Each poisoning
-- attempt may then make its own ordinary resistance check, just as source
-- actor::poison does after the flavour's initial immunity gate.
local function poison_resistance(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return player_resistance.poison(ctx, hit.defender)
    end

    return monster_poison.effective_resistance(ctx,
        hit.defender, hit.defender_definition)
end

-- Poison is an independent one-in-three branch with an HD-scaled dose.
-- The saved poison owner still decides whether partial rPois resists it.
local function apply_poison(ctx, hit)
    if roll.melee(ctx, 3) ~= 0 then
        return false
    end

    local low = math.floor(hit.hit_dice * 3 / 2)
    local high = math.floor(hit.hit_dice * 5 / 2)
    local amount = low + roll.melee(ctx, high - low + 1)

    if ctx:has(hit.defender, component.PLAYER) then
        local actor = ctx:get(hit.attacker, component.ACTOR)

        return player_poison.deliver(ctx, amount, actor.kind_id)
    end

    return monster_poison.apply(ctx, hit.defender,
        hit.defender_definition, 1 + math.floor(amount / 7),
        hit.attacker, false, hit.player_credit)
end

-- A monster's slow or paralysis enchantment makes the ordinary will
-- contest after poison resistance; the player uses direct status owners.
local function control(ctx, hit, paralyse)
    if not ctx:has(hit.defender, component.PLAYER) and
        monster_stasis.intrinsic(hit.defender_definition) then
        return false
    end

    local power = 1 + roll.melee(ctx, 3)

    if ctx:has(hit.defender, component.PLAYER) then
        if paralyse then
            return paralysis.melee(ctx, hit.defender, power)
        end

        return player_slow.apply(ctx, hit.defender, power)
    end

    if will.resists(ctx, hit.defender_definition, power,
        hit.defender, streams.MELEE, hit.attacker) then
        return false
    end

    if paralyse then
        monster_paralysis.apply_unresisted(ctx, hit.defender,
            hit.defender_definition, power)
    else
        monster_slow.apply(ctx, hit.defender,
            hit.defender_definition, power * 10, streams.MELEE)
    end

    return true
end

-- Hornet and jorogumo venom can poison and disable in one hit. The
-- control branch is independent of the poisoning branch, while positive
-- rPois rejects each control attempt two times in three.
function afflictions.poison_paralysis(ctx, hit)
    if hit.damage_done <= 0 then
        return false
    end

    local resistance = poison_resistance(ctx, hit)

    if resistance >= 3 then
        return false
    end

    local poisoned = apply_poison(ctx, hit)
    local paralyse = roll.melee(ctx, 6) == 0

    if resistance > 0 and roll.melee(ctx, 3) ~= 0 then
        return poisoned
    end

    return control(ctx, hit, paralyse) or poisoned
end

return afflictions
