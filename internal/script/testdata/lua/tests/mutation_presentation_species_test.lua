local component = require("constants.component")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local species = require("ids.species")
local records = require("policy.mutations.records")
local screen = require("policy.presentation.mutations")
local harness = require("tests.harness")

local test = {}

local function add_player(ctx, species_id)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species_id,
        job_id = jobs.JOB_FIGHTER,
        name = "Mutation display",
    })

    return player
end

local function text_of(result)
    local lines = {}

    for _, write in ipairs(result.writes) do
        lines[#lines + 1] = write.text
    end

    return table.concat(lines, "\n")
end

function test.run(ctx)
    local formicid = add_player(ctx, species.SP_FORMICID)

    records.grant_innate(ctx, formicid, mutations.MUT_ANTENNAE, 1)

    local formicid_screen = screen.rows(ctx, {
        owner = formicid,
        height = 24,
    })
    local formicid_text = text_of(formicid_screen)
    local stasis = formicid_text:find("You cannot be hasted", 1, true)
    local antennae = formicid_text:find("antennae", 1, true)

    harness.truthy(stasis and antennae and stasis < antennae,
        "source species traits precede real mutations")
    harness.equal(formicid_screen.options[1].key, "a",
        "fake mutations do not consume examine hotkeys")

    local spriggan = add_player(ctx, species.SP_SPRIGGAN)
    local spriggan_text = text_of(screen.rows(ctx, {
        owner = spriggan,
        height = 24,
    }))

    harness.truthy(spriggan_text:find("You are too small for most types of armour.",
        1, true), "little species shows its armour limitation")
    harness.truthy(spriggan_text:find("problems with some larger weapons.",
        1, true), "little species shows its weapon limitation")
    harness.falsy(spriggan_text:find("You are rather mundane.", 1, true),
        "source fake mutations suppress mundane placeholder")

    local octopode = add_player(ctx, species.SP_OCTOPODE)
    local octopode_text = text_of(screen.rows(ctx, {
        owner = octopode,
        height = 24,
    }))

    harness.truthy(octopode_text:find("You are amphibious.", 1, true),
        "water species without Mertail shows amphibiousness")
end

return test
