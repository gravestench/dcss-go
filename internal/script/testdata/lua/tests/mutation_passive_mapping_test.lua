local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local mapping = require("policy.world.mapping")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

local function input(difficulty)
    local values = {}

    for _ = 1, 9 do
        values[#values + 1] = difficulty
    end

    return {
        width = 3,
        height = 3,
        origins = {
            { x = 1, y = 1 },
        },
        difficulty = values,
    }
end

function test.run(ctx)
    local player = ctx:create()
    local world = setmetatable({}, { __index = ctx })

    function world.player()
        return player
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Mapper",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    harness.equal(#mapping.plan(world, input(0)), 0,
        "ordinary sight does not magic-map terrain")

    records.grant_acquired(ctx, player,
        mutations.MUT_PASSIVE_MAPPING, 1)

    harness.equal(#mapping.plan(world, input(0)), 9,
        "low-difficulty cells within the source radius are mapped")
    harness.equal(#mapping.plan(world, input(99)), 0,
        "high-difficulty cells remain unknown")
end

return test
