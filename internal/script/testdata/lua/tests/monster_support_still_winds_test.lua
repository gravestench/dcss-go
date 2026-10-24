local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local mutation_records = require("policy.mutations.records")
local spells = require("ids.spells")
local clouds = require("ids.clouds")
local terrain = require("constants.terrain")
local wind = require("policy.combat.monster_support.still_winds")
local placement = require("policy.clouds.placement")

local test = {}

-- The isolated rule harness supplies geometry while real ECS cloud entities
-- carry position, kind, and lifespan through the production Lua policies.
local function level_context(ctx, player, ally)
    local game = setmetatable({}, { __index = ctx })

    function game.player()
        return player
    end

    function game.visible()
        return true
    end

    function game.actor_at(_, _, x, y)
        if x == 6 and y == 5 then
            return ally
        end

        return nil
    end

    function game.walkable()
        return true
    end

    function game.cell()
        return terrain.DNGN_FLOOR
    end

    return game
end

-- Casting removes old clouds and later placement stays blocked until the
-- actor-owned aura ends. The old cloud does not return after expiry.
function test.run(ctx)
    local caster = ctx:create()
    local ally = ctx:create()
    local player = ctx:create()
    local cloud = ctx:create()

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })

    ctx:add(caster, component.POSITION, {
        level_id = 1,
        x = 5,
        y = 5,
    })

    ctx:add(caster, component.HEALTH, {
        current = 30,
        max = 30,
    })

    ctx:add(ally, component.ACTOR, {
        kind_id = monsters.MONS_FIRE_ELEMENTAL,
        speed = 10,
    })

    -- Elemental immunity reads a live actor profile, which requires HP.
    ctx:add(ally, component.HEALTH, {
        current = 30,
        max = 30,
    })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 8,
        y = 5,
    })

    ctx:add(cloud, component.WORLD_CLOUD, {
        kind_id = clouds.CLOUD_FIRE,
        level_id = 1,
        x = 6,
        y = 5,
        decay_aut = 100,
    })

    local game = level_context(ctx, player, ally)
    local effect = effects.effect(spells.SPELL_STILL_WINDS)
    local plan = effect.plan(game, caster, player)

    harness.falsy(plan,
        "fire-immune ally does not need a cloud-clearing cast")

    ctx:set(ally, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    plan = effect.plan(game, caster, player)

    harness.truthy(plan,
        "hazardous cloud on an ally makes Still Winds useful")

    effect.resolve(game, caster, player, nil, plan)

    harness.truthy(wind.active_level(game, 1),
        "actor status suppresses the entire current level")
    harness.falsy(ctx:get(cloud, component.WORLD_CLOUD),
        "the source cast clears existing cloud entities")
    harness.falsy(placement.place(game, clouds.CLOUD_FIRE,
        caster, 1, 7, 5, 50),
        "ordinary new clouds cannot form under Still Winds")

    wind.tick(game, caster, 1000)

    harness.falsy(wind.active_level(game, 1),
        "expiry restores ordinary cloud generation")
    harness.falsy(ctx:get(cloud, component.WORLD_CLOUD),
        "expired wind does not resurrect removed clouds")

    local shelter = ctx:create()

    ctx:add(shelter, component.WORLD_CLOUD, {
        kind_id = clouds.CLOUD_PETRIFY,
        level_id = 1,
        x = 7,
        y = 5,
        opaque = true,
        decay_aut = 100,
    })

    mutation_records.grant_acquired(game, player,
        mutations.MUT_PETRIFICATION_RESISTANCE, 1)

    harness.truthy(effect.plan(game, caster, player),
        "cloud-specific immunity lets an opaque cloud shelter the player")
end

return test
