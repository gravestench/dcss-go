local navigation = {}
local catalog = require("policy.catalog")
local fighter = require("policy.combat.fighter")

local ordinary_monsters = {
    MONS_RAT = true,
    MONS_QUOKKA = true,
    MONS_FRILLED_LIZARD = true,
    MONS_GIANT_COCKROACH = true,
    MONS_WORM = true,
    MONS_JACKAL = true,
    MONS_ADDER = true,
    MONS_BAT = true,
    MONS_BALL_PYTHON = true,
    MONS_ENDOPLASM = true,
    MONS_DART_SLUG = true,
    MONS_GOBLIN = true,
    MONS_HOBGOBLIN = true,
    MONS_KOBOLD = true,
}

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

    if cell == "+" then
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

        if not actor or not ordinary_monsters[actor.kind_id] then
            error("unsupported player melee target " .. ctx:id(target))
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
    local glyph = downstairs and ">" or "<"
    local missing = downstairs and "There are no stairs down here." or
        "There are no stairs up here."
    local cell = ctx:cell(position.level_id, position.x, position.y)
    local stair = ctx:stair_at(position.level_id, position.x, position.y)

    if cell ~= glyph or not stair then
        return {
            message = missing,
        }
    end

    if stair.unavailable ~= "" then
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
