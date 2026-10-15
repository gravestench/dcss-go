local catalog = require("policy.catalog")
local potions = require("policy.potions")
local harness = require("tests.harness")
local items = require("ids.items")
local categories = require("constants.catalog")
local item_classes = require("constants.item_classes")

local test = {}

function test.run()
    harness.equal(type(potions.get), "function",
        "potion effects use the shared registry")

    local active = 0

    for _, item in ipairs(catalog.all(categories.ITEMS)) do
        if item.class == item_classes.POTIONS and
            not item.explicitly_removed then
            active = active + 1

            local effect = potions.get(item.id)

            harness.equal(type(effect), "table",
                item.id .. " has a registered effect")
            harness.equal(type(effect.can_quaff), "function",
                item.id .. " has a preflight rule")
            harness.equal(type(effect.apply), "function",
                item.id .. " has a quaff rule")
        end
    end

    harness.equal(active, 17, "pinned DCSS has 17 active potions")

    local duplicate, duplicate_error = pcall(potions.register,
        items.POT_CURING, potions.get(items.POT_CURING))

    harness.falsy(duplicate, "duplicate potion handler is rejected")
    harness.truthy(duplicate_error:find("duplicate potion effect", 1,
        true), "duplicate error identifies the broken contract")

    local malformed, malformed_error = pcall(potions.register,
        items.POT_CURING, {})

    harness.falsy(malformed, "malformed potion handler is rejected")
    harness.truthy(malformed_error:find("needs can_quaff and apply", 1,
        true), "malformed error identifies the required methods")
end

return test
