local navigation = {}
local catalog = require("policy.catalog")
local fighter = require("policy.combat.fighter")
local abyss = require("policy.world.abyss")
local component = require("constants.component")

local function rooted(ctx)
    local form = ctx:get(ctx:player(), component.PLAYER_FORM)

    return form and form.form_id == "tree" and
        form.remaining_aut > 0
end

function navigation.move(ctx, position, dx, dy)
    if dx < -1 or dx > 1 or dy < -1 or dy > 1 or (dx == 0 and dy == 0) then
        return {
            message = "Invalid movement direction.",
        }
    end

    local x = position.x + dx
    local y = position.y + dy
    local cell = ctx:cell(position.level_id, x, y)

    if not cell then
        return {
            message = "You cannot move there.",
        }
    end

    if rooted(ctx) and not ctx:actor_at(position.level_id, x, y) then
        return {
            message = "Your roots keep you in place.",
        }
    end

    if cell == "DNGN_CLOSED_DOOR" then
        return {
            intent = {
                kind = 8,
                dx = dx,
                dy = dy,
            },
            cost = 10,
        }
    end

    if not ctx:walkable(position.level_id, x, y) then
        return {
            message = "You cannot move there.",
        }
    end

    local target = ctx:actor_at(position.level_id, x, y)

    if target then
        local actor = ctx:get(target, "core.actor")

        if not actor then
            error("player melee target has no actor " .. ctx:id(target))
        end

        local attack = fighter.attack(ctx, catalog.get("monsters", actor.kind_id))

        if attack.weapon_plus < -100 or attack.weapon_plus > 100 then
            error("invalid Fighter attack weapon enchantment")
        end
    end

    return {
        intent = {
            kind = 1,
            dx = dx,
            dy = dy,
        },
        cost = 10,
        attack_target = target,
    }
end

function navigation.stairs(ctx, position, downstairs)
    if rooted(ctx) then
        return {
            message = "Your roots keep you in place.",
        }
    end

    local glyph = downstairs and "DNGN_STONE_STAIRS_DOWN_I" or
        "DNGN_STONE_STAIRS_UP_I"
    local missing = downstairs and "There are no stairs down here." or
        "There are no stairs up here."
    local cell = ctx:cell(position.level_id, position.x, position.y)
    local stair = ctx:stair_at(position.level_id, position.x, position.y)

    if cell ~= glyph or not stair then
        return {
            message = missing,
        }
    end

    local abyss_exit = position.level_id == abyss.level_id and not downstairs and
        ctx:has(ctx:player(), "world.banishment")

    if stair.unavailable ~= "" and not abyss_exit then
        return {
            message = stair.unavailable,
        }
    end

    return {
        intent = {
            kind = downstairs and 5 or 4,
        },
        cost = 10,
    }
end

return navigation
