
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.catalog")
local damage = require("policy.magic.damage")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local resistance = require("policy.combat.player_resistance")
local resistance_ids = require("constants.resistance_ids")
local spells = require("ids.spells")
local species = require("ids.species")

local test = {}

-- Seed torment petrification owner components once so each branch changes only the mutation under test.
local function player(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Torment test",
    })

    return entity
end

-- Attach the spell-defined form so torment rules see its holiness state.
local function assume_form(ctx, entity, spell_id)
    local form = forms[spell_id]

    ctx:add(entity, component.PLAYER_FORM, {
        form_id = form.id,
        remaining_aut = 100,
        power = 40,
    })
end

-- One torment mutation level reduces damage without immunity.
function test.run(ctx)
    local entity = player(ctx)

    harness.equal(type(resistance.torment), "function",
        "player resistance exposes torment immunity")
    harness.equal(type(resistance.petrification), "function",
        "player resistance exposes petrification immunity")
    harness.equal(type(resistance.torment_loss), "function",
        "player resistance exposes torment loss")

    harness.equal(resistance.torment(ctx, entity), false,
        "living Human has no torment immunity")
    harness.equal(resistance.petrification(ctx, entity), false,
        "living Human can be petrified")
    harness.equal(resistance.torment_loss(ctx, entity, 100), 49,
        "ordinary torment takes half current HP less one")

    records.grant_acquired(ctx, entity,
        mutations.MUT_TORMENT_RESISTANCE, 1)

    -- Partial resistance changes the loss fraction while leaving torment active.
    harness.equal(resistance.torment(ctx, entity), false,
        "one torment mutation level reduces damage without immunity")
    -- The formula is checked after the baseline half-current-HP torment calculation.
    harness.equal(resistance.torment_loss(ctx, entity, 100), 24,
        "one mutation level halves source torment loss")

    records.grant_acquired(ctx, entity,
        mutations.MUT_TORMENT_RESISTANCE, 1)

    harness.equal(resistance.torment(ctx, entity), true,
        "second torment mutation level gives immunity")
    harness.equal(resistance.torment_loss(ctx, entity, 100), 0,
        "immune player takes no torment loss")

    records.delete(ctx, entity, mutations.MUT_TORMENT_RESISTANCE,
        classes.ACQUIRED, 2)
    records.grant_acquired(ctx, entity,
        mutations.MUT_PETRIFICATION_RESISTANCE, 1)

    harness.equal(resistance.petrification(ctx, entity), true,
        "petrification mutation protects the player")

    records.delete(ctx, entity,
        mutations.MUT_PETRIFICATION_RESISTANCE, classes.ACQUIRED, 1)
    assume_form(ctx, entity, spells.SPELL_STATUE_FORM)

    harness.equal(resistance.petrification(ctx, entity), true,
        "statue form protects against petrification")
    harness.equal(resistance.torment_loss(ctx, entity, 100), 24,
        "statue form halves torment after the normal loss")

    ctx:remove(entity, component.PLAYER_FORM)
    assume_form(ctx, entity, spells.SPELL_NECROMUTATION)

    harness.equal(resistance.torment(ctx, entity), true,
        "lich form is immune to torment")
    harness.equal(resistance.torment_loss(ctx, entity, 100), 0,
        "lich form takes no torment loss")

    ctx:remove(entity, component.PLAYER_FORM)
    assume_form(ctx, entity, spells.SPELL_STORM_FORM)

    harness.equal(resistance.petrification(ctx, entity), true,
        "storm form is immune to petrification")

    ctx:remove(entity, component.PLAYER_FORM)
    ctx:add(entity, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 0,
        petrified_aut = 60,
    })

    harness.equal(resistance.torment(ctx, entity), true,
        "fully petrified player is immune to torment")
    harness.equal(damage.player_resistance(ctx, entity,
        resistance_ids.NEGATIVE_ENERGY), 3,
        "fully petrified player has three levels of negative protection")
end

return test
