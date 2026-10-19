-- Mindburst is an enchantment contact with a will save for the player, but
-- its damage bypasses armour and uses this arc's current chaos dice.
local component = require("constants.component")
local harness = require("tests.harness")
local hex = require("policy.combat.monster_spells.hex")
local damage = require("policy.combat.monster_hexes.damage")
local mindburst = require("policy.combat.monster_area.chaos_mindburst")
local monster_mindburst = require("policy.combat.monster_hexes.mindburst")
local calculators = require("policy.combat.monster_beams.calculators")

local test = {}
local caster = 11
local player = 22
local monster = 33

-- Stub only the common dice, viability, save, and health owners. This
-- leaves the Chain policy responsible for the order of those decisions.
function test.run()
    local saved = {
        resisted = hex.resisted,
        viable = monster_mindburst.viable,
        dice = calculators.damage_dice,
        roll = calculators.roll_damage,
        damage = damage.apply,
    }
    local observed = {
        saves = 0,
        dice_power = 0,
        hits = 0,
    }
    local ctx = {}
    local profile = {
        rng_stream = "monster_spell",
    }

    -- Player identity alone decides whether a willpower save is allowed.
    function ctx:has(target, id)
        return target == player and id == component.PLAYER
    end

    monster_mindburst.viable = function(_, _, target)
        return target ~= 44
    end

    hex.resisted = function()
        observed.saves = observed.saves + 1

        return true
    end

    calculators.damage_dice = function(_, _, power)
        observed.dice_power = power

        return {
            count = 3,
            sides = 7,
        }
    end

    calculators.roll_damage = function()
        return 12
    end

    damage.apply = function(_, _, target, amount)
        observed.hits = observed.hits + 1
        harness.equal(target, monster, "monster receives unarmoured damage")
        harness.equal(amount, 12, "source dice reach health unchanged")
    end

    mindburst.apply(ctx, caster, player, nil, 17, profile)
    mindburst.apply(ctx, caster, 44, nil, 12, profile)
    mindburst.apply(ctx, caster, monster, nil, 8, profile)

    harness.equal(observed.saves, 1,
        "only the viable player rolls a Chaos Mindburst save")
    harness.equal(observed.dice_power, 8,
        "the monster's late arc uses attenuated power")
    harness.equal(observed.hits, 1,
        "an unresisted, viable actor takes one hit")

    hex.resisted = saved.resisted
    monster_mindburst.viable = saved.viable
    calculators.damage_dice = saved.dice
    calculators.roll_damage = saved.roll
    damage.apply = saved.damage
end

return test
