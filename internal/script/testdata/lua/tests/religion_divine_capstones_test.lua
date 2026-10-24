-- Use production god modules, mutation records, spell catalog, and the
-- shared blessing registry. These cases cover the source's distinct menu
-- eligibility without restating component schemas in a fixture.
local abilities = require("ids.abilities")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")
local jobs = require("ids.jobs")
local kiku = require("policy.abilities.weapon_blessing.kikubaaqudgha")
local knowledge = require("policy.abilities.kikubaaqudgha.forbidden_knowledge")
local mutation_records = require("policy.mutations.records")
local mutations = require("ids.mutations")
local piety = require("policy.religion.piety")
local registry = require("policy.abilities.registry")
local records = require("policy.character.spell_records")
local species = require("ids.species")
local shining_one = require("policy.abilities.weapon_blessing.shining_one")
local spells = require("ids.spells")

local test = {}

-- Source Kiku keeps Forbidden Knowledge available to a character who
-- cannot grasp a weapon. Choosing it spends the same lifetime flag that
-- removes pain branding, including after a later worship change.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Capstone tester",
    })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.KIKUBAAQUDGHA,
        piety = piety.breakpoint(6),
    })

    local sword = ctx:create()

    ctx:add(sword, component.ITEM, {
        kind_id = items.WPN_LONG_SWORD,
        quantity = 1,
    })
    ctx:add(sword, component.CARRIED_BY, { holder = player })

    local bow = ctx:create()

    ctx:add(bow, component.ITEM, {
        kind_id = items.WPN_SHORTBOW,
        quantity = 1,
    })
    ctx:add(bow, component.CARRIED_BY, { holder = player })

    harness.truthy(kiku.available(ctx, player))
    harness.truthy(knowledge.available(ctx, player))
    harness.truthy(kiku.eligible(ctx, player, sword))
    harness.truthy(kiku.eligible(ctx, player, bow))
    harness.truthy(shining_one.eligible(ctx, player, bow))
    harness.equal(knowledge.usable(ctx, player)[1], spells.SPELL_HAUNT)

    ctx:add(sword, component.ITEM_ARTEFACT, {})
    harness.falsy(kiku.eligible(ctx, player, sword),
        "divine brands do not rebrand artefacts")

    mutation_records.grant_acquired(ctx, player,
        mutations.MUT_NO_GRASPING, 1)

    harness.falsy(kiku.available(ctx, player))
    harness.truthy(knowledge.available(ctx, player))

    local prompt = knowledge.prepare(ctx, player, {})

    harness.truthy(prompt.confirmation)
    harness.equal(knowledge.prepare(ctx, player, {
        cancelled = true,
    }), "Okay.")

    knowledge.resolve(ctx, player)

    local haunt = records.find(ctx, player, spells.SPELL_HAUNT)

    haunt.state.known_slot = 1
    ctx:set(haunt.entity, component.SPELL_RECORD, haunt.state)
    harness.equal(knowledge.usable(ctx, player)[1], spells.SPELL_HAUNT,
        "memorised spells remain source gift candidates")

    harness.falsy(knowledge.available(ctx, player))
    harness.falsy(registry.usable_now(ctx, player,
        registry.get(abilities.KIKU_BLESS_WEAPON)))

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.god_id = gods.SHINING_ONE
    ctx:set(player, component.RELIGION_WORSHIP, worship)

    harness.falsy(shining_one.available(ctx, player),
        "No Grasping also blocks TSO's weapon capstone")

    local mummy = ctx:create()

    ctx:add(mummy, component.PLAYER, {
        species_id = species.SP_MUMMY,
        job_id = jobs.JOB_FIGHTER,
        name = "Useless gift tester",
    })
    ctx:add(mummy, component.RELIGION_WORSHIP, {
        god_id = gods.KIKUBAAQUDGHA,
        piety = piety.breakpoint(6),
    })
    mutation_records.grant_acquired(ctx, mummy,
        mutations.MUT_NO_LOVE, 1)

    harness.equal(#knowledge.usable(ctx, mummy), 0)
    harness.equal(knowledge.prepare(ctx, mummy, {}),
        "Kikubaaqudgha has no more spells that you can make use of!")
end

return test
