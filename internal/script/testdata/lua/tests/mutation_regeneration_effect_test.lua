local regeneration = require("policy.character.regeneration")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local base_hp, base_mp = regeneration.rates(ctx, player, 30, 4)

    harness.equal(base_hp, 10, "source base HP regeneration")
    harness.equal(base_mp, 9, "source base MP regeneration")

    records.grant_acquired(ctx, player, mutations.MUT_REGENERATION, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_MANA_REGENERATION, 1)

    local boosted_hp, boosted_mp = regeneration.rates(ctx, player, 30, 4)

    harness.equal(boosted_hp, 90,
        "Regeneration adds one source pip of 80")
    harness.equal(boosted_mp, 18,
        "Mana Regeneration doubles the base rate")

    records.grant_acquired(ctx, player, mutations.MUT_HP_CASTING, 1)

    local _, blocked_mp = regeneration.rates(ctx, player, 30, 4)

    harness.equal(blocked_mp, 0, "HP casting forbids MP regeneration")

    local blocked = ctx:create()

    records.grant_acquired(ctx, blocked,
        mutations.MUT_NO_REGENERATION, 1)

    harness.falsy(regeneration.hp_allowed(ctx, blocked),
        "No Regeneration forbids passive HP healing")

    records.grant_acquired(ctx, player, mutations.MUT_MANA_LINK, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.MANA_LINK), 1,
        "Mana Link owns the HP-to-MP redirection rule")
end

return test
