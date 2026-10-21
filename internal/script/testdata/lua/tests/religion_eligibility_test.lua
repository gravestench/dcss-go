-- Source worship restrictions depend on live species, mutation, form, and
-- wallet state. The same catalog definitions drive all 26 candidate gods.
local categories = require("constants.catalog")
local component = require("constants.component")
local eligibility = require("policy.religion.eligibility")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local forms = require("constants.form_ids")

local test = {}

-- Supply ordinary live player components; each case starts with no history.
local function player(ctx, species_id, job_id)
    local owner = ctx:create()

    ctx:add(owner, component.PLAYER, {
        species_id = species_id or species.SP_HUMAN,
        job_id = job_id or jobs.JOB_FIGHTER,
        name = "Eligibility test",
    })
    ctx:add(owner, component.WALLET, {})
    ctx:add(owner, component.RELIGION_WORSHIP, {})

    return owner
end

-- Use the source god facts to check every candidate, including exceptions
-- that reject a human only after a live condition changes.
local function ordinary_candidates(ctx)
    local human = player(ctx)

    for _, id in ipairs(register.ids(categories.GODS)) do
        local allowed = eligibility.check(ctx, human, id, true)

        if id == gods.BEOGH then
            harness.truthy(allowed, "Beogh requires an orc")
        else
            harness.equal(allowed, nil, "ordinary human may join " .. id)
        end
    end

    local forlorn = player(ctx)

    records.grant_acquired(ctx, forlorn, mutations.MUT_FORLORN, 1)

    for _, id in ipairs(register.ids(categories.GODS)) do
        harness.truthy(eligibility.check(ctx, forlorn, id, false),
            "Forlorn rejects " .. id)
    end
end

-- Permanent species and mutation restrictions remain when testing whether
-- a player could ever worship; temporary form and funds tests do not.
local function permanent_restrictions(ctx)
    local ghoul = player(ctx, species.SP_GHOUL)
    local demonspawn = player(ctx, species.SP_DEMONSPAWN)
    local caster = player(ctx)
    local loveless = player(ctx)
    local orc = player(ctx, species.SP_HILL_ORC)

    for _, id in ipairs({ gods.ZIN, gods.SHINING_ONE, gods.ELYVILON }) do
        harness.truthy(eligibility.check(ctx, ghoul, id, false))
        harness.truthy(eligibility.check(ctx, demonspawn, id, false))
    end

    records.grant_acquired(ctx, caster, mutations.MUT_INNATE_CASTER, 1)

    for _, id in ipairs({
        gods.SIF_MUNA,
        gods.VEHUMET,
        gods.KIKUBAAQUDGHA,
    }) do
        harness.truthy(eligibility.check(ctx, caster, id, false))
    end

    harness.equal(eligibility.check(ctx, caster, gods.TROG, false), nil)
    harness.equal(eligibility.check(ctx, orc, gods.BEOGH, true), nil)

    records.grant_innate(ctx, loveless, mutations.MUT_NO_LOVE, 1)

    for _, id in ipairs({
        gods.BEOGH,
        gods.JIYVA,
        gods.HEPLIAKLQANA,
        gods.FEDHAS,
        gods.YREDELEMNUL,
    }) do
        harness.truthy(eligibility.check(ctx, loveless, id, false))
    end
end

-- Forms and temporary No Love alter current eligibility without rewriting
-- the species or permanent mutation result.
local function temporary_restrictions(ctx)
    local transformed = player(ctx)

    ctx:add(transformed, component.PLAYER_FORM, {
        form_id = forms.TREE,
    })

    harness.truthy(eligibility.check(ctx, transformed, gods.ZIN, true))
    harness.equal(eligibility.check(ctx, transformed, gods.ZIN, false), nil)
    harness.equal(eligibility.check(ctx, transformed, gods.SHINING_ONE, true), nil)

    ctx:set(transformed, component.PLAYER_FORM, {
        form_id = forms.LICH,
    })

    harness.truthy(eligibility.check(ctx, transformed, gods.SHINING_ONE, true))
    harness.equal(eligibility.check(ctx, transformed, gods.SHINING_ONE, false), nil)

    local loveless = player(ctx)

    records.grant_temporary(ctx, loveless, mutations.MUT_NO_LOVE, 1, 50)
    harness.truthy(eligibility.check(ctx, loveless, gods.FEDHAS, true))
    harness.equal(eligibility.check(ctx, loveless, gods.FEDHAS, false), nil)
end

-- Gozag's source fee depends on generated gold, with a free first god for
-- Monks. Current wallet funds matter only to the temporary check.
local function gozag_fee(ctx)
    local fighter = player(ctx)
    local balance = ctx:get(fighter, component.WALLET)

    balance.generated_gold = 100
    balance.gold = 10
    ctx:set(fighter, component.WALLET, balance)

    harness.truthy(eligibility.check(ctx, fighter, gods.GOZAG, true))
    harness.equal(eligibility.check(ctx, fighter, gods.GOZAG, false), nil)

    balance.gold = 25
    ctx:set(fighter, component.WALLET, balance)

    harness.equal(eligibility.check(ctx, fighter, gods.GOZAG, true), nil)

    local monk = player(ctx, species.SP_HUMAN, jobs.JOB_MONK)
    local monk_balance = ctx:get(monk, component.WALLET)

    monk_balance.generated_gold = 100
    ctx:set(monk, component.WALLET, monk_balance)

    harness.equal(eligibility.check(ctx, monk, gods.GOZAG, true), nil)

    local worship = ctx:get(monk, component.RELIGION_WORSHIP)

    worship.worshipped[gods.TROG] = 1
    ctx:set(monk, component.RELIGION_WORSHIP, worship)

    harness.truthy(eligibility.check(ctx, monk, gods.GOZAG, true))
end

-- Group related source restrictions so a failure identifies the family that
-- drifted when a catalog or player-state owner changes.
function test.run(ctx)
    ordinary_candidates(ctx)
    permanent_restrictions(ctx)
    temporary_restrictions(ctx)
    gozag_fee(ctx)
end

return test
