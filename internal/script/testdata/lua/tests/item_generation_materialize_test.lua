-- Two locations must fail.

local component = require("constants.component")
local generation = require("policy.item_generation")
local harness = require("tests.harness")
local ids = require("ids.items")

local test = {}

-- Materialization is deterministic and must reject any accidental RNG draw.
local function context()
    local state = {
        created = 0,
        attached = {},
    }

    -- Allocate a distinct fixture entity for each materialized item so a
    -- duplicate creation becomes visible in the asserted count.
    function state:create()
        self.created = self.created + 1

        return self.created
    end

    -- Record installed ECS components for inspection after materialization;
    -- the test does not need a second component-store implementation.
    function state:add(entity, name, value)
        self.attached[name] = value
    end

    -- Materialization must consume an already rolled result, so any new RNG
    -- draw is a regression in the roll/materialize boundary.
    function state:random()
        error("materialization may not draw randomness")
    end

    return state
end

-- Materialize one roll at a requested location and inspect the exact ECS
-- location component, preventing an item from existing in two places.
local function create_one(location, expected_component)
    local ctx = context()
    local rolled = {
        kind_id = ids.WPN_CLUB,
        quantity = 1,
        plus = 2,
        charges = 0,
        ego = "",
        components = {},
    }
    local entity = generation.create(ctx, rolled, location)

    harness.equal(entity, 1, "new entity")
    harness.equal(ctx.attached[component.ITEM].kind_id,
        ids.WPN_CLUB, "materialized item kind")
    harness.truthy(ctx.attached[expected_component],
        "selected item location")

    return ctx
end

-- Every generated entity has exactly one owner or floor position; invalid
-- mixed placement must fail before an entity is created.
local function exactly_one_location()
    create_one({
        position = {
            level_id = 1,
            x = 4,
            y = 5,
        },
    }, component.POSITION)
    create_one({
        carrier = 8,
    }, component.CARRIED_BY)
    create_one({
        reservation = 7,
    }, component.RESERVED_BY)

    local ctx = context()
    local okay = pcall(generation.create, ctx, {
        kind_id = ids.WPN_CLUB,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
        components = {},
    }, {
        carrier = 8,
        reservation = 7,
    })

    harness.falsy(okay, "two locations must fail")
    harness.equal(ctx.created, 0, "invalid location creates no entity")
end

-- Exercise every supported destination through the same creation path to
-- preserve the invariant that each new item has exactly one location.
function test.run()
    exactly_one_location()
end

return test
