-- Jiyva gifts run against the production mutation catalog and ECS
-- records, so a modded mutation uses the same path as bundled ones.
local component = require("constants.component")
local gifts = require("policy.religion.gifts")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutation_ids = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local streams = require("constants.rng_streams")

local test = {}

-- Script only the religion gate and the first two deletion rolls. The
-- production mutation selector supplies all four added mutation levels.
local function owner(ctx, points, religion_draws)
    local player = ctx:create()
    local game = setmetatable({}, { __index = ctx })
    local religion_index = 0
    local deletion_index = 0
    local mutation_seed = 37

    function game:player()
        return player
    end

    function game:random(stream, bound)
        if stream == streams.RELIGION then
            religion_index = religion_index + 1

            local value = religion_draws[religion_index]

            harness.truthy(value, "missing Jiyva religion draw")
            harness.truthy(value < bound, "Jiyva religion draw out of range")

            return value
        end

        if stream == streams.MUTATION and bound == 100 and
            deletion_index < 2 then
            deletion_index = deletion_index + 1

            return 0
        end

        if stream == streams.MUTATION then
            -- The standalone harness returns zero for every draw. A
            -- small deterministic sequence lets the real weighted
            -- selector reach more than one mutation family.
            mutation_seed = (mutation_seed * 48271) % 2147483647

            return mutation_seed % bound
        end

        return ctx:random(stream, bound)
    end

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Jiyva gift test",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.JIYVA,
        piety = points,
    })

    return game, player
end

-- A gift cleanses acquired bad ranks before giving new mutation levels.
-- The same saved worship component then suppresses another check.
local function mutation_cycle(ctx)
    local game, player = owner(ctx, 200, { 51, 0, 0, 0 })

    records.grant_acquired(game, player, mutation_ids.MUT_FRAIL, 2)

    harness.truthy(gifts.check(game, player))

    local frail = records.find(game, player, mutation_ids.MUT_FRAIL)
    local total = 0

    for _, entry in ipairs(records.list(game, player)) do
        total = total + entry.state.acquired
    end

    harness.equal(frail and frail.state.acquired or 0, 0)
    harness.equal(total, 4)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.gift_total[gods.JIYVA], 1)
    harness.truthy(state.gift_timeout >= 45)
    harness.falsy(gifts.check(game, player))
end

-- Source does not attempt mutation RNG before the third-star threshold.
local function low_piety(ctx)
    local game, player = owner(ctx, 74, {})

    harness.falsy(gifts.check(game, player))
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP)
        .gift_total[gods.JIYVA], nil)
end

-- Both scenarios use the same registered god definition and schemas.
function test.run(ctx)
    mutation_cycle(ctx)
    low_piety(ctx)
end

return test
