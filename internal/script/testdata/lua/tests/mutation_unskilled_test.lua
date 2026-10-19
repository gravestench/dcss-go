
local capabilities = require("constants.mutation_capabilities")
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local formulas = require("policy.character.formulas")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local transition = require("policy.mutations.transition")
local skills = require("ids.skills")
local species = require("ids.species")
local catalog = require("policy.catalog")
local harness = require("tests.harness")

local test = {}

-- Removing Unskilled restores skill level from preserved points.
function test.run(ctx)
    local player = ctx:create()
    local human = catalog.get("species", species.SP_HUMAN)
    local baseline = formulas.skill_aptitude(human, skills.SK_FIGHTING)

    harness.equal(formulas.effective_skill_aptitude(ctx, player,
        human, skills.SK_FIGHTING), baseline,
        "skill aptitude starts at the species value")

    records.grant_acquired(ctx, player, mutations.MUT_UNSKILLED, 2)

    harness.equal(effects.sum(ctx, player,
        capabilities.SKILL_APTITUDE_PENALTY), 2,
        "two Unskilled levels reduce every usable skill aptitude by two")
    harness.equal(formulas.effective_skill_aptitude(ctx, player,
        human, skills.SK_FIGHTING), baseline - 2,
        "effective Fighting aptitude uses the mutation level")
    harness.equal(formulas.effective_skill_aptitude(ctx, player,
        human, skills.SK_SPELLCASTING),
        formulas.skill_aptitude(human, skills.SK_SPELLCASTING) - 2,
        "Unskilled applies to magic as well as mundane skills")

    local trained = ctx:create()
    local fighting = {
        id = skills.SK_FIGHTING,
        level = 10,
        points = 2775,
    }
    local baseline_hp = formulas.max_hp(ctx, trained, 27, human,
        { fighting })

    ctx:add(trained, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = require("ids.jobs").JOB_FIGHTER,
        name = "Unskilled test",
    })
    ctx:add(trained, component.PROGRESSION, {
        level = 27,
    })
    ctx:add(trained, component.SKILLS, {
        entries = { fighting },
    })
    ctx:add(trained, component.HEALTH, {
        current = baseline_hp,
        max = baseline_hp,
    })
    ctx:add(trained, component.REGENERATION, {
        hp_progress = 0,
    })
    ctx:add(trained, component.MAGIC, {
        current = 1,
        max = 1,
    })

    local granted = transition.grant(ctx, trained,
        mutations.MUT_UNSKILLED, classes.ACQUIRED, true)

    harness.equal(granted.kind, "granted", "Unskilled is granted")
    -- Saved points remain while the derived skill level changes under aptitude.
    harness.equal(ctx:get(trained, component.SKILLS).entries[1].level, 9,
        "the new aptitude immediately lowers the effective skill level")
    harness.truthy(ctx:get(trained, component.HEALTH).max < baseline_hp,
        "the Fighting change immediately recalculates maximum HP")

    transition.remove(ctx, trained, mutations.MUT_UNSKILLED,
        classes.ACQUIRED)

    -- Mutation removal recalculates from points rather than refunding or retraining them.
    harness.equal(ctx:get(trained, component.SKILLS).entries[1].level, 10,
        "removing Unskilled restores skill level from preserved points")
    harness.equal(ctx:get(trained, component.HEALTH).max, baseline_hp,
        "maximum HP follows the restored Fighting level")
end

return test
