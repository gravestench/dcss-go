
local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local exploration = require("policy.world.exploration")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Proxy exploration draws while preserving the player's regeneration components.
local function predictable(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to explore regen fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    -- Use the final exploration draw to check per-cell regeneration without early success.
    function proxy.random(_, stream, bound)
        harness.equal(stream, "exploration", "exploration RNG stream")

        return bound - 1
    end

    return proxy
end

-- Newly seen cells restore MP one draw at a time.
function test.run(ctx)
    local player = ctx:create()
    local steady = predictable(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Explorer",
    })
    ctx:add(player, component.HEALTH, {
        current = 1,
        max = 420,
    })
    ctx:add(player, component.MAGIC, {
        current = 1,
        max = 270,
    })

    exploration.on_seen(steady, 4)

    harness.equal(ctx:get(player, component.HEALTH).current, 1,
        "ordinary exploration has no healing")

    records.grant_acquired(ctx, player,
        mutations.MUT_EXPLORE_REGEN, 1)
    exploration.on_seen(steady, 4)

    harness.equal(ctx:get(player, component.HEALTH).current, 5,
        "newly seen cells heal HP one draw at a time")
    harness.equal(ctx:get(player, component.MAGIC).current, 5,
        "newly seen cells restore MP one draw at a time")

    exploration.on_seen(steady, 0)

    harness.equal(ctx:get(player, component.HEALTH).current, 5,
        "refreshing already seen cells does not heal")
end

return test
