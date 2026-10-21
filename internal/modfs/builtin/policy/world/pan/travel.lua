-- Theory of operation: a Pan portal produces one immutable travel plan
-- before any level or ECS entity changes. The plan owns source direction,
-- prior-vault history, and the original return site. Go stages the requested
-- level and commits this state only after generation and population succeed.
local operations = require("constants.pan_travel")
local region = require("policy.generation.pan.region")
local landing = require("policy.world.stair_landing")
local terrain = require("constants.terrain")
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")

local travel = {}

-- Copy the saved visit order before appending the active region's maps.
-- A failed plan must not change the history referenced by the live save.
local function history_ids(state, active_ids)
    local ids = {}

    for _, id in ipairs(state and state.vault_ids or {}) do
        ids[#ids + 1] = id
    end

    for _, id in ipairs(active_ids or {}) do
        ids[#ids + 1] = id
    end

    return ids
end

-- Record the portal cell once. Transit reuses this value and never pushes
-- its own gate, so a later exit returns to the ordinary world.
local function origin(position)
    return {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }
end

-- Build the next region's saved history before asking the generator to
-- draw. The unique storage ID lets Go stage it beside the current region.
local function new_region(state, active_ids, return_site, retire_id)
    local seen = state and state.regions_seen or 0
    local ids = history_ids(state, active_ids)
    local history = {
        levels_seen = seen,
        prior_vault_ids = ids,
    }
    local next_state = {
        regions_seen = seen + 1,
        vault_ids = ids,
        active_level_id = region.level_id(seen),
        return_site = return_site,
    }

    return {
        operation = operations.NEW_REGION,
        retire_level_id = retire_id,
        history = history,
        next_state = next_state,
    }
end

-- A completed visit still constrains once-per-run maps after its level is
-- retired. Clearing the return pointer prevents a later save from treating
-- a past region as the currently active one.
local function departed_state(state, active_ids)
    return {
        regions_seen = state.regions_seen,
        vault_ids = history_ids(state, active_ids),
        active_level_id = 0,
    }
end

-- Validate the saved active region before a source exit or transit uses it.
-- A portal on some other floor cannot consume a stale Pan return record.
local function active_state(position, state)
    if not state or state.active_level_id ~= position.level_id or
        not state.return_site then
        error("Pan portal has no matching active region and return site")
    end
end

-- Select the source gate's direction and structural operation. Ordinary
-- stairs return nil so their existing command path remains authoritative.
function travel.prepare(ctx, position, downstairs, state, active_ids)
    local feature = ctx:cell(position.level_id, position.x, position.y)
    local portal

    if feature == terrain.DNGN_ENTER_PANDEMONIUM then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        if state and state.active_level_id and
            state.active_level_id ~= 0 then
            error("cannot enter Pan while another region is active")
        end

        portal = new_region(state, {}, origin(position), 0)
    elseif feature == terrain.DNGN_TRANSIT_PANDEMONIUM then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        active_state(position, state)
        portal = new_region(state, active_ids, state.return_site,
            position.level_id)
    elseif feature == terrain.DNGN_EXIT_PANDEMONIUM then
        if downstairs then
            return { message = "There are no stairs down here." }
        end

        active_state(position, state)
        local site = state.return_site
        local x, y = landing.find(ctx, site.level_id, site.x, site.y)

        portal = {
            operation = operations.RETURN,
            retire_level_id = position.level_id,
            destination = {
                level_id = site.level_id,
                x = x,
                y = y,
            },
            next_state = departed_state(state, active_ids),
        }
    elseif feature == terrain.DNGN_EXIT_THROUGH_ABYSS then
        if not downstairs then
            return { message = "There are no stairs up here." }
        end

        active_state(position, state)
        local x, y = landing.find(ctx, abyss.level_id, 40, 35)

        portal = {
            operation = operations.ABYSS,
            retire_level_id = position.level_id,
            return_site = state.return_site,
            destination = {
                level_id = abyss.level_id,
                x = x,
                y = y,
            },
            next_state = departed_state(state, active_ids),
        }
    end

    if not portal then
        return nil
    end

    return {
        portal = portal,
        cost = 10,
    }
end

-- Apply one already staged and validated destination. Lua owns source
-- messages and the Abyss escape pointer; Go only exposes the generic grid
-- move and commits the saved Pan record after these ECS changes succeed.
function travel.commit(ctx, input)
    local operation = input.operation
    local destination = input.destination
    local player = ctx:player()
    local position = ctx:get(player, component.POSITION)

    if not position or not destination or
        not ctx:walkable(destination.level_id, destination.x,
            destination.y) or
        ctx:actor_at(destination.level_id, destination.x,
            destination.y) then
        error("Pan portal destination is unavailable")
    end

    if operation == operations.ABYSS then
        local site = input.return_site

        if not site then
            error("Pan Abyss exit has no original return site")
        end

        ctx:add(player, component.BANISHMENT, {
            origin_level_id = site.level_id,
            origin_x = site.x,
            origin_y = site.y,
        })
    end

    ctx:move_actor(player, destination.level_id,
        destination.x, destination.y)

    if operation == operations.NEW_REGION then
        local branch = catalog.get(categories.BRANCHES,
            branches.BRANCH_PANDEMONIUM)

        return { message = branch.entry_message }
    end

    if operation == operations.ABYSS then
        return { message = "You pass through the gate into the Abyss." }
    end

    return { message = "You pass through the gate." }
end

register.policy({
    id = "world.pan.commit_travel",
    run = travel.commit,
})

return travel
