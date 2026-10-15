local catalog = require("policy.catalog")
local component = require("constants.component")
local hex = require("policy.combat.monster_spells.hex")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")

local test = {}

local function spell_context(ctx, player, draws)
    local proxy = setmetatable({}, { __index = ctx })
    local next_draw = 0

    function proxy.player()
        return player
    end

    function proxy.random(_, stream, bound)
        next_draw = next_draw + 1
        local fixture = draws[next_draw]

        if stream ~= "monster_spell" or not fixture or
            bound ~= fixture.bound then
            error("unexpected hostile hex draw " .. next_draw ..
                " with bound " .. bound)
        end

        return fixture.value
    end

    function proxy.draws_used()
        return next_draw
    end

    return proxy
end

function test.run(ctx)
    local player = ctx:create()
    local caster = ctx:create()
    local basilisk = catalog.get("monsters", monsters.MONS_BASILISK)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Demonic Will test",
    })
    ctx:add(player, component.PROGRESSION, {
        level = 27,
        total_xp = 1000000,
    })
    ctx:add(caster, component.HEALTH, {
        current = 30,
        max = 30,
    })

    records.grant_innate(ctx, player, mutations.MUT_DEMONIC_WILL, 1)

    local rolls = spell_context(ctx, player, {
        { bound = 100, value = 0 },
        { bound = 101, value = 0 },
        { bound = 10, value = 0 },
        { bound = 4, value = 0 },
    })

    harness.equal(hex.resisted(rolls, caster, player, basilisk), true,
        "Demonic Will resists the hostile enchantment")
    harness.equal(ctx:get(caster, component.HEALTH).current, 27,
        "successful resistance lashes the caster for source damage")
    harness.equal(rolls.draws_used(), 4,
        "backlash follows both willpower rolls")

    local plain = ctx:create()

    ctx:add(plain, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Ordinary Will test",
    })
    ctx:add(plain, component.PROGRESSION, {
        level = 10,
        total_xp = 20000,
    })

    local ordinary_rolls = spell_context(ctx, plain, {
        { bound = 100, value = 45 },
        { bound = 101, value = 45 },
    })

    harness.equal(hex.resisted(ordinary_rolls, caster, plain, basilisk),
        true,
        "monster hexes step down enchantment power after dividing by three")
    harness.equal(ctx:get(caster, component.HEALTH).current, 27,
        "ordinary resistance does not trigger Demonic Will")
end

return test
