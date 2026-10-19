-- Wind Blast must push actors and clouds through the ordinary world owners.
-- Its AI should decline a distant foe before committing a spell intent.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local clouds = require("ids.clouds")
local jobs = require("ids.jobs")
local monsters = require("ids.monsters")
local species = require("ids.species")
local phases = require("constants.equipment_phases")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local geometry = require("policy.combat.monster_wind_geometry")

local test = {}

-- Use real ECS actor and cloud state while the sparse grid exposes the
-- same line and occupancy services as the game runtime.
function test.run(ctx)
    -- Cloud fallback is centered on its present cell, unlike the actor
    -- fallback centered on the blocked ray cell. A diagonal bend proves
    -- that the two scans admit different same-radius alternatives.
    local alternatives = geometry.alternates({ x = 20, y = 20 },
        { x = 22, y = 22 }, { x = 23, y = 23 },
        { x = 22, y = 22 })
    local found_diagonal = false

    for _, cell in ipairs(alternatives) do
        if cell.x == 21 and cell.y == 23 then
            found_diagonal = true
        end
    end

    harness.truthy(found_diagonal,
        "clouds can bend around a diagonal blocked ray")

    local game = fixture.observed_context(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_WIND_DRAKE,
        20, 20, 100)
    local foe = fixture.actor(ctx, monsters.MONS_RAT,
        23, 20, 100)
    local cloud = ctx:create()

    ctx:add(foe, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })
    ctx:add(foe, component.MONSTER_ENERGY, { points = 3 })
    ctx:add(cloud, component.WORLD_CLOUD, {
        kind_id = clouds.CLOUD_FIRE,
        level_id = 1,
        x = 22,
        y = 20,
        decay_aut = 100,
    })

    function game:random()
        return 0
    end

    local wind = effects.effect(spells.SPELL_WIND_BLAST)
    local plan = wind.plan(game, caster, foe)

    harness.truthy(plan,
        "Wind Blast plans a visible foe inside three cells")
    wind.resolve(game, caster, foe, nil, plan)

    harness.truthy(ctx:get(foe, component.POSITION).x > 23,
        "wind pushes an actor away from its source")
    harness.truthy(ctx:get(cloud, component.WORLD_CLOUD).x > 22,
        "wind pushes an in-cone cloud away from its source")
    harness.equal(ctx:get(foe, component.MONSTER_ENERGY).points, 0,
        "wind energy loss respects the saved monster energy floor")

    local distant = fixture.actor(ctx, monsters.MONS_RAT,
        27, 20, 100)

    ctx:add(distant, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    harness.falsy(wind.plan(game, caster, distant),
        "Wind Blast declines a foe outside source tactical range")

    local blocked = fixture.actor(ctx, monsters.MONS_RAT,
        33, 20, 100)

    ctx:add(blocked, component.VAULT_ACTOR_OVERRIDES, {
        attitude = attitudes.FRIENDLY,
    })

    game.walls["34:20"] = true
    game.walls["34:19"] = true
    game.walls["34:21"] = true

    local second_caster = fixture.actor(ctx, monsters.MONS_WIND_DRAKE,
        30, 20, 100)
    local before = ctx:get(blocked, component.HEALTH).current
    local second_plan = wind.plan(game, second_caster, blocked)

    harness.truthy(second_plan,
        "Wind Blast plans a foe before a solid collision cell")
    wind.resolve(game, second_caster, blocked, nil, second_plan)

    harness.truthy(ctx:get(blocked, component.HEALTH).current < before,
        "a blocked push deals source collision dice after armour")

    -- A displaced player cannot finish an equipment action at the old
    -- cell. This models the source stop_delay call on player movement.
    local player = game:player()
    local player_caster = fixture.actor(ctx, monsters.MONS_WIND_DRAKE,
        50, 20, 100)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Wind target",
    })
    ctx:add(player, component.HEALTH, {
        current = 100,
        max = 100,
    })
    ctx:add(player, component.EQUIPMENT_DELAY, {
        slot = "boots",
        phase = phases.REMOVE,
        remaining = 20,
    })
    game:move_actor(player, 1, 53, 20)

    function game:random(_, bound)
        return bound - 1
    end

    local player_plan = wind.plan(game, player_caster, player)

    harness.truthy(player_plan,
        "wind plans a player at source tactical distance")
    wind.resolve(game, player_caster, player, nil, player_plan)

    harness.truthy(ctx:get(player, component.POSITION).x > 53,
        "wind displaces the player")
    harness.falsy(ctx:has(player, component.EQUIPMENT_DELAY),
        "player displacement interrupts equipment delay")
end

return test
