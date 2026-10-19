-- The two new blast profiles come from separate source zaps. Check their
-- registered formulas so an area handler cannot silently use Hurl
-- Damnation's dice or Fireball's smaller blast.
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local flavours = require("constants.beam_flavours")
local harness = require("tests.harness")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local test = {}

-- Compare the actual catalog records and calculator output at one power;
-- this imports production definitions instead of redeclaring their schema.
function test.run(ctx)
    local damnation = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_CALL_DOWN_DAMNATION)
    local fire = catalog.get(categories.MONSTER_BEAMS,
        spells.SPELL_FIRE_STORM)
    local dice = calculators.damage_dice(ctx, damnation, 100)

    harness.equal(damnation.zap_id,
        zaps.ZAP_CALL_DOWN_DAMNATION,
        "Call Down uses its own source zap")
    harness.equal(damnation.explosion_radius, 1,
        "Call Down stays a radius-one blast")
    harness.equal(damnation.flavour,
        flavours.BEAM_DAMNATION,
        "Call Down bypasses ordinary AC and resistances")
    harness.equal(dice.count, 3,
        "the monster zap rolls three damnation dice")
    harness.equal(dice.sides, 15,
        "the source monster dice have fifteen sides")

    local storm = calculators.damage_dice(ctx, fire, 100)

    harness.equal(fire.zap_id, zaps.ZAP_FIRE_STORM,
        "Fire Storm uses its own source zap")
    harness.equal(fire.flavour, flavours.BEAM_LAVA,
        "the storm keeps its partly irresistible lava flavour")
    harness.equal(storm.count, 8,
        "the storm rolls eight source dice")
    harness.truthy(storm.sides == 6 or storm.sides == 7,
        "power one hundred divides the storm maximum across eight dice")
end

return test
