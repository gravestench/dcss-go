-- ECS collection fields copy Lua lists and maps across add/get/set, preserve
-- entity handles and empty defaults, and reject sparse or mistyped values.

local harness = require("tests.harness")
local schema = require("schemas.collection_fields")

local test = {}

-- Run one invalid component write under pcall so later collection-shape cases
-- still execute after the schema rejects the attempted value.
local function rejects(action, message)
    local ok = pcall(action)

    harness.equal(ok, false, message)
end

-- Round-trip homogeneous lists and maps through a real component schema, then
-- challenge sparse and wrongly typed values at the Lua/ECS boundary.
function test.run(ctx)
    local owner = ctx:create()
    local target = ctx:create()
    local empty_owner = ctx:create()

    ctx:add(empty_owner, schema.id, {})

    local defaults = ctx:get(empty_owner, schema.id)

    harness.equal(#defaults.ints, 0, "list defaults to empty")
    harness.equal(next(defaults.int_map), nil, "map defaults to empty")

    local source = {
        bools = { true, false },
        ints = { -4, 7 },
        uints = { 0, 5 },
        floats = { 1.25, -2.5 },
        strings = { "one", "two" },
        entities = { target },
        bool_map = { flag = true },
        int_map = { score = -3 },
        uint_map = { count = 4 },
        float_map = { ratio = 0.5 },
        string_map = { label = "ready" },
        entity_map = { target = target },
    }

    ctx:add(owner, schema.id, source)
    -- Mutating the input after add must not mutate the stored component.
    source.ints[1] = 99
    source.int_map.score = 99

    local first = ctx:get(owner, schema.id)

    harness.equal(first.ints[1], -4, "add copies list values")
    harness.equal(first.int_map.score, -3, "add copies map values")
    harness.equal(first.entities[1], target, "list keeps entity handles")
    harness.equal(first.entity_map.target, target, "map keeps entity handles")
    harness.equal(first.bools[2], false, "bool list survives round trip")
    harness.equal(first.uints[2], 5, "uint list survives round trip")
    harness.equal(first.floats[1], 1.25, "float list survives round trip")
    harness.equal(first.strings[2], "two", "string list survives round trip")
    harness.equal(first.bool_map.flag, true, "bool map survives round trip")
    harness.equal(first.uint_map.count, 4, "uint map survives round trip")
    harness.equal(first.float_map.ratio, 0.5, "float map survives round trip")
    harness.equal(first.string_map.label, "ready", "string map survives round trip")

    -- A get result is another copy; writes require an explicit set.
    first.ints[1] = 81
    first.int_map.score = 81

    local second = ctx:get(owner, schema.id)

    harness.equal(second.ints[1], -4, "get copies list values")
    harness.equal(second.int_map.score, -3, "get copies map values")

    second.ints = {}
    second.int_map = {}
    ctx:set(owner, schema.id, second)

    local replaced = ctx:get(owner, schema.id)

    harness.equal(#replaced.ints, 0, "empty list is retained")
    harness.equal(next(replaced.int_map), nil, "empty map is retained")

    -- A list with a missing numeric index must fail instead of silently
    -- shifting values when Lua data crosses into a typed ECS field.
    rejects(function()
        ctx:set(owner, schema.id, { ints = { [1] = 1, [3] = 3 } })
    end, "sparse list is rejected")

    -- Map keys are strings by schema; numeric Lua keys must not be coerced
    -- into strings during component validation.
    rejects(function()
        ctx:set(owner, schema.id, { int_map = { [1] = 3 } })
    end, "nonstring map key is rejected")

    -- Element types remain enforced inside collections, not only on the
    -- outer table shape.
    rejects(function()
        ctx:set(owner, schema.id, { bools = { "true" } })
    end, "wrong element kind is rejected")
end

return test
