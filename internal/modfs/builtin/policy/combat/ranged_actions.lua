local catalog = require("policy.catalog")
local brands = require("policy.combat.brands")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")
local items = require("policy.inventory.items")
local practice = require("policy.combat.practice")
local projectiles = require("policy.combat.monster_projectiles")
local reflection = require("policy.combat.reflection")
local monster_poison = require("policy.combat.monster_poison")
local launcher_brands = require("policy.combat.launcher_brands")
local player_health = require("policy.combat.player_health")
local jelly = require("policy.mutations.effects.projectiles.jelly_missile")
local classes = require("constants.item_classes")
local categories = require("constants.catalog")
local artefact_properties = require("policy.item_generation.artefacts.properties")
local artefact_ids = require("ids.artefact_properties")

local actions = {}

-- Copy the weapon profile before applying artefact properties so catalog data stays immutable.
local function launcher_profile(ctx, launcher)
    local source = launcher.definition.weapon
    local profile = {}

    for name, value in pairs(source) do
        profile[name] = value
    end

    profile.damage = profile.damage + artefact_properties.value(ctx,
        launcher.entity, artefact_ids.BASE_DAMAGE)
    profile.hit = profile.hit + artefact_properties.value(ctx,
        launcher.entity, artefact_ids.BASE_ACCURACY)
    profile.speed = profile.speed + artefact_properties.value(ctx,
        launcher.entity, artefact_ids.BASE_DELAY)

    return profile
end

-- A monster in melee reach uses melee policy, even on a diagonal.
local function adjacent(a, b)
    return a.level_id == b.level_id and
        math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1
end

-- Reject invalid ranged intent before any hit or damage RNG, then snapshot player defence.
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

-- Persist shield block count before HP damage so repeated projectiles use current block state.
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

-- A shield block and zero-damage hit need distinct player-facing outcomes.
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

-- A reflectable blocked launcher shot reuses its projectile and brand against the shooter.
local function return_launcher(ctx, attacker, launcher, definition,
    projectile, effect, outcome)
    if outcome.kind ~= "block" or not effect.reflectable or
        not reflection.active(ctx, ctx:player()) then
        return
    end

    local defense = reflection.return_defense(ctx, attacker,
        definition, true)

    if not defense then
        return
    end

    reflection.begin(ctx, projectile.name)

    local weapon = launcher_profile(ctx, launcher)
    local rebound = effect.resolve_launcher(ctx, attacker, definition,
        defense, weapon, launcher.item, projectile)
    local extra = 0
    local extra_message

    if rebound.kind == "hit" then
        extra, extra_message = launcher_brands.apply(ctx,
            launcher.ego or "", projectile, definition, rebound.damage)
    end

    local remaining = reflection.return_outcome(ctx, ctx:player(), attacker,
        definition, projectile.name, rebound)

    if remaining and remaining.current > 0 then
        reflection.extra_damage(ctx, ctx:player(), attacker, extra)
    end

    if extra_message then
        ctx:emit("combat", extra_message)
    end
end

-- Returned missiles can poison the shooter only if the reflected target survives.
local function return_missile(ctx, attacker, definition, kind, effect,
    name, outcome)
    if outcome.kind ~= "block" or not effect.reflectable or
        not reflection.active(ctx, ctx:player()) then
        return
    end

    local defense = reflection.return_defense(ctx, attacker,
        definition, true)

    if not defense then
        return
    end

    reflection.begin(ctx, name)

    local rebound, poison = effect.resolve(ctx, attacker, definition,
        defense, kind)
    local remaining = reflection.return_outcome(ctx, ctx:player(), attacker,
        definition, name, rebound)

    if remaining and remaining.current > 0 and (poison or 0) > 0 then
        monster_poison.apply(ctx, attacker, definition, poison,
            ctx:player(), true)
    end
end

-- Validate ammo against the equipped launcher before resolving damage and after-death brand effects.
local function launcher_attack(ctx, attacker, launcher, definition, defense, health)
    local weapon = launcher_profile(ctx, launcher)
    local projectile = catalog.get(categories.ITEMS, weapon.ammo_id)
    local brand = launcher.ego or ""

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

    return_launcher(ctx, attacker, launcher, definition,
        projectile, effect, outcome)

    if outcome.kind == "hit" and
        (health.current > 0 or brands.after_death(brand)) then
        brands.apply(ctx, brand, outcome.damage, definition.id,
            projectile.name, health)
    end

    if outcome.kind == "hit" then
        jelly.absorb(ctx, ctx:player(), projectile.id, outcome.damage)
    end
end

-- Thrown stacks use their projectile effect, then reflection and poison share the landed outcome.
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

    return_missile(ctx, attacker, definition, kind, effect, name, outcome)

    if poison > 0 then
        brands.poison(ctx, poison, definition.id)
    end

    if outcome.kind == "hit" then
        jelly.absorb(ctx, ctx:player(), kind.id, outcome.damage)
    end
end

-- The weapon swap updates both equipped entities to keep the two slots mutually consistent.
local function swap_launcher(ctx, worn)
    local alternate = worn.alternate_weapon

    ctx:set(alternate.entity, "core.equipped", { slot = "weapon" })

    if worn.weapon then
        ctx:set(worn.weapon.entity, "core.equipped", { slot = "alternate_weapon" })
    end
end

-- Example: actions.monster(ctx, attacker, intent) with monster with equipped Sling -> launcher shot path
-- Monster ranged actions choose equipped launchers or thrown missiles before spending the attack.
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
