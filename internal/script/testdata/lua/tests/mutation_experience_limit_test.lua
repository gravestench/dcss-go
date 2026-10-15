local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local advancement = require("policy.character.advancement")
local experience_limit = require("policy.character.experience_limit")
local formulas = require("policy.character.formulas")
local records = require("policy.mutations.records")
local view = require("policy.presentation.view")
local harness = require("tests.harness")

local test = {}

local function player_at_level(ctx, level, total_xp)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Experience limit test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = level,
        total_xp = total_xp,
        pending_stat_level = 0,
    })

    return player
end

function test.run(ctx)
    local xp = formulas.experience_needed(25, 1)
    local player = player_at_level(ctx, 24, xp)

    harness.equal(experience_limit.max_level(ctx, player), 27,
        "an ordinary player can reach XL27")

    records.grant_acquired(ctx, player,
        mutations.MUT_INEXPERIENCED, 3)

    harness.equal(experience_limit.max_level(ctx, player), 24,
        "each Inexperienced level removes one attainable XL")
    harness.equal(formulas.level_for_experience(xp, 1,
        experience_limit.max_level(ctx, player)), 24,
        "experience lookup respects the mutation cap")
    harness.equal(formulas.level_progress(xp, 24, 1,
        experience_limit.max_level(ctx, player)), 0,
        "the terminal shows no next-level progress at the cap")

    local session = setmetatable({}, { __index = ctx })

    function session.player()
        return player
    end

    local presented = view.player(session, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        total_xp = xp,
        level = 24,
    })

    harness.equal(presented.next_level_percent, 0,
        "the real player presentation uses the effective mutation cap")

    advancement.advance(ctx, player)
    harness.equal(ctx:get(player, component.PROGRESSION).level, 24,
        "earned XP cannot advance past the Inexperienced cap")
end

return test
