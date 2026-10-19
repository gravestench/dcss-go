
local effects = require("policy.mutations.effects.registry")
local harness = require("tests.harness")
local mutations = require("ids.mutations")

local test = {}

-- Active mutation ids must have a behavior policy or an explicit passive mapping.
function test.run()
    local missing = effects.missing()
    local absent = {}

    for _, id in ipairs(missing) do
        absent[id] = true
    end

    harness.falsy(absent[mutations.MUT_HOP],
        "the registered Hop ability satisfies mutation effect coverage")
    harness.falsy(absent[mutations.MUT_HURL_DAMNATION],
        "the registered Damnation ability satisfies coverage")
    harness.falsy(absent[mutations.MUT_WORD_OF_CHAOS],
        "the registered Word ability satisfies coverage")
    harness.falsy(absent[mutations.MUT_BEAK],
        "the registered peck attack satisfies Beak coverage")
    harness.falsy(absent[mutations.MUT_HORNS],
        "the registered headbutt satisfies Horns coverage")
    harness.falsy(absent[mutations.MUT_FANGS],
        "the registered bite satisfies Fangs coverage")
    harness.falsy(absent[mutations.MUT_SPINY],
        "the registered melee retaliation satisfies Spiny coverage")
    harness.falsy(absent[mutations.MUT_POWERED_BY_PAIN],
        "the registered damage reaction satisfies Pain coverage")
    harness.falsy(absent[mutations.MUT_POWERED_BY_DEATH],
        "the registered kill effect satisfies Death coverage")

    harness.equal(#missing, 0,
        "active mutations without behavior: " .. table.concat(missing, ", "))
end

return test
