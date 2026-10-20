-- Source banishment counts as Pikel leaving his minions. The world
-- transition must dismiss marked lemures without killing Pikel.
local abyss = require("policy.world.abyss")
local clouds = require("ids.clouds")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local catalog = require("policy.catalog")

local test = {}

-- Use real ECS entities and the fixture's open grid, with an explicit
-- destination move for the saved Abyss origin.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        50, 50, 100)
    local game = fixture.context(ctx, player)
    local pikel = fixture.actor(ctx, monsters.MONS_PIKEL,
        10, 10, 40)
    local minion = fixture.actor(ctx, monsters.MONS_LEMURE,
        11, 10, 20)
    local other = fixture.actor(ctx, monsters.MONS_LEMURE,
        12, 10, 20)

    ctx:add(minion, component.PIKEL_BAND, {
        band_member = true,
    })
    ctx:add(minion, component.FOLLOWER, {
        leader = pikel,
    })

    -- Choose the first open Abyss cell and the first smoke duration.
    function game:random(_, bound)
        harness.truthy(bound > 0, "invalid Abyss placement draw")

        return 0
    end

    local definition = catalog.get("monsters", monsters.MONS_PIKEL)

    harness.truthy(abyss.banish_monster(game, pikel, definition),
        "Pikel did not move to the Abyss")
    harness.equal(ctx:get(pikel, component.POSITION).level_id,
        abyss.level_id, "Pikel remains alive in the Abyss")
    harness.falsy(ctx:has(minion, component.ACTOR),
        "banished Pikel retained a marked minion")
    harness.truthy(ctx:has(other, component.ACTOR),
        "banishment dismissed an unrelated lemure")

    local smoke = ctx:query({ component.WORLD_CLOUD })

    harness.equal(#smoke, 1, "banishment leaves one minion smoke cloud")
    harness.equal(ctx:get(smoke[1], component.WORLD_CLOUD).kind_id,
        clouds.CLOUD_BLACK_SMOKE, "banishment cloud kind")
end

return test
