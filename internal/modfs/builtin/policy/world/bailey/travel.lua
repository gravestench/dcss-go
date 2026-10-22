-- Theory of operation: an accepted gate creates one Bailey floor through
-- the generic staged-level transaction. The player owns the exact return
-- site while visiting; leaving retires the floor and its temporary actors.
local branches = require("ids.branches")
local bailey = require("constants.bailey")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local domains = require("constants.portal_domains")
local levels = require("policy.generation.branch_levels")
local portal = require("policy.world.bailey.portal")
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
-- A failed entry leaves the gate and its clock untouched.
local function prepare_entry(ctx, position)
    local player = ctx:player()

    if ctx:get(player, component.PLAYER_BAILEY_VISIT) then
        error("Bailey entrance found during an active visit")
    end

    local _, marker = portal.at(ctx, position.level_id,
        position.x, position.y)

    if not marker or marker.spent or
        ctx:aut() >= marker.expires_aut then
        return { message = "The bailey entrance has closed." }
    end

    local identity = ctx:get(player, component.PLAYER)

    if not identity then
        error("Bailey visitor has no character identity")
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "enter",
            source = source(position),
            generate_policy = "world.generate_bailey_level",
            generation_input = {
                species_id = identity.species_id,
                player_name = identity.name,
                theme = marker.theme,
            },
            commit_policy = "world.bailey.commit_travel",
            expected_branch_id = branches.BRANCH_BAILEY,
            expected_level_id = levels.id(branches.BRANCH_BAILEY, 1),
        },
        cost = 10,
    }
end

-- The visit component is the reciprocal outside pointer. Bailey returns to
-- that exact cell; an occupant temporarily blocks exit rather than moving
-- the player to a different Dungeon coordinate without their knowledge.
local function prepare_exit(ctx, position)
    local visit = ctx:get(ctx:player(), component.PLAYER_BAILEY_VISIT)

    if not visit or visit.level_id ~= position.level_id then
        error("Bailey exit has no matching visitor return site")
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
            commit_policy = "world.bailey.commit_travel",
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

    if feature == terrain.DNGN_ENTER_BAILEY then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        return prepare_entry(ctx, position)
    end

    if feature == terrain.DNGN_EXIT_BAILEY then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        return prepare_exit(ctx, position)
    end

    return nil
end

-- The kernel has already staged and checked the destination. Spend the
-- outside gate and move the player in the same transaction.
local function commit_entry(ctx, input)
    local site = input.source
    local destination = input.destination
    local entity, marker = portal.at(ctx, site.level_id, site.x, site.y)

    if not entity or marker.spent or
        ctx:aut() >= marker.expires_aut or
        ctx:cell(site.level_id, site.x, site.y) ~=
            terrain.DNGN_ENTER_BAILEY then
        error("Bailey entrance changed during travel")
    end

    local player = ctx:player()

    ctx:add(player, component.PLAYER_BAILEY_VISIT, {
        origin_level_id = site.level_id,
        origin_x = site.x,
        origin_y = site.y,
        level_id = destination.level_id,
        vault_id = input.vault_id,
        theme = marker.theme,
    })

    marker.spent = true
    marker.closure_reason = bailey.CLOSURE_ENTRY
    ctx:set(entity, component.WORLD_BAILEY_PORTAL, marker)
    ctx:set_cell(site.level_id, site.x, site.y,
        terrain.DNGN_STONE_ARCH)
    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)

    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_BAILEY)

    return { message = branch.entry_message }
end

-- Returning consumes the visit pointer. The generic transaction then
-- retires the Bailey floor, including monsters and loose items on it.
local function commit_exit(ctx, input)
    local destination = input.destination
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_BAILEY_VISIT)

    if not visit or visit.level_id ~= input.source.level_id or
        visit.origin_level_id ~= destination.level_id then
        error("Bailey return site changed during travel")
    end

    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)
    ctx:remove(player, component.PLAYER_BAILEY_VISIT)

    return { message = "You return from the bailey." }
end

-- This is the only Bailey-specific transaction callback; Go does not
-- dispatch on the portal's name or on a C++ vault constructor.
function travel.commit(ctx, input)
    local destination = input.destination

    if not destination or
        not ctx:walkable(destination.level_id,
            destination.x, destination.y) or
        ctx:actor_at(destination.level_id,
            destination.x, destination.y) then
        error("Bailey portal destination is unavailable")
    end

    if input.operation == "enter" then
        return commit_entry(ctx, input)
    end

    if input.operation == "return" then
        return commit_exit(ctx, input)
    end

    error("unknown Bailey travel operation")
end

register.policy({
    id = "world.bailey.commit_travel",
    run = travel.commit,
})

return travel
