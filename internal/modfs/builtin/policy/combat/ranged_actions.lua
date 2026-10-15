local catalog = require("policy.catalog")
local brands = require("policy.combat.brands")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local items = require("policy.inventory.items")
local practice = require("policy.combat.practice")
local projectiles = require("policy.combat.monster_projectiles")
local player_health = require("policy.combat.player_health")
local jelly = require("policy.mutations.effects.projectiles.jelly_missile")
local classes = require("constants.item_classes")
local categories = require("constants.catalog")

local actions = {}

local function adjacent(a, b)
    return a.level_id == b.level_id and
        math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1
end

local function target(ctx, attacker)
    local player = ctx:player()
    local actor = ctx:get(attacker, "core.actor")
    local attack_pos = ctx:get(attacker, "core.position")
    local player_pos = ctx:get(player, "core.position")
    local attack_health = ctx:get(attacker, "core.health")
    local health = ctx:get(player, "core.health")

    if not actor or not attack_pos or not player_pos or not attack_health or
        not health or attack_health.current <= 0 or health.current <= 0 or
        attack_pos.level_id ~= player_pos.level_id or
        adjacent(attack_pos, player_pos) then
        error("monster cannot shoot distant or dead player")
    end

    if not ctx:projectile_clear(attack_pos.level_id, attack_pos.x, attack_pos.y,
        player_pos.x, player_pos.y) then
        error("monster has no clear shot")
    end

    return catalog.get(categories.MONSTERS, actor.kind_id),
        fighter.defense(ctx), health
end

local function apply(ctx, outcome, health, defense, attacker)
    local player = ctx:player()
    local state = ctx:get(player, "core.combat")

    if not state then
        error("player has no combat state")
    end

    state.shield_blocks = outcome.shield_blocks
    ctx:set(player, "core.combat", state)
    local updated = player_health.damage(ctx, player, outcome.damage,
        false, attacker)

    if outcome.kind == "block" then
        practice.incoming_shield(ctx, outcome, defense)
    end

    return updated
end

local function hit_message(name, outcome, include_damage)
    if outcome.kind == "block" then
        return "You block the " .. name .. "."
    end

    if outcome.kind ~= "hit" then
        return "The " .. name .. " misses you."
    end

    if include_damage then
        if outcome.damage == 0 then
            return "The " .. name .. " hits you but does no damage."
        end

        return "The " .. name .. " hits you for " .. outcome.damage .. " damage."
    end

    return "The " .. name .. " hits you."
end

local function launcher_attack(ctx, attacker, launcher, definition, defense, health)
    local weapon = launcher.definition.weapon
    local projectile = catalog.get(categories.ITEMS, weapon.ammo_id)
    local brand = launcher.item.ego or ""

    if projectile.class ~= classes.MISSILES or not projectile.missile then
        error("monster launcher has invalid projectile")
    end

    local effect = projectiles.effect(projectile.id)

    if not effect.resolve_launcher then
        error("unsupported monster launcher ammo " .. projectile.id)
    end

    effect.validate_launcher(launcher.item)
    local outcome = effect.resolve_launcher(ctx, attacker, definition, defense,
        weapon, launcher.item, projectile)

    health = apply(ctx, outcome, health, defense, attacker)
    ctx:emit("combat", "The " .. definition.name .. " shoots " ..
        items.phrase(projectile.name, 1) .. ".")
    ctx:emit("combat", hit_message(projectile.name, outcome, true))

    if outcome.kind == "hit" and
        (health.current > 0 or brands.after_death(brand)) then
        brands.apply(ctx, brand, outcome.damage, definition.id,
            projectile.name, health)
    end

    if outcome.kind == "hit" then
        jelly.absorb(ctx, ctx:player(), projectile.id, outcome.damage)
    end
end

local function missile_attack(ctx, attacker, missile, definition, defense, health)
    local kind = missile.definition
    local item = missile.item

    if item.quantity <= 0 or kind.class ~= classes.MISSILES or not kind.missile then
        error("monster has no matching missile stack")
    end

    local effect = projectiles.effect(kind.id)
    effect.validate(item)
    local outcome, poison, name = effect.resolve(ctx, attacker,
        definition, defense, kind)

    apply(ctx, outcome, health, defense, attacker)

    ctx:emit("combat", "The " .. definition.name .. " throws " ..
        items.phrase(name, 1) .. ".")
    ctx:emit("combat", hit_message(name, outcome, effect.show_damage))

    if poison > 0 then
        brands.poison(ctx, poison, definition.id)
    end

    if outcome.kind == "hit" then
        jelly.absorb(ctx, ctx:player(), kind.id, outcome.damage)
    end
end

local function swap_launcher(ctx, worn)
    local alternate = worn.alternate_weapon

    ctx:set(alternate.entity, "core.equipped", { slot = "weapon" })

    if worn.weapon then
        ctx:set(worn.weapon.entity, "core.equipped", { slot = "alternate_weapon" })
    end
end

function actions.monster(ctx, attacker, intent)
    local definition, defense, health = target(ctx, attacker)
    local worn = equipment.worn(ctx, attacker, {
        weapon = true,
        alternate_weapon = true,
        missile = true,
    })

    if worn.weapon and worn.weapon.entity == intent.item_id then
        launcher_attack(ctx, attacker, worn.weapon, definition, defense, health)

        return
    end

    if worn.alternate_weapon and worn.alternate_weapon.entity == intent.item_id then
        swap_launcher(ctx, worn)
        launcher_attack(ctx, attacker, worn.alternate_weapon,
            definition, defense, health)

        return
    end

    if worn.missile and worn.missile.entity == intent.item_id then
        missile_attack(ctx, attacker, worn.missile, definition, defense, health)

        return
    end

    error("monster ranged intent has no equipped item")
end

return actions
