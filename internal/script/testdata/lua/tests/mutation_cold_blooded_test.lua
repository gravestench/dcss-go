
local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local cold = require("policy.character.cold_blooded")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Proxy the cold coin flip while reading the player's saved Slow component.
local function predictable(ctx, player)
    local world = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to cold blooded fixture actor so player-only branches execute on that entity.
    function world.player()
        return player
    end

    -- Win the named cold coin flip to start the saved slow duration.
    function world.random(_, stream, bound)
        harness.equal(stream, "cold", "cold exposure uses its saved stream")
        harness.equal(bound, 2, "cold exposure is a coin flip")

        return 0
    end

    return world
end

-- Unresisted cold adds a saved eight-turn slow.
function test.run(ctx)
    local player = ctx:create()
    local world = predictable(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Cold-blooded",
    })

    cold.expose(world, player, 8, 0)
    harness.equal(ctx:get(player, component.PLAYER_SLOW), nil,
        "cold exposure cannot slow an ordinary player")

    records.grant_acquired(ctx, player, mutations.MUT_COLD_BLOODED, 1)
    cold.expose(world, player, 8, 1)
    harness.equal(ctx:get(player, component.PLAYER_SLOW), nil,
        "cold resistance protects a cold-blooded player")

    cold.expose(world, player, 8, 0)
    harness.equal(ctx:get(player, component.PLAYER_SLOW).remaining_aut, 80,
        "unresisted cold adds a saved eight-turn slow")

    cold.expose(world, player, 8, 0)
    harness.equal(ctx:get(player, component.PLAYER_SLOW).remaining_aut, 160,
        "further cold exposure extends the shared slow")

    ctx:add(player, component.DURATIONS, {
        haste_aut = 50,
    })
    cold.expose(world, player, 100, 0)

    harness.equal(ctx:get(player, component.PLAYER_SLOW).remaining_aut, 1500,
        "haste raises the source slow-duration cap to 150 turns")
end

return test
