local component = require("constants.component")
local armour_egos = require("constants.armour_egos")
local damage_causes = require("constants.damage_causes")
local items = require("ids.items")
local mutations = require("ids.mutations")
local health_policy = require("policy.combat.player_health")
local records = require("policy.mutations.records")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local harness = require("tests.harness")

local test = {}

local function player_with_vitals(ctx, hp, mp)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = hp,
        max = hp,
    })
    ctx:add(player, component.MAGIC, {
        current = mp,
        max = mp,
    })

    return player
end

local function player_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    function proxy.player()
        return player
    end

    return proxy
end

local function equip_guardian_spirit(ctx, player)
    local amulet = ctx:create()

    ctx:add(amulet, component.ITEM, {
        kind_id = items.AMU_GUARDIAN_SPIRIT,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(amulet, component.CARRIED_BY, {
        holder = player,
    })
    ctx:add(amulet, component.EQUIPPED, {
        slot = "amulet",
    })
end

local function equip_spirit_armour(ctx, player)
    local robe = ctx:create()

    ctx:add(robe, component.ITEM, {
        kind_id = items.ARM_ROBE,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = armour_egos.SPIRIT_SHIELD,
    })
    ctx:add(robe, component.CARRIED_BY, {
        holder = player,
    })
    ctx:add(robe, component.EQUIPPED, {
        slot = "body",
    })
end

function test.run(ctx)
    local mutated = player_with_vitals(ctx, 10, 6)
    local battle = player_context(ctx, mutated)

    records.grant_acquired(ctx, mutated, mutations.MUT_MANA_SHIELD, 1)

    harness.equal(effects.sum(ctx, mutated,
        capabilities.SPIRIT_SHIELD), 1,
        "Mana Shield owns spirit shielding")

    local health, dealt = health_policy.damage(battle, mutated, 8)

    harness.equal(dealt, 5,
        "mana shield shares ordinary damage with MP")
    harness.equal(health.current, 5,
        "mana shield leaves the shared HP damage")
    harness.equal(ctx:get(mutated, component.MAGIC).current, 3,
        "mana shield consumes its share of MP")

    local protected = player_with_vitals(ctx, 3, 6)
    local protected_battle = player_context(ctx, protected)

    equip_guardian_spirit(ctx, protected)

    local surviving = health_policy.damage(protected_battle, protected, 6)

    harness.equal(surviving.current, 1,
        "guardian spirit prevents a roundoff death when MP can cover it")
    harness.equal(ctx:get(protected, component.MAGIC).current, 2,
        "guardian spirit pays the MP needed to preserve one HP")

    local poisoned = player_with_vitals(ctx, 10, 6)
    local poisoned_battle = player_context(ctx, poisoned)

    records.grant_acquired(ctx, poisoned, mutations.MUT_MANA_SHIELD, 1)

    local after_poison = health_policy.damage(poisoned_battle, poisoned,
        8, false, nil, damage_causes.POISON)

    harness.equal(after_poison.current, 2,
        "poison bypasses spirit shielding")
    harness.equal(ctx:get(poisoned, component.MAGIC).current, 6,
        "poison does not spend MP")

    local armoured = player_with_vitals(ctx, 10, 6)
    local armoured_battle = player_context(ctx, armoured)

    equip_spirit_armour(ctx, armoured)

    local after_armour = health_policy.damage(armoured_battle, armoured, 8)

    harness.equal(after_armour.current, 5,
        "spirit-shield armour shares damage with MP")
    harness.equal(ctx:get(armoured, component.MAGIC).current, 3,
        "spirit-shield armour spends MP")
end

return test
