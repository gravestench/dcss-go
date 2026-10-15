local branches = require("ids.branches")
local component = require("constants.component")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")

local test = {}

local function player(ctx, species_id)
    local owner = ctx:create()

    ctx:add(owner, component.PLAYER, {
        species_id = species_id,
        job_id = jobs.JOB_FIGHTER,
    })

    return owner
end

local function in_form(ctx, owner, form_id)
    ctx:add(owner, component.PLAYER_FORM, {
        form_id = form_id,
        remaining_aut = 20,
        power = 40,
    })
end

function test.run(ctx)
    local dragon_cases = {
        {
            species_id = species.SP_BLACK_DRACONIAN,
            mutation_id = mutations.MUT_SHOCK_RESISTANCE,
        },
        {
            species_id = species.SP_YELLOW_DRACONIAN,
            mutation_id = mutations.MUT_ACIDIC_BITE,
        },
        {
            species_id = species.SP_YELLOW_DRACONIAN,
            mutation_id = mutations.MUT_ACID_RESISTANCE,
        },
        {
            species_id = species.SP_GREEN_DRACONIAN,
            mutation_id = mutations.MUT_STINGER,
        },
        {
            species_id = species.SP_PALE_DRACONIAN,
            mutation_id = mutations.MUT_STEAM_RESISTANCE,
        },
    }

    for _, case in ipairs(dragon_cases) do
        local owner = player(ctx, case.species_id)

        records.grant_innate(ctx, owner, case.mutation_id, 1)
        in_form(ctx, owner, "dragon")

        harness.equal(levels.effective(ctx, owner, case.mutation_id), 1,
            "matching draconian trait remains active in Dragon Form")
    end

    local statue = player(ctx, species.SP_HUMAN)

    records.grant_acquired(ctx, statue,
        mutations.MUT_SANGUINE_ARMOUR, 1)
    in_form(ctx, statue, "statue")
    harness.equal(levels.effective(ctx, statue,
        mutations.MUT_SANGUINE_ARMOUR), 0,
        "nonbleeding Statue Form suppresses Sanguine Armour")

    local mummy = player(ctx, species.SP_MUMMY)

    records.grant_acquired(ctx, mummy, mutations.MUT_BERSERK, 1)
    harness.equal(levels.effective(ctx, mummy,
        mutations.MUT_BERSERK), 0,
        "lifeless undead cannot use Berserk mutation")

    local formicid = player(ctx, species.SP_FORMICID)

    records.grant_acquired(ctx, formicid, mutations.MUT_TELEPORT, 1)
    harness.equal(levels.effective(ctx, formicid,
        mutations.MUT_TELEPORT), 0,
        "permanent stasis suppresses Teleportitis")

    local abyss = player(ctx, species.SP_HUMAN)

    records.grant_acquired(ctx, abyss, mutations.MUT_TELEPORT, 1)
    ctx:add(abyss, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    local abyss_context = setmetatable({}, { __index = ctx })

    function abyss_context.level_branch()
        return branches.BRANCH_ABYSS
    end

    harness.equal(levels.effective(abyss_context, abyss,
        mutations.MUT_TELEPORT), 0,
        "Abyss suppresses Teleportitis")
end

return test
