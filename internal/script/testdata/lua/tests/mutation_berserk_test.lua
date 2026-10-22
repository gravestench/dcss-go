
local component = require("constants.component")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local forms = require("policy.magic.effects.forms.player")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local rage = require("policy.character.rage")
local records = require("policy.mutations.records")
local species = require("ids.species")

local test = {}

-- Rage expiry preserves current HP to source rounding.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
        total_xp = 0,
        pending_stat_level = 0,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })

    local baseline_max = forms.max_hp(ctx, player)
    local baseline_current = math.floor(baseline_max * 3 / 5)
    local rage_max = math.floor(baseline_max * 3 / 2)
    local rage_current = math.floor(baseline_current * rage_max /
        baseline_max)

    ctx:add(player, component.HEALTH, {
        current = baseline_current,
        max = baseline_max,
    })
    ctx:add(player, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(player, component.DURATIONS, {
        might_aut = 0,
        haste_aut = 0,
    })

    local world = setmetatable({}, { __index = ctx })
    local messages = {}

    -- Force the low rage draw while asserting each requested bound stays positive.
    function world.random(_, _, bound)
        harness.truthy(bound > 0, "rage random bounds stay positive")
        return 0
    end

    -- Capture berserk events separately from the policy state being asserted.
    function world.emit(_, _, message)
        messages[#messages + 1] = message
    end

    harness.truthy(rage.begin(world, player),
        "a living player can enter berserk rage")
    harness.equal(ctx:get(player, component.HEALTH).max, rage_max,
        "rage raises maximum HP by fifty percent")
    -- Entering rage changes both current and maximum HP with source rounding.
    harness.equal(ctx:get(player, component.HEALTH).current, rage_current,
        "rage scales current HP with maximum HP")
    -- The scripted RNG fixes the minimum duration before action penalties are exercised.
    harness.equal(ctx:get(player, component.RAGE).remaining_aut, 100,
        "minimum source rage lasts ten turns")
    harness.equal(messages[1],
        "A red film seems to cover your vision as you go berserk!",
        "rage begins with the source message")

    rage.melee(world, player)
    rage.tick(world, player, 10)
    harness.equal(ctx:get(player, component.RAGE).remaining_aut, 90,
        "a melee turn spends time without a no-combat penalty")

    rage.tick(world, player, 10)
    -- Peaceful actions shorten rage separately from elapsed action time.
    harness.equal(ctx:get(player, component.RAGE).remaining_aut, 70,
        "the first noncombat turn adds ten aut of rage penalty")

    rage.tick(world, player, 10)
    harness.equal(messages[#messages],
        "You feel a strong urge to attack something.",
        "the second noncombat turn warns about rage decay")

    local warning_state = ctx:get(player, component.RAGE)
    warning_state.remaining_aut = 100
    warning_state.noncombat_actions = 3
    ctx:set(player, component.RAGE, warning_state)

    rage.tick(world, player, 10)
    harness.equal(messages[#messages],
        "You feel your anger nearly subside.",
        "the fourth noncombat turn warns about rage decay")

    warning_state = ctx:get(player, component.RAGE)
    warning_state.remaining_aut = 100
    warning_state.noncombat_actions = 5
    ctx:set(player, component.RAGE, warning_state)

    rage.tick(world, player, 10)
    harness.equal(messages[#messages],
        "Your blood rage is quickly leaving you.",
        "the sixth noncombat turn warns about rage decay")

    local state = ctx:get(player, component.RAGE)
    state.remaining_aut = 10
    ctx:set(player, component.RAGE, state)

    rage.tick(world, player, 10)

    harness.equal(ctx:get(player, component.HEALTH).max, baseline_max,
        "rage expiry restores base maximum HP")
    harness.truthy(ctx:get(player, component.HEALTH).current >=
        baseline_current - 1,
        "rage expiry preserves current HP to source rounding")
    harness.equal(ctx:get(player, component.RAGE).cooldown_aut, 280,
        "source exhaustion cooldown lasts twice the slow duration")
    harness.equal(ctx:get(player, component.PLAYER_SLOW).remaining_aut, 210,
        "rage expiry slows the player")
    harness.equal(rage.begin(world, player), false,
        "cooldown blocks another rage")

    local attacker = ctx:create()
    local monster = ctx:create()

    ctx:add(attacker, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(attacker, component.HEALTH, {
        current = 12,
        max = 20,
    })
    ctx:add(attacker, component.REGENERATION, {
        hp_progress = 0,
        mp_progress = 0,
    })
    ctx:add(attacker, component.DURATIONS, {
        might_aut = 0,
        haste_aut = 0,
    })
    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_PLANT,
        speed = 10,
    })
    records.grant_acquired(ctx, attacker, mutations.MUT_BERSERK, 2)

    effects.trigger(world, attacker, capabilities.ON_MELEE_ATTEMPT, {
        target = monster,
    })
    harness.equal(rage.active(world, attacker), false,
        "attacking firewood cannot trigger rage")

    ctx:set(monster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    effects.trigger(world, attacker, capabilities.ON_MELEE_ATTEMPT, {
        target = monster,
    })
    harness.truthy(rage.active(world, attacker),
        "berserk mutation can trigger before a melee hit")
end

return test
