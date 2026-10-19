local brands = require("constants.weapon_brands")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local player_brands = require("policy.combat.player_brands")
local fixture = require("tests.monster_ally_support_fixture")

local test = {}

-- Give each defender ten HP so brand side effects can be separated from
-- ordinary weapon damage and death cleanup.
local function zero_damage_target(ctx, kind_id)
    local target = ctx:create()
    local definition = catalog.get("monsters", kind_id)

    ctx:add(target, component.ACTOR, {
        kind_id = kind_id,
        speed = definition.speed,
    })
    ctx:add(target, component.HEALTH, {
        current = 10,
        max = 10,
    })

    return target, definition
end

-- Fix the combat-stream poison roll while leaving ECS state live.
local function poison_rolls(ctx)
    local proxy = setmetatable({}, { __index = ctx })

    -- Use melee-stream poison rolls at the proc and damage bounds separately.
    function proxy.random(_, stream, bound)
        harness.equal(stream, "melee", "poison brand uses combat RNG")

        if bound == 4 then
            return 1
        end

        return 0
    end

    return proxy
end

-- Compare zero-damage brand gates and named melee draws on identical target records.
function test.run(base)
    local ctx = fixture.observed_context(base)
    local attacker = ctx:create()
    local rat, rat_definition = zero_damage_target(ctx,
        monsters.MONS_RAT)
    local hit = {
        attacker = attacker,
        defender = rat,
        definition = rat_definition,
        damage_done = 0,
        health = ctx:get(rat, component.HEALTH),
    }

    -- A no-damage elemental hit must not even request a random draw.
    player_brands.apply({}, brands.FLAMING, hit)
    harness.equal(ctx:get(rat, component.HEALTH).current, 10,
        "zero base damage prevents flaming damage")

    player_brands.apply(poison_rolls(ctx), brands.VENOM, hit)
    harness.truthy(ctx:has(rat, component.PROJECTILE_POISON),
        "venom can poison after a zero-damage contact")

    -- Venom may poison after a zero-damage contact, except on immune undead.
    local undead, undead_definition = zero_damage_target(ctx,
        monsters.MONS_WIGHT)
    local immune_hit = {
        attacker = attacker,
        defender = undead,
        definition = undead_definition,
        damage_done = 0,
        health = ctx:get(undead, component.HEALTH),
    }

    player_brands.apply(poison_rolls(ctx), brands.VENOM, immune_hit)
    harness.falsy(ctx:has(undead, component.PROJECTILE_POISON),
        "undead poison immunity blocks the brand")

    local profane, profane_definition = zero_damage_target(ctx,
        monsters.MONS_PROFANE_SERVITOR)
    local holy_hit = {
        attacker = attacker,
        defender = profane,
        definition = profane_definition,
        damage_done = 5,
        health = ctx:get(profane, component.HEALTH),
    }

    player_brands.apply({}, brands.HOLY_WRATH, holy_hit)
    harness.equal(ctx:get(profane, component.HEALTH).current, 10,
        "profane servitor's source holy resistance blocks holy wrath")

    immune_hit.health.current = 0
    player_brands.apply({}, brands.VENOM, immune_hit)
    harness.falsy(ctx:has(undead, component.PROJECTILE_POISON),
        "a dead defender receives no venom effect")

    -- Chaos self-effects cannot enchant an actor already killed by the hit.
    local dead_chaos = setmetatable({}, { __index = ctx })

    -- Force Chaos to retain its self-effect weight while checking the dead-target gate.
    function dead_chaos.random(_, stream, bound)
        harness.equal(stream, "melee", "chaos chooses on the melee stream")
        harness.truthy(bound >= 41, "chaos retains the self-effect weight")

        return 40
    end

    hit.health.current = 0
    player_brands.apply(dead_chaos, brands.CHAOS, hit)
    harness.falsy(ctx:has(rat, component.MONSTER_ENCHANT),
        "a chaos self-effect cannot enchant a dead defender")
end

return test
