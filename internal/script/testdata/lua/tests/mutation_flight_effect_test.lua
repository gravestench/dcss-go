local component = require("constants.component")
local flight = require("policy.combat.flight")
local movement = require("policy.character.movement")
local mutations = require("ids.mutations")
local species = require("ids.species")
local jobs = require("ids.jobs")
local records = require("policy.mutations.records")
local forms = require("policy.magic.effects.forms.catalog")
local spells = require("ids.spells")
local harness = require("tests.harness")

local test = {}

local function player(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Flight test",
    })

    return entity
end

function test.run(ctx)
    local ordinary = player(ctx)
    local tengu = player(ctx)
    local wings = player(ctx)
    local floating = player(ctx)

    records.grant_acquired(ctx, tengu,
        mutations.MUT_TENGU_FLIGHT, 1)
    records.grant_acquired(ctx, wings,
        mutations.MUT_BIG_WINGS, 1)
    records.grant_acquired(ctx, floating,
        mutations.MUT_FLOAT, 1)

    harness.falsy(flight.active(ctx, ordinary),
        "ordinary player has no permanent flight")
    harness.truthy(flight.active(ctx, tengu),
        "Tengu Flight grants permanent flight")
    harness.truthy(flight.active(ctx, wings),
        "Big Wings grants permanent flight")
    harness.truthy(flight.active(ctx, floating),
        "Float grants permanent flight")

    harness.equal(movement.base(ctx, tengu), 9,
        "flying Tengu move one aut faster")
    harness.equal(movement.base(ctx, wings), 10,
        "Big Wings does not give the Tengu speed perk")
    harness.equal(movement.base(ctx, floating), 10,
        "Float does not give the Tengu speed perk")

    ctx:add(wings, component.PLAYER_FORM, {
        form_id = forms[spells.SPELL_SPIDER_FORM].id,
        remaining_aut = 100,
        power = 0,
        appendage_mask = 0,
    })
    ctx:add(tengu, component.PLAYER_FORM, {
        form_id = forms[spells.SPELL_SPIDER_FORM].id,
        remaining_aut = 100,
        power = 0,
        appendage_mask = 0,
    })

    harness.falsy(flight.active(ctx, wings),
        "Spider Form suppresses body-based Big Wings")
    harness.truthy(flight.active(ctx, tengu),
        "Spider Form retains magical Tengu flight")
end

return test
