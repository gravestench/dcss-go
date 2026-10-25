-- A scheduled trait is granted once at its level. Losing and regaining XL
-- must leave the historical innate rank and the saved grant flag intact.
local component = require("constants.component")
local demonspawn = require("policy.character.demonspawn")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local levels = require("policy.mutations.levels")
local species = require("ids.species")

local test = {}

-- Use the production mutation transition rather than a test grant shim.
function test.run(ctx)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local draw = 31

    function game:random(_, bound)
        draw = (draw * 48271) % 2147483647

        return draw % bound
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_DEMONSPAWN,
        job_id = jobs.JOB_FIGHTER,
        name = "Growth test",
    })
    demonspawn.start(game, player)

    local first = demonspawn.list(ctx, player)[1]

    harness.equal(first.state.level, 2)
    harness.equal(levels.base(ctx, player, first.state.mutation_id), 0)
    demonspawn.grant_level(game, player, 2)
    harness.equal(levels.base(ctx, player, first.state.mutation_id), 1)
    harness.truthy(ctx:get(first.entity,
        component.DEMONSPAWN_TRAIT).granted)

    demonspawn.grant_level(game, player, 2)
    harness.equal(levels.base(ctx, player, first.state.mutation_id), 1,
        "repeating XL2 must not duplicate the trait")
    demonspawn.validate(ctx, player, species.SP_DEMONSPAWN, 2)
end

return test
