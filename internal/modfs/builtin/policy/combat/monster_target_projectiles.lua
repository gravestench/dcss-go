-- Theory of operation: Ru can make a hostile monster's committed shot
-- target a monster. The ordinary missile module still supplies contact
-- rolls; this owner replaces player defense, HP, and post-hit effects with
-- their monster equivalents without copying each projectile formula.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local classes = require("constants.item_classes")
local component = require("constants.component")
local equipment = require("policy.combat.equipment")
local exploding = require(
    "policy.combat.monster_missile_egos.exploding")
local item_ids = require("ids.items")
local items = require("policy.inventory.items")
local launcher_brands = require("policy.combat.launcher_brands")
local missile_egos = require("constants.missile_egos")
local monster_defense = require("policy.combat.monster_defense")
local monster_health = require("policy.combat.monster_health")
local monster_poison = require("policy.combat.monster_poison")
local projectiles = require("policy.combat.monster_projectiles")
local projectile_effects = require("policy.combat.projectile_effects")
local ranged_equipment = require(
    "policy.combat.monster_ranged_equipment")
local target_brands = require("policy.combat.monster_target_brands")

local actions = {}

-- Build the defender's current shield, evasion, and armour after Ru has
-- selected it. A self-directed shot skips the monster's own shield.
local function defender_state(ctx, attacker, victim)
    local actor = ctx:get(victim, component.ACTOR)
    local health = ctx:get(victim, component.HEALTH)
    local combat = ctx:get(victim, component.COMBAT)

    if not actor or not health or not combat or health.current <= 0 then
        error("redirected missile has no living monster target")
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local defense = {
        ev = monster_defense.evasion(ctx, victim, definition),
        ac = monster_defense.armour(ctx, victim, definition),
        gdr = 0,
        shield_class = 0,
        shield_blocks = combat.shield_blocks,
        monster_shield = monster_defense.shield(ctx, victim,
            definition),
        skip_shield = attacker == victim,
    }

    return definition, defense
end

-- Shared contact results update the monster's actual HP and block count.
-- A redirected kill by a hostile actor awards no player credit.
local function landed(ctx, attacker, victim, definition, name, outcome)
    if outcome.kind == "block" then
        monster_defense.register_block(ctx, victim)
        ctx:emit(channels.COMBAT, "The " .. definition.name ..
            " blocks the " .. name .. ".")

        return nil
    end

    if outcome.kind ~= "hit" then
        ctx:emit(channels.COMBAT, "The " .. name .. " misses the " ..
            definition.name .. ".")

        return nil
    end

    local health = monster_health.damage(ctx, victim,
        outcome.damage, attacker)

    ctx:emit(channels.COMBAT, "The " .. name .. " hits the " ..
        definition.name .. ".")

    return health
end

-- The real launcher, ammunition, and monster defense still feed the
-- existing projectile-specific contact resolver. A landed weapon brand
-- uses the ordinary monster-target brand owner.
local function launcher(ctx, attacker, victim, attacker_def,
    target_def, defense, item)
    local weapon = ranged_equipment.launcher_profile(ctx, item)
    local projectile = catalog.get(categories.ITEMS, weapon.ammo_id)

    if projectile.class ~= classes.MISSILES or
        not projectile.missile then
        error("redirected launcher has invalid ammunition")
    end

    local effect = projectiles.effect(projectile.id)

    if not effect.resolve_launcher then
        error("unsupported redirected launcher ammo " .. projectile.id)
    end

    effect.validate_launcher(item.item)

    local outcome = effect.resolve_launcher(ctx, attacker,
        attacker_def, defense, weapon, item.item, projectile)

    ctx:emit(channels.COMBAT, "The " .. attacker_def.name .. " shoots " ..
        items.phrase(projectile.name, 1) .. ".")

    local health = landed(ctx, attacker, victim, target_def,
        projectile.name, outcome)
    local brand = item.ego or ""

    if outcome.kind == "hit" and health and
        not launcher_brands.passive(brand) then
        target_brands.apply(ctx, brand, {
            attacker = attacker,
            attacker_name = attacker_def.name,
            defender = victim,
            definition = target_def,
            damage_done = outcome.damage,
            health = health,
            weapon_entity = item.entity,
            projectile_name = projectile.name,
            player_credit = false,
        })
    end
end

-- Thrown coatings and egos run after the base hit against the new actor.
-- Explosion instead uses the impact cell even after a shield block.
local function missile(ctx, attacker, victim, attacker_def,
    target_def, defense, selected)
    local kind = selected.definition
    local item = selected.item

    if item.quantity <= 0 or kind.class ~= classes.MISSILES or
        not kind.missile then
        error("redirected missile stack is invalid")
    end

    local effect = projectiles.effect(kind.id)

    effect.validate(item, kind.id)

    local outcome, poison, name = effect.resolve(ctx, attacker,
        attacker_def, defense, kind, item)

    ctx:emit(channels.COMBAT, "The " .. attacker_def.name .. " throws " ..
        items.phrase(name, 1) .. ".")

    local health = landed(ctx, attacker, victim, target_def,
        name, outcome)
    local ego = item.ego or ""

    if ego == missile_egos.EXPLODING and
        (outcome.kind == "hit" or outcome.kind == "block") then
        local position = ctx:get(victim, component.POSITION)

        exploding.impact(ctx, attacker, position.level_id,
            position.x, position.y)
    end

    if health and health.current > 0 and (poison or 0) > 0 then
        monster_poison.apply(ctx, victim, target_def,
            poison, attacker)
    end

    local poisoned_dart = kind.id == item_ids.MI_DART and
        ego == missile_egos.POISONED

    if not health or health.current <= 0 or ego == "" or
        ego == missile_egos.EXPLODING or poisoned_dart then
        return
    end

    local extra = projectile_effects.missile(ctx, ego,
        kind, victim, target_def, outcome.damage,
        health.current, attacker)

    if extra > 0 then
        monster_health.damage(ctx, victim, extra, attacker)
    end
end

-- Match the saved equipped item selected by AI. A switched launcher
-- updates both slots before firing, as in the player-directed path.
function actions.attack(ctx, attacker, intent, victim)
    local actor = ctx:get(attacker, component.ACTOR)
    local attacker_def = catalog.get(categories.MONSTERS, actor.kind_id)
    local target_def, defense = defender_state(ctx, attacker, victim)
    local worn = equipment.worn(ctx, attacker, {
        weapon = true,
        alternate_weapon = true,
        missile = true,
    })

    if worn.weapon and worn.weapon.entity == intent.item_id then
        launcher(ctx, attacker, victim, attacker_def,
            target_def, defense, worn.weapon)

        return
    end

    if worn.alternate_weapon and
        worn.alternate_weapon.entity == intent.item_id then
        ranged_equipment.swap_launcher(ctx, worn)
        launcher(ctx, attacker, victim, attacker_def,
            target_def, defense, worn.alternate_weapon)

        return
    end

    if worn.missile and worn.missile.entity == intent.item_id then
        missile(ctx, attacker, victim, attacker_def,
            target_def, defense, worn.missile)

        return
    end

    error("redirected monster ranged intent has no equipped item")
end

return actions
