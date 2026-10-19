-- One sheep's top roll succeeds, and the real player sleep component keeps
-- the result through action timing and save/restore.
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.fixtures.monster_status")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local spells = require("ids.spells")

local test = {}

-- Override only the RNG service to select the successful one-in-twenty-five
-- edge; all components and their defaults remain production definitions.
function test.run(ctx)
    local player = fixture.actor(ctx,
        monsters.MONS_GOBLIN, 2, 1, 30)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })

    local caster = fixture.actor(ctx,
        monsters.MONS_DREAM_SHEEP, 1, 1, 10)
    local live = fixture.context(ctx, player, 100)

    -- The highest legal draw gives one sheep the minimum successful power.
    function live:random(_, bound)
        return bound - 1
    end

    local effect = effects.effect(spells.SPELL_DREAM_DUST)
    local plan = effect.plan(live, caster, player)

    harness.truthy(plan, "a visible player and sheep permit Dream Dust")

    effect.resolve(live, caster, player, nil, plan)

    local state = ctx:get(player, component.PLAYER_SLEEP)

    harness.truthy(state and state.remaining_aut >= 50,
        "successful Dream Dust stores the shared player sleep timer")
end

return test
