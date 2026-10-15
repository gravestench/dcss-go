local items = require("ids.items")
local potions = require("policy.potions")
local component = require("constants.component")
local harness = require("tests.harness")

local test = {}

function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.MAGIC, {
        current = 10,
        max = 10,
    })

    local magic = potions.get(items.POT_MAGIC)

    harness.equal(type(magic), "table",
        "magic potion has a focused effect module")
    harness.equal(magic.can_quaff(ctx, player),
        "Your magic is already full.",
        "known magic potion refuses full MP")

    ctx:set(player, component.MAGIC, {
        current = 0,
        max = 20,
    })

    harness.falsy(magic.can_quaff(ctx, player),
        "magic potion is usable below max MP")

    magic.apply(ctx, player)

    harness.equal(ctx:get(player, component.MAGIC).current, 10,
        "potion of magic restores the source minimum ten MP")
end

return test
