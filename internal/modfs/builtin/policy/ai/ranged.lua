local common = require("policy.ai.common")
local equipment = require("policy.ai.equipment")

local ranged = {}

local valid_sling_brands = {
    SPWPN_NORMAL = true,
    SPWPN_FLAMING = true,
    SPWPN_FREEZING = true,
    SPWPN_VORPAL = true,
}

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function goblin_sling(ctx, monster)
    local item_entity, item, kind = equipment.find(ctx, monster, "weapon")

    if not kind or kind.id ~= "WPN_SLING" then
        return nil
    end

    if not kind.weapon or not contains(kind.weapon.damage_flags, "DAMV_NON_MELEE") then
        error("goblin has invalid sling definition")
    end

    if item.ego ~= "" and not valid_sling_brands[item.ego] then
        error("unsupported goblin sling brand " .. item.ego)
    end

    return item_entity
end

local function kobold_missile(ctx, monster)
    local item_entity, item, kind = equipment.find(ctx, monster, "missile")

    if not kind then
        return nil
    end

    local stone = kind.id == "MI_STONE" and item.ego == ""
    local dart = kind.id == "MI_DART" and item.ego == "poisoned"

    if not stone and not dart then
        error("unsupported kobold missile " .. kind.id .. "/" .. item.ego)
    end

    if kind.class ~= "OBJ_MISSILES" or not kind.missile then
        error("invalid kobold missile definition " .. kind.id)
    end

    return item_entity
end

function ranged.choose_sling(ctx, monster, position, player)
    local actor = ctx:get(monster, "core.actor")

    if not actor or actor.kind_id ~= "MONS_GOBLIN" or common.adjacent(position, player) then
        return nil
    end

    local item_entity = goblin_sling(ctx, monster)

    if not item_entity then
        return nil
    end

    local roll = ctx:random("ai", 5)

    if roll == 0 or
        not ctx:projectile_clear(position.level_id, position.x, position.y, player.x, player.y) then
        return nil
    end

    return {
        kind = 13,
        item_id = item_entity,
    }
end

function ranged.choose_throw(ctx, monster, position, player)
    local actor = ctx:get(monster, "core.actor")

    if not actor or actor.kind_id ~= "MONS_KOBOLD" or common.adjacent(position, player) then
        return nil
    end

    local item_entity = kobold_missile(ctx, monster)

    if not item_entity then
        return nil
    end

    local roll = ctx:random("ai", 3)

    if roll ~= 0 or
        not ctx:projectile_clear(position.level_id, position.x, position.y, player.x, player.y) then
        return nil
    end

    return {
        kind = 13,
        item_id = item_entity,
    }
end

return ranged
