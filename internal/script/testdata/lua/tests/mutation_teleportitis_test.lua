local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local branches = require("ids.branches")
local component = require("constants.component")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local species = require("ids.species")
local teleportitis = require("policy.mutations.effects.teleportitis")
local terrain = require("constants.terrain")

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
        x = 9,
        y = 8,
    })
    ctx:add(monster, component.HEALTH, {
        current = 5,
        max = 5,
    })

    records.grant_innate(ctx, player, mutations.MUT_TELEPORT, 1)

    local world = setmetatable({}, { __index = ctx })
    local messages = {}
    function world.player()
        return player
    end

    function world.level_size()
        return 12, 12
    end

    function world.level_branch()
        return branches.BRANCH_DUNGEON
    end

    function world.walkable(_, _, x, y)
        return x >= 0 and y >= 0 and x < 12 and y < 12
    end

    function world.cell()
        return terrain.DNGN_FLOOR
    end

    function world.actor_at(_, _, x, y)
        if x == 9 and y == 8 then
            return monster
        end

        return nil
    end

    function world.visible()
        return true
    end

    function world.aut()
        return 0
    end

    function world.random(_, stream, bound)
        harness.truthy(bound > 0, "teleport random bounds stay positive")

        if stream == "teleport" then
            return 8
        end

        return 0
    end

    function world.move_actor(_, entity, level_id, x, y)
        ctx:set(entity, component.POSITION, {
            level_id = level_id,
            x = x,
            y = y,
        })
    end

    function world.emit(_, _, message)
        messages[#messages + 1] = message
    end

    teleportitis.tick(world, player, 10)

    local position = ctx:get(player, component.POSITION)

    harness.equal(position.x, 8,
        "teleportitis moves toward a monster at a sampled destination")
    harness.equal(position.y, 8,
        "teleportitis uses the sampled y coordinate")
    harness.equal(messages[#messages],
        "Your surroundings seem slightly different.",
        "a destination visible from the origin uses the source message")

    local trail = cloud.at(world, 1, 1, 1)

    harness.truthy(trail,
        "teleportitis leaves source translocation energy")
    harness.equal(ctx:get(trail, component.WORLD_CLOUD).kind_id,
        cloud_ids.CLOUD_TLOC_ENERGY,
        "the trail uses the source translocation cloud kind")

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    local quiet = setmetatable({}, { __index = world })

    function quiet.visible()
        return false
    end

    teleportitis.tick(quiet, player, 10)
    harness.equal(ctx:get(player, component.POSITION).x, 1,
        "a destination without a visible threat fails silently")

    ctx:set(monster, component.ACTOR, {
        kind_id = monsters.MONS_PLANT,
        speed = 10,
    })

    teleportitis.tick(world, player, 10)
    harness.equal(ctx:get(player, component.POSITION).x, 1,
        "a hostile but harmless plant cannot trigger teleportitis")

    ctx:set(monster, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    local dangerous = setmetatable({}, { __index = world })

    function dangerous.cell(_, _, x, y)
        if x == 8 and y == 8 then
            return terrain.DNGN_LAVA
        end

        return terrain.DNGN_FLOOR
    end

    teleportitis.tick(dangerous, player, 10)
    harness.equal(ctx:get(player, component.POSITION).x, 1,
        "teleportitis refuses a hazardous landing")

    ctx:set(player, component.PLAYER, {
        species_id = species.SP_FORMICID,
        job_id = jobs.JOB_FIGHTER,
    })

    teleportitis.tick(world, player, 10)
    harness.equal(ctx:get(player, component.POSITION).x, 1,
        "permanent stasis suppresses teleportitis")
end

return test
