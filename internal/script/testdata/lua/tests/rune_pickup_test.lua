-- Rune pickup must convert a floor item into durable character progress.
-- Pan reads the same saved component after the item entity is destroyed.
local component = require("constants.component")
local harness = require("tests.harness")
local item_ids = require("ids.items")
local rune_policy = require("policy.character.runes")
local identification = require("policy.items.identification")
local pickup = require("systems.item_pickup")

local test = {}

-- Use actual item and position components while assigning this player to
-- the test context used by identification and pickup.
local function world_context(ctx)
    local world = setmetatable({}, { __index = ctx })
    local player = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 5,
    })
    ctx:add(player, component.INTENT, {
        kind = 3,
    })
    rune_policy.initialise(world, player)
    identification.initialize(world, player)

    -- Name lookup and rune progress use the same actual player entity.
    function world:player()
        return player
    end

    return world, player
end

-- Picking up a Pan rune records its item ID and removes the floor item,
-- rather than giving the player a removable inventory stack.
local function pickup_records_progress(ctx)
    local world, player = world_context(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.ITEM, {
        kind_id = item_ids.RUNE_CEREBOV,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(entity, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 5,
    })

    pickup.update(world, player)

    harness.truthy(rune_policy.has(world, player,
        item_ids.RUNE_CEREBOV), "rune progress was not saved")
    harness.equal(rune_policy.pan_count(world, player), 1,
        "fiery rune does not count toward Pan")

    for _, item in ipairs(ctx:query({ component.ITEM })) do
        harness.falsy(item == entity, "collected rune remains on floor")
    end
end

-- Exercise the live pickup system, not a duplicate test-only rune grant.
function test.run(ctx)
    pickup_records_progress(ctx)
end

return test
