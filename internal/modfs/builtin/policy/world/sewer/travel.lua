-- Theory of operation: an accepted drain creates one Sewer floor through
-- the generic staged-level transaction. The player owns the exact return
-- site while visiting; leaving retires the floor and its temporary actors.
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local domains = require("constants.portal_domains")
local levels = require("policy.generation.branch_levels")
local portal = require("policy.world.sewer.portal")
local terrain = require("constants.terrain")

local travel = {}

-- A plan names the actor's actual cell so the kernel can reject stale
-- commands before staging another level.
local function source(position)
    return {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }
end

-- Time is compared against the saved deadline, not a fresh duration roll.
-- A failed entry leaves the drain and its clock untouched.
local function prepare_entry(ctx, position)
    local player = ctx:player()

    if ctx:get(player, component.PLAYER_SEWER_VISIT) then
        error("Sewer entrance found during an active visit")
    end

    local _, marker = portal.at(ctx, position.level_id,
        position.x, position.y)

    if not marker or marker.spent or
        ctx:aut() >= marker.expires_aut then
        return { message = "The sewer entrance has collapsed." }
    end

    local identity = ctx:get(player, component.PLAYER)

    if not identity then
        error("Sewer visitor has no character identity")
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "enter",
            source = source(position),
            generate_policy = "world.generate_sewer_level",
            generation_input = {
                species_id = identity.species_id,
                player_name = identity.name,
            },
            commit_policy = "world.sewer.commit_travel",
            expected_branch_id = branches.BRANCH_SEWER,
            expected_level_id = levels.id(branches.BRANCH_SEWER, 1),
        },
        cost = 10,
    }
end

-- The visit component is the reciprocal outside pointer. Sewer returns to
-- that exact cell; an occupant temporarily blocks exit rather than moving
-- the player to a different Dungeon coordinate without their knowledge.
local function prepare_exit(ctx, position)
    local visit = ctx:get(ctx:player(), component.PLAYER_SEWER_VISIT)

    if not visit or visit.level_id ~= position.level_id then
        error("Sewer exit has no matching visitor return site")
    end

    if not ctx:walkable(visit.origin_level_id,
        visit.origin_x, visit.origin_y) or
        ctx:actor_at(visit.origin_level_id,
            visit.origin_x, visit.origin_y) then
        return { message = "The way back through the drain is blocked." }
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "return",
            source = source(position),
            commit_policy = "world.sewer.commit_travel",
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

-- Portal terrain owns this direction rule; ordinary stair travel handles
-- all other features after this policy returns nil.
function travel.prepare(ctx, position, downstairs)
    local feature = ctx:cell(position.level_id, position.x, position.y)

    if feature == terrain.DNGN_ENTER_SEWER then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        return prepare_entry(ctx, position)
    end

    if feature == terrain.DNGN_EXIT_SEWER then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        return prepare_exit(ctx, position)
    end

    return nil
end

-- The kernel has already staged and checked the destination. Spend the
-- outside drain and move the player in the same transaction.
local function commit_entry(ctx, input)
    local site = input.source
    local destination = input.destination
    local entity, marker = portal.at(ctx, site.level_id, site.x, site.y)

    if not entity or marker.spent or
        ctx:aut() >= marker.expires_aut or
        ctx:cell(site.level_id, site.x, site.y) ~=
            terrain.DNGN_ENTER_SEWER then
        error("Sewer entrance changed during travel")
    end

    local player = ctx:player()

    ctx:add(player, component.PLAYER_SEWER_VISIT, {
        origin_level_id = site.level_id,
        origin_x = site.x,
        origin_y = site.y,
        level_id = destination.level_id,
        vault_id = input.vault_id,
    })

    marker.spent = true
    ctx:set(entity, component.WORLD_SEWER_PORTAL, marker)
    ctx:set_cell(site.level_id, site.x, site.y,
        terrain.DNGN_EXPIRED_PORTAL)
    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)

    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_SEWER)

    return { message = branch.entry_message }
end

-- Returning consumes the visit pointer. The generic transaction then
-- retires the Sewer floor, including monsters and loose items on it.
local function commit_exit(ctx, input)
    local destination = input.destination
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_SEWER_VISIT)

    if not visit or visit.level_id ~= input.source.level_id or
        visit.origin_level_id ~= destination.level_id then
        error("Sewer return site changed during travel")
    end

    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)
    ctx:remove(player, component.PLAYER_SEWER_VISIT)

    return { message = "You return from the sewer." }
end

-- This is the only Sewer-specific transaction callback; Go does not
-- dispatch on the portal's name or on a C++ vault constructor.
function travel.commit(ctx, input)
    local destination = input.destination

    if not destination or
        not ctx:walkable(destination.level_id,
            destination.x, destination.y) or
        ctx:actor_at(destination.level_id,
            destination.x, destination.y) then
        error("Sewer portal destination is unavailable")
    end

    if input.operation == "enter" then
        return commit_entry(ctx, input)
    end

    if input.operation == "return" then
        return commit_exit(ctx, input)
    end

    error("unknown Sewer travel operation")
end

register.policy({
    id = "world.sewer.commit_travel",
    run = travel.commit,
})

return travel
