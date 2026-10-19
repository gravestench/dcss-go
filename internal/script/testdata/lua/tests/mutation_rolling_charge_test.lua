
local component = require("constants.component")
local abilities = require("ids.abilities")
local harness = require("tests.harness")
local intent = require("constants.intent")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local terrain = require("constants.terrain")
local charge = require("policy.abilities.rolling_charge")
local attack_delay = require("policy.combat.delay")
local melee_actions = require("policy.combat.melee_actions")
local player_attack = require("policy.combat.player_attack")
local player_movement = require("policy.character.movement")
local timing = require("policy.command_timing")
local records = require("policy.mutations.records")

local test = {}

-- A three-cell Rolling Charge doubles damage before armour.
function test.run(ctx)
    local player = ctx:create()
    local monster = ctx:create()

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    -- A real player always has health; charge checks survival after movement
    -- before applying its attack, so the focused fixture needs that owner.
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 1,
    })
    ctx:add(monster, component.HEALTH, {
        current = 20,
        max = 20,
    })

    records.grant_innate(ctx, player, mutations.MUT_ROLL, 1)

    local world = setmetatable({}, { __index = ctx })

    -- Bind the planning world to the charging player.
    function world.player()
        return player
    end

    -- Make rolling charge sight deterministic while leaving actor positions to the ECS fixture.
    function world.visible()
        return true
    end

    -- Allow the straight charge path across the fixture floor.
    function world.walkable()
        return true
    end

    -- Return rolling charge fixture terrain that gates the environmental branch.
    function world.cell()
        return terrain.DNGN_FLOOR
    end

    -- Expose rolling charge fixture occupant at the queried cell for collision or targeting.
    function world.actor_at(_, _, x, y)
        if x == 4 and y == 1 then
            return monster
        end

        return nil
    end

    local plan = charge.plan(world, player, {
        dx = 3,
        dy = 0,
    })

    harness.equal(plan.destination.x, 3,
        "Rolling Charge stops beside the first monster")
    -- The damage bonus uses completed steps, not the originally selected target distance.
    harness.equal(plan.distance, 2,
        "charge bonus uses distance actually travelled")
    harness.equal(plan.target, monster,
        "the charge attacks its obstructing monster")

    local blocked = setmetatable({}, { __index = world })

    -- Block the intermediate square to reject a charge through terrain.
    function blocked.walkable(_, _, x, y)
        return x ~= 2 or y ~= 1
    end

    local no_plan, rejection = charge.plan(blocked, player, {
        dx = 3,
        dy = 0,
    })

    harness.falsy(no_plan,
        "Rolling Charge cannot pass through a wall")
    -- A wall rejection must happen before action time or melee damage is committed.
    harness.truthy(rejection,
        "blocked charge has a no-time explanation")

    local battle = setmetatable({}, { __index = ctx })

    -- Bind combat timing to the same player after the plan is resolved.
    function battle.player()
        return player
    end

    -- Use high melee draws so the charge damage comparison is deterministic.
    function battle.random(_, _, bound)
        return bound - 1
    end

    local input = {
        strength = 10,
        dexterity = 10,
        damage_attribute = 10,
        fighting100 = 0,
        weapon100 = 0,
        using_weapon = true,
        weapon_damage = 10,
        weapon_plus = 0,
        defender_ac = 0,
    }

    local ordinary = player_attack.damage(battle, input)
    input.roll_distance = 3

    harness.equal(player_attack.damage(battle, input), ordinary * 2,
        "a three-cell Rolling Charge doubles damage before armour")

    ctx:add(monster, component.AI, {
        behavior = "wander",
    })

    -- Commit the Rolling Charge endpoint so movement distance can be asserted.
    function world.move_actor(_, entity, level_id, x, y)
        ctx:set(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    -- Freeze rolling charge world time; the explicit aut argument drives every timer change.
    function world.aut()
        return 0
    end

    -- Force the low ability draw after the mocked charge attack.
    function world.random()
        return 0
    end

    -- Capture rolling charge events separately from the policy state being asserted.
    function world.emit()
    end

    local original_attack = melee_actions.player

    -- Suppress ordinary melee so the charge noise assertion isolates the ability path.
    melee_actions.player = function()
    end

    charge.resolve(world, player, {
        dx = 3,
        dy = 0,
    })

    melee_actions.player = original_attack

    harness.equal(ctx:get(monster, component.AI).behavior, "seek",
        "Rolling Charge noise alerts its nearby target")

    local original_base = player_movement.base
    local original_scale = player_movement.scale
    local original_delay = attack_delay.player

    -- Pin base movement to 12 aut while testing Rolling Charge action cost.
    player_movement.base = function()
        return 12
    end

    -- Keep scaled movement at 12 aut so attack delay controls the cost comparison.
    player_movement.scale = function()
        return 12
    end

    -- Pin attack delay at 18 aut to test the slower charge cost branch.
    attack_delay.player = function()
        return 18
    end

    local cost = timing.action_cost(world, player, {
        intent_kind = intent.PLAYER_ABILITY,
        ability_id = abilities.ROLLING_CHARGE,
    }, 10)

    player_movement.base = original_base
    player_movement.scale = original_scale
    attack_delay.player = original_delay

    -- Movement and attack share the slower weapon timing after a valid charge.
    harness.equal(cost, 18,
        "Rolling Charge keeps the slower weapon attack delay")
end

return test
