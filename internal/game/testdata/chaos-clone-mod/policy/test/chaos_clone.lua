local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local effect_ids = require("constants.chaos_effects")
local effects = require("policy.combat.player_brands.chaos_effects")
local abyss = require("policy.world.abyss")
local net = require("policy.combat.net")
local items = require("ids.items")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")
local monster_health = require("policy.combat.monster_health")
local monster_slow = require("policy.combat.monster_slow")

local policy = {}

function policy.run(ctx)
    local target

    for _, entity in ipairs(ctx:query({ component.AI })) do
        target = entity
        break
    end

    if not target then
        error("chaos clone fixture has no monster")
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    effects.apply_named(ctx, effect_ids.CLONE, {
        attacker = ctx:player(),
        defender = target,
        definition = definition,
        damage_done = 1,
        health = ctx:get(target, component.HEALTH),
    })

    return {}
end

function policy.haste(ctx)
    local target

    for _, entity in ipairs(ctx:query({ component.AI })) do
        target = entity
        break
    end

    if not target then
        error("chaos haste fixture has no monster")
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    effects.apply_named(ctx, effect_ids.HASTE, {
        attacker = ctx:player(),
        defender = target,
        definition = definition,
        damage_done = 1,
        health = ctx:get(target, component.HEALTH),
    })

    return {}
end

function policy.banish_netted(ctx)
    local target

    for _, entity in ipairs(ctx:query({ component.AI })) do
        target = entity
        break
    end

    if not target then
        error("banishment fixture has no monster")
    end

    local position = ctx:get(target, component.POSITION)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local net_item = ctx:create()

    ctx:add(net_item, component.ITEM, {
        kind_id = items.MI_THROWING_NET,
        quantity = 1,
    })

    ctx:add(net_item, component.POSITION, position)
    net.catch(ctx, target, net_item, definition)
    abyss.banish_monster(ctx, target, definition)

    return {}
end

function policy.clone_summon(ctx)
    local player = ctx:player()
    local target = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_SMALL_MAMMAL, monsters.MONS_BAT, 1, 4)

    if not target then
        error("summoned chaos clone fixture has no open cell")
    end

    local definition = catalog.get(categories.MONSTERS, monsters.MONS_BAT)

    effects.apply_named(ctx, effect_ids.CLONE, {
        attacker = player,
        defender = target,
        definition = definition,
        damage_done = 1,
        health = ctx:get(target, component.HEALTH),
    })

    return {}
end

function policy.damage_spectral(ctx)
    local spectral
    local attacker

    for _, entity in ipairs(ctx:query({ component.AI })) do
        if ctx:has(entity, component.SPECTRAL_WEAPON) then
            spectral = entity
        else
            attacker = entity
        end
    end

    if not spectral or not attacker then
        error("spectral damage fixture lacks an ally or attacker")
    end

    monster_health.damage(ctx, spectral, 8, attacker)

    return {}
end

function policy.banish_follower(ctx)
    local target

    for _, entity in ipairs(ctx:query({ "core.follower" })) do
        target = entity
        break
    end

    if not target then
        error("banishment fixture has no jackal follower")
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    abyss.banish_monster(ctx, target, definition)

    return {}
end

function policy.clone_slowed(ctx)
    local target

    for _, entity in ipairs(ctx:query({ component.AI })) do
        target = entity
        break
    end

    if not target then
        error("slow clone fixture has no monster")
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    monster_slow.apply(ctx, target, definition)
    effects.apply_named(ctx, effect_ids.CLONE, {
        attacker = ctx:player(),
        defender = target,
        definition = definition,
        damage_done = 1,
        health = ctx:get(target, component.HEALTH),
    })

    return {}
end

function policy.kill_clone(ctx)
    local clone

    for _, entity in ipairs(ctx:query({ component.CHAOS_CLONE })) do
        clone = entity
        break
    end

    if not clone then
        error("chaos reward fixture has no clone")
    end

    local health = ctx:get(clone, component.HEALTH)

    health.current = 0
    ctx:set(clone, component.HEALTH, health)
    ctx:signal("player_kill", clone)

    return {}
end

function policy.clone_geared(ctx)
    local target

    for _, entity in ipairs(ctx:query({ component.AI })) do
        target = entity
        break
    end

    if not target then
        error("geared chaos clone fixture has no monster")
    end

    local weapon = ctx:create()

    ctx:add(weapon, component.ITEM, {
        kind_id = items.WPN_DAGGER,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })

    ctx:add(weapon, component.CARRIED_BY, { holder = target })
    ctx:add(weapon, component.EQUIPPED, { slot = "weapon" })

    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    effects.apply_named(ctx, effect_ids.CLONE, {
        attacker = ctx:player(),
        defender = target,
        definition = definition,
        damage_done = 1,
        health = ctx:get(target, component.HEALTH),
    })

    return {}
end

register.policy({
    id = "test.chaos_clone",
    run = policy.run,
})

register.policy({
    id = "test.chaos_haste",
    run = policy.haste,
})

register.policy({
    id = "test.banish_netted",
    run = policy.banish_netted,
})

register.policy({
    id = "test.clone_summon",
    run = policy.clone_summon,
})

register.policy({
    id = "test.damage_spectral",
    run = policy.damage_spectral,
})

register.policy({
    id = "test.banish_follower",
    run = policy.banish_follower,
})

register.policy({
    id = "test.clone_slowed",
    run = policy.clone_slowed,
})

register.policy({
    id = "test.kill_clone",
    run = policy.kill_clone,
})

register.policy({
    id = "test.clone_geared",
    run = policy.clone_geared,
})

return policy
