-- A mod-added ring changes defense through the production consumer.

local component = require("constants.component")
local fighter = require("policy.combat.fighter")
local fixture = require("tests.fixtures.jewellery")
local harness = require("tests.harness")
local ids = require("ids.test_items")

local test = {}

-- Equip a mod-defined ring in a real combat fixture, then compare evasion
-- before and after so its property reaches the production defense consumer.
function test.run(ctx)
    local battle, player = fixture.player(ctx)
    local baseline = fighter.defense(battle).ev
    local ring = fixture.carry(ctx, player, ids.RING_WARD, -3)

    ctx:add(ring, component.EQUIPPED, { slot = "ring_left" })

    harness.equal(fighter.defense(battle).ev, baseline - 3,
        "a mod-added ring changes defense through the production consumer")
end

return test
