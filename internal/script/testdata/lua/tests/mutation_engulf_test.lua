
local component = require("constants.component")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local species = require("ids.species")
local engulf = require("policy.combat.engulf")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Keep the engulf target visible while checking speech and damage branches.
local function visible_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to engulf fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    -- Make engulf sight deterministic while leaving actor positions to the ECS fixture.
    function proxy.visible()
        return true
    end

    return proxy
end

-- A breathing engulfed monster cannot speak.
function test.run(ctx)
    local player = ctx:create()
    local rat = ctx:create()
    local screen = visible_context(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Engulf test",
    })
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(rat, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })
    ctx:add(rat, component.HEALTH, {
        current = 30,
        max = 30,
    })
    ctx:add(rat, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })
    records.grant_acquired(ctx, player, mutations.MUT_ENGULF, 1)

    local applied = false

    for _ = 1, 20 do
        if engulf.on_player_hit(screen, rat, 3) then
            applied = true
            break
        end
    end

    harness.truthy(applied, "eligible damaging melee can engulf")
    -- Water hold disables vocal actions while the actor remains trapped.
    harness.truthy(engulf.silenced(screen, rat),
        "a breathing engulfed monster cannot speak")

    local before = ctx:get(rat, component.HEALTH).current

    engulf.tick(screen, rat)

    local after = ctx:get(rat, component.HEALTH).current

    harness.truthy(after < before,
        "an engulfed land monster takes asphyxiation damage")

    local position = ctx:get(rat, component.POSITION)
    position.x = 8
    ctx:set(rat, component.POSITION, position)
    engulf.release_far(screen, rat)

    -- The hold component ends when victim and holder no longer share the required position.
    harness.falsy(engulf.active(screen, rat),
        "separation releases water hold")
end

return test
