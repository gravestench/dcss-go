-- Trog makes source magic skills harmful to train, but does not destroy
-- skill points or saved choices. The live worship owner lifts that temporary
-- ban when the player leaves; Gnoll distributed training is the source case.
local availability = require("policy.character.skill_availability")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutation_records = require("policy.mutations.records")
local mutations = require("ids.mutations")
local skills = require("ids.skills")
local skills_screen = require("policy.presentation.skills")
local species = require("ids.species")
local training = require("policy.character.training")
local worship = require("policy.religion.worship")

local test = {}

-- Find a human-facing row by its source skill name without reproducing the
-- screen's letter assignment or fixed-column positions in this test.
local function displayed_row(result, name)
    for _, write in ipairs(result.writes) do
        if write.text:find(name, 1, true) then
            return write.text
        end
    end

    error("missing skill screen row " .. name)
end

-- Build real player and training components so the test cannot drift from
-- the production schema or bypass the source skill-weight owner.
local function player(ctx, species_id)
    local actor = ctx:create()

    ctx:add(actor, component.PLAYER, {
        species_id = species_id,
        job_id = jobs.JOB_FIGHTER,
        name = "Trog training test",
    })
    ctx:add(actor, component.WALLET, {})
    ctx:add(actor, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 35,
    })
    ctx:add(actor, component.SKILLS, {
        entries = {
            {
                id = skills.SK_FIGHTING,
                level = 2,
                points = 150,
            },
            {
                id = skills.SK_SPELLCASTING,
                level = 2,
                points = 150,
            },
        },
    })
    ctx:add(actor, component.SKILL_TRAINING, {
        manual = true,
        available_xp = 100,
        settings = {
            {
                id = skills.SK_FIGHTING,
                enabled = true,
                focused = false,
            },
            {
                id = skills.SK_SPELLCASTING,
                enabled = true,
                focused = false,
            },
        },
    })

    return actor
end

-- Source order ends the magic group at Poison Magic; Invocations is mundane
-- for this restriction even though it appears nearby in skill lists.
local function source_group(ctx, actor)
    harness.truthy(availability.training_forbidden(ctx, actor,
        skills.SK_SPELLCASTING))
    harness.truthy(availability.training_forbidden(ctx, actor,
        skills.SK_POISON_MAGIC))
    harness.falsy(availability.training_forbidden(ctx, actor,
        skills.SK_FIGHTING))
    harness.falsy(availability.training_forbidden(ctx, actor,
        skills.SK_INVOCATIONS))
    harness.falsy(availability.forbidden_skill(ctx, actor,
        skills.SK_SPELLCASTING), "Trog cannot erase learned magic")
end

-- Excluding harmful magic from weighting must allocate the full share to
-- mundane skills; merely rejecting the final point would strand XP.
local function allocation(ctx, actor)
    local identity = ctx:get(actor, component.PLAYER)
    local definition = catalog.get(categories.SPECIES,
        identity.species_id)
    local trained = ctx:get(actor, component.SKILLS)
    local settings = ctx:get(actor, component.SKILL_TRAINING)
    local player_context = setmetatable({}, { __index = ctx })

    function player_context.player()
        return actor
    end

    local percentages = training.training_percent(player_context, {})

    harness.equal(percentages[skills.SK_SPELLCASTING], 0)
    harness.equal(percentages[skills.SK_FIGHTING], 100)

    local screen = skills_screen.rows(player_context, {
        species_id = identity.species_id,
        skills = trained.entries,
        skill_training = settings,
        skill_percent = percentages,
        height = 24,
    })

    harness.truthy(displayed_row(screen, "Spellcasting"):find("--", 1, true),
        "the skill screen marks harmful training unavailable")

    harness.falsy(training.change(ctx, actor, trained.entries,
        settings, definition, skills.SK_SPELLCASTING, true))
    harness.equal(training.spend_experience(ctx, actor,
        skills.SK_SPELLCASTING, 100), 0)

    local after = ctx:get(actor, component.SKILLS).entries

    harness.equal(after[2].points, 150)
end

-- Leaving Trog removes the temporary restriction without clearing saved
-- settings or magic points; a prior trained caster can resume later.
local function leave(ctx, actor)
    worship.renounce(ctx, actor)

    harness.falsy(availability.training_forbidden(ctx, actor,
        skills.SK_SPELLCASTING))

    local trained = ctx:get(actor, component.SKILLS)
    local settings = ctx:get(actor, component.SKILL_TRAINING)

    harness.equal(trained.entries[2].points, 150)
    harness.truthy(settings.settings[2].enabled)
end

-- The source join hook does not disable the distributed-training Gnoll's
-- magic skills. Its mutation gives the player a uniform bundle instead.
local function gnoll(ctx)
    local actor = player(ctx, species.SP_GNOLL)

    mutation_records.grant_innate(ctx, actor,
        mutations.MUT_DISTRIBUTED_TRAINING, 1)

    harness.falsy(availability.training_forbidden(ctx, actor,
        skills.SK_SPELLCASTING))
end

-- Run separate ordinary and distributed cases on production components.
function test.run(ctx)
    local actor = player(ctx, species.SP_HUMAN)

    source_group(ctx, actor)
    allocation(ctx, actor)
    leave(ctx, actor)
    gnoll(ctx)
end

return test
