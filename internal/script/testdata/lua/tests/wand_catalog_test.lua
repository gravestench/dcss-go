local harness = require("tests.harness")
local items = require("ids.items")
local spells = require("ids.spells")
local effects = require("policy.magic.effects.registry")
local component = require("constants.component")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local wands = require("policy.inventory.wands")

local test = {}

function test.run(ctx)
    local expected = {
        [items.WAND_FLAME] = spells.SPELL_THROW_FLAME,
        [items.WAND_PARALYSIS] = spells.SPELL_PARALYSE,
        [items.WAND_DIGGING] = spells.SPELL_DIG,
        [items.WAND_ICEBLAST] = spells.SPELL_ICEBLAST,
        [items.WAND_POLYMORPH] = spells.SPELL_POLYMORPH,
        [items.WAND_CHARMING] = spells.SPELL_CHARMING,
        [items.WAND_ACID] = spells.SPELL_CORROSIVE_BOLT,
        [items.WAND_LIGHT] = spells.SPELL_BOLT_OF_LIGHT,
        [items.WAND_QUICKSILVER] = spells.SPELL_QUICKSILVER_BOLT,
        [items.WAND_MINDBURST] = spells.SPELL_MINDBURST,
        [items.WAND_ROOTS] = spells.SPELL_FASTROOT,
    }

    local count = 0

    for wand_id, spell_id in pairs(expected) do
        harness.equal(wands.spell(wand_id), spell_id,
            "source wand spell mapping " .. wand_id)
        harness.truthy(effects.get(spell_id),
            "mapped wand effect must be registered: " .. spell_id)
        count = count + 1
    end

    harness.equal(count, 11, "all source wand kinds are covered")

    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_MP_WANDS, 1)
    ctx:add(player, component.MAGIC, {
        current = 2,
        max = 5,
    })
    ctx:add(player, component.HEALTH, {
        current = 2,
        max = 10,
    })
    ctx:add(player, component.PLAYER, {
        name = "Wand tester",
        species_id = species.SP_HUMAN,
        job_id = "JOB_FIGHTER",
        starting_weapon_id = "WPN_RAPIER",
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })

    harness.equal(wands.mp_cost(ctx, player), 2,
        "MP Wands spends at most available MP")
    harness.equal(wands.power(ctx, player, 0), 15,
        "an untrained wand has source base power")
    harness.equal(wands.power(ctx, player, 3), 20,
        "three MP raises untrained wand power by one third")

    records.grant_acquired(ctx, player, mutations.MUT_HP_CASTING, 1)

    harness.equal(wands.mp_cost(ctx, player), 1,
        "HP Casting wand cost uses HP and leaves at least one")
end

return test
