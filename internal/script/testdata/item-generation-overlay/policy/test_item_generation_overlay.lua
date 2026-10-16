local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local policies = require("policy.item_generation.catalog")

local probe = {}

function probe.read()
    local definition = catalog.get("items", "WPN_TEST_SPROCKET")
    local policy = policies.policy(classes.OBJ_WEAPONS)
    local result = {}

    policy.roll(nil, definition, {}, result)

    return {
        kind = definition.name,
        eligible = policy.eligible(nil, definition, {}),
        weight = policy.weight(nil, definition, {}),
        plus = result.plus,
    }
end

register.policy({
    id = "test.item_generation_overlay",
    run = probe.read,
})

return probe
