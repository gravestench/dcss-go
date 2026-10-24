-- The live death system awards conduct before testing divine recovery.
-- A same-kill piety gain can therefore open the first-star chance gate.
local component = require("constants.component")
local death = require("systems.actor_death")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Seed the normal XP and conduct inputs, then make the religion draw
-- visibly depend on the worship state at the moment it is requested.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        10, 10, 50)
    local game = fixture.context(ctx, player)
    local messages = {}

    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Divine recovery test",
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
        current = 5,
        max = 20,
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.MAKHLEB,
        piety = 30,
        penance = {},
    })

    local victim = fixture.actor(ctx, monsters.MONS_RAT,
        12, 10, 1)
    local health = ctx:get(victim, component.HEALTH)

    health.current = 0
    ctx:set(victim, component.HEALTH, health)

    function game:random(stream, bound)
        if stream == streams.RELIGION and bound > 30 then
            return 30
        end

        return 0
    end

    ctx:signal("player_kill", victim)
    death.update(game)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    harness.truthy(worship.piety > 30,
        "the credited rat gave Makhleb piety")
    harness.equal(ctx:get(player, component.HEALTH).current, 51,
        "same-kill conduct opened Makhleb recovery")
    harness.truthy(ctx:get(player, component.PROGRESSION).total_xp > 0,
        "the same death granted experience once")

    -- Fedhas and Jiyva can make a formerly neutral follower hostile.
    -- The source still withholds XP and every XP-based kill reward.
    local neutral = fixture.actor(ctx, monsters.MONS_RAT, 13, 10, 1)
    local neutral_health = ctx:get(neutral, component.HEALTH)
    local xp_before = ctx:get(player, component.PROGRESSION).total_xp
    local hp_before = ctx:get(player, component.HEALTH).current

    ctx:add(neutral, component.RELIGION_WAS_NEUTRAL, {
        remembered = true,
    })
    neutral_health.current = 0
    ctx:set(neutral, component.HEALTH, neutral_health)
    ctx:signal("player_kill", neutral)
    death.update(game)

    harness.equal(ctx:get(player, component.PROGRESSION).total_xp,
        xp_before, "a formerly neutral victim gives no XP")
    harness.equal(ctx:get(player, component.HEALTH).current,
        hp_before, "a formerly neutral victim gives no recovery")

    -- Source ENCH_MAD restores reward eligibility even when the neutral
    -- history marker remains on the victim.
    local frenzied = fixture.actor(ctx, monsters.MONS_RAT,
        15, 10, 1)
    local frenzied_health = ctx:get(frenzied, component.HEALTH)

    ctx:add(frenzied, component.RELIGION_WAS_NEUTRAL, {
        remembered = true,
    })
    ctx:add(frenzied, component.MONSTER_ALLEGIANCE, {
        charm_aut = 0,
        frenzy_aut = 10,
        fatigue_aut = 0,
        berserk_hp = false,
    })
    frenzied_health.current = 0
    ctx:set(frenzied, component.HEALTH, frenzied_health)
    ctx:signal("player_kill", frenzied)
    death.update(game)

    harness.truthy(ctx:get(player, component.PROGRESSION).total_xp >
        xp_before, "frenzy restores reward eligibility")

    -- Devour and Makhleb both restore HP from this credited kill. The
    -- source combines the award and prints one health-gain message.
    records.grant_acquired(ctx, player,
        mutations.MUT_DEVOUR_ON_KILL, 1)
    local player_health = ctx:get(player, component.HEALTH)

    player_health.current = 40
    ctx:set(player, component.HEALTH, player_health)

    local combined = fixture.actor(ctx, monsters.MONS_RAT,
        14, 10, 1)
    local combined_health = ctx:get(combined, component.HEALTH)
    local health_messages_before = 0

    for _, message in ipairs(messages) do
        if message == "You feel better." then
            health_messages_before = health_messages_before + 1
        end
    end

    combined_health.current = 0
    ctx:set(combined, component.HEALTH, combined_health)
    ctx:signal("player_kill", combined)
    death.update(game)

    local health_messages_after = 0

    for _, message in ipairs(messages) do
        if message == "You feel better." then
            health_messages_after = health_messages_after + 1
        end
    end

    harness.equal(ctx:get(player, component.HEALTH).current, 42,
        "Devour and Makhleb both heal the same kill")
    harness.equal(health_messages_after - health_messages_before, 1,
        "combined healing announces once")
end

return test
