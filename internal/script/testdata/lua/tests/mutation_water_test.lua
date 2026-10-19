
local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local terrain = require("constants.terrain")
local levels = require("policy.mutations.levels")
local movement = require("policy.character.movement")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Nimble Swimmer does not change land movement.
function test.run(ctx)
    local player = ctx:create()
    local feature = terrain.DNGN_FLOOR
    local grid = setmetatable({}, { __index = ctx })

    -- Return water fixture terrain that gates the environmental branch.
    function grid.cell()
        return feature
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Water test",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    records.grant_acquired(ctx, player,
        mutations.MUT_NIMBLE_SWIMMER, 1)

    harness.equal(levels.effective(grid, player,
        mutations.MUT_NIMBLE_SWIMMER), 0,
        "Nimble Swimmer is inactive away from water")
    harness.equal(movement.base(grid, player), 10,
        "Nimble Swimmer does not change land movement")

    feature = terrain.DNGN_SHALLOW_WATER

    harness.equal(levels.effective(grid, player,
        mutations.MUT_NIMBLE_SWIMMER), 1,
        "Nimble Swimmer activates on water")
    harness.equal(movement.base(grid, player), 16,
        "level one still wades through water")

    records.grant_acquired(ctx, player,
        mutations.MUT_NIMBLE_SWIMMER, 1)

    harness.equal(movement.base(grid, player), 6,
        "level two swims four aut faster")
end

return test
