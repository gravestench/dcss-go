-- All active jewellery properties need an effect capability, including modded rings.

local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local capabilities = require("constants.jewellery_capabilities")
local magnitudes = require("constants.jewellery_magnitudes")
local ids = require("ids.items")
local harness = require("tests.harness")
local jewellery = require("policy.inventory.jewellery")
local classes = require("ids.object_classes")
local kinds = require("constants.jewellery_kind")

local expected = {
    [ids.RING_PROTECTION] = { [capabilities.AC] = magnitudes.ITEM_PLUS },
    [ids.RING_PROTECTION_FROM_FIRE] = {
        [capabilities.FIRE_RESISTANCE] = 1,
    },
    [ids.RING_POISON_RESISTANCE] = {
        [capabilities.POISON_RESISTANCE] = 1,
    },
    [ids.RING_PROTECTION_FROM_COLD] = {
        [capabilities.COLD_RESISTANCE] = 1,
    },
    [ids.RING_STRENGTH] = {
        [capabilities.STRENGTH] = magnitudes.ITEM_PLUS,
    },
    [ids.RING_SLAYING] = {
        [capabilities.SLAYING] = magnitudes.ITEM_PLUS,
    },
    [ids.RING_SEE_INVISIBLE] = {
        [capabilities.SEE_INVISIBLE] = 1,
    },
    [ids.RING_RESIST_CORROSION] = {
        [capabilities.CORROSION_RESISTANCE] = 1,
    },
    [ids.RING_EVASION] = { [capabilities.EV] = magnitudes.ITEM_PLUS },
    [ids.RING_DEXTERITY] = {
        [capabilities.DEXTERITY] = magnitudes.ITEM_PLUS,
    },
    [ids.RING_INTELLIGENCE] = {
        [capabilities.INTELLIGENCE] = magnitudes.ITEM_PLUS,
    },
    [ids.RING_WIZARDRY] = { [capabilities.WIZARDRY] = 1 },
    [ids.RING_MAGICAL_POWER] = { [capabilities.MAX_MP] = 9 },
    [ids.RING_FLIGHT] = { [capabilities.PERMANENT_FLIGHT] = 1 },
    [ids.RING_LIFE_PROTECTION] = {
        [capabilities.NEGATIVE_ENERGY_RESISTANCE] = 1,
    },
    [ids.RING_WILLPOWER] = { [capabilities.WILLPOWER_PIPS] = 1 },
    [ids.RING_FIRE] = {
        [capabilities.FIRE_RESISTANCE] = 1,
        [capabilities.COLD_RESISTANCE] = -1,
    },
    [ids.RING_ICE] = {
        [capabilities.COLD_RESISTANCE] = 1,
        [capabilities.FIRE_RESISTANCE] = -1,
    },
    [ids.AMU_ACROBAT] = { [capabilities.ACROBAT] = 1 },
    [ids.AMU_MANA_REGENERATION] = { [capabilities.MP_REGEN] = 40 },
    [ids.AMU_GUARDIAN_SPIRIT] = {
        [capabilities.SPIRIT_SHIELD] = 1,
    },
    [ids.AMU_FAITH] = { [capabilities.FAITH] = 1 },
    [ids.AMU_REFLECTION] = { [capabilities.REFLECTION] = 1 },
    [ids.AMU_REGENERATION] = { [capabilities.HP_REGEN] = 80 },
}

local test = {}

-- Verify every active jewellery definition has a registered effect, catching
-- missing Lua capability handlers before an item is equipped in play.
function test.run()
    local count = 0

    -- Every active jewellery ID must map to a supported capability rather
    -- than relying on item-specific branches at equipment time.
    for _, definition in ipairs(catalog.all(categories.ITEMS)) do
        if definition.jewellery and not definition.explicitly_removed then
            count = count + 1

            local want = expected[definition.id]
            local got = definition.jewellery.effects

            harness.truthy(want, "missing expected jewellery " ..
                definition.id)
            harness.truthy(got, "missing effects for " .. definition.id)

            for capability, magnitude in pairs(want) do
                harness.equal(got[capability], magnitude,
                    definition.id .. "/" .. capability)
            end

            for capability in pairs(got) do
                harness.truthy(want[capability] ~= nil,
                    "unexpected " .. definition.id .. "/" .. capability)
            end
        end
    end

    harness.equal(count, 24, "all active jewellery effects are covered")

    -- Reuse an existing capability from a modded ring, then reject an unknown
    -- capability and a plus magnitude without plus-bearing item metadata.
    local modded = {
        id = "MOD_SUN_RING",
        class = classes.OBJ_JEWELLERY,
        jewellery = {
            kind = kinds.RING,
            effects = { [capabilities.FIRE_RESISTANCE] = 1 },
        },
    }

    harness.equal(jewellery.effects(modded)[capabilities.FIRE_RESISTANCE],
        1, "a modded ring can use an existing effect capability")

    modded.jewellery.effects = { mystery = 1 }
    harness.falsy(pcall(jewellery.effects, modded),
        "unknown effect capabilities fail validation")

    modded.jewellery.effects = {
        [capabilities.AC] = magnitudes.ITEM_PLUS,
    }
    harness.falsy(pcall(jewellery.effects, modded),
        "item-plus magnitude requires an enchanted item")

    modded.jewellery.pluses = true
    harness.truthy(pcall(jewellery.effects, modded),
        "a modded enchanted ring can use its item plus")
end

return test
