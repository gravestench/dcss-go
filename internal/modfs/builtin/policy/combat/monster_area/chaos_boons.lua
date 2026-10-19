-- A Chaos arc can help its victim. These effects use the same saved player
-- and monster statuses as potions, allied beams, and ordinary spell boons.
-- Source: beam.cc:apply_enchantment_to_monster and affect_player_enchantment.
-- Example: boons.apply(ctx, caster, player, BEAM_MIGHT, 17) extends Might.
local agility = require("policy.character.agility")
local allegiance = require(
    "policy.magic.effects.statuses.monster_allegiance")
local chaos_effects = require("constants.chaos_effects")
local chaos_status = require("policy.combat.player_brands.chaos_status")
local component = require("constants.component")
local duration = require("policy.combat.monster_support.duration")
local eligibility = require(
    "policy.combat.monster_support.boon_eligibility")
local flavours = require("constants.beam_flavours")
local haste = require("policy.character.haste")
local healing = require("policy.combat.monster_support.healing")
local invisibility = require(
    "policy.combat.monster_support.invisibility")
local might = require("policy.character.might")
local monster_boons = require("policy.combat.monster_support.boons")
local player_healing = require("policy.potions.effects.heal_wounds")
local player_invisibility = require(
    "policy.potions.effects.invisibility")
local rage = require("policy.character.rage")
local streams = require("constants.rng_streams")

local boons = {}

-- Send player status wording through the usual game message channel.
local function player_message(ctx, message)
    if message then
        ctx:emit("spell", message)
    end
end

-- Player Haste shares the two-thirds source timer with potion Haste.
local function haste_player(ctx, _, target, power)
    player_message(ctx, haste.apply(ctx, target, power,
        streams.MONSTER_SPELL))
end

-- Monster Haste preserves its stationary and stasis guards.
local function haste_monster(ctx, _, target)
    if eligibility.haste(ctx, target) then
        monster_boons.haste(ctx, target,
            duration.beneficial(ctx, target))
    end
end

-- Player Might duration depends on current arc power, not initial HD.
local function might_player(ctx, _, target, power)
    player_message(ctx, might.apply(ctx, target, power,
        streams.MONSTER_SPELL))
end

-- Stationary monsters cannot gain a melee Might boon.
local function might_monster(ctx, _, target)
    if eligibility.might(ctx, target) then
        monster_boons.might(ctx, target,
            duration.beneficial(ctx, target))
    end
end

-- The player's agility timer owns its evasion bonus and expiration.
local function agility_player(ctx, _, target, power)
    player_message(ctx, agility.apply(ctx, target, power,
        streams.MONSTER_SPELL))
end

-- Monster agility has its own saved Chaos status beside generic boons.
local function agility_monster(ctx, _, target)
    if eligibility.might(ctx, target) then
        chaos_status.apply(ctx, target, chaos_effects.AGILITY,
            duration.beneficial(ctx, target))
    end
end

-- Player invisibility keeps its potionlike duration and glow rules.
local function invisible_player(ctx, _, target)
    player_message(ctx, player_invisibility.apply(ctx, target,
        streams.MONSTER_SPELL))
end

-- Monster invisibility uses the saved monster enchant timer.
local function invisible_monster(ctx, _, target)
    invisibility.grant(ctx, target,
        duration.beneficial(ctx, target))
end

-- The player receives the source Heal Wounds potionlike effect.
local function heal_player(ctx, _, target)
    player_message(ctx, player_healing.apply(ctx, target,
        streams.MONSTER_SPELL))
end

-- Monster healing rolls this arc's dice inside the shared health owner.
local function heal_monster(ctx, caster, target, power, profile)
    healing.beam(ctx, caster, target, profile, power)
end

-- Berserk already owns the player's HP and fatigue transition.
local function berserk_player(ctx, _, target)
    rage.begin(ctx, target, streams.MONSTER_SPELL)
end

-- A monster already frenzied does not restart its frenzy timer.
local function berserk_monster(ctx, _, target)
    if not allegiance.frenzied(ctx, target) then
        allegiance.start_berserk(ctx, target)
    end
end

local handlers = {
    [flavours.BEAM_HASTE] = {
        player = haste_player,
        monster = haste_monster,
    },
    [flavours.BEAM_MIGHT] = {
        player = might_player,
        monster = might_monster,
    },
    [flavours.BEAM_AGILITY] = {
        player = agility_player,
        monster = agility_monster,
    },
    [flavours.BEAM_INVISIBILITY] = {
        player = invisible_player,
        monster = invisible_monster,
    },
    [flavours.BEAM_HEALING] = {
        player = heal_player,
        monster = heal_monster,
    },
    [flavours.BEAM_BERSERK] = {
        player = berserk_player,
        monster = berserk_monster,
    },
}

-- Select one small status handler after the ordinary beam contact succeeds.
function boons.apply(ctx, caster, defender, flavour, power, profile)
    local pair = handlers[flavour]

    if not pair then
        error("unknown chain chaos boon " .. tostring(flavour))
    end

    if ctx:has(defender, component.PLAYER) then
        return pair.player(ctx, caster, defender, power, profile)
    end

    return pair.monster(ctx, caster, defender, power, profile)
end

-- The impact policy uses this lookup before routing direct damage.
function boons.handles(flavour)
    return handlers[flavour] ~= nil
end

return boons
