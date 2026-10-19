
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local records = require("policy.mutations.records")
local mutations = require("ids.mutations")
local species_ids = require("ids.species")
local harness = require("tests.harness")

local test = {}

-- Acquired High Magic increases maximum MP.
function test.run(ctx)
    local player = ctx:create()
    local species = catalog.get("species", species_ids.SP_HUMAN)
    local skills = {}
    local base_hp = formulas.max_hp(ctx, player, 10, species, skills)
    local base_mp = formulas.max_mp(ctx, player, 10, species, skills)

    records.grant_acquired(ctx, player, mutations.MUT_ROBUST, 1)
    records.grant_acquired(ctx, player, mutations.MUT_HIGH_MAGIC, 1)

    harness.equal(formulas.max_hp(ctx, player, 10, species, skills),
        math.floor(base_hp * 110 / 100),
        "acquired Robust increases maximum HP")
    harness.equal(formulas.max_mp(ctx, player, 10, species, skills),
        math.floor((base_mp - species.mp_mod) * 110 / 100) + species.mp_mod,
        "acquired High Magic increases maximum MP")
end

return test
