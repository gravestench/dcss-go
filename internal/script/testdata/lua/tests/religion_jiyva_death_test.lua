-- The Royal Jelly's death is durable player history, not an inference
-- from whether Slime:5's seals happen to be open on the current floor.
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local death_hooks = require("policy.combat.death_hooks")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local eligibility = require("policy.religion.eligibility")
local jobs = require("ids.jobs")
local life = require("policy.religion.jiyva.life")
local monsters = require("ids.monsters")
local species = require("ids.species")

local test = {}

-- A real unsummoned Royal Jelly death sets the flag once. Jiyva remains
-- available to a current devotee or a former devotee under penance;
-- after that penance ends, the dead god is unavailable to new draws.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
        penance = {},
    })
    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })

    local game = fixture.context(ctx, player)
    local jelly = fixture.actor(ctx, monsters.MONS_ROYAL_JELLY,
        10, 10, 100)

    local definition = catalog.get(categories.MONSTERS,
        monsters.MONS_ROYAL_JELLY)
    local position = ctx:get(jelly, component.POSITION)

    harness.falsy(death_hooks.run(game, jelly, definition,
        position, false, {}))

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.truthy(state.royal_jelly_dead)
    harness.truthy(life.dead(state))
    harness.truthy(string.find(eligibility.check(game, player,
        gods.JIYVA, true), "vanished", 1, true))

    state.penance[gods.JIYVA] = 1
    ctx:set(player, component.RELIGION_WORSHIP, state)
    harness.falsy(life.dead(state))
    harness.equal(eligibility.check(game, player, gods.JIYVA, true), nil)

    state.penance[gods.JIYVA] = 0
    state.god_id = gods.JIYVA
    ctx:set(player, component.RELIGION_WORSHIP, state)
    harness.falsy(life.dead(state))
end

return test
