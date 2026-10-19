-- Source mon-cast.cc casts Portal Projectile by making a real monster
-- throw with teleport delivery. The equipped weapon or missile keeps its
-- ordinary contact, brand, reflection, and damage rules; only its travel
-- corridor is skipped. The player spell instead grants a timed status.
local component = require("constants.component")
local equipment = require("policy.combat.equipment")
local projectiles = require("policy.combat.monster_projectiles")
local ranged = require("policy.combat.ranged_actions")
local target = require("policy.combat.monster_spell_target")
local target_kind = require("constants.target_kind")
local item_classes = require("constants.item_classes")
local catalog = require("policy.catalog")
local monster_flags = require("constants.monster_flags")

local effect = {}
local SIGHT_RADIUS = 7

-- Source M_PREFER_RANGED archers can launch a portal shot in melee reach.
local function can_shoot_adjacent(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition and definition.flags or {}) do
        if flag == monster_flags.PREFER_RANGED then
            return true
        end
    end

    return false
end

-- Select from the monster's live equipped slots. An alternate launcher is
-- valid even when the primary weapon is melee; ranged action swaps it first.
local function projectile_item(ctx, caster)
    local worn = equipment.worn(ctx, caster, {
        weapon = true,
        alternate_weapon = true,
        missile = true,
    })

    for _, slot in ipairs({ "weapon", "alternate_weapon" }) do
        local entry = worn[slot]
        local weapon = entry and entry.definition.weapon

        if weapon and weapon.ammo_id and
            projectiles.effect(weapon.ammo_id).resolve_launcher then
            return entry.entity
        end
    end

    local missile = worn.missile

    if missile and missile.definition.class == item_classes.MISSILES and
        missile.item.quantity > 0 then
        return missile.entity
    end

    return nil
end

-- Check visibility but deliberately avoid projectile_clear: the source
-- teleport throw can arrive beyond a wall. Empty hands cannot cast it.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)
    local health = foe and ctx:get(foe, component.HEALTH)
    local close = source and destination and
        math.abs(source.x - destination.x) <= 1 and
        math.abs(source.y - destination.y) <= 1

    if not source or not destination or not health or
        health.current <= 0 or source.level_id ~= destination.level_id or
        (close and not can_shoot_adjacent(ctx, caster)) or
        foe ~= ctx:player() or not projectile_item(ctx, caster) or
        not ctx:visible(source.level_id, source.x, source.y,
            SIGHT_RADIUS, destination.x, destination.y) then
        return nil
    end

    return {
        kind = target_kind.ENTITY,
        entity = foe,
    }
end

-- Gear can change between planning and execution. Re-read the slot, then
-- let the existing ranged owner perform the physical attack in portal mode.
function effect.resolve(ctx, caster, foe, _, plan)
    target.require_entity(plan, foe)

    local item = projectile_item(ctx, caster)

    if not item then
        return
    end

    ranged.monster(ctx, caster, { item_id = item }, { portal = true })
end

return effect
