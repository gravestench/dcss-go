local capabilities = require("constants.mutation_capabilities")
local classes = require("constants.mutation_classes")
local effects = require("policy.mutations.effects.registry")
local damage = require("policy.magic.damage")
local player_resistance = require("policy.combat.player_resistance")
local mutations = require("ids.mutations")
local item_ids = require("ids.items")
local species = require("ids.species")
local records = require("policy.mutations.records")
local resistances = require("constants.resistance_ids")
local harness = require("tests.harness")

local test = {}

local function player_context(ctx, owner)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy.player()
        return owner
    end

    return proxy
end

local function equip(ctx, owner, kind_id, slot, ego)
    local item = ctx:create()

    ctx:add(item, "core.item", {
        kind_id = kind_id,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = ego or "",
    })
    ctx:add(item, "core.carried_by", { holder = owner })
    ctx:add(item, "core.equipped", { slot = slot })

    return item
end

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, "core.player", {
        species_id = species.SP_HUMAN,
        job_id = "JOB_FIGHTER",
        name = "Resistance test",
    })

    records.grant_acquired(ctx, player,
        mutations.MUT_HEAT_RESISTANCE, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_HEAT_VULNERABILITY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_TEMPERATURE_SENSITIVITY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_COLD_RESISTANCE, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_COLD_VULNERABILITY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_SHOCK_RESISTANCE, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_SHOCK_VULNERABILITY, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_THIN_METALLIC_SCALES, 3)

    harness.equal(effects.sum(ctx, player,
        capabilities.FIRE_RESISTANCE), 0,
        "heat protection and vulnerabilities cancel")
    harness.equal(effects.sum(ctx, player,
        capabilities.COLD_RESISTANCE), 0,
        "cold protection and vulnerabilities cancel")
    harness.equal(effects.sum(ctx, player,
        capabilities.ELECTRICITY_RESISTANCE), 1,
        "metallic scales grant electricity resistance at level three")
    harness.equal(damage.player_resistance(ctx, player,
        resistances.ELECTRICITY), 1,
        "damage policy consumes the registered resistance")

    records.delete(ctx, player,
        mutations.MUT_THIN_METALLIC_SCALES, classes.ACQUIRED, 1)

    harness.equal(damage.player_resistance(ctx, player,
        resistances.ELECTRICITY), 0,
        "metallic scales grant no resistance below level three")

    records.grant_acquired(ctx, player,
        mutations.MUT_POISON_RESISTANCE, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_SLIMY_GREEN_SCALES, 3)
    records.grant_acquired(ctx, player,
        mutations.MUT_CLARITY, 1)

    harness.equal(effects.sum(ctx, player,
        capabilities.POISON_RESISTANCE), 2,
        "poison mutation levels combine before the source cap")
    harness.equal(player_resistance.poison(ctx, player), 1,
        "poison resistance is capped after mutation bonuses")
    harness.equal(player_resistance.clarity(ctx, player), true,
        "Clarity grants poison-independent mental protection")

    records.delete(ctx, player,
        mutations.MUT_POISON_RESISTANCE, classes.ACQUIRED, 1)
    records.delete(ctx, player,
        mutations.MUT_SLIMY_GREEN_SCALES, classes.ACQUIRED, 1)

    harness.equal(player_resistance.poison(ctx, player), 0,
        "two levels of slimy scales give no poison resistance")

    records.grant_acquired(ctx, player,
        mutations.MUT_ACID_RESISTANCE, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_STEAM_RESISTANCE, 1)

    harness.equal(damage.player_resistance(ctx, player,
        resistances.ACID), 1,
        "acid mutation grants one boolean corrosion resistance level")
    harness.equal(damage.player_elemental(ctx, player, 18,
        resistances.ACID), 9,
        "corrosive self-hit consumes the player's acid resistance")
    harness.equal(damage.player_resistance(ctx, player,
        resistances.STEAM), 2,
        "steam mutation contributes two resistance levels")
    harness.equal(damage.player_elemental(ctx, player, 18,
        resistances.STEAM), 6,
        "steam resistance uses player beam damage reduction")

    records.delete(ctx, player,
        mutations.MUT_ACID_RESISTANCE, classes.ACQUIRED, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_YELLOW_SCALES, 3)

    harness.equal(damage.player_resistance(ctx, player,
        resistances.ACID), 1,
        "level-three Yellow Scales preserve corrosion resistance")

    local geared = ctx:create()

    equip(ctx, geared, item_ids.ARM_STEAM_DRAGON_ARMOUR, "body")
    equip(ctx, geared, item_ids.RING_RESIST_CORROSION, "ring_left")

    local geared_ctx = player_context(ctx, geared)

    harness.equal(damage.player_resistance(geared_ctx, geared,
        resistances.STEAM), 2,
        "steam dragon scales provide two steam resistance levels")
    harness.equal(damage.player_resistance(geared_ctx, geared,
        resistances.ACID), 1,
        "corrosion ring provides boolean acid resistance")

    local acid_armour = ctx:create()

    equip(ctx, acid_armour, item_ids.ARM_ACID_DRAGON_ARMOUR, "body")

    harness.equal(damage.player_resistance(player_context(ctx, acid_armour),
        acid_armour,
        resistances.ACID), 1,
        "acid dragon scales provide corrosion resistance")

    local plain_resistance = ctx:create()

    equip(ctx, plain_resistance, item_ids.ARM_ROBE, "body",
        "SPARM_RESISTANCE")

    local plain_ctx = player_context(ctx, plain_resistance)

    harness.equal(damage.player_resistance(plain_ctx, plain_resistance,
        resistances.ACID), 0,
        "fire-and-cold resistance ego gives no acid protection")
    harness.equal(damage.player_resistance(plain_ctx, plain_resistance,
        resistances.STEAM), 2,
        "fire resistance also protects against steam")

    local negative = ctx:create()

    records.grant_acquired(ctx, negative,
        mutations.MUT_NEGATIVE_ENERGY_RESISTANCE, 1)

    harness.equal(damage.player_resistance(ctx, negative,
        resistances.NEGATIVE_ENERGY), 1,
        "negative energy mutation grants one source protection level")
    harness.equal(damage.player_elemental(ctx, negative, 18,
        resistances.NEGATIVE_ENERGY), 9,
        "one rN level halves resistible negative energy damage")

    records.grant_acquired(ctx, negative,
        mutations.MUT_NEGATIVE_ENERGY_RESISTANCE, 1)

    harness.equal(damage.player_elemental(ctx, negative, 18,
        resistances.NEGATIVE_ENERGY), 4,
        "two rN levels quarter resistible negative energy damage")

    records.grant_acquired(ctx, negative,
        mutations.MUT_NEGATIVE_ENERGY_RESISTANCE, 1)

    harness.equal(damage.player_elemental(ctx, negative, 18,
        resistances.NEGATIVE_ENERGY), 0,
        "three rN levels prevent negative energy beam damage")

    local negative_gear = ctx:create()

    equip(ctx, negative_gear, item_ids.ARM_PEARL_DRAGON_ARMOUR, "body")
    equip(ctx, negative_gear, item_ids.RING_LIFE_PROTECTION, "ring_left")

    harness.equal(damage.player_resistance(
        player_context(ctx, negative_gear), negative_gear,
        resistances.NEGATIVE_ENERGY), 2,
        "pearl dragon scales and life protection ring each grant rN")
end

return test
