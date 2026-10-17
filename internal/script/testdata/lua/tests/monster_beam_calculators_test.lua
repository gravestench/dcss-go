local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local harness = require("tests.harness")
local spells = require("ids.spells")

local test = {}

local function fixed_random(_, _, bound)
    return bound - 1
end

function test.run()
    local fire = catalog.get("monster_beams", spells.SPELL_BOLT_OF_FIRE)
    local dart = catalog.get("monster_beams", spells.SPELL_MAGIC_DART)
    local random = { random = fixed_random }

    harness.equal(calculators.to_hit(fire, 120), 21,
        "Bolt of Fire uses its source monster to-hit formula")
    harness.equal(calculators.to_hit(dart, 120), 1500,
        "Magic Dart uses the source automatic-hit value")

    local dice = calculators.damage_dice(random, fire, 120)

    harness.equal(dice.count, 3,
        "Bolt of Fire keeps three damage dice")
    harness.equal(dice.sides, 18,
        "Bolt of Fire calculates damage sides from power")
    harness.equal(calculators.roll_damage(random, dice), 54,
        "rolling maximum results keeps the source dice total")

    local sleep = catalog.get("monster_beams", spells.SPELL_SLEEP)

    harness.equal(calculators.damage_dice(random, sleep, 120).count, 0,
        "Sleep has no implicit damage")
    harness.equal(calculators.to_hit(sleep, 120), 1500,
        "Sleep's enchantment ray bypasses ordinary evasion")
    harness.equal(calculators.enchantment_power(sleep, 120), 40,
        "Sleep uses its source enchantment power formula")
end

return test
