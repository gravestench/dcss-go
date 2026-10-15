local component = require("constants.component")
local harness = require("tests.harness")
local items = require("ids.items")
local attraction = require("policy.potions.attraction")
local potions = require("policy.potions")

local test = {}

function test.run(ctx)
    local player = ctx:create()
    local effect = potions.get(items.POT_ATTRACTION)

    harness.truthy(effect, "attraction potion is registered")
    effect.apply(ctx, player)

    harness.equal(ctx:get(player, component.POTION_ATTRACTION).remaining_aut,
        200, "attraction has the source minimum duration")

    attraction.tick(ctx, player, 10)

    harness.equal(ctx:get(player, component.POTION_ATTRACTION).remaining_aut,
        190, "attraction duration uses elapsed action time")
end

return test
