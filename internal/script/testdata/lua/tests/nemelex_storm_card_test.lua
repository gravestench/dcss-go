-- Storm samples distant cells after wind. This isolates damage and noise
-- endpoints while retaining real explosion geometry and actor components.
local actors = require("policy.combat.monster_wind_actors")
local blast = require("policy.magic.effects.summons.blast")
local cards = require("ids.cards")
local clouds = require("policy.combat.monster_wind_clouds")
local component = require("constants.component")
local effects = require("policy.religion.cards.effects.dispatch")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local noise = require("policy.world.noise")
local resistances = require("constants.resistance_ids")
local streams = require("constants.rng_streams")

local test = {}

-- One tier-zero reservoir slot retains its first valid cell. The wind owner
-- sees source power 66 and cards RNG; the resulting blast uses electricity.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local victim = fixture.actor(ctx, monsters.MONS_RAT, 0, 0)
    local pushed = 0
    local damaged = 0
    local expected_tier = 0

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    local old_push = actors.push
    local old_clouds = clouds.push
    local old_collisions = actors.collisions
    local old_land = actors.land
    local old_noise = noise.emit
    local old_hit = blast.hit

    -- Wind behavior has its own tests; observe the card's source arguments.
    actors.push = function(_, caster, origin, aim, radius, power, stream)
        harness.equal(caster, player)
        harness.equal(origin.x, 7)
        harness.equal(aim, nil)
        harness.equal(radius, 5)
        harness.equal(power, (expected_tier + 1) * 66)
        harness.equal(stream, streams.CARDS)
        pushed = pushed + 1

        return {}, {}
    end

    -- The card still calls both deferred wind passes after actor movement.
    clouds.push = function() end
    actors.collisions = function() end
    actors.land = function() end
    noise.emit = function() return 12, true end

    -- Damage handoff retains raw 3d9 and the shared resistance identifier.
    blast.hit = function(_, target, raw, resistance, source, stream)
        harness.equal(target, victim)
        harness.equal(raw, 3 * (9 + 9 * expected_tier))
        harness.equal(resistance, resistances.ELECTRICITY)
        harness.equal(source, player)
        harness.equal(stream, streams.CARDS)
        damaged = damaged + 1
    end

    -- Only one distant cell is in sight, so duplicate reservoirs collapse
    -- to one blast at each tier without depending on all fixture floor cells.
    function owner:visible_no_trans(_, _, _, _, x, y)
        return x == 0 and y == 0
    end

    -- The count takes its minimum; one valid cell fills every sampler slot.
    function owner:random(stream, bound)
        harness.equal(stream, streams.CARDS)

        if bound == 9 + 9 * expected_tier then
            return bound - 1
        end

        return 0
    end

    local success, message = pcall(function()
        for tier = 0, 2 do
            expected_tier = tier

            effects.apply(owner, player, cards.STORM, {
                tier = tier,
                power = 300,
            })
        end

        -- Exercise the real wind owner with a nearby rat after the source
        -- arguments have been checked independently above.
        actors.push = old_push
        clouds.push = old_clouds
        actors.collisions = old_collisions
        actors.land = old_land
        expected_tier = 0

        local blown = fixture.actor(ctx, monsters.MONS_RAT, 8, 7)

        effects.apply(owner, player, cards.STORM, {
            tier = 0,
            power = 300,
        })

        harness.truthy(ctx:get(blown, component.POSITION).x > 8)
    end)

    actors.push = old_push
    clouds.push = old_clouds
    actors.collisions = old_collisions
    actors.land = old_land
    noise.emit = old_noise
    blast.hit = old_hit

    if not success then
        error(message)
    end

    harness.equal(pushed, 3)
    harness.equal(damaged, 4)
end

return test
