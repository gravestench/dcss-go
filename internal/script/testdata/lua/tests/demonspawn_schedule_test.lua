-- Creation must commit future Demonspawn grants once, then later readers
-- inspect the saved entities instead of drawing another ancestry.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local demonspawn = require("policy.character.demonspawn")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")

local test = {}

-- Inspect real source facet definitions through the runtime catalog.
local function check_schedule(ctx, player, expected)
    local scheduled = demonspawn.list(ctx, player)
    local seen_levels = {}
    local facets = {}

    harness.equal(#scheduled, expected)
    harness.equal(scheduled[1].state.level, 2)

    for _, entry in ipairs(scheduled) do
        local trait = entry.state
        local definition = catalog.get(categories.DEMONSPAWN_FACETS,
            trait.facet_id)

        harness.truthy(not seen_levels[trait.level],
            "duplicate Demonspawn level")
        harness.truthy(trait.level >= 2 and trait.level <= 27)
        harness.equal(trait.mutation_id,
            definition.mutations[trait.rank_index])
        seen_levels[trait.level] = true
        facets[trait.facet_id] = (facets[trait.facet_id] or 0) + 1
    end

    for _, count in pairs(facets) do
        harness.equal(count, 3)
    end

    harness.equal(demonspawn.has(ctx, player,
        scheduled[1].state.mutation_id), true)
    demonspawn.validate(ctx, player, species.SP_DEMONSPAWN)
end

-- The same game may start several characters; their schedules remain
-- independently owned and a human receives none.
function test.run(ctx)
    local game = setmetatable({}, { __index = ctx })
    local draw = 23
    local first_roll

    -- The standard Lua test context always returns zero. A varying draw
    -- gives the source's unique timing slots a reproducible sequence.
    function game:random(_, bound)
        if first_roll then
            local value = first_roll

            first_roll = nil

            return value % bound
        end

        draw = (draw * 48271) % 2147483647

        return draw % bound
    end

    for _, expected in ipairs({ 18, 15 }) do
        local player = ctx:create()

        first_roll = expected == 18 and 0 or 1

        ctx:add(player, component.PLAYER, {
            species_id = species.SP_DEMONSPAWN,
            job_id = jobs.JOB_FIGHTER,
            name = "Facet test",
        })
        demonspawn.start(game, player)
        check_schedule(ctx, player, expected)
    end

    local human = ctx:create()

    ctx:add(human, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Human test",
    })
    demonspawn.start(ctx, human)
    harness.equal(#demonspawn.list(ctx, human), 0)
    demonspawn.validate(ctx, human, species.SP_HUMAN)
end

return test
