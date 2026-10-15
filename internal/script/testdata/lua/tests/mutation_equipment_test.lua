local catalog = require("policy.catalog")
local equipment = require("policy.inventory.equipment")
local records = require("policy.mutations.records")
local mutations = require("ids.mutations")
local species_ids = require("ids.species")
local item_ids = require("ids.items")
local projectiles = require("policy.commands.projectiles")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local species = catalog.get("species", species_ids.SP_HUMAN)
    local gloves = catalog.get("items", item_ids.ARM_GLOVES)

    harness.truthy(equipment.can_wear(ctx, player, species, gloves),
        "human can wear gloves without claws")

    records.grant_acquired(ctx, player, mutations.MUT_CLAWS, 3)

    harness.falsy(equipment.can_wear(ctx, player, species, gloves),
        "level-three acquired claws block gloves")

    local weapon = ctx:create()

    ctx:add(weapon, "core.item", {
        kind_id = item_ids.WPN_DAGGER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(weapon, "core.carried_by", {
        holder = player,
    })

    local missile = ctx:create()

    ctx:add(missile, "core.item", {
        kind_id = item_ids.MI_DART,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(missile, "core.carried_by", {
        holder = player,
    })

    records.grant_acquired(ctx, player, mutations.MUT_NO_GRASPING, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.HANDHELD_USE_FORBIDDEN), 1,
        "No Grasping owns the handheld-item restriction")

    harness.truthy(equipment.prepare_wield(ctx, player,
        ctx:id(weapon)).message,
        "No Grasping prevents wielding a weapon")
    harness.truthy(projectiles.prepare(ctx, player, false,
        ctx:id(missile), 1, 0).message,
        "No Grasping prevents throwing a missile")

    records.grant_acquired(ctx, player, mutations.MUT_NO_ARMOUR, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.ARMOUR_USE_FORBIDDEN), 1,
        "No Armour owns the armour restriction")
end

return test
