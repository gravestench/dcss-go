-- Degeneration drains source intelligence minimum.

local items = require("ids.items")
local potions = require("policy.potions")
local component = require("constants.component")
local jobs = require("ids.jobs")
local species = require("ids.species")
local harness = require("tests.harness")

local test = {}

-- Exercise volatile stat and status effects with saved player attributes so
-- each potion's mutation of character state is observable after application.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })

    local degeneration = potions.get(items.POT_DEGENERATION)

    harness.equal(type(degeneration), "table",
        "degeneration has a focused effect module")

    degeneration.apply(ctx, player)

    local loss = ctx:get(player, component.STAT_LOSS)

    harness.equal(loss.strength, 1,
        "degeneration drains source strength minimum")
    harness.equal(loss.intelligence, 1,
        "degeneration drains source intelligence minimum")
    harness.equal(loss.dexterity, 1,
        "degeneration drains source dexterity minimum")

    local berserker = ctx:create()

    ctx:add(berserker, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Berserk potion test",
    })
    ctx:add(berserker, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(berserker, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })

    local berserk = potions.get(items.POT_BERSERK_RAGE)

    harness.equal(type(berserk), "table",
        "berserk rage has a focused effect module")
    harness.falsy(berserk.can_quaff(ctx, berserker),
        "living Human can drink berserk rage")

    berserk.apply(ctx, berserker)

    harness.truthy(ctx:has(berserker, component.RAGE),
        "berserk potion enters the source rage state")
end

return test
