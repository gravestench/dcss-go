local common = require("policy.ai.common")
local equipment = require("policy.ai.equipment")
local projectiles = require("policy.combat.monster_projectiles")
local ammunition = require("ids.ammunition")

local ranged = {}

-- Only launchers with a supported ammo class enter the ranged path.
local function ranged_weapon(kind)
    local weapon = kind and kind.weapon

    if not weapon or weapon.ammo_id == ammunition.NONE then
        return false
    end

    for _, flag in ipairs(weapon.damage_flags or {}) do
        if flag == "DAMV_NON_MELEE" then
            return true
        end
    end

    return false
end

-- Trace the projectile corridor before AI commits to firing.
local function clear_distant_shot(ctx, position, player)
    return not common.adjacent(position, player) and
        ctx:projectile_clear(position.level_id, position.x, position.y,
            player.x, player.y)
end

-- Prefer a wielded launcher at nonadjacent range, then reject ammo or trajectories that cannot hit.
-- Example: ranged.choose_launcher(ctx, monster, position, player) rejects blocked distant shots.
function ranged.choose_launcher(ctx, monster, position, player)
    if common.adjacent(position, player) then
        return nil, false
    end

    local item_entity, item, kind = equipment.find(ctx, monster, "weapon")

    if not ranged_weapon(kind) then
        item_entity, item, kind = equipment.find(ctx, monster, "alternate_weapon")
    end

    if not ranged_weapon(kind) then
        return nil, false
    end

    local effect = projectiles.effect(kind.weapon.ammo_id)

    if not effect.resolve_launcher then
        error("unsupported monster launcher ammo " .. kind.weapon.ammo_id)
    end

    effect.validate_launcher(item)

    -- Preserve the current roster's ranged choice roll before tracing.
    if ctx:random("ai", 5) == 0 or not clear_distant_shot(ctx, position, player) then
        return nil, true
    end

    return {
        kind = 13,
        item_id = item_entity,
    }, true
end

-- Thrown inventory is considered only after range and line checks pass.
function ranged.choose_throw(ctx, monster, position, player)
    if common.adjacent(position, player) then
        return nil
    end

    local item_entity, item, kind = equipment.find(ctx, monster, "missile")

    if not kind then
        return nil
    end

    if kind.class ~= "OBJ_MISSILES" or not kind.missile or item.quantity <= 0 then
        error("monster has invalid ranged missile " .. kind.id)
    end

    projectiles.effect(kind.id).validate(item, kind.id)

    -- Ordinary monster shots consume no stack item; nets are a source exception.
    if ctx:random("ai", 3) ~= 0 or not clear_distant_shot(ctx, position, player) then
        return nil
    end

    return {
        kind = 13,
        item_id = item_entity,
    }
end

return ranged
