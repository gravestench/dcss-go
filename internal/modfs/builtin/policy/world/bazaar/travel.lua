-- Theory of operation: the outside gate creates one Bazaar floor through
-- the generic staged-level transaction. Lua saves its exact return cell on
-- the player and spends the entrance only after staging succeeds. The exit
-- returns to that cell and retires the market with all of its shop stock.
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local domains = require("constants.portal_domains")
local landing = require("policy.world.stair_landing")
local levels = require("policy.generation.branch_levels")
local portal = require("policy.world.bazaar.portal")
local terrain = require("constants.terrain")

local travel = {}

-- All portal plans carry their actual source cell. The kernel rejects a
-- stale plan if its cell differs from the actor's current location.
local function source(position)
    return {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }
end

-- An entrance is usable only while its corresponding saved marker still
-- owns a live arch and no Bazaar visit is already in progress.
local function prepare_entry(ctx, position)
    local player = ctx:player()

    if ctx:get(player, component.PLAYER_BAZAAR_VISIT) then
        error("Bazaar entrance found during an active visit")
    end

    local _, marker = portal.at(ctx, position.level_id,
        position.x, position.y)

    if not marker or marker.spent or
        (marker.timed and ctx:aut() >= marker.expires_aut) then
        return { message = "The gate to the bazaar has closed." }
    end

    local identity = ctx:get(player, component.PLAYER)

    if not identity then
        error("Bazaar visitor has no character identity")
    end

    return {
        portal = {
            domain = domains.LUA,
            operation = "enter",
            source = source(position),
            generate_policy = "world.generate_bazaar_level",
            generation_input = {
                species_id = identity.species_id,
                player_name = identity.name,
            },
            commit_policy = "world.bazaar.commit_travel",
            expected_branch_id = branches.BRANCH_BAZAAR,
            expected_level_id = levels.id(branches.BRANCH_BAZAAR, 1),
        },
        cost = 10,
    }
end

-- The visit component is the sole return pointer. A newly generated
-- Bazaar cannot claim an unrelated outside level or an old visit's gate.
local function prepare_exit(ctx, position)
    local visit = ctx:get(ctx:player(), component.PLAYER_BAZAAR_VISIT)

    if not visit or visit.level_id ~= position.level_id then
        error("Bazaar exit has no matching visitor return site")
    end

    local x, y = landing.find(ctx, visit.origin_level_id,
        visit.origin_x, visit.origin_y)

    return {
        portal = {
            domain = domains.LUA,
            operation = "return",
            source = source(position),
            commit_policy = "world.bazaar.commit_travel",
            retire_level_id = position.level_id,
            destination = {
                level_id = visit.origin_level_id,
                x = x,
                y = y,
            },
        },
        cost = 10,
    }
end

-- Stair direction remains a rule of the terrain under the player. A
-- regular stair falls through to the ordinary navigation owner.
function travel.prepare(ctx, position, downstairs)
    local feature = ctx:cell(position.level_id, position.x, position.y)

    if feature == terrain.DNGN_ENTER_BAZAAR then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        return prepare_entry(ctx, position)
    end

    if feature == terrain.DNGN_EXIT_BAZAAR then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        return prepare_exit(ctx, position)
    end

    return nil
end

-- After the kernel has staged and checked the destination, spend the
-- source arch, store the return pointer, and move the ECS player together.
local function commit_entry(ctx, input)
    local site = input.source
    local destination = input.destination
    local entity, marker = portal.at(ctx, site.level_id, site.x, site.y)

    if not entity or marker.spent or
        ctx:cell(site.level_id, site.x, site.y) ~=
            terrain.DNGN_ENTER_BAZAAR then
        error("Bazaar entrance changed during travel")
    end

    local player = ctx:player()

    ctx:add(player, component.PLAYER_BAZAAR_VISIT, {
        origin_level_id = site.level_id,
        origin_x = site.x,
        origin_y = site.y,
        level_id = destination.level_id,
        vault_id = input.vault_id,
    })

    marker.spent = true
    ctx:set(entity, component.WORLD_BAZAAR_PORTAL, marker)
    ctx:set_cell(site.level_id, site.x, site.y,
        terrain.DNGN_STONE_ARCH)
    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)

    local branch = catalog.get(categories.BRANCHES,
        branches.BRANCH_BAZAAR)

    return { message = branch.entry_message }
end

-- The one-way outside arch was spent at entry, so exit only consumes the
-- active return pointer and leaves the old market ready for retirement.
local function commit_exit(ctx, input)
    local destination = input.destination
    local player = ctx:player()
    local visit = ctx:get(player, component.PLAYER_BAZAAR_VISIT)

    if not visit or visit.level_id ~= input.source.level_id or
        visit.origin_level_id ~= destination.level_id then
        error("Bazaar return site changed during travel")
    end

    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)
    ctx:remove(player, component.PLAYER_BAZAAR_VISIT)

    return { message = "You return from the bazaar." }
end

-- This policy is the only Bazaar-specific commit callback. Go supplies
-- a validated landing and calls it inside the normal portal transaction.
function travel.commit(ctx, input)
    local destination = input.destination

    if not destination or
        not ctx:walkable(destination.level_id,
            destination.x, destination.y) or
        ctx:actor_at(destination.level_id,
            destination.x, destination.y) then
        error("Bazaar portal destination is unavailable")
    end

    if input.operation == "enter" then
        return commit_entry(ctx, input)
    end

    if input.operation == "return" then
        return commit_exit(ctx, input)
    end

    error("unknown Bazaar travel operation")
end

register.policy({
    id = "world.bazaar.commit_travel",
    run = travel.commit,
})

return travel
