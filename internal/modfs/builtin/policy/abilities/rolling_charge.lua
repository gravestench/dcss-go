-- Source: spl-transloc.cc:palentonga_charge. The charge follows a clear
-- cell-centre ray, stops beside the first monster, then makes one melee hit.
local abilities = require("ids.abilities")
local actions = require("policy.combat.melee_actions")
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local flight = require("policy.combat.flight")
local ids = require("policy.magic.effects.zaps.ids")
local levels = require("policy.mutations.levels")
local movement = require("policy.abilities.movement")
local mutations = require("ids.mutations")
local noise = require("policy.world.noise")
local registry = require("policy.abilities.registry")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local trajectory = require("policy.combat.trajectory")
local water = require("policy.character.water")

local charge = {}

function charge.range(level)
    return 3 + level
end

local function safe_path(ctx, player, origin, path, last)
    local airborne = flight.permanent(ctx, player)
    local swimmer = water.can_swim(ctx, player)

    for index = 1, last do
        local cell = path[index]
        local feature = ctx:cell(origin.level_id, cell.x, cell.y)

        if not airborne and
            (feature == terrain.DNGN_LAVA or
                (feature == terrain.DNGN_DEEP_WATER and
                    not swimmer)) then
            return false
        end
    end

    return true
end

function charge.plan(ctx, player, input)
    local dx = input.dx or 0
    local dy = input.dy or 0
    local origin = ctx:get(player, component.POSITION)
    local level = levels.effective(ctx, player, mutations.MUT_ROLL)
    local range = charge.range(level)
    local target_x = origin.x + dx
    local target_y = origin.y + dy

    if dx == 0 and dy == 0 then
        return nil, "Okay, then."
    end

    if math.max(math.abs(dx), math.abs(dy)) > range then
        return nil, "That's out of range!"
    end

    if not ctx:visible(origin.level_id, origin.x, origin.y,
        range, target_x, target_y) then
        return nil, "You cannot see that target."
    end

    local ray = trajectory.to_target(ctx, origin.level_id,
        origin.x, origin.y, target_x, target_y, range)
    local contact = ray.contacts[1]

    if not contact then
        return nil, "There's nothing you can charge at!"
    end

    local monster = contact.actor

    if monster == player or not ctx:has(monster, component.ACTOR) or
        not targets.enemy(ctx, player, monster) then
        return nil, "You cannot charge that creature."
    end

    local index

    for step, cell in ipairs(ray.path) do
        if cell.x == contact.x and cell.y == contact.y then
            index = step
            break
        end
    end

    if not index or index < 2 then
        return nil, "You're already next to your target!"
    end

    if not safe_path(ctx, player, origin, ray.path, index - 1) then
        return nil, "You cannot roll through dangerous terrain."
    end

    local destination = ray.path[index - 1]

    return {
        target = monster,
        destination = destination,
        path = ray.path,
        distance = math.max(math.abs(destination.x - origin.x),
            math.abs(destination.y - origin.y)),
    }
end

function charge.prepare(ctx, player, input)
    local _, rejection = charge.plan(ctx, player, input)

    return rejection
end

local function dust_trail(ctx, player, level_id, origin, plan)
    local visited = { origin }

    for index = 1, #plan.path - 2 do
        visited[#visited + 1] = plan.path[index]
    end

    for _, cell in ipairs(visited) do
        cloud.place(ctx, cloud_ids.CLOUD_DUST, player, level_id,
            cell.x, cell.y,
            (2 + ctx:random("mutation", 3)) * 10)
    end
end

function charge.resolve(ctx, player, intent)
    local plan, rejection = charge.plan(ctx, player, intent)

    if not plan then
        ctx:emit("mutation", rejection)
        return
    end

    if not movement.escape_grasp(ctx, player, 1) then
        return
    end

    local origin = ctx:get(player, component.POSITION)

    ctx:move_actor(player, origin.level_id,
        plan.destination.x, plan.destination.y)

    if ctx:has(player, component.WATER_HOLD) then
        ctx:remove(player, component.WATER_HOLD)
    end

    ctx:emit("combat", "You roll forward with a clatter of scales!")
    noise.emit(ctx, {
        level_id = origin.level_id,
        x = plan.destination.x,
        y = plan.destination.y,
    }, 4, player)
    dust_trail(ctx, player, origin.level_id, origin, plan)

    local target_position = ctx:get(plan.target, component.POSITION)
    local target_health = ctx:get(plan.target, component.HEALTH)

    if target_health and target_health.current > 0 and
        target_position and target_position.level_id == origin.level_id and
        math.max(math.abs(target_position.x - plan.destination.x),
            math.abs(target_position.y - plan.destination.y)) == 1 then
        actions.player(ctx, plan.target, {
            roll_distance = plan.distance,
        })
    end
end

registry.add(abilities.ROLLING_CHARGE, {
    mutation_id = mutations.MUT_ROLL,
    name = "Rolling Charge",
    range = charge.range,
    prepare = charge.prepare,
    resolve = charge.resolve,
})

return charge
