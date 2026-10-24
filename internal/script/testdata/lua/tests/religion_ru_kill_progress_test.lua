-- Ru's kill progress belongs to the actual death phase. The source
-- chance is separate from exploration and can fire even at six stars.
local component = require("constants.component")
local death = require("systems.actor_death")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Create an ordinary credited death while retaining Ru's saved clock.
-- The second victim is formerly neutral and therefore gives no XP.
local function kill(ctx, game, neutral)
    local victim = fixture.actor(ctx, monsters.MONS_RAT,
        neutral and 13 or 12, 10, 1)
    local health = ctx:get(victim, component.HEALTH)

    if neutral then
        ctx:add(victim, component.RELIGION_WAS_NEUTRAL, {
            remembered = true,
        })
    end

    health.current = 0
    ctx:set(victim, component.HEALTH, health)
    ctx:signal("player_kill", victim)
    death.update(game)
end

-- A successful coin flip increments once, a failed flip and an
-- uncredited death do not, and source 200 piety stops the roll.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 50)
    local game = fixture.context(ctx, player)
    local coin = 0
    local coin_draws = 0

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Ru progress test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
    })
    ctx:add(player, component.SKILL_TRAINING, {
        available_xp = 0,
        cost_level = 1,
        settings = {},
        recent_practice = {},
        recent_all = {},
    })
    ctx:add(player, component.MAGIC, {
        current = 1,
        max = 1,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.RU,
        piety = 160,
        penance = {},
    })
    ctx:add(player, component.RELIGION_RU, {
        sacrifice_progress = 4,
        sacrifice_delay = 50,
        sacrifice_penalty = 0,
        available = {},
        health = {},
        essence = {},
        purity = {},
        arcana = {},
    })

    function game:random(stream, bound)
        if stream == streams.RELIGION and bound == 2 then
            coin_draws = coin_draws + 1

            return coin
        end

        return 0
    end

    kill(ctx, game, false)
    harness.equal(ctx:get(player, component.RELIGION_RU)
        .sacrifice_progress, 5,
        "a credited kill advances Ru progress on a winning coin")
    harness.equal(coin_draws, 1)

    coin = 1
    kill(ctx, game, false)
    harness.equal(ctx:get(player, component.RELIGION_RU)
        .sacrifice_progress, 5,
        "a losing coin does not advance Ru")

    coin = 0
    kill(ctx, game, true)
    harness.equal(ctx:get(player, component.RELIGION_RU)
        .sacrifice_progress, 5,
        "a formerly neutral kill is not a progress source")
    harness.equal(coin_draws, 2,
        "uncredited death does not draw the Ru coin")

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 200
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    kill(ctx, game, false)
    harness.equal(coin_draws, 2,
        "200 piety stops the source Ru kill roll")
end

return test
