-- Geryon carries the Horn before death, so the ordinary inventory drop
-- transfers the same item entity to the floor when he is defeated.
local gear = require("policy.population.gear.registry")
local component = require("constants.component")
local death = require("policy.death")
local factory = require("policy.population.factory")
local fixture = require("tests.fixtures.monster_gear_world")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")

local test = {}

-- The source assigns a miscellaneous loadout slot rather than creating
-- the Horn as a scripted death reward.
function test.run(ctx)
    local loadout = gear.loadout(ctx, monsters.MONS_GERYON, 30)

    harness.truthy(loadout)
    harness.equal(loadout.misc.kind_id, items.MISC_HORN_OF_GERYON)

    local world = fixture.new(ctx)
    local geryon = factory.spawn(world,
        monsters.MONS_GERYON, 1, 10, 10)
    local horn

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.CARRIED_BY,
    })) do
        local item = ctx:get(entity, component.ITEM)
        local carrier = ctx:get(entity, component.CARRIED_BY)

        if carrier.holder == geryon and
            item.kind_id == items.MISC_HORN_OF_GERYON then
            horn = entity
        end
    end

    harness.truthy(horn, "Geryon has no physical Horn")
    harness.falsy(ctx:has(horn, component.EQUIPPED),
        "Geryon should carry rather than wield the Horn")
    death.drop_inventory(world, geryon,
        ctx:get(geryon, component.POSITION))
    harness.truthy(ctx:has(horn, component.POSITION),
        "Geryon's death did not drop the Horn")
end

return test
