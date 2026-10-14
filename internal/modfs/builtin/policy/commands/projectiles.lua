local catalog = require("policy.catalog")
local equipment = require("policy.inventory.equipment")
local items = require("policy.inventory.items")
local trajectory = require("policy.combat.trajectory")

local projectiles = {}

local launcher_ammo = {
    MI_NEEDLE = true,
    MI_ARROW = true,
    MI_BOLT = true,
    MI_SLING_BULLET = true,
}

local throw_excluded = {
    MI_ARROW = true,
    MI_BOLT = true,
    MI_SLING_BULLET = true,
}

local function selected_item(ctx, player, firing, item_id)
    local entity = firing and equipment.in_slot(ctx, player, "weapon") or
        (item_id ~= 0 and ctx:entity(item_id) or nil)
    local item = entity and ctx:get(entity, "core.item")
    local carrier = entity and ctx:get(entity, "core.carried_by")

    if not item or not carrier or carrier.holder ~= player then
        return nil, nil, "You are not carrying that item."
    end

    local kind = items.kind(item)
    items.validate(item, kind)

    if firing then
        if not kind.weapon or not launcher_ammo[kind.weapon.ammo_id] then
            return nil, nil, "You are not wielding a ranged weapon."
        end

        return entity, kind, nil
    end

    if kind.class ~= "OBJ_MISSILES" or throw_excluded[kind.id] then
        return nil, nil, "You cannot throw that item."
    end

    local player_state = ctx:get(player, "core.player")
    local species = catalog.get("species", player_state.species_id)

    if kind.id == "MI_JAVELIN" and species.size ~= "SIZE_MEDIUM" and
        species.size ~= "SIZE_LARGE" then
        return nil, nil, "You are too small to throw javelins."
    end

    if kind.id == "MI_LARGE_ROCK" and species.size ~= "SIZE_LARGE" then
        return nil, nil, "You cannot throw large rocks."
    end

    return entity, kind, nil
end

function projectiles.prepare(ctx, player, firing, item_id, dx, dy)
    local entity, _, message = selected_item(ctx, player, firing, item_id)

    if message then
        return { message = message }
    end

    local position = ctx:get(player, "core.position")
    local x = position.x + dx
    local y = position.y + dy

    if dx == 0 and dy == 0 then
        return { message = "Choose a target for your projectile." }
    end

    if math.max(math.abs(dx), math.abs(dy)) > 7 or
        not ctx:visible(position.level_id, position.x, position.y, 7, x, y) then
        return { message = "You cannot see that target." }
    end

    local impact = trajectory.trace(ctx, position.level_id, position.x, position.y, x, y)

    if impact.blocked then
        return { message = "Your shot is blocked." }
    end

    return {
        intent = {
            kind = 13,
            dx = dx,
            dy = dy,
            item_id = entity,
        },
        cost = 10,
    }
end

return projectiles
