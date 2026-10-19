
local component = require("constants.component")
local holiness = require("constants.monster_holiness")
local monster_flags = require("constants.monster_flags")
local mutations = require("ids.mutations")
local effects = require("policy.combat.player_kill_effects")
local death = require("policy.death")
local powered = require("policy.character.powered_by_death")
local regeneration = require("policy.character.regeneration")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Seed kill effects owner components once so each branch changes only the mutation under test.
local function player(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.HEALTH, {
        current = 10,
        max = 30,
    })
    ctx:add(entity, component.PROGRESSION, {
        level = 5,
    })

    return entity
end

-- Keep kill-effect draws and emitted messages observable in one proxy.
local function kill_context(ctx, draws)
    local proxy = harness.random_context(ctx, draws)
    local messages = {}

    -- Capture kill effects events separately from the policy state being asserted.
    function proxy.emit(_, _, message)
        messages[#messages + 1] = message
    end

    -- Return Devour and Powered-by-Death messages recorded during the kill.
    function proxy.messages()
        return messages
    end

    return proxy
end

-- Devour on Kill uses the source three-roll average.
function test.run(ctx)
    harness.equal(death.experience({
        flags = { monster_flags.NO_EXP_GAIN },
    }, 10), 0, "no-XP monsters cannot trigger kill rewards")

    local natural = {
        holiness = { holiness.NATURAL },
        flags = {},
    }
    local undead = {
        holiness = { holiness.UNDEAD },
        flags = {},
    }

    local eater = player(ctx)
    records.grant_acquired(ctx, eater,
        mutations.MUT_DEVOUR_ON_KILL, 1)
    local feast = kill_context(ctx, { 0, 5, 6, 6 })

    effects.run(feast, eater, natural, 12)
    harness.equal(ctx:get(eater, component.HEALTH).current, 16,
        "Devour on Kill uses the source three-roll average")
    -- The fixed draw sequence checks that a failed trigger skips all healing rolls.
    harness.equal(feast.draws_used(), 4,
        "Devour on Kill draws chance before healing")
    harness.equal(feast.messages()[1], "You feel better.",
        "Devour on Kill reports actual healing")

    local ineligible = kill_context(ctx, {})
    effects.run(ineligible, eater, undead, 12)
    effects.run(ineligible, eater, natural, 0)
    harness.equal(ctx:get(eater, component.HEALTH).current, 16,
        "undead and zero-XP kills do not feed the player")

    local reaper = player(ctx)
    records.grant_acquired(ctx, reaper,
        mutations.MUT_POWERED_BY_DEATH, 2)
    local first = kill_context(ctx, { 1, 0, 2 })

    effects.run(first, reaper, undead, 12)
    harness.equal(powered.strength(ctx, reaper), 2,
        "Powered by Death gains source-random strength on a kill")
    harness.equal(ctx:get(reaper, component.POWERED_BY_DEATH).remaining_aut,
        30, "Powered by Death gets a three-turn timer")
    -- Kill effects share a specific mutation-stream order that later rolls depend on.
    harness.equal(first.draws_used(), 3,
        "Powered by Death draws duration, chance, then increment")

    local base_rate = regeneration.rates(ctx, eater, 30, 0)
    local powered_rate = regeneration.rates(ctx, reaper, 30, 0)
    harness.equal(powered_rate, base_rate + 200,
        "each Powered by Death strength adds 100 HP regen")

    local fading = kill_context(ctx, { 0 })
    powered.tick(fading, reaper, 30)
    harness.equal(powered.strength(ctx, reaper), 1,
        "expiring duration loses one stack")
    harness.equal(ctx:get(reaper, component.POWERED_BY_DEATH).remaining_aut,
        20, "remaining stacks reset the source timer")
end

return test
