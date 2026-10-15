local catalog = require("policy.catalog")
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local transition = require("policy.mutations.transition")

local test = {}

local function player(ctx)
    local owner = ctx:create()

    ctx:add(owner, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })

    return owner
end

function test.run(ctx)
    local events = {}
    local world = setmetatable({}, { __index = ctx })

    function world.emit(_, kind, message)
        if kind == "mutation" then
            events[#events + 1] = message
        end
    end

    local skin = player(ctx)
    local skin_definition = catalog.get("mutations",
        mutations.MUT_TOUGH_SKIN)

    transition.grant(world, skin, mutations.MUT_TOUGH_SKIN,
        classes.ACQUIRED, false)
    harness.equal(events[#events], skin_definition.gain[1],
        "mutation gain emits its source level message")

    transition.remove(world, skin, mutations.MUT_TOUGH_SKIN,
        classes.ACQUIRED)
    harness.equal(events[#events], skin_definition.lose[1],
        "mutation loss emits its source level message")

    local trade = player(ctx)
    local frail = catalog.get("mutations", mutations.MUT_FRAIL)

    records.grant_acquired(ctx, trade, mutations.MUT_FRAIL, 1)
    transition.grant(world, trade, mutations.MUT_ROBUST,
        classes.ACQUIRED, false)
    harness.equal(events[#events], frail.lose[1],
        "conflict trade emits the lost mutation message")
end

return test
