-- Uskayaw selects a visible hostile actor before its five-way punishment.
-- The test controls only wrath RNG and reads the real saved frenzy and
-- player paralysis components after each branch.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local uskayaw = require("policy.religion.wrath.uskayaw")

local test = {}

-- The first candidate wins reservoir selection. A zero switch result
-- starts Berserk, while switch result two directly paralyzes the player.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 10, 10)
    local foe = fixture.actor(ctx, monsters.MONS_ORC, 12, 10)
    local game = fixture.context(ctx, player)
    local choice = 0

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Dance tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
        penance = {
            [gods.USKAYAW] = 4,
        },
    })

    function game:random(stream, bound)
        if stream == streams.CARDS then
            if bound == 5 then
                return choice
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    uskayaw.apply(game, player)

    local rage = ctx:get(foe, component.MONSTER_ALLEGIANCE)

    harness.truthy(rage and rage.frenzy_aut > 0,
        "the hostile candidate enters saved Berserk")

    choice = 2
    uskayaw.apply(game, player)

    local paralysis = ctx:get(player, component.PLAYER_PARALYSIS)

    harness.truthy(paralysis and paralysis.remaining_aut >= 20,
        "Uskayaw's solo creates saved player paralysis")
    harness.equal(ctx:get(player,
        component.RELIGION_WORSHIP).penance[gods.USKAYAW], 3)
end

return test
