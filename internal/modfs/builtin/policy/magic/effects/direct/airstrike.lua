local damage = require("policy.magic.damage")
local monster_defense = require("policy.combat.monster_defense")
local registry = require("policy.magic.effects.registry")
local target = require("policy.magic.effects.direct.target")

local function cell(ctx, player, dx, dy)
    local position = ctx:get(player, "core.position")

    return position.level_id, position.x + dx, position.y + dy
end

local function prepare(ctx, player, _, dx, dy)
    local level_id, x, y = cell(ctx, player, dx, dy)

    if not ctx:walkable(level_id, x, y) then
        return "That would be an unthinking act."
    end
end

local function empty_neighbours(ctx, level_id, x, y)
    local count = 0

    for offset_y = -1, 1 do
        for offset_x = -1, 1 do
            local neighbour = offset_x ~= 0 or offset_y ~= 0
            local next_x = x + offset_x
            local next_y = y + offset_y

            if neighbour and ctx:walkable(level_id, next_x, next_y) and
                not ctx:actor_at(level_id, next_x, next_y) then
                count = count + 1
            end
        end
    end

    return count
end

-- Source: spl-damage.cc:base_airstrike_damage and cast_airstrike.
-- Air has no corresponding resistance in fight.cc:_beam_to_resist.
local function resolve(ctx, player, intent, _, power)
    local monster, level_id, x, y = target.at_aim(ctx, player, intent)

    if not monster then
        ctx:emit("spell", "The spell fizzles.")
        return
    end

    local definition = damage.monster(ctx, monster)

    if not definition then
        ctx:emit("spell", "The spell fizzles.")
        return
    end

    local sides = math.floor(power / 14)
    local remainder = power % 14

    if ctx:random("spell", 14) < remainder then
        sides = sides + 1
    end

    sides = sides + empty_neighbours(ctx, level_id, x, y) * 2

    local rolled = 0

    if sides > 0 then
        rolled = 2 + ctx:random("spell", sides) +
            ctx:random("spell", sides)
    end

    local ac = monster_defense.armour(ctx, monster, definition)
    local dealt = math.max(0, rolled - ctx:random("spell", ac + 1))

    damage.apply(ctx, monster, dealt)
    ctx:emit("spell", "The air twists around and strikes the " ..
        definition.name .. ".")
end

local spells = require("ids.spells")
local effect = {}

function effect.can_target(ctx, player)
    return target.visible_hostile(ctx, player, 7, false)
end

effect.prepare = prepare
effect.resolve = resolve

registry.add(spells.SPELL_AIRSTRIKE, effect)

return effect
