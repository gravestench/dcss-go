-- Theory of operation: Lua decides whether this source gate may be used
-- and supplies the saved difficulty. The generic staged portal transaction
-- owns floor installation, rollback, and later retirement.
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local domains = require("constants.portal_domains")
local ice_cave = require("constants.ice_cave")
local levels = require("policy.generation.branch_levels")
local portal = require("policy.world.ice_cave.portal")
local terrain = require("constants.terrain")

local travel = {}

-- A plan names the actual player cell, so stale commands cannot target a
-- different entrance after movement or a floor change.
local function source(position)
    return {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }
end

-- Read the fixed entrance component. This check does not spend the gate;
-- failed generation leaves its timer and the current game unchanged.
local function prepare_entry(ctx, position)
    local player = ctx:player()

    if ctx:get(player, component.PLAYER_ICE_CAVE_VISIT) then
        error("Ice Cave entrance found during an active visit")
    end

    local _, marker = portal.at(ctx, position.level_id,
        position.x, position.y)

    if not marker or marker.spent or
        ctx:aut() >= marker.expires_aut then
        return { message = "The ice cave entrance has melted away." }
    end

    local identity = ctx:get(player, component.PLAYER)

    if not identity then
        error("Ice Cave visitor has no character identity")
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "enter",
            source = source(position),
            generate_policy = "world.generate_ice_cave_level",
            generation_input = {
                species_id = identity.species_id,
                player_name = identity.name,
                hard = marker.hard,
            },
            commit_policy = "world.ice_cave.commit_travel",
            expected_branch_id = branches.BRANCH_ICE_CAVE,
            expected_level_id = levels.id(branches.BRANCH_ICE_CAVE, 1),
        },
        cost = 10,
    }
end

-- The visit component is the reciprocal outside pointer. An actor on
-- that cell blocks return instead of silently moving the player elsewhere.
local function prepare_exit(ctx, position)
    local visit = ctx:get(ctx:player(), component.PLAYER_ICE_CAVE_VISIT)

    if not visit or visit.level_id ~= position.level_id then
        error("Ice Cave exit has no matching visitor return site")
    end

    if not ctx:walkable(visit.origin_level_id,
        visit.origin_x, visit.origin_y) or
        ctx:actor_at(visit.origin_level_id,
            visit.origin_x, visit.origin_y) then
        return { message = "The way back through the gate is blocked." }
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "return",
            source = source(position),
            commit_policy = "world.ice_cave.commit_travel",
            retire_level_id = position.level_id,
            destination = {
                level_id = visit.origin_level_id,
                x = visit.origin_x,
                y = visit.origin_y,
            },
        },
        cost = 10,
    }
end

-- The grid feature selects the direction; other stairs remain owned by
-- ordinary branch travel after this policy returns nil.
function travel.prepare(ctx, position, downstairs)
    local feature = ctx:cell(position.level_id, position.x, position.y)

    if feature == terrain.DNGN_ENTER_ICE_CAVE then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        return prepare_entry(ctx, position)
    end

    if feature == terrain.DNGN_EXIT_ICE_CAVE then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        return prepare_exit(ctx, position)
    end

    return nil
end

-- The destination is already staged and checked. Spending the outside
-- gate, adding the visit pointer, and moving the player are one commit.
local function commit_entry(ctx, input)
    local site = input.source
    local destination = input.destination
    local entity, marker = portal.at(ctx, site.level_id, site.x, site.y)

    if not entity or marker.spent or
        ctx:aut() >= marker.expires_aut or
        ctx:cell(site.level_id, site.x, site.y) ~=
            terrain.DNGN_ENTER_ICE_CAVE then
        error("Ice Cave entrance changed during travel")
    end

    local player = ctx:player()

    ctx:add(player, component.PLAYER_ICE_CAVE_VISIT, {
        origin_level_id = site.level_id,
        origin_x = site.x,
        origin_y = site.y,
        level_id = destination.level_id,
        vault_id = input.vault_id,
        hard = marker.hard,
    })

    marker.spent = true
    marker.closure_reason = ice_cave.CLOSURE_ENTRY
    ctx:set(entity, component.WORLD_ICE_CAVE_PORTAL, marker)
    ctx:set_cell(site.level_id, site.x, site.y,
        terrain.DNGN_EXPIRED_PORTAL)
    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)

    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_ICE_CAVE)

    return { message = branch.entry_message }
end

-- Returning removes the reciprocal pointer. The generic transaction
-- retires the temporary floor and every entity still owned by it.
local function commit_exit(ctx, input)
    local destination = input.destination
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_ICE_CAVE_VISIT)

    if not visit or visit.level_id ~= input.source.level_id or
        visit.origin_level_id ~= destination.level_id or
        visit.origin_x ~= destination.x or
        visit.origin_y ~= destination.y then
        error("Ice Cave return site changed during travel")
    end

    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)
    ctx:remove(player, component.PLAYER_ICE_CAVE_VISIT)

    return { message = "You return from the ice cave." }
end

-- This callback runs only after the staged kernel has checked the target.
-- A changed cell or occupant still aborts before mutating the visit.
function travel.commit(ctx, input)
    local destination = input.destination

    if not destination or
        not ctx:walkable(destination.level_id,
            destination.x, destination.y) or
        ctx:actor_at(destination.level_id,
            destination.x, destination.y) then
        error("Ice Cave portal destination is unavailable")
    end

    if input.operation == "enter" then
        return commit_entry(ctx, input)
    end

    if input.operation == "return" then
        return commit_exit(ctx, input)
    end

    error("unknown Ice Cave travel operation")
end

register.policy({
    id = "world.ice_cave.commit_travel",
    run = travel.commit,
})

return travel
