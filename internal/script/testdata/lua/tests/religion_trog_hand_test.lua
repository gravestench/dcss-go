-- Trog's Hand has one saved timer; resistance, regeneration, and the
-- duration owner must all observe that same ECS component.
local component = require("constants.component")
local gods = require("constants.gods")
local hand = require("policy.religion.trog.hand")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local piety = require("policy.religion.piety")
local regeneration = require("policy.character.regeneration")
local resistance = require("policy.combat.player_resistance")
local species = require("ids.species")
local trog = require("policy.religion.gods.trog")

local test = {}

-- Give the ordinary stat readers real player schemas and force only the
-- Hand's two dice to their minimum; no copy of production fields appears.
function test.run(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local messages = {}

    -- Shared player readers use this accessor in both the harness and game.
    function game:player()
        return player
    end

    -- Each Hand die lands at one, exposing the minimum duration exactly.
    function game:random(_, bound)
        harness.truthy(bound > 0)

        return 0
    end

    -- Keep duration messages visible for start, warning, and expiry checks.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, { level = 10 })
    ctx:add(player, component.SKILLS, { entries = {} })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 75,
    })

    local base_hp = regeneration.rates(game, player, 60, 20)
    local base_will = resistance.willpower(game, player)

    hand.invoke(game, player)

    harness.truthy(hand.active(game, player))
    harness.equal(ctx:get(player,
        component.RELIGION_TROG_HAND).remaining_aut, 70)
    harness.equal(regeneration.rates(game, player, 60, 20),
        base_hp + 100)
    harness.equal(resistance.willpower(game, player), base_will + 80)
    harness.equal(messages[1], "Your skin crawls.")

    hand.invoke(game, player)
    harness.equal(ctx:get(player,
        component.RELIGION_TROG_HAND).remaining_aut, 140)

    hand.tick(game, player, 80)
    harness.equal(messages[#messages],
        "You feel the effects of Trog's Hand fading.")
    hand.tick(game, player, 60)

    harness.falsy(hand.active(game, player))
    harness.equal(regeneration.rates(game, player, 60, 20), base_hp)
    harness.equal(resistance.willpower(game, player), base_will)

    hand.invoke(game, player)
    trog.leave(game, player)
    harness.falsy(hand.active(game, player))

    hand.invoke(game, player)
    piety.offend(game, player, 0, 1)
    harness.falsy(hand.active(game, player))
end

return test
