-- Moving away can provoke an adjacent monster before the player's position
-- changes. Use real catalog, ECS energy, and allegiance data so this test
-- catches drift between ordinary monsters and the movement rule.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local melee = require("policy.combat.melee_actions")
local monsters = require("ids.monsters")
local opportunity = require("policy.combat.opportunity_attacks")
local distortion = require("policy.combat.brands.distortion")

local test = {}

-- The monster must lose adjacency, have a usable attack, and be quick enough
-- to follow the player's action. A slow actor cannot buy a free attack with
-- a lucky chance roll.
local function check_eligibility(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 20, 20, 100)
    local game = fixture.context(ctx, player)
    local ogre = fixture.actor(ctx, monsters.MONS_OGRE, 19, 20, 100)
    local energy = { points = 70 }

    ctx:add(ogre, component.MONSTER_ENERGY, energy)

    local origin = ctx:get(player, component.POSITION)
    local destination = {
        level_id = 1,
        x = 21,
        y = 20,
    }

    harness.truthy(opportunity.eligible(game, ogre, origin,
        destination, 10), "adjacent pursuing ogre can attack")
    harness.falsy(opportunity.eligible(game, ogre, origin,
        destination, 4), "slow player action cannot fund an attack")

    ctx:set(ogre, component.MONSTER_ENERGY, { points = 60 })
    harness.falsy(opportunity.eligible(game, ogre, origin,
        destination, 10), "insufficient future energy prevents attack")

    ctx:set(ogre, component.MONSTER_ENERGY, energy)
    game:move_actor(ogre, 1, 20, 19)
    harness.falsy(opportunity.eligible(game, ogre, origin,
        destination, 10), "still-adjacent monster does not attack")
end

-- The source refunds up to one turn of attack energy. The player has not
-- moved when the strike runs, and the moving flag must reach melee policy.
local function check_strike(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 40, 20, 100)
    local game = fixture.context(ctx, player)
    local ogre = fixture.actor(ctx, monsters.MONS_OGRE, 39, 20, 100)
    local original = melee.monster
    local struck = false

    ctx:add(ogre, component.MONSTER_ENERGY, { points = 70 })

    function game:random(_, bound)
        harness.equal(bound, 3, "only the source one-in-three draw")

        return 0
    end

    melee.monster = function(_, attacker, options)
        harness.equal(attacker, ogre)
        harness.truthy(options.player_moving)
        harness.equal(ctx:get(player, component.POSITION).x, 40)
        struck = true
    end

    local origin = ctx:get(player, component.POSITION)
    local moved = opportunity.run(game, origin, {
        level_id = 1,
        x = 41,
        y = 20,
    }, 10)

    melee.monster = original

    harness.truthy(moved, "surviving player may finish the move")
    harness.truthy(struck, "eligible ogre struck before departure")
    harness.equal(ctx:get(ogre, component.MONSTER_ENERGY).points, 65,
        "fifteen-energy attack refunds ten points")

    -- A reaction can take energy during melee. The refund applies to the
    -- live value, capped by the pre-attack amount.
    ctx:set(ogre, component.MONSTER_ENERGY, { points = 70 })

    melee.monster = function()
        ctx:set(ogre, component.MONSTER_ENERGY, { points = 60 })
    end

    opportunity.run(game, origin, {
        level_id = 1,
        x = 41,
        y = 20,
    }, 10)

    melee.monster = original

    harness.equal(ctx:get(ogre, component.MONSTER_ENERGY).points, 55,
        "reaction energy loss remains after the opportunity refund")
end

-- Confusion and paralysis are checked before the chance draw. Holding the
-- monster yourself is the one constriction case the source still permits.
local function check_status_gates(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 60, 20, 100)
    local game = fixture.context(ctx, player)
    local ogre = fixture.actor(ctx, monsters.MONS_OGRE, 59, 20, 100)
    local origin = ctx:get(player, component.POSITION)
    local destination = {
        level_id = 1,
        x = 61,
        y = 20,
    }

    ctx:add(ogre, component.MONSTER_ENERGY, { points = 70 })
    ctx:add(ogre, component.MONSTER_CONFUSION, {
        remaining_aut = 20,
    })
    harness.falsy(opportunity.eligible(game, ogre, origin,
        destination, 10), "confused monster cannot make a pursuit strike")

    ctx:remove(ogre, component.MONSTER_CONFUSION)
    ctx:add(ogre, component.PARALYSIS, { remaining_aut = 20 })
    harness.falsy(opportunity.eligible(game, ogre, origin,
        destination, 10), "paralyzed monster cannot strike")

    ctx:remove(ogre, component.PARALYSIS)
    ctx:add(ogre, component.PLAYER_CONSTRICTION, { by = player })
    harness.truthy(opportunity.eligible(game, ogre, origin,
        destination, 10), "player-held monster may attack the player")
end

-- Moving attacks exclude distortion banishment and blink before the draw.
-- Seventy-five is the sum of warp and no-effect source weights.
local function check_moving_distortion(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 90, 20, 100)
    local game = fixture.context(ctx, player)

    function game:random(_, bound)
        harness.equal(bound, 75, "movement distortion omits relocation")

        return 74
    end

    distortion.apply(game, {
        defender = player,
        player_moving = true,
    })

    harness.equal(ctx:get(player, component.POSITION).x, 90)
end

function test.run(ctx)
    check_eligibility(ctx)
    check_status_gates(ctx)
    check_strike(ctx)
    check_moving_distortion(ctx)
end

return test
