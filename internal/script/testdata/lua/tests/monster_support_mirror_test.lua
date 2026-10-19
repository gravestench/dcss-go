local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local mirror = require("policy.combat.monster_support.injury_mirror")
local monster_health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- The isolated harness has no host clock; its ECS components still carry
-- the production saved state and the test controls only absolute aut.
local function timed_context(ctx)
    local game = setmetatable({}, { __index = ctx })
    local now = 0

    function game.aut()
        return now
    end

    function game.advance(to_aut)
        now = to_aut
    end

    return game
end

-- Both participants use real monster HP so returned damage can be checked
-- without replacing the production damage and death paths.
local function monster(ctx)
    local entity = ctx:create()

    ctx:add(entity, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })

    ctx:add(entity, component.HEALTH, {
        current = 100,
        max = 100,
    })

    return entity
end

-- Injury Mirror reflects two thirds of direct HP loss once, then respects
-- its separate absolute recast clock after the aura expires.
function test.run(ctx)
    local game = timed_context(fixture.observed_context(ctx))
    local caster = monster(ctx)
    local attacker = monster(ctx)
    local effect = effects.effect(spells.SPELL_INJURY_MIRROR)
    local plan = effect.plan(game, caster)

    effect.resolve(game, caster, attacker, nil, plan)

    harness.truthy(mirror.active(game, caster),
        "the mirror aura has a saved duration")
    harness.equal(ctx:get(caster, component.MONSTER_INJURY_MIRROR).recast_at_aut,
        150, "recast clock starts from absolute game aut")

    monster_health.damage(game, caster, 30, attacker)

    harness.equal(ctx:get(caster, component.HEALTH).current, 70,
        "ordinary damage still reaches the mirrored monster")
    harness.equal(ctx:get(attacker, component.HEALTH).current, 80,
        "two thirds of dealt damage returns to its source")

    mirror.tick(game, caster, 70)

    harness.falsy(mirror.active(game, caster),
        "the mirror aura expires independently of recast")
    harness.falsy(effect.plan(game, caster),
        "the caster cannot immediately recast after expiry")

    game.advance(150)

    harness.truthy(effect.plan(game, caster),
        "the slot becomes useful when its source recast time arrives")
end

return test
