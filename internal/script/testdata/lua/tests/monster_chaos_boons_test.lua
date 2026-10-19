-- Chain of Chaos boons use the same player and monster status owners as
-- potions, allied beams, and frenzy. Chaos itself owns only dispatch.
local component = require("constants.component")
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local boons = require("policy.combat.monster_area.chaos_boons")
local monster_boons = require("policy.combat.monster_support.boons")
local monster_healing = require("policy.combat.monster_support.healing")
local monster_invisibility = require(
    "policy.combat.monster_support.invisibility")
local duration = require("policy.combat.monster_support.duration")
local eligibility = require(
    "policy.combat.monster_support.boon_eligibility")
local player_agility = require("policy.character.agility")
local player_haste = require("policy.character.haste")
local player_healing = require("policy.potions.effects.heal_wounds")
local player_invisibility = require(
    "policy.potions.effects.invisibility")
local player_might = require("policy.character.might")

local test = {}
local caster = 11
local player = 22
local monster = 33

-- A source beam may buff either actor; the selected owner receives this
-- arc's power, while monster Healing receives its already-rolled amount.
function test.run()
    local saved = {
        monster_haste = monster_boons.haste,
        monster_heal = monster_healing.beam,
        monster_invisible = monster_invisibility.grant,
        player_agile = player_agility.apply,
        player_haste = player_haste.apply,
        player_heal = player_healing.apply,
        player_invisible = player_invisibility.apply,
        player_might = player_might.apply,
        duration = duration.beneficial,
        eligibility = eligibility.haste,
    }
    local observed = {}
    local ctx = {}

    -- Separate player and monster dispatch through the real component ID.
    function ctx:has(target, id)
        return target == player and id == component.PLAYER
    end

    -- A wounded target lets the healing path reach its owner.
    function ctx:get(_, id)
        if id == component.HEALTH then
            return {
                current = 4,
                max = 10,
            }
        end
    end

    -- Messages are outside this ownership test's observable state.
    function ctx:emit()
    end

    duration.beneficial = function()
        return 100
    end

    eligibility.haste = function()
        return true
    end

    monster_boons.haste = function(_, target, duration)
        observed.monster_haste = {
            target = target,
            duration = duration,
        }
    end

    monster_healing.beam = function(_, _, target, _, power)
        observed.monster_heal = {
            target = target,
            power = power,
        }
    end

    monster_invisibility.grant = function(_, target, duration)
        observed.monster_invisible = {
            target = target,
            duration = duration,
        }
    end

    player_agility.apply = function(_, target, power)
        observed.player_agile = {
            target = target,
            power = power,
        }
    end

    player_haste.apply = function(_, target, power)
        observed.player_haste = {
            target = target,
            power = power,
        }
    end

    player_healing.apply = function(_, target)
        observed.player_heal = target
    end

    player_invisibility.apply = function(_, target)
        observed.player_invisible = target
    end

    player_might.apply = function(_, target, power)
        observed.player_might = {
            target = target,
            power = power,
        }
    end

    boons.apply(ctx, caster, player, flavours.BEAM_HASTE, 17)
    boons.apply(ctx, caster, player, flavours.BEAM_MIGHT, 8)
    boons.apply(ctx, caster, player, flavours.BEAM_AGILITY, 6)
    boons.apply(ctx, caster, player, flavours.BEAM_INVISIBILITY, 5)
    boons.apply(ctx, caster, player, flavours.BEAM_HEALING, 4)
    boons.apply(ctx, caster, monster, flavours.BEAM_HASTE, 17)
    boons.apply(ctx, caster, monster, flavours.BEAM_INVISIBILITY, 8)
    boons.apply(ctx, caster, monster, flavours.BEAM_HEALING, 4, {})

    harness.equal(observed.player_haste.power, 17,
        "player haste receives the current arc power")
    harness.equal(observed.player_might.power, 8,
        "player might receives the current arc power")
    harness.equal(observed.player_agile.power, 6,
        "player agility receives the current arc power")
    harness.equal(observed.player_invisible, player,
        "player invisibility goes to its existing owner")
    harness.equal(observed.player_heal, player,
        "player healing goes to its existing owner")
    harness.equal(observed.monster_haste.target, monster,
        "monster haste goes to its existing owner")
    harness.equal(observed.monster_invisible.target, monster,
        "monster invisibility goes to its existing owner")
    harness.equal(observed.monster_heal.power, 4,
        "monster healing uses the current arc's damage dice")

    monster_boons.haste = saved.monster_haste
    monster_healing.beam = saved.monster_heal
    monster_invisibility.grant = saved.monster_invisible
    player_agility.apply = saved.player_agile
    player_haste.apply = saved.player_haste
    player_healing.apply = saved.player_heal
    player_invisibility.apply = saved.player_invisible
    player_might.apply = saved.player_might
    duration.beneficial = saved.duration
    eligibility.haste = saved.eligibility
end

return test
