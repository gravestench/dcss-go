
local capabilities = require("constants.mutation_capabilities")
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local schools = require("constants.spell_schools")
local skills = require("ids.skills")
local species = require("ids.species")
local training = require("policy.character.training")
local transition = require("policy.mutations.transition")
local harness = require("tests.harness")

local test = {}

-- Training controls cannot re-enable a sacrificed skill.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Skill sacrifice test",
    })
    ctx:add(player, component.HEALTH, {
        current = 18,
        max = 18,
    })
    ctx:add(player, component.SKILLS, {
        entries = {
            {
                id = skills.SK_DODGING,
                level = 2,
                points = 150,
            },
            {
                id = skills.SK_FIGHTING,
                level = 2,
                points = 150,
            },
        },
    })
    ctx:add(player, component.SKILL_TRAINING, {
        settings = {
            {
                id = skills.SK_DODGING,
                enabled = true,
                focused = true,
            },
            {
                id = skills.SK_FIGHTING,
                enabled = true,
                focused = false,
            },
        },
    })

    local result = transition.grant(ctx, player,
        mutations.MUT_NO_DODGING, classes.ACQUIRED, true)

    harness.equal(result.kind, "granted", "Dodging sacrifice is acquired")
    harness.equal(effects.sum(ctx, player,
        capabilities.SKILL_FORBIDDEN, skills.SK_DODGING), 1,
        "Dodging sacrifice forbids its named skill")
    harness.equal(effects.sum(ctx, player,
        capabilities.SKILL_FORBIDDEN, skills.SK_FIGHTING), 0,
        "Dodging sacrifice preserves other skills")

    local entries = ctx:get(player, component.SKILLS).entries
    local training_state = ctx:get(player, component.SKILL_TRAINING)
    local settings = training_state.settings

    -- Sacrifice permanently clears saved points as well as the visible level.
    harness.equal(entries[1].points, 0,
        "sacrificed skill points are removed immediately")
    harness.equal(entries[1].level, 0,
        "sacrificed skill level is removed immediately")
    harness.falsy(settings[1].enabled,
        "sacrificed skill cannot remain enabled for training")
    harness.falsy(settings[1].focused,
        "sacrificed skill cannot remain focused")
    harness.truthy(settings[2].enabled,
        "other skill settings remain intact")

    local human = require("policy.catalog").get("species", species.SP_HUMAN)
    local changed = training.change(ctx, player, entries, training_state,
        human, skills.SK_DODGING, true)

    -- The UI control path must enforce the same forbidden-skill rule as training.
    harness.falsy(changed,
        "training controls cannot re-enable a sacrificed skill")

    transition.grant(ctx, player, mutations.MUT_NO_AIR_MAGIC,
        classes.ACQUIRED, true)

    harness.equal(effects.sum(ctx, player,
        capabilities.SKILL_FORBIDDEN, skills.SK_AIR_MAGIC), 1,
        "Air sacrifice forbids Air Magic training")
    harness.equal(effects.sum(ctx, player,
        capabilities.SPELL_SCHOOL_FORBIDDEN, schools.AIR), 1,
        "Air sacrifice forbids casting Air spells")
    harness.equal(effects.sum(ctx, player,
        capabilities.SPELL_SCHOOL_FORBIDDEN, schools.FIRE), 0,
        "Air sacrifice leaves other schools available")

    transition.grant(ctx, player, mutations.MUT_MISSING_HAND,
        classes.ACQUIRED, true)

    harness.equal(effects.sum(ctx, player,
        capabilities.SKILL_FORBIDDEN, skills.SK_SHIELDS), 1,
        "Missing Hand makes Shields training useless")
end

return test
