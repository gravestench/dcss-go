local component = require("constants.component")
local common = require("policy.magic.effects.translocation.common")
local habitat = require("policy.combat.monster_habitat")
local net = require("policy.combat.net")
local targets = require("policy.ai.targets")
local teleport = require("policy.magic.effects.zaps.teleport_other")
local trajectory = require("policy.combat.trajectory")
local roll = require("policy.combat.roll")

local attraction = {}

local function nearest(left, right)
    return left.distance < right.distance
end

local function eligible(ctx, player, center, monster)
    local distance = common.distance(center, monster.position)

    if distance <= 1 or distance > 8 or
        not targets.enemy(ctx, player, monster.entity) or
        teleport.no_tele(monster.actor, monster.definition,
            ctx, monster.entity) then
        return false
    end

    return ctx:visible(center.level_id, center.x, center.y, 8,
        monster.position.x, monster.position.y)
end

local function destination(ctx, center, monster, steps)
    local position = monster.position
    local ray = trajectory.to_target(ctx, center.level_id,
        position.x, position.y, center.x, center.y, monster.distance)

    if ray.blocked then
        return nil
    end

    local last = math.min(steps, monster.distance - 1, #ray.path)

    for index = last, 1, -1 do
        local cell = ray.path[index]

        if not ctx:actor_at(center.level_id, cell.x, cell.y) and
            habitat.at(ctx, monster.entity, center.level_id,
                cell.x, cell.y) then
            return cell
        end
    end

    return nil
end

-- Source: spl-transloc.cc:attract_monsters. The source draws monsters
-- toward the player after each action, stopping at least one cell away.
function attraction.pull(ctx, player, aut)
    local center = ctx:get(player, component.POSITION)

    if not center then
        return
    end

    local monsters = {}

    for _, monster in ipairs(common.monsters(ctx, center.level_id)) do
        if eligible(ctx, player, center, monster) then
            monster.distance = common.distance(center, monster.position)
            monsters[#monsters + 1] = monster
        end
    end

    table.sort(monsters, nearest)

    for _, monster in ipairs(monsters) do
        local steps = roll.random_divide(ctx, 3 * aut, 10,
            "potion")
        local cell = destination(ctx, center, monster, steps)

        if cell then
            net.release(ctx, monster.entity)
            ctx:move_actor(monster.entity, center.level_id,
                cell.x, cell.y)
            ctx:emit("duration", "The " .. monster.definition.name ..
                " is attracted toward you.")
        end
    end
end

function attraction.tick(ctx, player, aut)
    local state = ctx:get(player, component.POTION_ATTRACTION)

    if not state or aut <= 0 then
        return
    end

    attraction.pull(ctx, player, aut)
    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.POTION_ATTRACTION)
        ctx:emit("duration", "You no longer feel attractive to monsters.")
    else
        ctx:set(player, component.POTION_ATTRACTION, state)
    end
end

return attraction
