local item_ids = require("ids.items")
local mutations = require("ids.mutations")
local jobs = require("ids.jobs")
local species = require("ids.species")
local potion_rules = require("policy.character.potion_rules")
local potions = require("policy.potions")
local quaff = require("policy.commands.quaff")
local records = require("policy.mutations.records")
local harness = require("tests.harness")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")

local test = {}

local function carried_potion(ctx, player, kind_id)
    local entity = ctx:create()

    ctx:add(entity, "core.item", {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(entity, "core.carried_by", { holder = player })

    return entity
end

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, "core.health", {
        current = 1,
        max = 40,
    })

    local curing = carried_potion(ctx, player, item_ids.POT_CURING)
    harness.truthy(quaff.prepare(ctx, player, ctx:id(curing)).intent,
        "ordinary player can drink curing")

    local mutable = ctx:create()

    ctx:add(mutable, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Mutation potion test",
    })

    local mutation_potion = carried_potion(ctx, mutable,
        item_ids.POT_MUTATION)

    harness.truthy(quaff.prepare(ctx, mutable,
        ctx:id(mutation_potion)).intent,
        "a living player can drink a potion of mutation")

    local mummy = ctx:create()

    ctx:add(mummy, "core.player", {
        species_id = species.SP_MUMMY,
        job_id = jobs.JOB_FIGHTER,
        name = "Mutation potion test",
    })

    local forbidden_potion = carried_potion(ctx, mummy,
        item_ids.POT_MUTATION)
    local forbidden = quaff.prepare(ctx, mummy,
        ctx:id(forbidden_potion))

    harness.falsy(forbidden.intent,
        "an unsafe undead player cannot drink a potion of mutation")
    harness.equal(forbidden.message, "You cannot mutate.",
        "the mutation potion uses the source refusal")

    ctx:add(mutable, "magic.player_form", {
        form_id = "lich",
        remaining_aut = 20,
    })

    local lich_refusal = quaff.prepare(ctx, mutable,
        ctx:id(mutation_potion))

    harness.equal(lich_refusal.message,
        "You cannot drink in this form.",
        "form drinking restriction precedes mutation potion checks")

    ctx:remove(mutable, "magic.player_form")

    records.grant_acquired(ctx, mutable, mutations.MUT_STRONG, 1)

    local mutation_draws = harness.random_context(ctx, { 0, 0, 0 })
    local potion_draws = { 0, 0, 0 }
    local next_potion_draw = 0
    local potion_ctx = setmetatable({}, { __index = mutation_draws })

    function potion_ctx.random(_, stream, bound)
        if stream == "mutation" then
            return mutation_draws:random(stream, bound)
        end

        harness.equal(stream, "potion", "potion counts use potion RNG")
        next_potion_draw = next_potion_draw + 1

        local value = potion_draws[next_potion_draw]

        harness.truthy(value and value < bound,
            "the potion draw matches its source bound")

        return value
    end

    potions[item_ids.POT_MUTATION](potion_ctx, mutable)

    harness.equal(next_potion_draw, 3,
        "mutation potion draws both counts and the good-mutation coinflip")
    harness.equal(mutation_draws:draws_used(), 3,
        "mutation choices draw only after removal attempts")
    harness.equal(records.find(ctx, mutable, mutations.MUT_STRONG).state.acquired,
        2, "mutation potion removes two attempts then grants two levels")

    records.grant_acquired(ctx, player, mutations.MUT_NO_DRINK, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.POTION_FORBIDDEN), 1,
        "No Drink contributes a reusable potion prohibition")

    local refused = quaff.prepare(ctx, player, ctx:id(curing))

    harness.falsy(refused.intent,
        "No Drink rejects a potion before issuing an intent")
    harness.equal(refused.message, "You can't drink.",
        "No Drink uses the source refusal")

    local reduced = ctx:create()

    ctx:add(reduced, "core.health", {
        current = 1,
        max = 40,
    })

    records.grant_acquired(ctx, reduced,
        mutations.MUT_NO_POTION_HEAL, 1)

    harness.equal(effects.sum(ctx, reduced,
        capabilities.POTION_HEALING_PENALTY), 1,
        "potion healing loss is a named mutation capability")

    local draw = 0
    local reduced_ctx = setmetatable({}, { __index = ctx })

    function reduced_ctx.random(_, stream, bound)
        harness.equal(stream, "potion", "healing uses potion RNG")
        harness.equal(bound, 2, "half healing rounds over two outcomes")
        draw = draw + 1

        return 2 - draw
    end

    harness.equal(potion_rules.healing_factor(reduced_ctx, reduced), 1,
        "one mutation level halves potion healing")
    harness.equal(potion_rules.scale_healing(reduced_ctx, reduced, 5), 2,
        "first odd half-heal rounds down")
    harness.equal(potion_rules.scale_healing(reduced_ctx, reduced, 5), 3,
        "second odd half-heal rounds up")

    records.grant_acquired(ctx, reduced,
        mutations.MUT_NO_POTION_HEAL, 1)

    harness.equal(potion_rules.healing_factor(ctx, reduced), 0,
        "two mutation levels block potion healing")
    local reduced_wounds = carried_potion(ctx, reduced,
        item_ids.POT_HEAL_WOUNDS)
    local reduced_curing = carried_potion(ctx, reduced,
        item_ids.POT_CURING)

    harness.falsy(quaff.prepare(ctx, reduced,
        ctx:id(reduced_wounds)).intent,
        "heal wounds is refused when potions cannot heal")
    harness.falsy(quaff.prepare(ctx, reduced,
        ctx:id(reduced_curing)).intent,
        "curing is refused without a curable condition")

    ctx:add(reduced, "core.poison", {
        amount_scaled = 10,
        source_monster_id = "",
    })

    harness.truthy(quaff.prepare(ctx, reduced,
        ctx:id(reduced_curing)).intent,
        "curing may remove poison when healing is blocked")

    local before = ctx:get(reduced, "core.health").current

    potions.POT_CURING(ctx, reduced)

    harness.equal(ctx:get(reduced, "core.health").current, before,
        "curing does not heal through No Potion Heal level two")
    harness.falsy(ctx:has(reduced, "core.poison"),
        "curing still removes poison")
end

return test
