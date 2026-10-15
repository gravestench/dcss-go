local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local formulas = require("policy.character.formulas")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local human = ctx:create()
    local demigod = ctx:create()

    records.grant_innate(ctx, demigod, mutations.MUT_DIVINE_ATTRS, 1)

    harness.equal(effects.base_sum(ctx, demigod,
        capabilities.DIVINE_ATTRIBUTES), 1,
        "Divine Attributes owns the stat progression rule")

    harness.truthy(formulas.needs_manual_stat(ctx, human, 3),
        "ordinary characters choose a stat at XL3")
    harness.falsy(formulas.needs_manual_stat(ctx, human, 6),
        "ordinary characters do not choose a stat at XL6")
    harness.equal(formulas.manual_stat_amount(ctx, human), 2,
        "ordinary manual choices grant two points")

    harness.truthy(formulas.needs_manual_stat(ctx, demigod, 3),
        "Divine Attributes chooses a stat at XL3")
    harness.truthy(formulas.needs_manual_stat(ctx, demigod, 6),
        "Divine Attributes chooses again at XL6")
    harness.falsy(formulas.needs_manual_stat(ctx, demigod, 7),
        "Divine Attributes does not choose at XL7")
    harness.equal(formulas.manual_stat_amount(ctx, demigod), 4,
        "Divine Attributes grants four points per choice")
end

return test
