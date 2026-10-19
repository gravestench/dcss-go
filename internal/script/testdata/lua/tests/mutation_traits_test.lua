
local catalog = require("policy.catalog")
local records = require("policy.mutations.records")
local traits = require("policy.character.traits")
local mutations = require("ids.mutations")
local species_ids = require("ids.species")
local spells = require("ids.spells")
local harness = require("tests.harness")

local test = {}

-- Human can use Portal Projectile before acquiring No Grasping.
function test.run(ctx)
    local player = ctx:create()
    local species = catalog.get("species", species_ids.SP_HUMAN)

    harness.truthy(traits.start_spell_usable(ctx, player, species,
        spells.SPELL_PORTAL_PROJECTILE),
        "Human can use Portal Projectile before acquiring No Grasping")

    records.grant_acquired(ctx, player, mutations.MUT_NO_GRASPING, 1)

    harness.falsy(traits.start_spell_usable(ctx, player, species,
        spells.SPELL_PORTAL_PROJECTILE),
        "acquired No Grasping blocks Portal Projectile")
end

return test
