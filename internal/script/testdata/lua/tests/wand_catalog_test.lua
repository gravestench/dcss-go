local harness = require("tests.harness")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local classes = require("ids.object_classes")
local effects = require("policy.magic.effects.registry")
local component = require("constants.component")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local wands = require("policy.inventory.wands")

local test = {}

function test.run(ctx)
    local count = 0

    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        if definition.class == classes.OBJ_WANDS then
            harness.equal(wands.spell(definition.id),
                definition.wand_spell_id,
                "wand resolver uses the registered spell link")
            harness.truthy(effects.get(definition.wand_spell_id),
                "mapped wand effect must be registered")
            count = count + 1
        end
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
