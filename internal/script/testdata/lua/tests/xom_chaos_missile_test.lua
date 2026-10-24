-- Chaotic ammunition uses the ranged source table after an ordinary hit.
-- It must draw a brand by weight, independent of file discovery order.
local chaos = require("policy.combat.chaos_missile")
local missile_effects = require("policy.combat.monster_missile_egos")
local melee_brands = require("policy.combat.brands")
local component = require("constants.component")
local catalog = require("policy.catalog")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local ranged_fixture = require("tests.fixtures.ranged_reflection")
local harness = require("tests.harness")
local items = require("ids.items")
local target_brands = require("policy.combat.monster_target_brands")
local missile_egos = require("constants.missile_egos")
local monsters = require("ids.monsters")
local projectile_effects = require("policy.combat.projectile_effects")
local ranged_actions = require("policy.combat.ranged_actions")
local streams = require("constants.rng_streams")
local weapon_brands = require("constants.weapon_brands")

local test = {}

-- The first and last bands exercise both ends of source's 59-weight table.
function test.run(ctx)
    local owner = fixture.observed_context(ctx)
    local draw = 0

    function owner:random(stream, bound)
        harness.equal(stream, streams.MELEE)

        if bound == 59 then
            return draw
        end

        return 0
    end

    harness.equal(chaos.choose(owner), missile_egos.FLAME)
    draw = 58
    harness.equal(chaos.choose(owner), missile_egos.DISPERSAL)

    -- A chaos stone is resolved through the same post-hit path as a
    -- normal player-thrown missile. The first band deals fire bonus damage.
    draw = 0

    local monster = fixture.actor(ctx, monsters.MONS_GNOLL, 9, 7, 12)
    local stone = catalog.get("items", items.MI_STONE)
    local definition = catalog.get("monsters", monsters.MONS_GNOLL)
    local extra = projectile_effects.missile(owner,
        missile_egos.CHAOS, stone, monster, definition, 5, 7)

    harness.equal(extra, 1)

    -- The monster-facing path applies the chosen brand to the real player
    -- health component after the base projectile hit.
    local battle, player, shooter = ranged_fixture.scene(ctx,
        items.MI_STONE, false, nil, false)

    function battle.random(_, stream, bound)
        harness.equal(stream, streams.MELEE)
        return 0
    end

    local shooter_definition = catalog.get("monsters",
        monsters.MONS_GOBLIN)

    missile_effects.apply_player(battle, shooter,
        shooter_definition, stone, missile_egos.CHAOS, 5)
    harness.equal(ctx:get(player, component.HEALTH).current, 19)

    -- Exercise the real monster action boundary with an upgraded stack.
    -- A hit must apply an additional Chaos result and keep the saved ego.
    local ranged, victim, thrower, ammo = ranged_fixture.scene(ctx,
        items.MI_STONE, false, nil, false)
    local stack = ctx:get(ammo, component.ITEM)

    stack.ego = missile_egos.CHAOS
    ctx:set(ammo, component.ITEM, stack)
    ctx:set(victim, component.HEALTH, {
        current = 100,
        max = 100,
    })

    function ranged.random(_, stream, bound)
        harness.equal(stream, streams.MELEE)

        if bound == 59 or bound == 3 or bound == 100 then
            return 0
        end

        if bound == 2 then
            return 1
        end

        return bound - 1
    end

    ranged_actions.monster(ranged, thrower, { item_id = ammo })
    harness.truthy(ctx:get(victim, component.HEALTH).current < 100)
    harness.equal(ctx:get(ammo, component.ITEM).ego,
        missile_egos.CHAOS)

    -- Reflection reverses attacker and defender. A returned chaos stone
    -- therefore draws a monster-facing effect against its original thrower.
    local normal, _, normal_shooter, normal_stone =
        ranged_fixture.scene(ctx, items.MI_STONE, true)

    ranged_fixture.block_then_return(normal)
    ranged_actions.monster(normal, normal_shooter, {
        item_id = normal_stone,
    })

    local normal_hp = ctx:get(normal_shooter,
        component.HEALTH).current
    local reflected, _, chaos_shooter, chaos_stone =
        ranged_fixture.scene(ctx, items.MI_STONE, true)
    local chaos_stack = ctx:get(chaos_stone, component.ITEM)

    chaos_stack.ego = missile_egos.CHAOS
    ctx:set(chaos_stone, component.ITEM, chaos_stack)
    ranged_fixture.block_then_return(reflected)

    local standard_random = reflected.random

    function reflected.random(game, stream, bound)
        if bound == 59 or bound == 3 then
            return 0
        end

        return standard_random(game, stream, bound)
    end

    ranged_actions.monster(reflected, chaos_shooter, {
        item_id = chaos_stone,
    })
    harness.equal(ctx:get(chaos_shooter, component.HEALTH).current,
        normal_hp - 1)

    -- A player who picks up a chaos launcher reuses the same monster
    -- target brand owner instead of acquiring a second ranged-only table.
    local launcher_context, archer, target = ranged_fixture.scene(ctx,
        items.MI_STONE, false, nil, false)

    ctx:add(archer, component.RELIGION_WORSHIP, {
        god_id = gods.NO_GOD,
    })

    function launcher_context.random()
        return 0
    end

    local target_definition = catalog.get("monsters",
        monsters.MONS_GOBLIN)
    local target_health = ctx:get(target, component.HEALTH)

    target_brands.apply(launcher_context, weapon_brands.CHAOS, {
        attacker = archer,
        attacker_name = "you",
        defender = target,
        definition = target_definition,
        damage_done = 5,
        health = target_health,
        projectile_name = stone.name,
        player_credit = true,
    })
    harness.equal(ctx:get(target, component.HEALTH).current, 39)

    -- The same item brand on a monster's melee weapon resolves against
    -- the player rather than failing when the first attack lands.
    local melee, melee_player, melee_monster = ranged_fixture.scene(ctx,
        items.MI_STONE, false, nil, false)

    function melee.random()
        return 0
    end

    melee_brands.apply(melee, weapon_brands.CHAOS, 5,
        monsters.MONS_GOBLIN, "goblin",
        ctx:get(melee_player, component.HEALTH), melee_monster)
    harness.equal(ctx:get(melee_player, component.HEALTH).current, 19)
end

return test
