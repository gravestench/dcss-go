local component = require("constants.component")
local fixture = require("tests.fixtures.ranged_reflection")
local harness = require("tests.harness")
local ids = require("ids.items")
local mod_ids = require("ids.test_items")
local jewellery = require("tests.fixtures.jewellery")
local ranged_actions = require("policy.combat.ranged_actions")

local test = {}

function test.run(ctx)
    local battle, player, shooter, missile = fixture.scene(ctx,
        ids.MI_STONE, false)
    local amulet = jewellery.carry(ctx, player,
        mod_ids.AMU_REFLECTOR)

    ctx:add(amulet, component.EQUIPPED, { slot = "amulet" })

    fixture.block_then_return(battle)
    ranged_actions.monster(battle, shooter, { item_id = missile })

    harness.truthy(ctx:get(shooter, component.HEALTH).current < 40,
        "modded reflector returns the shot without an item-ID branch")
end

return test
