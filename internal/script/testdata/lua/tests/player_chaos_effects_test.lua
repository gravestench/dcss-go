local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effect_ids = require("constants.chaos_effects")
local effects = require("policy.combat.player_brands.chaos_effects")
local chaos_status = require("policy.combat.player_brands.chaos_status")
local harness = require("tests.harness")
local monsters = require("ids.monsters")

local test = {}

local function floor_cell()
    return "DNGN_FLOOR"
end

local function zero_random()
    return 0
end

function test.run(ctx)
    local rat = ctx:create()
    local definition = catalog.get(categories.MONSTERS, monsters.MONS_RAT)

    ctx:add(rat, component.ACTOR, {
        kind_id = definition.id,
        speed = definition.speed,
    })

    ctx:add(rat, component.HEALTH, {
        current = 10,
        max = 10,
    })

    local hit = {
        attacker = ctx:create(),
        defender = rat,
        definition = definition,
        damage_done = 1,
        health = ctx:get(rat, component.HEALTH),
    }

    effects.apply_named(ctx, effect_ids.HASTE, hit)

    local status = ctx:get(rat, component.MONSTER_CHAOS)

    harness.truthy(status and status.haste_aut > 0,
        "chaos haste changes the defender's saved actor state")

    ctx:add(rat, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    local proxy = setmetatable({}, { __index = ctx })
    proxy.cell = floor_cell
    proxy.random = zero_random

    hit.damage_done = 1000
    effects.apply_named(proxy, effect_ids.POLYMORPH, hit)

    local actor = ctx:get(rat, component.ACTOR)

    harness.truthy(actor.kind_id ~= monsters.MONS_RAT,
        "chaos polymorph changes the defender kind")

    local second = ctx:create()

    ctx:add(second, component.ACTOR, {
        kind_id = definition.id,
        speed = definition.speed,
    })

    ctx:add(second, component.HEALTH, {
        current = 10,
        max = 10,
    })

    local other_hit = {
        attacker = hit.attacker,
        defender = second,
        definition = definition,
        damage_done = 1,
        health = ctx:get(second, component.HEALTH),
    }

    effects.apply_named(ctx, effect_ids.RAGE, other_hit)
    effects.apply_named(ctx, effect_ids.MIGHT, other_hit)
    effects.apply_named(ctx, effect_ids.AGILITY, other_hit)
    effects.apply_named(ctx, effect_ids.INVISIBLE, other_hit)
    effects.apply_named(ctx, effect_ids.SLOW, other_hit)
    effects.apply_named(ctx, effect_ids.PARALYSIS, other_hit)
    effects.apply_named(ctx, effect_ids.PETRIFY, other_hit)

    harness.truthy(ctx:has(second, component.MONSTER_ALLEGIANCE),
        "chaos rage adds saved frenzy")
    harness.truthy(ctx:has(second, component.MONSTER_ENCHANT),
        "chaos invisibility adds saved enchantment")
    harness.truthy(ctx:has(second, component.PROJECTILE_SLOW),
        "chaos slow changes later monster turns")
    harness.truthy(ctx:has(second, component.PARALYSIS),
        "chaos paralysis prevents monster actions")
    harness.truthy(ctx:has(second, component.MONSTER_STASIS),
        "chaos petrify adds staged petrification")

    local shifter = ctx:create()

    ctx:add(shifter, component.ACTOR, {
        kind_id = definition.id,
        speed = definition.speed,
    })

    ctx:add(shifter, component.HEALTH, {
        current = 10,
        max = 10,
    })

    ctx:add(shifter, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 2,
    })

    effects.apply_named(proxy, effect_ids.SHIFTER, {
        attacker = hit.attacker,
        defender = shifter,
        definition = definition,
        damage_done = 1,
        health = ctx:get(shifter, component.HEALTH),
    })

    harness.truthy(ctx:get(shifter, component.ACTOR).kind_id ~=
        monsters.MONS_RAT,
        "chaos shifter transforms immediately without a will check")

    local first_shape = ctx:get(shifter, component.ACTOR).kind_id

    chaos_status.shift(proxy, shifter)

    harness.truthy(ctx:get(shifter, component.ACTOR).kind_id ~= first_shape,
        "a chaos shapeshifter can transform on a later monster turn")
end

return test
