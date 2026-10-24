-- Theory of operation: Duel enters through a staged temporary branch.
-- A saved visit names the exact outside return cell; the chosen monster
-- keeps its ECS identity and accompanies the player only while still alive.
local branches = require("ids.branches")
local awareness = require("policy.ai.awareness")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local domains = require("constants.portal_domains")
local elven_twins = require("policy.monsters.elven_twins")
local twin_causes = require("constants.elven_twin")
local levels = require("policy.generation.branch_levels")
local terrain = require("constants.terrain")
local okawaru = require("constants.okawaru")

local travel = {}

-- Monster inventory does not transit into or out of Okawaru's Arena.
-- Destroy carried items before movement instead of dropping arena loot.
local function destroy_inventory(ctx, monster)
    for _, item in ipairs(ctx:query({ component.CARRIED_BY })) do
        local owner = ctx:get(item, component.CARRIED_BY)

        if owner.holder == monster then
            ctx:destroy(item)
        end
    end
end

-- A source forced transition breaks restraints and unfinished player
-- equipment actions rather than letting them resume on another level.
local function stop_delay(ctx, player, monster)
    for _, entity in ipairs({ player, monster }) do
        if ctx:has(entity, component.CONSTRICTION) then
            ctx:remove(entity, component.CONSTRICTION)
        end

        if ctx:has(entity, component.PLAYER_CONSTRICTION) then
            ctx:remove(entity, component.PLAYER_CONSTRICTION)
        end
    end

    if ctx:has(player, component.EQUIPMENT_DELAY) then
        ctx:remove(player, component.EQUIPMENT_DELAY)
    end
end

-- The staged floor must exist and the target must still occupy the chosen
-- outside cell when the timed action commits. Any error rolls back the plan.
local function enter(ctx, input)
    local player = ctx:player()
    local site = input.source
    local landing = input.destination
    local payload = input.payload or {}
    local markers = input.generation_output or {}
    local target_id = tonumber(payload.target_id)
    local target = target_id and ctx:entity(target_id)
    local position = target and ctx:get(target, component.POSITION)
    local health = target and ctx:get(target, component.HEALTH)

    if not target or not position or not health or
        health.current <= 0 or position.level_id ~= site.level_id or
        not ctx:walkable(landing.level_id,
            markers.target_x, markers.target_y) or
        ctx:actor_at(landing.level_id,
            markers.target_x, markers.target_y) then
        error("Duel target or Arena landing changed during travel")
    end

    local visit = {
        origin_level_id = site.level_id,
        origin_x = site.x,
        origin_y = site.y,
        level_id = landing.level_id,
        vault_id = input.vault_id,
        target_id = payload.target_id,
        target_x = markers.barrier_x,
        target_y = markers.barrier_y,
        exit_x = markers.exit_x,
        exit_y = markers.exit_y,
        victory = false,
        return_aut = 0,
    }

    stop_delay(ctx, player, target)
    destroy_inventory(ctx, target)
    -- The source treats an Arena challenge as a departure from the
    -- outside floor. Resolve the sibling before moving its target away.
    elven_twins.grieve(ctx, target, nil, position, twin_causes.DUEL)
    ctx:add(target, component.MONSTER_ARENA_DUEL, {
        current = true,
        abandoned = false,
        root_id = payload.target_id,
    })
    ctx:add(player, component.PLAYER_ARENA_VISIT, visit)
    ctx:move_actor(target, landing.level_id,
        markers.target_x, markers.target_y)
    ctx:move_actor(player, landing.level_id, landing.x, landing.y)
    -- The source explicitly alerts the challenger on arrival. This also
    -- prevents a sleeping target from treating the Duel as a free attack.
    awareness.alert(ctx, target, player)
    if not costs.enough_magic(ctx, player, okawaru.DUEL_MP) then
        local magic = ctx:get(player, component.MAGIC)

        error("Arena commitment has " ..
            tostring(magic and magic.current) .. " MP")
    end

    costs.spend(ctx, player, okawaru.DUEL_MP,
        costs.piety_cost(ctx, okawaru.DUEL_PIETY))

    return { message = "You enter Okawaru's Arena!" }
end

-- Find a free neighboring cell at the exact outside return site for a
-- living opponent. An occupied return site rejects the command freely.
local function target_return(ctx, visit, return_x, return_y)
    local sites = {}
    local reserved = {}

    for _, target in ipairs(ctx:query({
        component.MONSTER_ARENA_DUEL,
        component.POSITION,
        component.HEALTH,
    })) do
        local mark = ctx:get(target, component.MONSTER_ARENA_DUEL)
        local position = ctx:get(target, component.POSITION)
        local health = ctx:get(target, component.HEALTH)

        if mark.current and position.level_id == visit.level_id and
            health.current > 0 then
            local site

            for dy = -1, 1 do
                for dx = -1, 1 do
                    local x = return_x + dx
                    local y = return_y + dy
                    local key = x .. ":" .. y

                    if (dx ~= 0 or dy ~= 0) and not reserved[key] and
                        ctx:walkable(visit.origin_level_id, x, y) and
                        not ctx:actor_at(visit.origin_level_id, x, y) then
                        site = { id = tostring(ctx:id(target)), x = x, y = y }
                        reserved[key] = true
                        break
                    end
                end

                if site then
                    break
                end
            end

            if not site then
                return false
            end

            sites[#sites + 1] = site
        end
    end

    return sites
end

-- The visible < arch returns to the saved cell and retires this one-floor
-- branch. It remains usable before victory if a player can reach it.
function travel.prepare(ctx, position, downstairs)
    if ctx:cell(position.level_id, position.x, position.y) ~=
        terrain.DNGN_EXIT_ARENA then
        return nil
    end

    if downstairs then
        return { message = "There are no stairs down here." }
    end

    local visit = ctx:get(ctx:player(), component.PLAYER_ARENA_VISIT)

    if not visit or position.level_id ~= visit.level_id then
        error("Arena exit has no active Duel visit")
    end

    if not ctx:walkable(visit.origin_level_id,
        visit.origin_x, visit.origin_y) or
        ctx:actor_at(visit.origin_level_id,
            visit.origin_x, visit.origin_y) then
        return { message = "The way back from the Arena is blocked." }
    end

    local return_sites = target_return(ctx, visit,
        visit.origin_x, visit.origin_y)

    if return_sites == false then
        return { message = "There is no room for your opponent outside." }
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "return",
            source = {
                level_id = position.level_id,
                x = position.x,
                y = position.y,
            },
            commit_policy = "world.arena.commit_travel",
            retire_level_id = position.level_id,
            destination = {
                level_id = visit.origin_level_id,
                x = visit.origin_x,
                y = visit.origin_y,
            },
            payload = {
                targets = return_sites,
            },
        },
        cost = 10,
    }
end

-- Renunciation can happen anywhere in the Arena. If the original cell is
-- now occupied, find the nearest safe outside landing before the timed
-- action starts; ordinary voluntary exit still requires that exact cell.
function travel.prepare_forced(ctx, player, operation)
    local visit = ctx:get(player, component.PLAYER_ARENA_VISIT)
    local position = ctx:get(player, component.POSITION)

    if not visit then
        return nil
    end

    local landing

    for radius = 0, 5 do
        for dy = -radius, radius do
            for dx = -radius, radius do
                local x = visit.origin_x + dx
                local y = visit.origin_y + dy

                if math.max(math.abs(dx), math.abs(dy)) == radius and
                    ctx:walkable(visit.origin_level_id, x, y) and
                    not ctx:actor_at(visit.origin_level_id, x, y) then
                    landing = { x = x, y = y }
                    break
                end
            end

            if landing then
                break
            end
        end

        if landing then
            break
        end
    end

    if not landing then
        return { message = "There is no safe place to return from the Arena." }
    end

    local return_sites = target_return(ctx, visit, landing.x, landing.y)

    if return_sites == false then
        return { message = "There is no room for your opponent outside." }
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = operation or "renounce",
            source = {
                level_id = position.level_id,
                x = position.x,
                y = position.y,
            },
            commit_policy = "world.arena.commit_travel",
            retire_level_id = position.level_id,
            destination = {
                level_id = visit.origin_level_id,
                x = landing.x,
                y = landing.y,
            },
            payload = {
                targets = return_sites,
            },
        },
        cost = 10,
    }
end

-- Returning a live challenger destroys its arena gear again, clears the
-- current mark, and records the abandoned lineage at the outside landing.
local function leave(ctx, input)
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_ARENA_VISIT)
    local landing = input.destination

    if not visit or visit.level_id ~= input.source.level_id or
        visit.origin_level_id ~= landing.level_id or
        (input.operation == "return" and
            (visit.origin_x ~= landing.x or
                visit.origin_y ~= landing.y)) then
        error("Arena return site changed during travel")
    end

    local payload = input.payload or {}

    for _, site in ipairs(payload.targets or {}) do
        local target = ctx:entity(tonumber(site.id))
        local mark = target and ctx:get(target,
            component.MONSTER_ARENA_DUEL)

        if not mark or not mark.current or
            not ctx:walkable(landing.level_id, site.x, site.y) or
            ctx:actor_at(landing.level_id, site.x, site.y) then
            error("Arena opponent cannot return")
        end

        destroy_inventory(ctx, target)
        stop_delay(ctx, player, target)
        mark.current = false
        mark.abandoned = true
        ctx:set(target, component.MONSTER_ARENA_DUEL, mark)
        ctx:move_actor(target, landing.level_id, site.x, site.y)
    end

    ctx:move_actor(player, landing.level_id, landing.x, landing.y)
    ctx:remove(player, component.PLAYER_ARENA_VISIT)

    return { message = "You are returned from the Arena." }
end

-- The generic Lua portal owns staging, rollback, and floor retirement;
-- this callback owns only Okawaru's saved relationship and resource cost.
function travel.commit(ctx, input)
    if input.operation == "enter" then
        return enter(ctx, input)
    end

    if input.operation == "return" then
        return leave(ctx, input)
    end

    if input.operation == "depart" then
        return leave(ctx, input)
    end

    if input.operation == "renounce" then
        local result = leave(ctx, input)
        local worship = require("policy.religion.worship")

        if not worship.renounce(ctx, ctx:player()) then
            error("Arena renunciation lost Okawaru worship")
        end

        ctx:emit("religion", "You have renounced your religion.")

        return result
    end

    error("unknown Arena travel operation")
end

register.policy({
    id = "world.arena.commit_travel",
    run = travel.commit,
})

return travel
