
local catalog = require("policy.catalog")
local component = require("constants.component")
local hex = require("policy.combat.monster_spells.hex")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local spells = require("ids.spells")

local test = {}

-- Script monster-spell rolls and count them so Demonic Will tests pin hex resistance order.
local function spell_context(ctx, player, draws)
    local proxy = setmetatable({}, { __index = ctx })
    local next_draw = 0

    -- Bind policy ownership to demonic will hex fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    -- Consume scripted monster-spell bounds in order so resistance cannot skip a draw.
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

    -- Check how many named RNG draws the hex path consumed.
    function proxy.draws_used()
        return next_draw
    end

    return proxy
end

-- Monster hexes step down enchantment power after dividing by three.
function test.run(ctx)
    local player = ctx:create()
    local caster = ctx:create()
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
    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_BASILISK,
    })

    local profile = catalog.get("monster_beams", spells.SPELL_PETRIFY)

    records.grant_innate(ctx, player, mutations.MUT_DEMONIC_WILL, 1)

    local rolls = spell_context(ctx, player, {
        { bound = 100, value = 0 },
        { bound = 101, value = 0 },
        { bound = 10, value = 0 },
        { bound = 4, value = 0 },
    })

    harness.equal(hex.resisted(rolls, caster, player, profile), true,
        "Demonic Will resists the hostile enchantment")
    harness.equal(ctx:get(caster, component.HEALTH).current, 27,
        "successful resistance lashes the caster for source damage")
    -- A resisted hex consumes both will checks before retaliation damage.
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

    harness.equal(hex.resisted(ordinary_rolls, caster, plain, profile),
        true,
        "monster hexes step down enchantment power after dividing by three")
    -- Backlash is gated by the mutation rather than resistance alone.
    harness.equal(ctx:get(caster, component.HEALTH).current, 27,
        "ordinary resistance does not trigger Demonic Will")
end

return test
