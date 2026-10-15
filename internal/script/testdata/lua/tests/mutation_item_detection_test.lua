local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local detection = require("policy.world.item_detection")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local world = setmetatable({}, { __index = ctx })

    function world.player()
        return player
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Sniffer",
    })

    harness.equal(detection.radius(world, 7), 0,
        "ordinary players do not sense hidden items")

    records.grant_acquired(ctx, player, mutations.MUT_JELLY_GROWTH, 1)

    harness.equal(detection.radius(world, 7), 5,
        "Jelly Growth senses items within five cells")

    records.grant_acquired(ctx, player, mutations.MUT_STRONG_NOSE, 1)

    harness.equal(detection.radius(world, 7), 7,
        "Strong Nose takes precedence and uses sight radius")

    local candidates = {
        { x = 4, y = 0 },
        { x = 7, y = 0 },
        { x = 8, y = 0 },
    }
    local selected = detection.plan(world, {
        player_x = 0,
        player_y = 0,
        sight_radius = 7,
        items = candidates,
    })

    harness.equal(#selected, 2,
        "sensing uses a square radius and excludes distant items")
end

return test
