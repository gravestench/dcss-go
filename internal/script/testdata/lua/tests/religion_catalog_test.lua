-- Every active source god has one discoverable content file. This test reads
-- the same registry as live rules, so a renamed file cannot change ID order.
local categories = require("constants.catalog")
local gods = require("constants.gods")
local harness = require("tests.harness")
local modes = require("constants.god_piety_modes")
local names = require("policy.religion.names")
local temple = require("policy.generation.temple.plan")

local test = {}

-- Cover the whole pantheon and the exceptional facts that eligibility and
-- piety will consume, instead of copying a second test-only god catalog.
function test.run()
    local ids = register.ids(categories.GODS)
    local expected = {}

    for key, id in pairs(gods) do
        if key ~= "NO_GOD" and key ~= "ECUMENICAL" then
            expected[id] = true
        end
    end

    harness.equal(#ids, 26)

    for index, id in ipairs(ids) do
        local definition = register.get(categories.GODS, id)

        harness.truthy(expected[id], "source god has a definition")
        harness.equal(definition.id, id)
        harness.equal(names[id], definition.name)
        harness.truthy(definition.name ~= "", "god has a display name")
        harness.truthy(definition.starting_piety >= 0)

        if index > 1 then
            harness.truthy(ids[index - 1] < id, "stable ID order")
        end

        expected[id] = nil
    end

    harness.equal(next(expected), nil)
    harness.equal(names[gods.ECUMENICAL], "an unknown god")

    local temple_ids = temple.god_ids()

    harness.equal(#temple_ids, 22)

    for _, id in ipairs(temple_ids) do
        harness.truthy(register.get(categories.GODS, id).temple_eligible)
    end
    harness.truthy(register.get(categories.GODS, gods.ZIN).good)
    harness.truthy(register.get(categories.GODS, gods.BEOGH).requires_orc)
    harness.truthy(register.get(categories.GODS, gods.FEDHAS).requires_love)
    harness.truthy(register.get(categories.GODS, gods.SIF_MUNA).rejects_innate_caster)
    harness.equal(register.get(categories.GODS, gods.GOZAG).piety_mode, modes.NONE)
    harness.equal(register.get(categories.GODS, gods.XOM).piety_mode, modes.XOM)
    harness.equal(register.get(categories.GODS, gods.IGNIS).starting_piety, 130)
end

return test
