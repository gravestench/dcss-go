-- Use production item IDs and the real Akara schema for each source
-- weapon-family conversion. No test-only copy of the conversion map exists.
local blessed = require("policy.abilities.weapon_blessing.item")
local brands = require("constants.weapon_brands")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local items = require("ids.items")

local test = {}

-- The paired base kind changes on the same entity; TSO also claims a
-- converted holy weapon as a god-acquired item for later provenance.
local function check_pair(ctx, demon, holy)
    local weapon = ctx:create()

    ctx:add(weapon, component.ITEM, {
        kind_id = demon,
        quantity = 1,
        plus = 8,
    })

    blessed.apply(ctx, weapon, {
        god_id = gods.SHINING_ONE,
        brand = brands.HOLY_WRATH,
    })

    local upgraded = ctx:get(weapon, component.ITEM)
    local origin = ctx:get(weapon, component.ITEM_PROVENANCE)

    harness.equal(upgraded.kind_id, holy)
    harness.equal(upgraded.ego, brands.HOLY_WRATH)
    harness.equal(upgraded.plus, 9)
    harness.equal(origin.god_id, gods.SHINING_ONE)

    blessed.apply(ctx, weapon, {
        god_id = gods.KIKUBAAQUDGHA,
        brand = brands.PAIN,
    })

    local corrupted = ctx:get(weapon, component.ITEM)

    harness.equal(corrupted.kind_id, demon)
    harness.equal(corrupted.ego, brands.PAIN)
    harness.equal(corrupted.plus, 9)
end

-- All three source pairs share the one item action. A mundane ranged
-- weapon is brandable for TSO/Kiku but has no demon/holy subtype change.
function test.run(ctx)
    check_pair(ctx, items.WPN_DEMON_BLADE,
        items.WPN_EUDEMON_BLADE)
    check_pair(ctx, items.WPN_DEMON_WHIP,
        items.WPN_SACRED_SCOURGE)
    check_pair(ctx, items.WPN_DEMON_TRIDENT,
        items.WPN_TRISHULA)

    local bow = ctx:create()

    ctx:add(bow, component.ITEM, {
        kind_id = items.WPN_SHORTBOW,
        quantity = 1,
        plus = 0,
    })

    blessed.apply(ctx, bow, {
        god_id = gods.SHINING_ONE,
        brand = brands.HOLY_WRATH,
    })

    local branded = ctx:get(bow, component.ITEM)

    harness.equal(branded.kind_id, items.WPN_SHORTBOW)
    harness.equal(branded.ego, brands.HOLY_WRATH)
    harness.equal(branded.plus, 2)
end

return test
