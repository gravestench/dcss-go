-- Source monster flags give three ordinary species permanent cloud rings.
-- They must use the same live ECS clouds and action refresh as a Pan lord.
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ids = require("ids.clouds")
local monsters = require("ids.monsters")
local ring = require("policy.combat.monster_cloud_ring")

local test = {}

local cases = {
    {
        monster_id = monsters.MONS_ASMODEUS,
        cloud_id = ids.CLOUD_FIRE,
        x = 20,
    },

    {
        monster_id = monsters.MONS_BAI_SUZHEN_DRAGON,
        cloud_id = ids.CLOUD_STORM,
        x = 35,
    },

    {
        monster_id = monsters.MONS_TAINTED_LEVIATHAN,
        cloud_id = ids.CLOUD_MIASMA,
        x = 50,
    },
}

-- A source flag is immutable species data, while each resulting cloud is
-- a saved world entity. No Pan lord component is needed on these actors.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 8, 8, 100)
    local game = fixture.context(ctx, player)

    function game:random(_, bound)
        harness.equal(bound, 6)

        return 0
    end

    for _, case in ipairs(cases) do
        local actor = fixture.actor(ctx, case.monster_id,
            case.x, 20, 100)

        harness.falsy(ctx:get(actor, component.PANDEMONIUM_LORD))
        ring.surround(game, actor)

        local _, cloud = clouds.at(game, 1, case.x, 19)

        harness.truthy(cloud, case.monster_id .. " has no cloud ring")
        harness.equal(cloud.kind_id, case.cloud_id)

        game:move_actor(actor, 1, case.x, 25)
        ring.surround(game, actor)

        local _, moved = clouds.at(game, 1, case.x, 24)

        harness.truthy(moved, case.monster_id .. " ring did not follow")
        harness.equal(moved.kind_id, case.cloud_id)
    end
end

return test
