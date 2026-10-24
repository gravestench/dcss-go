-- Pacified monsters seek a way off the floor instead of joining the
-- ordinary neutral wander loop. The grid and trap ECS roster supply exit
-- facts; this owner decides which route and when departure is complete.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local constriction = require("policy.combat.constriction")
local engulf = require("policy.combat.engulf")
local flay = require("policy.combat.monster_flay")
local net = require("policy.combat.net")
local recall = require("policy.abilities.beogh.recall")
local route = require("policy.ai.route")
local senses = require("policy.character.senses")
local terrain = require("constants.terrain")
local trap_ids = require("ids.traps")
local intents = require("constants.intent")

local departure = {}
local DISTANT_EXIT = 21

-- Source also permits a pacified monster to leave through a teleport or
-- shaft trap. Trap entities keep their kind independently of the grid.
local function exit_trap(ctx, level_id, x, y)
    for _, entity in ipairs(ctx:query({ component.WORLD_TRAP })) do
        local trap = ctx:get(entity, component.WORLD_TRAP)

        if trap.level_id == level_id and trap.x == x and trap.y == y and
            (trap.kind_id == trap_ids.TRAP_TELEPORT or
                trap.kind_id == trap_ids.TRAP_TELEPORT_PERMANENT or
                trap.kind_id == trap_ids.TRAP_SHAFT) then
            return trap.kind_id
        end
    end

    return nil
end

-- The generic grid property includes stairs and travel gates. Keeping
-- this test here lets each modded level expose its own exit geometry.
local function exit_at(ctx, level_id, x, y)
    return ctx:travel_feature_at(level_id, x, y) or
        exit_trap(ctx, level_id, x, y) ~= nil
end

-- Cache the nearest reachable exit in the ordinary saved AI target. The
-- scan runs only when the current target disappears or becomes blocked.
local function choose_exit(ctx, state, position)
    local width, height = ctx:level_size(position.level_id)
    local trap_cells = {}
    local best
    local best_distance

    -- A trap is an ECS entity, so collect its cells once before scanning
    -- terrain instead of querying the trap roster for every grid square.
    for _, entity in ipairs(ctx:query({ component.WORLD_TRAP })) do
        local trap = ctx:get(entity, component.WORLD_TRAP)

        if trap.level_id == position.level_id and
            (trap.kind_id == trap_ids.TRAP_TELEPORT or
                trap.kind_id == trap_ids.TRAP_TELEPORT_PERMANENT or
                trap.kind_id == trap_ids.TRAP_SHAFT) then
            trap_cells[trap.y * width + trap.x] = true
        end
    end

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if (ctx:travel_feature_at(position.level_id, x, y) or
                trap_cells[y * width + x]) and
                not ctx:actor_at(position.level_id, x, y) then
                local dx, dy, found = ctx:route_step(position.level_id,
                    position.x, position.y, x, y, nil)
                local distance = math.max(math.abs(position.x - x),
                    math.abs(position.y - y))

                if found and (dx ~= 0 or dy ~= 0) and
                    (not best_distance or distance < best_distance) then
                    best = { x = x, y = y }
                    best_distance = distance
                end
            end
        end
    end

    if best then
        state.target_x = best.x
        state.target_y = best.y
    else
        state.target_x = 0
        state.target_y = 0
    end

    return best
end

-- Keep a valid saved destination through turns and saves. A moved stair,
-- occupant, or newly blocked route sends the monster to another exit.
function departure.intent(ctx, monster, state, position)
    if exit_at(ctx, position.level_id, position.x, position.y) then
        return state, { kind = intents.WAIT }
    end

    local target_x = state.target_x or 0
    local target_y = state.target_y or 0
    local valid = exit_at(ctx, position.level_id, target_x, target_y)
    local found = false

    if valid and not ctx:actor_at(position.level_id,
        target_x, target_y) then
        local _, _, reachable = ctx:route_step(position.level_id,
            position.x, position.y, target_x, target_y, nil)

        found = reachable
    end

    if not found and not choose_exit(ctx, state, position) then
        return nil
    end

    local target = { x = state.target_x, y = state.target_y }

    return state, route.follow(ctx, monster, state, position,
        target, nil, false, true)
end

-- Source dismisses an already pacified actor on an exit, or once it is
-- three normal sight radii from the player. Other neutral actors stay.
local function ready(ctx, monster, position)
    if not ctx:has(monster, component.ELYVILON_PACIFIED) then
        return false
    end

    local player = ctx:get(ctx:player(), component.POSITION)
    local distance = player and player.level_id == position.level_id and
        math.max(math.abs(position.x - player.x),
            math.abs(position.y - player.y)) or 0

    return exit_at(ctx, position.level_id, position.x, position.y) or
        distance >= DISTANT_EXIT
end

-- Source names the physical route only when the player sees that cell.
-- A distant hard reset and an unseen trap do not reveal the escape path.
local function announce(ctx, position, name)
    if not senses.player_sees_cell(ctx, position) then
        return
    end

    local feature = ctx:cell(position.level_id, position.x, position.y)
    local action

    if feature == terrain.DNGN_STONE_STAIRS_UP_I then
        action = " goes up the stairs."
    elseif feature == terrain.DNGN_STONE_STAIRS_DOWN_I then
        action = " goes down the stairs."
    elseif ctx:travel_feature_at(position.level_id,
        position.x, position.y) then
        action = " passes through the gate."
    elseif exit_trap(ctx, position.level_id,
        position.x, position.y) == trap_ids.TRAP_SHAFT then
        action = " jumps into the shaft."
    end

    if action then
        ctx:emit("religion", "The " .. name .. action)
    end
end

-- Leaving is a hard reset: carried gear departs with the monster and
-- no corpse, on-death hook, or second XP award runs. Clear live links
-- before deleting the actor so saved relations cannot name a missing ID.
function departure.complete(ctx, monster)
    local position = ctx:get(monster, component.POSITION)

    if not position or not ready(ctx, monster, position) then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    announce(ctx, position, definition.name)

    flay.release_for_ghost(ctx, monster)
    net.release(ctx, monster)
    constriction.release_for(ctx, monster)
    engulf.release_for(ctx, monster)
    recall.forget(ctx, ctx:player(), monster)

    for _, ally in ipairs(ctx:query({ component.SUMMON_BOND })) do
        local bond = ctx:get(ally, component.SUMMON_BOND)

        if bond.guardian == monster then
            ctx:remove(ally, component.SUMMON_BOND)
        end
    end

    for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(item, component.CARRIED_BY)

        if carrier.holder == monster then
            ctx:destroy(item)
        end
    end

    ctx:remove_actor(monster, position.level_id)
    ctx:destroy(monster)

    return true
end

return departure
