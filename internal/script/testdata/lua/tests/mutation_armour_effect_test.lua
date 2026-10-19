
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Sturdy Frame removes two encumbrance per level.
function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_STURDY_FRAME, 2)
    records.grant_acquired(ctx, player, mutations.MUT_QUADRUMANOUS, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_LARGE_BONE_PLATES, 3)
    records.grant_acquired(ctx, player, mutations.MUT_DEFORMED, 1)
    records.grant_acquired(ctx, player, mutations.MUT_PSEUDOPODS, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.BODY_ENCUMBRANCE_REDUCTION), 4,
        "Sturdy Frame removes two encumbrance per level")
    harness.equal(effects.sum(ctx, player,
        capabilities.QUADRUMANOUS_SHIELDS), 1,
        "Quadrumanous grants the source shield fit rule")
    harness.equal(effects.sum(ctx, player,
        capabilities.SHIELD_CLASS_BONUS), 16,
        "level-three bone plates add sixteen internal shield points")
    harness.equal(effects.sum(ctx, player,
        capabilities.BODY_ARMOUR_AC_PENALTY), 2,
        "deformed and pseudopods both flag poor body armour fit")
end

return test
