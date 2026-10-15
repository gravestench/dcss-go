local items = require("ids.items")
local jobs = require("ids.jobs")
local species = require("ids.species")
local potions = require("policy.potions")
local potion_resistance = require("policy.potions.resistance")
local damage = require("policy.magic.damage")
local flight = require("policy.combat.flight")
local enhancement = require("policy.magic.enhancement")
local resources = require("policy.magic.resources")
local ambrosia_rules = require("policy.potions.ambrosia")
local confusion = require("policy.magic.player_confusion")
local component = require("constants.component")
local resistance_ids = require("constants.resistance_ids")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Potion resistance test",
    })

    local resistance = potions.get(items.POT_RESISTANCE)

    harness.equal(type(resistance), "table",
        "resistance has a focused effect module")

    local before = damage.player_resistance(ctx, player,
        resistance_ids.FIRE)

    resistance.apply(ctx, player)

    local state = ctx:get(player, component.POTION_RESISTANCE)

    harness.equal(state.remaining_aut, 350,
        "resistance potion lasts source minimum 35 turns")
    harness.equal(damage.player_resistance(ctx, player,
        resistance_ids.FIRE), before + 1,
        "resistance potion raises live fire resistance")

    potion_resistance.tick(ctx, player, 350)

    harness.falsy(ctx:has(player, component.POTION_RESISTANCE),
        "resistance expires after its saved action time")
    harness.equal(damage.player_resistance(ctx, player,
        resistance_ids.FIRE), before,
        "expiration removes live fire resistance")

    local flight_potion = potions.get(items.POT_FLIGHT)

    harness.equal(type(flight_potion), "table",
        "flight has a focused effect module")
    harness.falsy(flight.active(ctx, player),
        "ordinary Human begins on the ground")

    flight_potion.apply(ctx, player)

    harness.equal(ctx:get(player, component.ZAP_FLIGHT).remaining_aut,
        250, "flight potion lasts source minimum 25 turns")
    harness.truthy(flight.active(ctx, player),
        "flight potion changes the live movement capability")

    local brilliance = potions.get(items.POT_BRILLIANCE)

    harness.equal(type(brilliance), "table",
        "brilliance has a focused effect module")
    harness.equal(resources.spell_cost(ctx, player, 7), 7,
        "ordinary spell cost is its level")

    brilliance.apply(ctx, player)

    harness.equal(resources.spell_cost(ctx, player, 7), 4,
        "brilliance rounds half spell cost upward")
    harness.equal(enhancement.apply(ctx, player, {
        schools = {},
    }, 100), 150,
        "brilliance gives a live spell power enhancement")

    ctx:add(player, component.HEALTH, {
        current = 10,
        max = 30,
    })
    ctx:add(player, component.MAGIC, {
        current = 0,
        max = 10,
    })

    local ambrosia = potions.get(items.POT_AMBROSIA)

    harness.equal(type(ambrosia), "table",
        "ambrosia has a focused effect module")

    ambrosia.apply(ctx, player)

    harness.truthy(confusion.active(ctx, player),
        "ambrosia deliberately confuses the drinker")
    harness.equal(ctx:get(player, component.POTION_AMBROSIA).remaining_aut,
        30, "ambrosia lasts the source minimum three turns")

    ambrosia_rules.tick(ctx, player, 10)

    harness.equal(ctx:get(player, component.HEALTH).current, 13,
        "ambrosia restores its source minimum HP per turn")
    harness.equal(ctx:get(player, component.MAGIC).current, 3,
        "ambrosia restores its source minimum MP per turn")
end

return test
