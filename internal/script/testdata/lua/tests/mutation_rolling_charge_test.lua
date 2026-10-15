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

    function world.player()
        return player
    end

    function world.visible()
        return true
    end

    function world.walkable()
        return true
    end

    function world.cell()
        return terrain.DNGN_FLOOR
    end

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
    harness.equal(plan.distance, 2,
        "charge bonus uses distance actually travelled")
    harness.equal(plan.target, monster,
        "the charge attacks its obstructing monster")

    local blocked = setmetatable({}, { __index = world })

    function blocked.walkable(_, _, x, y)
        return x ~= 2 or y ~= 1
    end

    local no_plan, rejection = charge.plan(blocked, player, {
        dx = 3,
        dy = 0,
    })

    harness.falsy(no_plan,
        "Rolling Charge cannot pass through a wall")
    harness.truthy(rejection,
        "blocked charge has a no-time explanation")

    local battle = setmetatable({}, { __index = ctx })

    function battle.player()
        return player
    end

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

    function world.move_actor(_, entity, level_id, x, y)
        ctx:set(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    function world.aut()
        return 0
    end

    function world.random()
        return 0
    end

    function world.emit()
    end

    local original_attack = melee_actions.player

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

    player_movement.base = function()
        return 12
    end

    player_movement.scale = function()
        return 12
    end

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

    harness.equal(cost, 18,
        "Rolling Charge keeps the slower weapon attack delay")
end

return test
