-- Every random item class needs a registered generation policy with a valid weight.

local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local generation_catalog = require("policy.item_generation.catalog")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local validation = require("policy.item_generation.validate")

local test = {}

-- Stand in for a valid eligibility callback so registry tests can isolate
-- schema validation from the behavior of a real item class.
local function eligible()
    return true
end

-- Give the fixture a positive weight, the minimum valid selectable class
-- value needed to test registry wiring.
local function weight()
    return 1
end

-- A no-op roll callback is sufficient for registration checks, which only
-- validate that the policy supplies a callable implementation.
local function roll()
end

-- Capture a specific validation failure while allowing the rest of the
-- registry cases to run in the same Lua test module.
local function expect_error(expected, fn, ...)
    local okay, message = pcall(fn, ...)

    harness.falsy(okay, "expected generation validation error")
    harness.truthy(tostring(message):find(expected, 1, true),
        "missing error text " .. expected)
end

-- Submit valid and malformed class policies against a real item definition,
-- ensuring registration rejects incomplete mod handlers with source context.
function test.run()
    local mace = catalog.get("items", item_ids.WPN_MACE)
    local origin = register.origin("items", mace.id)
    local policy = {
        eligible = eligible,
        weight = weight,
        roll = roll,
    }
    local test_class = classes.OBJ_TEST_GENERATION

    generation_catalog.register(test_class, policy)
    harness.equal(generation_catalog.policy(test_class), policy,
        "registered class policy")

    expect_error("duplicate", generation_catalog.register, test_class, policy)

    local malformed = {
        id = mace.id,
        class = mace.class,
        generation = {
            mode = "random",
            weight = -1,
        },
    }

    expect_error(origin, validation.definition, malformed)

    malformed.generation.weight = 1
    malformed.generation.mode = "unknown"

    expect_error("mode", validation.definition, malformed)

    malformed.generation.mode = "random"
    malformed.generation.property_id = "IMPOSSIBLE_PROPERTY"

    expect_error("IMPOSSIBLE_PROPERTY", validation.definition, malformed)
end

return test
